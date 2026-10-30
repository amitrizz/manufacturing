import { Router } from 'express';
import { connectToMongo, normalizeDoc } from '../config/db.js';
import { validate, validateObjectId, companyIdSchema } from '../middlewares/validation.js';
import { z } from 'zod';

const router = Router();

// Validation schemas
const grnReceiveSchema = z.object({
  po_id: z.string().optional(),
  supplier_id: z.string().uuid().optional(),
  invoice_number: z.string().max(100).optional(),
  notes: z.string().max(500).optional(),
  received_items: z.array(z.object({
    material_id: z.string().min(1),
    received_qty: z.number().positive(),
  })).min(1, 'At least one item required'),
});

// GET /purchase/grn-receipts
router.get('/purchase/grn-receipts', async (req, res) => {
  try {
    const database = await connectToMongo();
    const companyId = req.companyId;
    const scope = companyId ? { company_id: companyId } : {};

    const [grns, pos, suppliers, txs, materials] = await Promise.all([
      database.collection('grn_receipts').find(scope).sort({ created_at: -1 }).toArray(),
      database.collection('purchase_orders').find(scope).toArray(),
      database.collection('suppliers').find(scope).toArray(),
      database.collection('stock_transactions').find({ ...scope, reference_type: 'GRN' }).toArray(),
      database.collection('materials').find(scope).toArray(),
    ]);

    const poMap = new Map(pos.map((p) => [p.id || String(p._id), p]));
    const supMap = new Map(suppliers.map((s) => [s.id || String(s._id), s]));
    const matMap = new Map(materials.map((m) => [m.id || String(m._id), m]));

    const txByGrn = {};
    for (const tx of txs) {
      const refId = tx.reference_id;
      if (!refId) continue;
      if (!txByGrn[refId]) txByGrn[refId] = [];
      const mat = matMap.get(tx.material_id);
      txByGrn[refId].push({
        material_id: tx.material_id,
        material_name: mat?.name || 'Material',
        material_code: mat?.code || '',
        quantity: tx.quantity,
        unit: mat?.unit || 'units',
      });
    }

    const result = grns.map((g) => {
      const gId = g.id || String(g._id);
      const po = g.po_id ? poMap.get(g.po_id) : null;
      const sup = g.supplier_id ? supMap.get(g.supplier_id) : null;
      const items = txByGrn[gId] || [];
      const total_qty = items.reduce((sum, it) => sum + (it.quantity || 0), 0);
      const items_summary =
        items.length > 0
          ? items.map((it) => `${it.material_name} (${it.quantity} ${it.unit})`).join(', ')
          : 'Direct Inward';

      return {
        ...normalizeDoc(g),
        po_number: po?.po_number || null,
        supplier_name: sup?.name || 'Supplier Unassigned',
        items,
        total_qty,
        items_summary,
      };
    });

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /purchase/receive-grn - Using MongoDB transactions for atomicity
router.post('/purchase/receive-grn', validate(grnReceiveSchema), async (req, res) => {
  const database = await connectToMongo();
  const client = database.client;
  const { po_id, supplier_id, invoice_number, notes, received_items } = req.validatedBody;
  const companyId = req.companyId;
  const now = Date.now();

  // Validate received items have positive quantities
  if (!received_items || received_items.length === 0) {
    return res.status(400).json({ error: 'At least one item with positive quantity required' });
  }

  const session = client.startSession();
  
  try {
    const result = await session.withTransaction(async () => {
      // 1. Generate GRN number (within transaction to avoid race conditions)
      const countScope = companyId ? { company_id: companyId } : {};
      const count = await database.collection('grn_receipts').countDocuments(countScope, { session });
      const seq = (count + 1).toString().padStart(4, '0');
      const grnNumber = `GRN-${seq}`;
      const grnId = `grn-${now}-${Math.random().toString(36).substr(2, 6)}`;

      // 2. Create GRN document
      const grnDoc = {
        _id: grnId,
        id: grnId,
        grn_number: grnNumber,
        po_id: po_id || null,
        supplier_id: supplier_id || null,
        received_date: now,
        invoice_number: invoice_number?.trim() || null,
        notes: notes?.trim() || null,
        created_at: now,
        updated_at: now,
        company_id: companyId,
      };
      await database.collection('grn_receipts').insertOne(grnDoc, { session });

      // 3. Process each received item
      for (const item of received_items) {
        const qty = Number(item.received_qty);
        if (qty <= 0) continue;

        const matFilter = { 
          $or: [{ id: item.material_id }, { _id: item.material_id }] 
        };
        if (companyId) matFilter.company_id = companyId;

        // Update material stock
        const materialResult = await database.collection('materials').updateOne(
          matFilter,
          { $inc: { current_stock: qty }, $set: { updated_at: now } },
          { session }
        );

        if (materialResult.matchedCount === 0) {
          throw new Error(`Material not found: ${item.material_id}`);
        }

        // Update PO item received quantity if linked to PO
        if (po_id) {
          const poItemFilter = { 
            po_id: po_id, 
            material_id: item.material_id 
          };
          if (companyId) poItemFilter.company_id = companyId;
          
          await database.collection('purchase_order_items').updateOne(
            poItemFilter,
            { $inc: { received_quantity: qty } },
            { session }
          );
        }

        // Create stock transaction
        const txDoc = {
          _id: `tx-${now}-${Math.random().toString(36).substr(2, 6)}`,
          id: `tx-${now}`,
          material_id: item.material_id,
          transaction_type: 'IN',
          category: 'RAW_MATERIAL',
          quantity: qty,
          reference_type: 'GRN',
          reference_id: grnId,
          notes: `Received via ${grnNumber}`,
          created_at: now,
          company_id: companyId,
        };
        await database.collection('stock_transactions').insertOne(txDoc, { session });
      }

      // 4. Update PO status if linked
      if (po_id) {
        const poItemFilter = { po_id: po_id };
        if (companyId) poItemFilter.company_id = companyId;
        
        const poItems = await database.collection('purchase_order_items').find(poItemFilter, { session }).toArray();
        if (poItems.length > 0) {
          const allReceived = poItems.every((it) => (it.received_quantity || 0) >= it.quantity);
          const newStatus = allReceived ? 'RECEIVED' : 'PARTIALLY_RECEIVED';
          
          const poFilter = { $or: [{ id: po_id }, { _id: po_id }] };
          if (companyId) poFilter.company_id = companyId;
          
          await database.collection('purchase_orders').updateOne(
            poFilter,
            { $set: { status: newStatus, updated_at: now } },
            { session }
          );
        }
      }

      // 5. Create activity log
      const actDoc = {
        _id: `act-${now}`,
        id: `act-${now}`,
        event_type: 'GRN_RECEIVED',
        title: `${grnNumber} processed`,
        description: po_id ? 'Stock updated from PO receipt' : 'Direct material inward received',
        reference_type: 'GRN',
        reference_id: grnId,
        timestamp: now,
        created_at: now,
        company_id: companyId,
      };
      await database.collection('activity_history').insertOne(actDoc, { session });

      return { success: true, grnId, grnNumber };
    });

    res.status(201).json(result);
  } catch (err) {
    // Transaction automatically aborted
    res.status(500).json({ error: err.message });
  } finally {
    await session.endSession();
  }
});

// DELETE /purchase/delete-grn/:id - Using transactions for atomicity
router.delete('/purchase/delete-grn/:id', validateObjectId('id'), async (req, res) => {
  const database = await connectToMongo();
  const client = database.client;
  const grnId = req.params.id;
  const companyId = req.companyId;
  const now = Date.now();

  const session = client.startSession();

  try {
    const result = await session.withTransaction(async () => {
      // Find GRN
      const grnFilter = { $or: [{ id: grnId }, { _id: grnId }] };
      if (companyId) grnFilter.company_id = companyId;
      
      const grn = await database.collection('grn_receipts').findOne(grnFilter, { session });
      if (!grn) {
        throw new Error('GRN_NOT_FOUND');
      }

      // Get related stock transactions
      const txFilter = { reference_type: 'GRN', reference_id: grnId };
      if (companyId) txFilter.company_id = companyId;
      
      const txs = await database.collection('stock_transactions').find(txFilter, { session }).toArray();

      // Reverse stock for each transaction
      for (const tx of txs) {
        if (tx.material_id) {
          const matFilter = { $or: [{ id: tx.material_id }, { _id: tx.material_id }] };
          if (companyId) matFilter.company_id = companyId;
          
          await database.collection('materials').updateOne(
            matFilter,
            { $inc: { current_stock: -tx.quantity }, $set: { updated_at: now } },
            { session }
          );

          if (grn.po_id) {
            const poItemFilter = { po_id: grn.po_id, material_id: tx.material_id };
            if (companyId) poItemFilter.company_id = companyId;
            
            await database.collection('purchase_order_items').updateOne(
              poItemFilter,
              { $inc: { received_quantity: -tx.quantity } },
              { session }
            );
          }
        }
      }

      // Update PO status if linked
      if (grn.po_id) {
        const poItemFilter = { po_id: grn.po_id };
        if (companyId) poItemFilter.company_id = companyId;
        
        const poItems = await database.collection('purchase_order_items').find(poItemFilter, { session }).toArray();
        const anyReceived = poItems.some((it) => (it.received_quantity || 0) > 0);
        const allReceived = poItems.length > 0 && poItems.every((it) => (it.received_quantity || 0) >= it.quantity);
        const newStatus = allReceived ? 'RECEIVED' : anyReceived ? 'PARTIALLY_RECEIVED' : 'ISSUED';
        
        const poFilter = { $or: [{ id: grn.po_id }, { _id: grn.po_id }] };
        if (companyId) poFilter.company_id = companyId;
        
        await database.collection('purchase_orders').updateOne(
          poFilter,
          { $set: { status: newStatus, updated_at: now } },
          { session }
        );
      }

      // Delete stock transactions
      await database.collection('stock_transactions').deleteMany(txFilter, { session });

      // Delete GRN
      await database.collection('grn_receipts').deleteOne(grnFilter, { session });

      // Create activity log
      const actDoc = {
        _id: `act-${now}`,
        id: `act-${now}`,
        event_type: 'GRN_DELETED',
        title: 'GRN reversed',
        description: 'Goods receipt deleted and stock reversed',
        reference_type: 'GRN',
        reference_id: grnId,
        timestamp: now,
        created_at: now,
        company_id: companyId,
      };
      await database.collection('activity_history').insertOne(actDoc, { session });

      return { success: true, deletedGrn: grnId };
    });

    res.json(result);
  } catch (err) {
    if (err.message === 'GRN_NOT_FOUND') {
      return res.status(404).json({ error: 'GRN not found' });
    }
    res.status(500).json({ error: err.message });
  } finally {
    await session.endSession();
  }
});

export default router;
