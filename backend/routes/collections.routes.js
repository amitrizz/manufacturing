import { Router } from 'express';
import { ObjectId } from 'mongodb';
import { connectToMongo, normalizeDoc } from '../config/db.js';

const router = Router();

// Collections that are globally shared across all companies
const GLOBAL_COLLECTIONS = new Set(['companies', 'units']);

router.get('/collections/:name', async (req, res) => {
  try {
    const database = await connectToMongo();
    const colName = req.params.name;
    const col = database.collection(colName);

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
          key !== 'grn_number' &&
          key !== 'id' &&
          key !== '_id' &&
          key !== 'reference_id' &&
          key !== 'batch_number' &&
          key !== 'order_number' &&
          key !== 'rework_number' &&
          key !== 'machine_id' &&
          key !== 'product_id' &&
          key !== 'line_id' &&
          key !== 'plan_id' &&
          key !== 'po_id' &&
          key !== 'supplier_id' &&
          key !== 'customer_id' &&
          key !== 'company_id' &&
          key !== 'code'
        ) {
          filter[key] = Number(value);
        } else {
          filter[key] = value;
        }
      }
    }

    // Auto-scope by company if collection is multi-tenant and companyId is provided
    if (!GLOBAL_COLLECTIONS.has(colName) && req.companyId && !filter.company_id) {
      filter.company_id = req.companyId;
    }

    const docs = await col.find(filter).sort({ created_at: -1 }).toArray();
    res.json(docs.map(normalizeDoc));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/collections/:name/:id', async (req, res) => {
  try {
    const database = await connectToMongo();
    const colName = req.params.name;
    const col = database.collection(colName);
    const { id } = req.params;

    let idFilter = { $or: [{ id: id }, { _id: id }] };
    if (ObjectId.isValid(id)) {
      idFilter.$or.push({ _id: new ObjectId(id) });
    }

    let filter = idFilter;
    if (!GLOBAL_COLLECTIONS.has(colName) && req.companyId) {
      filter = { $and: [idFilter, { $or: [{ company_id: req.companyId }, { company_id: null }, { company_id: { $exists: false } }] }] };
    }

    const doc = await col.findOne(filter);
    if (!doc) return res.status(404).json({ error: 'Document not found' });
    res.json(normalizeDoc(doc));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/collections/:name', async (req, res) => {
  try {
    const database = await connectToMongo();
    const colName = req.params.name;
    const col = database.collection(colName);
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

    // Auto-assign company_id if multi-tenant collection
    if (!GLOBAL_COLLECTIONS.has(colName)) {
      const companyId = body.company_id || req.companyId;
      if (companyId) {
        doc.company_id = companyId;
      }
    }

    await col.insertOne(doc);
    res.status(201).json(normalizeDoc(doc));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/collections/:name/:id', async (req, res) => {
  try {
    const database = await connectToMongo();
    const colName = req.params.name;
    const col = database.collection(colName);
    const { id } = req.params;
    const now = Date.now();

    const updates = { ...req.body, updated_at: now };
    delete updates._id;

    let idFilter = { $or: [{ id: id }, { _id: id }] };
    if (ObjectId.isValid(id)) {
      idFilter.$or.push({ _id: new ObjectId(id) });
    }

    let filter = idFilter;
    if (!GLOBAL_COLLECTIONS.has(colName) && req.companyId) {
      filter = { $and: [idFilter, { $or: [{ company_id: req.companyId }, { company_id: null }, { company_id: { $exists: false } }] }] };
    }

    const result = await col.findOneAndUpdate(
      filter,
      { $set: updates },
      { returnDocument: 'after' }
    );

    const doc = result?.value || result;
    if (!doc) {
      return res.status(404).json({ error: 'Document not found' });
    }
    res.json(normalizeDoc(doc));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/collections/:name/:id', async (req, res) => {
  try {
    const database = await connectToMongo();
    const colName = req.params.name;
    const col = database.collection(colName);
    const { id } = req.params;

    let idFilter = { $or: [{ id: id }, { _id: id }] };
    if (ObjectId.isValid(id)) {
      idFilter.$or.push({ _id: new ObjectId(id) });
    }

    let filter = idFilter;
    if (!GLOBAL_COLLECTIONS.has(colName) && req.companyId) {
      filter = { $and: [idFilter, { $or: [{ company_id: req.companyId }, { company_id: null }, { company_id: { $exists: false } }] }] };
    }

    await col.deleteOne(filter);
    res.json({ success: true, deletedId: id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
