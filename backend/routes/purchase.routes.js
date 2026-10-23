import { Router } from 'express';
import { connectToMongo, normalizeDoc } from '../config/db.js';

const router = Router();

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

router.post('/purchase/receive-grn', async (req, res) => {
  try {
    const database = await connectToMongo();
    const { po_id, supplier_id, invoice_number, notes, received_items = [] } = req.body;
    const companyId = req.body.company_id || req.companyId || null;
    const now = Date.now();

    const countScope = companyId ? { company_id: companyId } : {};
    const count = await database.collection('grn_receipts').countDocuments(countScope);
    const seq = (count + 1).toString().padStart(4, '0');
    const grnNumber = `GRN-${seq}`;
    const grnId = `grn-${now}-${Math.random().toString(36).substr(2, 6)}`;

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
    };
    if (companyId) grnDoc.company_id = companyId;
    await database.collection('grn_receipts').insertOne(grnDoc);

    for (const item of received_items) {
      const qty = Number(item.received_qty);
      if (qty <= 0) continue;

      const matFilter = { $or: [{ id: item.material_id }, { _id: item.material_id }] };
      await database.collection('materials').updateOne(
        matFilter,
        { $inc: { current_stock: qty }, $set: { updated_at: now } }
      );

      if (po_id) {
        await database.collection('purchase_order_items').updateOne(
          { po_id: po_id, material_id: item.material_id },
          { $inc: { received_quantity: qty } }
        );
      }

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
      };
      if (companyId) txDoc.company_id = companyId;
      await database.collection('stock_transactions').insertOne(txDoc);
    }

    if (po_id) {
      const poItems = await database.collection('purchase_order_items').find({ po_id: po_id }).toArray();
      if (poItems.length > 0) {
        const allReceived = poItems.every((it) => (it.received_quantity || 0) >= it.quantity);
        const newStatus = allReceived ? 'RECEIVED' : 'PARTIALLY_RECEIVED';
        await database.collection('purchase_orders').updateOne(
          { $or: [{ id: po_id }, { _id: po_id }] },
          { $set: { status: newStatus, updated_at: now } }
        );
      }
    }

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
    };
    if (companyId) actDoc.company_id = companyId;
    await database.collection('activity_history').insertOne(actDoc);

    res.status(201).json({ success: true, grnId, grnNumber });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/purchase/delete-grn/:id', async (req, res) => {
  try {
    const database = await connectToMongo();
    const grnId = req.params.id;

    const grn = await database.collection('grn_receipts').findOne({ $or: [{ id: grnId }, { _id: grnId }] });
    if (!grn) return res.status(404).json({ error: 'GRN not found' });

    const companyId = grn.company_id || req.companyId || null;
    const txs = await database.collection('stock_transactions').find({ reference_type: 'GRN', reference_id: grnId }).toArray();
    const now = Date.now();

    for (const tx of txs) {
      if (tx.material_id) {
        await database.collection('materials').updateOne(
          { $or: [{ id: tx.material_id }, { _id: tx.material_id }] },
          { $inc: { current_stock: -tx.quantity }, $set: { updated_at: now } }
        );

        if (grn.po_id) {
          await database.collection('purchase_order_items').updateOne(
            { po_id: grn.po_id, material_id: tx.material_id },
            { $inc: { received_quantity: -tx.quantity } }
          );
        }
      }
    }

    if (grn.po_id) {
      const poItems = await database.collection('purchase_order_items').find({ po_id: grn.po_id }).toArray();
      const anyReceived = poItems.some((it) => (it.received_quantity || 0) > 0);
      const allReceived = poItems.length > 0 && poItems.every((it) => (it.received_quantity || 0) >= it.quantity);
      const newStatus = allReceived ? 'RECEIVED' : anyReceived ? 'PARTIALLY_RECEIVED' : 'ISSUED';
      await database.collection('purchase_orders').updateOne(
        { $or: [{ id: grn.po_id }, { _id: grn.po_id }] },
        { $set: { status: newStatus, updated_at: now } }
      );
    }

    await database.collection('stock_transactions').deleteMany({ reference_type: 'GRN', reference_id: grnId });
    await database.collection('grn_receipts').deleteOne({ $or: [{ id: grnId }, { _id: grnId }] });

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
    };
    if (companyId) actDoc.company_id = companyId;
    await database.collection('activity_history').insertOne(actDoc);

    res.json({ success: true, deletedGrn: grnId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
