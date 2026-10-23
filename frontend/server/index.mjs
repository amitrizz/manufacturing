import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { MongoClient, ObjectId } from 'mongodb';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;
const MONGODB_URI =
  process.env.DATABASE_URL ||
  'mongodb+srv://amit:amit@cluster0.tysk0hr.mongodb.net/manufacturing?retryWrites=true&w=majority&appName=Cluster0';
const DB_NAME = process.env.MONGODB_DB_NAME || 'manufacturing';

app.use(cors());
app.use(express.json({ limit: '10mb' }));

let client;
let db;

async function connectToMongo() {
  if (!db) {
    client = new MongoClient(MONGODB_URI);
    await client.connect();
    db = client.db(DB_NAME);
    console.log(`✅ MongoDB connected successfully to database: ${DB_NAME}`);
  }
  return db;
}

// Health check
app.get('/api/health', async (req, res) => {
  try {
    const database = await connectToMongo();
    const cols = await database.listCollections().toArray();
    res.json({
      status: 'ok',
      database: DB_NAME,
      collectionsCount: cols.length,
      cluster: 'cluster0.tysk0hr.mongodb.net',
    });
  } catch (err) {
    res.status(500).json({ status: 'error', error: err.message });
  }
});

// Helper for consistent ID handling
function normalizeDoc(doc) {
  if (!doc) return null;
  const normalized = { ...doc };
  if (!normalized.id && normalized._id) {
    normalized.id = String(normalized._id);
  }
  return normalized;
}

