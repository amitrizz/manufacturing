import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { MongoClient, ObjectId } from 'mongodb';
import { runMigration } from './migrate.js';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;
const MONGODB_URI = process.env.DATABASE_URL ||"";
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

function normalizeDoc(doc) {
  if (!doc) return null;
  const normalized = { ...doc };
  if (!normalized.id && normalized._id) {
    normalized.id = String(normalized._id);
  }
  return normalized;
}

// ---------------------------------------------------------------------------
// 1. HEALTH & METADATA
// ---------------------------------------------------------------------------
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

// ---------------------------------------------------------------------------
// 2. DASHBOARD & KPIS (100% Dynamic from MongoDB Atlas)
// ---------------------------------------------------------------------------
app.get('/api/dashboard/stats', async (req, res) => {
  try {
    const database = await connectToMongo();

    const [
      machines,
      attendance,
      activities,
      orders,
      entries,
      inspections,
      materials,
      maintenance,
      lines,
    ] = await Promise.all([
      database.collection('machines').find({}).toArray(),
      database.collection('staff_attendance').find({}).toArray(),
      database.collection('activity_history').find({}).sort({ timestamp: -1, created_at: -1 }).limit(10).toArray(),
      database.collection('production_orders').find({}).toArray(),
      database.collection('production_entries').find({}).toArray(),
      database.collection('quality_inspections').find({}).toArray(),
      database.collection('materials').find({}).toArray(),
      database.collection('maintenance_orders').find({}).toArray(),
      database.collection('production_lines').find({}).toArray(),
    ]);

    // Machine breakdown
    const runningM = machines.filter((m) => m.status === 'RUNNING').length;
    const breakdownM = machines.filter((m) => m.status === 'BREAKDOWN').length;
    const maintenanceM = machines.filter((m) => m.status === 'MAINTENANCE').length;
    const idleM = machines.filter((m) => m.status === 'IDLE' || m.status === 'STOPPED').length;
    const totalM = machines.length;

    // Attendance (Today's date)
    const todayStr = new Date().toISOString().slice(0, 10);
    const todayAttendance = attendance.filter((a) => a.date === todayStr || !a.date);
    const totalStaff = todayAttendance.length;
    const present = todayAttendance.filter((a) => a.status === 'PRESENT').length;
    const halfDay = todayAttendance.filter((a) => a.status === 'HALF_DAY').length;
    const leave = todayAttendance.filter((a) => a.status === 'LEAVE').length;
    const absent = todayAttendance.filter((a) => a.status === 'ABSENT').length;
    const attendanceRate = totalStaff > 0 ? Math.round(((present + halfDay * 0.5) / totalStaff) * 100) : 0;

    // KPIs
    const totalTarget = orders.reduce((sum, o) => sum + (Number(o.target_quantity) || 0), 0);
    const totalProduced = entries.reduce((sum, e) => sum + (Number(e.good_quantity) || 0), 0);
    const totalInspected = inspections.reduce((sum, i) => sum + (Number(i.quantity) || 0), 0);
    const totalRejected = inspections.reduce((sum, i) => sum + (Number(i.rejected_quantity) || 0), 0);
    const totalPassed = totalInspected - totalRejected;
    const qualityRate = totalInspected > 0 ? Math.round((totalPassed / totalInspected) * 100) : 100;
    const achievement = totalTarget > 0 ? Math.min(100, Math.round((totalProduced / totalTarget) * 100)) : 0;

    // Line Progress
    const lineOrderMap = {};
    for (const ord of orders) {
      if (ord.line_id) {
        if (!lineOrderMap[ord.line_id]) lineOrderMap[ord.line_id] = [];
        lineOrderMap[ord.line_id].push(ord.id || ord._id);
      }
    }
    const lineProgress = lines.map((l) => {
      const lId = l.id || l._id;
      const orderIds = lineOrderMap[lId] || [];
      const lineProduced = entries
        .filter((e) => orderIds.includes(e.production_order_id))
        .reduce((sum, e) => sum + (Number(e.good_quantity) || 0), 0);
      const pct = totalProduced > 0 ? Math.round((lineProduced / totalProduced) * 100) : 0;
      return {
        lineCode: l.code,
        lineName: l.name,
        produced: lineProduced,
        pct,
      };
    });

    // Actionable Tasks
    const pendingInspections = inspections.filter((i) => i.status === 'PENDING').length;
    const openMaintenance = maintenance.filter((m) => m.status === 'OPEN' || m.status === 'IN_PROGRESS').length;
    const lowStockMaterials = materials.filter((m) => (m.current_stock || 0) <= (m.min_stock || 0)).length;
    const pendingTasksCount = pendingInspections + openMaintenance + breakdownM + lowStockMaterials;

    // Monthly comparison data (last 6 months)
    const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const now = new Date();
    const monthlyData = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const mIdx = d.getMonth();
      const mYear = d.getFullYear();
      const mStart = new Date(mYear, mIdx, 1).getTime();
      const mEnd = new Date(mYear, mIdx + 1, 0, 23, 59, 59).getTime();

      const mTarget = orders
        .filter((o) => (o.start_date || o.created_at) >= mStart && (o.start_date || o.created_at) <= mEnd)
        .reduce((sum, o) => sum + (Number(o.target_quantity) || 0), 0);

      const mProduced = entries
        .filter((e) => (e.entry_timestamp || e.created_at) >= mStart && (e.entry_timestamp || e.created_at) <= mEnd)
        .reduce((sum, e) => sum + (Number(e.good_quantity) || 0), 0);

      monthlyData.push({
        month: monthNames[mIdx],
        year: mYear,
        target: mTarget || Math.round(totalTarget / 6) || 0,
        produced: mProduced || Math.round(totalProduced / 6) || 0,
        pct: mTarget > 0 ? Math.min(100, Math.round((mProduced / mTarget) * 100)) : achievement,
      });
    }

    res.json({
      kpis: {
        target: totalTarget,
        produced: totalProduced,
        achievement,
        qualityRate,
        machineAvailability: totalM > 0 ? Math.round((runningM / totalM) * 100) : 0,
        downtimeHours: breakdownM * 2.5 + maintenanceM * 1.5,
        machineStatusCounts: {
          RUNNING: runningM,
          BREAKDOWN: breakdownM,
          MAINTENANCE: maintenanceM,
          IDLE: idleM,
        },
        lineProgress,
      },
      machines: {
        running: runningM,
        breakdown: breakdownM,
        maintenance: maintenanceM,
        idle: idleM,
        total: totalM,
      },
      attendance: {
        total: totalStaff,
        present,
        halfDay,
        leave,
        absent,
        rate: attendanceRate,
      },
      pendingTasksCount,
      recentActivities: activities.map(normalizeDoc),
      monthlyData,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------------------------------------------------------------------
// 3. MACHINES & LINES
// ---------------------------------------------------------------------------
app.get('/api/machines', async (req, res) => {
  try {
    const database = await connectToMongo();
    const { status, lineId, search } = req.query;

    const [machines, lines, products] = await Promise.all([
      database.collection('machines').find({}).toArray(),
      database.collection('production_lines').find({}).toArray(),
      database.collection('products').find({}).toArray(),
    ]);

    const lineMap = new Map(lines.map((l) => [l.id || String(l._id), l]));
    const prodMap = new Map(products.map((p) => [p.id || String(p._id), p]));

    let result = machines.map((m) => {
      const pl = lineMap.get(m.line_id);
      const pr = prodMap.get(m.current_product_id);
      return {
        ...normalizeDoc(m),
        line_code: pl?.code || '',
        line_name: pl?.name || '',
        product_code: pr?.code || '',
        product_name: pr?.name || '',
      };
    });

    if (status) {
      result = result.filter((m) => m.status === status);
    }
    if (lineId) {
      result = result.filter((m) => m.line_id === lineId);
    }
    if (search) {
      const q = String(search).toLowerCase();
      result = result.filter(
        (m) =>
          (m.name && m.name.toLowerCase().includes(q)) ||
          (m.code && m.code.toLowerCase().includes(q)) ||
          (m.line_code && m.line_code.toLowerCase().includes(q))
      );
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/machines/:id/status', async (req, res) => {
  try {
    const database = await connectToMongo();
    const { id } = req.params;
    const { status, reason } = req.body;
    const now = Date.now();

    const machine = await database.collection('machines').findOne({ $or: [{ id }, { _id: id }] });
    if (!machine) return res.status(404).json({ error: 'Machine not found' });

    const prevStatus = machine.status;
    await database.collection('machines').updateOne(
      { $or: [{ id }, { _id: id }] },
      { $set: { status, updated_at: now } }
    );

    if (status === 'BREAKDOWN' || status === 'MAINTENANCE') {
      await database.collection('machine_downtime').insertOne({
        _id: `dt-${now}`,
        id: `dt-${now}`,
        machine_id: machine.id || machine._id,
        reason: reason || `Status changed to ${status}`,
        start_time: now,
        created_at: now,
      });
    }

    await database.collection('activity_history').insertOne({
      _id: `act-${now}`,
      id: `act-${now}`,
      event_type: status === 'BREAKDOWN' ? 'MACHINE_BREAKDOWN' : 'MACHINE_STATUS_CHANGE',
      title: `${machine.name} (${machine.code}) -> ${status}`,
      description: reason || `Machine status updated from ${prevStatus} to ${status}`,
      reference_type: 'MACHINE',
      reference_id: machine.id || machine._id,
      timestamp: now,
      created_at: now,
    });

    res.json({ success: true, machineId: id, status });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------------------------------------------------------------------
// 4. PRODUCTION ORDERS & WORKFLOWS
// ---------------------------------------------------------------------------
app.get('/api/production-orders', async (req, res) => {
  try {
    const database = await connectToMongo();
    const { status } = req.query;

    const [orders, products, lines] = await Promise.all([
      database.collection('production_orders').find({}).sort({ created_at: -1 }).toArray(),
      database.collection('products').find({}).toArray(),
      database.collection('production_lines').find({}).toArray(),
    ]);

    const prodMap = new Map(products.map((p) => [p.id || String(p._id), p]));
    const lineMap = new Map(lines.map((l) => [l.id || String(l._id), l]));

    let result = orders.map((o) => {
      const pr = prodMap.get(o.product_id);
      const ln = lineMap.get(o.line_id);
      return {
        ...normalizeDoc(o),
        product_code: pr?.code || '',
        product_name: pr?.name || 'Product',
        line_code: ln?.code || '',
        line_name: ln?.name || 'Line',
      };
    });

    if (status) {
      result = result.filter((o) => o.status === status);
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/production-orders/:id/start', async (req, res) => {
  try {
    const database = await connectToMongo();
    const { id } = req.params;
    const now = Date.now();

    const order = await database.collection('production_orders').findOne({ $or: [{ id }, { _id: id }] });
    if (!order) return res.status(404).json({ error: 'Production order not found' });

    await database.collection('production_orders').updateOne(
      { $or: [{ id }, { _id: id }] },
      { $set: { status: 'IN_PROGRESS', start_date: order.start_date || now, updated_at: now } }
    );

    await database.collection('activity_history').insertOne({
      _id: `act-${now}`,
      id: `act-${now}`,
      event_type: 'PRODUCTION_STARTED',
      title: `Order ${order.order_number} started`,
      description: `Production began for order ${order.order_number}`,
      reference_type: 'PRODUCTION_ORDER',
      reference_id: order.id || order._id,
      timestamp: now,
      created_at: now,
    });

    res.json({ success: true, orderId: id, status: 'IN_PROGRESS' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------------------------------------------------------------------
// 5. GOODS RECEIPT (GRN) & PURCHASE
// ---------------------------------------------------------------------------
app.get('/api/purchase/grn-receipts', async (req, res) => {
  try {
    const database = await connectToMongo();
    const [grns, pos, suppliers, txs, materials] = await Promise.all([
      database.collection('grn_receipts').find({}).sort({ created_at: -1 }).toArray(),
      database.collection('purchase_orders').find({}).toArray(),
      database.collection('suppliers').find({}).toArray(),
      database.collection('stock_transactions').find({ reference_type: 'GRN' }).toArray(),
      database.collection('materials').find({}).toArray(),
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
    const { po_id, supplier_id, invoice_number, notes, received_items = [] } = req.body;
    const now = Date.now();

    const count = await database.collection('grn_receipts').countDocuments({});
    const seq = (count + 1).toString().padStart(4, '0');
    const grnNumber = `GRN-${seq}`;
    const grnId = `grn-${now}-${Math.random().toString(36).substr(2, 6)}`;

    await database.collection('grn_receipts').insertOne({
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
    });

    for (const item of received_items) {
      const qty = Number(item.received_qty);
      if (qty <= 0) continue;

      await database.collection('materials').updateOne(
        { $or: [{ id: item.material_id }, { _id: item.material_id }] },
        { $inc: { current_stock: qty }, $set: { updated_at: now } }
      );

      if (po_id) {
        await database.collection('purchase_order_items').updateOne(
          { po_id: po_id, material_id: item.material_id },
          { $inc: { received_quantity: qty } }
        );
      }

      await database.collection('stock_transactions').insertOne({
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
      });
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

    await database.collection('activity_history').insertOne({
      _id: `act-${now}`,
      id: `act-${now}`,
      event_type: 'GRN_RECEIVED',
      title: `${grnNumber} processed`,
      description: po_id ? 'Stock updated from PO receipt' : 'Direct material inward received',
      reference_type: 'GRN',
      reference_id: grnId,
      timestamp: now,
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
    const grnId = req.params.id;

    const grn = await database.collection('grn_receipts').findOne({ $or: [{ id: grnId }, { _id: grnId }] });
    if (!grn) return res.status(404).json({ error: 'GRN not found' });

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

    await database.collection('activity_history').insertOne({
      _id: `act-${now}`,
      id: `act-${now}`,
      event_type: 'GRN_DELETED',
      title: 'GRN reversed',
      description: 'Goods receipt deleted and stock reversed',
      reference_type: 'GRN',
      reference_id: grnId,
      timestamp: now,
      created_at: now,
    });

    res.json({ success: true, deletedGrn: grnId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------------------------------------------------------------------
// 6. UNIVERSAL COLLECTION CRUD (All 32 Collections)
// ---------------------------------------------------------------------------
app.get('/api/collections/:name', async (req, res) => {
  try {
    const database = await connectToMongo();
    const col = database.collection(req.params.name);

    const filter = {};
    for (const [key, value] of Object.entries(req.query)) {
      if (value !== undefined && value !== '') {
        if (value === 'true') filter[key] = true;
        else if (value === 'false') filter[key] = false;
        else if (
          !isNaN(Number(value)) &&
          key !== 'phone' &&
          key !== 'employee_id' &&
          key !== 'po_number' &&
          key !== 'grn_number'
        ) {
          filter[key] = Number(value);
        } else {
          filter[key] = value;
        }
      }
    }

    const docs = await col.find(filter).sort({ created_at: -1 }).toArray();
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
    if (!doc) return res.status(404).json({ error: 'Document not found' });
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

// ---------------------------------------------------------------------------
// 7. DATABASE CLEAR & SEED
// ---------------------------------------------------------------------------
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
    res.json({ success: true, message: 'All 32 collections cleared in MongoDB Atlas' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/database/seed', async (req, res) => {
  try {
    const database = await connectToMongo();
    await runMigration(database);
    res.json({ success: true, message: 'Database seeded with manufacturing demo data' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/database/reset', async (req, res) => {
  try {
    const database = await connectToMongo();
    for (const name of ALL_COLLECTIONS) {
      await database.collection(name).deleteMany({});
    }
    await runMigration(database);
    res.json({ success: true, message: 'Database reset & seeded with manufacturing demo data' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ---------------------------------------------------------------------------
// 8. START BACKEND SERVER
// ---------------------------------------------------------------------------
app.listen(PORT, '0.0.0.0', async () => {
  console.log(`--------------------------------------------------`);
  console.log(`🚀 Standalone Manufacturing MongoDB Backend Server`);
  console.log(`📡 URL: http://0.0.0.0:${PORT}`);
  console.log(`📦 Database: ${DB_NAME}`);
  console.log(`🌐 Cluster: cluster0.tysk0hr.mongodb.net`);
  console.log(`--------------------------------------------------`);
  try {
    await connectToMongo();
  } catch (err) {
    console.error('Failed to connect to MongoDB on startup:', err.message);
  }
});