// ----------------------------------------------------
// Universal Collection CRUD API
// ----------------------------------------------------
app.get('/api/collections/:name', async (req, res) => {
  try {
    const database = await connectToMongo();
    const col = database.collection(req.params.name);

    const filter = {};
    for (const [key, value] of Object.entries(req.query)) {
      if (value !== undefined && value !== '') {
        if (value === 'true') filter[key] = true;
        else if (value === 'false') filter[key] = false;
        else if (!isNaN(Number(value)) && key !== 'phone' && key !== 'employee_id' && key !== 'po_number' && key !== 'grn_number') {
          filter[key] = Number(value);
        } else {
          filter[key] = value;
        }
      }
    }

    const sortField = req.params.name === 'stock_transactions' ? 'created_at' : 'created_at';
    const docs = await col.find(filter).sort({ [sortField]: -1 }).toArray();
    res.json(docs.map(normalizeDoc));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/collections/:name/:id', async (req, res) => {
  try {
    const database = await connectToMongo();
    const col = database.collection(req.params.name);
    const { id } = req.params;

    let filter = { $or: [{ id: id }, { _id: id }] };
    if (ObjectId.isValid(id)) {
      filter.$or.push({ _id: new ObjectId(id) });
    }

    const doc = await col.findOne(filter);
    if (!doc) {
      return res.status(404).json({ error: 'Document not found' });
    }
    res.json(normalizeDoc(doc));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/collections/:name', async (req, res) => {
  try {
    const database = await connectToMongo();
    const col = database.collection(req.params.name);
    const now = Date.now();
    const body = req.body || {};

    const id = body.id || body._id || `id-${now}-${Math.random().toString(36).substr(2, 7)}`;
    const doc = {
      ...body,
      _id: id,
      id: id,
      created_at: body.created_at || now,
      updated_at: now,
    };

    await col.insertOne(doc);
    res.status(201).json(normalizeDoc(doc));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.put('/api/collections/:name/:id', async (req, res) => {
  try {
    const database = await connectToMongo();
    const col = database.collection(req.params.name);
    const { id } = req.params;
    const now = Date.now();

    const updates = { ...req.body, updated_at: now };
    delete updates._id;

    let filter = { $or: [{ id: id }, { _id: id }] };
    if (ObjectId.isValid(id)) {
      filter.$or.push({ _id: new ObjectId(id) });
    }

    const result = await col.findOneAndUpdate(
      filter,
      { $set: updates },
      { returnDocument: 'after' }
    );

    res.json(normalizeDoc(result.value || result));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/collections/:name/:id', async (req, res) => {
  try {
    const database = await connectToMongo();
    const col = database.collection(req.params.name);
    const { id } = req.params;

    let filter = { $or: [{ id: id }, { _id: id }] };
    if (ObjectId.isValid(id)) {
      filter.$or.push({ _id: new ObjectId(id) });
    }

    await col.deleteOne(filter);
    res.json({ success: true, deletedId: id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ----------------------------------------------------
// Specific Business Operations for Goods Receipt (GRN)
// ----------------------------------------------------
app.get('/api/purchase/grn-receipts', async (req, res) => {
  try {
    const database = await connectToMongo();
    const grnCol = database.collection('grn_receipts');
    const poCol = database.collection('purchase_orders');
    const supCol = database.collection('suppliers');
    const txCol = database.collection('stock_transactions');
    const matCol = database.collection('materials');

    const [grns, pos, suppliers, txs, materials] = await Promise.all([
      grnCol.find({}).sort({ created_at: -1 }).toArray(),
      poCol.find({}).toArray(),
      supCol.find({}).toArray(),
      txCol.find({ reference_type: 'GRN' }).toArray(),
      matCol.find({}).toArray(),
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

app.post('/api/purchase/receive-grn', async (req, res) => {
  try {
    const database = await connectToMongo();
    const grnCol = database.collection('grn_receipts');
    const poCol = database.collection('purchase_orders');
    const poiCol = database.collection('purchase_order_items');
    const matCol = database.collection('materials');
    const txCol = database.collection('stock_transactions');
    const actCol = database.collection('activity_history');

    const { po_id, supplier_id, invoice_number, notes, received_items = [] } = req.body;
    const now = Date.now();

    const count = await grnCol.countDocuments({});
    const seq = (count + 1).toString().padStart(4, '0');
    const grnNumber = `GRN-${seq}`;
    const grnId = `grn-${now}-${Math.random().toString(36).substr(2, 6)}`;

    // 1. Insert GRN record
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
    await grnCol.insertOne(grnDoc);

    // 2. Process received items
    for (const item of received_items) {
      const qty = Number(item.received_qty);
      if (qty <= 0) continue;

      // Update material stock
      await matCol.updateOne(
        { $or: [{ id: item.material_id }, { _id: item.material_id }] },
        { $inc: { current_stock: qty }, $set: { updated_at: now } }
      );

      // If linked to PO, update PO item
      if (po_id) {
        await poiCol.updateOne(
          { po_id: po_id, material_id: item.material_id },
          { $inc: { received_quantity: qty } }
        );
      }

      // Add to stock_transactions
      const txId = `tx-${now}-${Math.random().toString(36).substr(2, 6)}`;
      await txCol.insertOne({
        _id: txId,
        id: txId,
        material_id: item.material_id,
        transaction_type: 'IN',
        category: 'RAW_MATERIAL',
        quantity: qty,
        reference_type: 'GRN',
        reference_id: grnId,
        notes: `Received via ${grnNumber}`,
        created_at: now,
      });
    }

    // 3. Update PO status if linked
    if (po_id) {
      const poItems = await poiCol.find({ po_id: po_id }).toArray();
      if (poItems.length > 0) {
        const allReceived = poItems.every((it) => (it.received_quantity || 0) >= it.quantity);
        const newStatus = allReceived ? 'RECEIVED' : 'PARTIALLY_RECEIVED';
        await poCol.updateOne(
          { $or: [{ id: po_id }, { _id: po_id }] },
          { $set: { status: newStatus, updated_at: now } }
        );
      }
    }

    // 4. Log activity
    await actCol.insertOne({
      _id: `act-${now}-${Math.random().toString(36).substr(2, 6)}`,
      id: `act-${now}`,
      event_type: 'GRN_RECEIVED',
      title: `${grnNumber} processed`,
      description: po_id ? 'Stock updated from PO receipt' : 'Direct material inward received',
      reference_type: 'GRN',
      reference_id: grnId,
      created_at: now,
    });

    res.status(201).json({ success: true, grnId, grnNumber });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/purchase/delete-grn/:id', async (req, res) => {
  try {
    const database = await connectToMongo();
    const grnCol = database.collection('grn_receipts');
    const poCol = database.collection('purchase_orders');
    const poiCol = database.collection('purchase_order_items');
    const matCol = database.collection('materials');
    const txCol = database.collection('stock_transactions');
    const actCol = database.collection('activity_history');

    const grnId = req.params.id;
    const grn = await grnCol.findOne({ $or: [{ id: grnId }, { _id: grnId }] });
    if (!grn) {
      return res.status(404).json({ error: 'GRN not found' });
    }

    const txs = await txCol.find({ reference_type: 'GRN', reference_id: grnId }).toArray();
    const now = Date.now();

    for (const tx of txs) {
      if (tx.material_id) {
        await matCol.updateOne(
          { $or: [{ id: tx.material_id }, { _id: tx.material_id }] },
          { $inc: { current_stock: -tx.quantity }, $set: { updated_at: now } }
        );

        if (grn.po_id) {
          await poiCol.updateOne(
            { po_id: grn.po_id, material_id: tx.material_id },
            { $inc: { received_quantity: -tx.quantity } }
          );
        }
      }
    }

    if (grn.po_id) {
      const poItems = await poiCol.find({ po_id: grn.po_id }).toArray();
      const anyReceived = poItems.some((it) => (it.received_quantity || 0) > 0);
      const allReceived = poItems.length > 0 && poItems.every((it) => (it.received_quantity || 0) >= it.quantity);
      const newStatus = allReceived ? 'RECEIVED' : anyReceived ? 'PARTIALLY_RECEIVED' : 'ISSUED';
      await poCol.updateOne(
        { $or: [{ id: grn.po_id }, { _id: grn.po_id }] },
        { $set: { status: newStatus, updated_at: now } }
      );
    }

    await txCol.deleteMany({ reference_type: 'GRN', reference_id: grnId });
    await grnCol.deleteOne({ $or: [{ id: grnId }, { _id: grnId }] });

    await actCol.insertOne({
      _id: `act-${now}-${Math.random().toString(36).substr(2, 6)}`,
      id: `act-${now}`,
      event_type: 'GRN_DELETED',
      title: 'GRN reversed',
      description: 'Goods receipt deleted and stock reversed',
      reference_type: 'GRN',
      reference_id: grnId,
      created_at: now,
    });

    res.json({ success: true, deletedGrn: grnId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ----------------------------------------------------
// Database Reset & Clear Endpoints
// ----------------------------------------------------
const ALL_COLLECTIONS = [
  'companies',
  'company_roles',
  'staff',
  'staff_attendance',
  'factories',
  'production_lines',
  'machines',
  'machine_downtime',
  'materials',
  'product_categories',
  'products',
  'bom',
  'bom_items',
  'production_plans',
  'production_orders',
  'production_entries',
  'quality_inspections',
  'quality_results',
  'rework_orders',
  'maintenance_orders',
  'maintenance_history',
  'finished_goods',
  'dispatch_orders',
  'suppliers',
  'customers',
  'purchase_requests',
  'purchase_orders',
  'purchase_order_items',
  'grn_receipts',
  'stock_transactions',
  'activity_history',
  'notifications',
];

app.post('/api/database/clear', async (req, res) => {
  try {
    const database = await connectToMongo();
    for (const name of ALL_COLLECTIONS) {
      await database.collection(name).deleteMany({});
    }
    res.json({ success: true, message: 'All business collections cleared in MongoDB Atlas' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/database/reset', async (req, res) => {
  try {
    const database = await connectToMongo();
    // Clear first
    for (const name of ALL_COLLECTIONS) {
      await database.collection(name).deleteMany({});
    }
    // Import using migration logic
    const { execSync } = await import('child_process');
    execSync('node scripts/migrate-to-mongodb.mjs', { stdio: 'inherit' });
    res.json({ success: true, message: 'MongoDB demo data re-seeded successfully' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Start listening
app.listen(PORT, '0.0.0.0', async () => {
  console.log(`--------------------------------------------------`);
  console.log(`🚀 Manufacturing MongoDB Backend API Server`);
  console.log(`📡 Listening on: http://0.0.0.0:${PORT}`);
  console.log(`📦 MongoDB Database: ${DB_NAME}`);
  console.log(`🌐 Cluster: cluster0.tysk0hr.mongodb.net`);
  console.log(`--------------------------------------------------`);
  try {
    await connectToMongo();
  } catch (err) {
    console.error('Failed to connect to MongoDB on startup:', err.message);
  }
});
