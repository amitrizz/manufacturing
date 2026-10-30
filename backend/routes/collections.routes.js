import { Router } from 'express';
import { ObjectId } from 'mongodb';
import { connectToMongo, normalizeDoc } from '../config/db.js';
import { validate, paginationSchema, validateObjectId, sanitizeQuery } from '../middlewares/validation.js';

const router = Router();

// Collections that are globally shared across all companies
const GLOBAL_COLLECTIONS = new Set(['companies', 'units']);
const MAX_LIMIT = 500;
const DEFAULT_LIMIT = 50;

router.get('/collections/:name', validate(paginationSchema), sanitizeQuery, async (req, res) => {
  try {
    const database = await connectToMongo();
    const colName = req.params.name;
    const col = database.collection(colName);

    // Validate collection name (alphanumeric + underscore)
    if (!/^[a-zA-Z][a-zA-Z0-9_]*$/.test(colName)) {
      return res.status(400).json({ error: 'Invalid collection name' });
    }

    const filter = {};
    const validatedQuery = req.validatedQuery || {};
    const { limit, skip, sort, order } = validatedQuery;
    
    // Ensure limit and skip are integers with defaults
    const safeLimit = Math.min(parseInt(limit) || DEFAULT_LIMIT, MAX_LIMIT);
    const safeSkip = parseInt(skip) || 0;
    
    // Build filter from query params (excluding pagination params)
    for (const [key, value] of Object.entries(req.query)) {
      if (['limit', 'skip', 'sort', 'order'].includes(key)) continue;
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
    console.log('[DEBUG] GET /collections/:name:', { colName, companyId: req.companyId, filterKeys: Object.keys(filter) });
    if (!GLOBAL_COLLECTIONS.has(colName) && req.companyId && !filter.company_id) {
      filter.company_id = req.companyId;
    }

    // Build sort object
    const sortField = sort || 'created_at';
    const sortOrder = order === 'asc' ? 1 : -1;
    const sortObj = { [sortField]: sortOrder };

    // Execute query with pagination
    const [docs, totalCount] = await Promise.all([
      col.find(filter)
        .sort(sortObj)
        .skip(safeSkip)
        .limit(safeLimit)
        .toArray(),
      col.countDocuments(filter),
    ]);

    res.json({
      data: docs.map(normalizeDoc),
      pagination: {
        total: totalCount,
        limit: safeLimit,
        skip: safeSkip,
        hasMore: safeSkip + safeLimit < totalCount,
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/collections/:name/:id', validateObjectId('id'), async (req, res) => {
  try {
    const database = await connectToMongo();
    const colName = req.params.name;
    const col = database.collection(colName);
    const { id } = req.params;

    // Validate collection name
    if (!/^[a-zA-Z][a-zA-Z0-9_]*$/.test(colName)) {
      return res.status(400).json({ error: 'Invalid collection name' });
    }

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

router.post('/collections/:name', validateObjectId('id'), sanitizeQuery, async (req, res) => {
  try {
    const database = await connectToMongo();
    const colName = req.params.name;
    const col = database.collection(colName);
    const now = Date.now();
    const body = req.body || {};

    // Validate collection name
    if (!/^[a-zA-Z][a-zA-Z0-9_]*$/.test(colName)) {
      return res.status(400).json({ error: 'Invalid collection name' });
    }

    const id = body.id || body._id || `id-${now}-${Math.random().toString(36).substr(2, 7)}`;
    const doc = {
      ...body,
      _id: id,
      id: id,
      created_at: body.created_at || now,
      updated_at: now,
    };

    // Auto-assign company_id if multi-tenant collection
    console.log('[DEBUG] POST /collections/:name:', { colName, bodyCompanyId: body.company_id, reqCompanyId: req.companyId });
    if (!GLOBAL_COLLECTIONS.has(colName)) {
      const companyId = body.company_id || req.companyId;
      if (companyId) {
        doc.company_id = companyId;
        console.log('[DEBUG] Assigned company_id to doc:', companyId);
      }
    }

    await col.insertOne(doc);
    res.status(201).json(normalizeDoc(doc));
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ error: 'Duplicate key error', field: err.keyValue });
    }
    res.status(500).json({ error: err.message });
  }
});

router.put('/collections/:name/:id', validateObjectId('id'), sanitizeQuery, async (req, res) => {
  try {
    const database = await connectToMongo();
    const colName = req.params.name;
    const col = database.collection(colName);
    const { id } = req.params;
    const now = Date.now();

    // Validate collection name
    if (!/^[a-zA-Z][a-zA-Z0-9_]*$/.test(colName)) {
      return res.status(400).json({ error: 'Invalid collection name' });
    }

    const updates = { ...req.body, updated_at: now };
    delete updates._id;
    delete updates.id; // Prevent ID modification
    delete updates.created_at; // Prevent created_at modification

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

router.delete('/collections/:name/:id', validateObjectId('id'), async (req, res) => {
  try {
    const database = await connectToMongo();
    const colName = req.params.name;
    const col = database.collection(colName);
    const { id } = req.params;

    // Validate collection name
    if (!/^[a-zA-Z][a-zA-Z0-9_]*$/.test(colName)) {
      return res.status(400).json({ error: 'Invalid collection name' });
    }

    let idFilter = { $or: [{ id: id }, { _id: id }] };
    if (ObjectId.isValid(id)) {
      idFilter.$or.push({ _id: new ObjectId(id) });
    }

    let filter = idFilter;
    if (!GLOBAL_COLLECTIONS.has(colName) && req.companyId) {
      filter = { $and: [idFilter, { $or: [{ company_id: req.companyId }, { company_id: null }, { company_id: { $exists: false } }] }] };
    }

    const result = await col.deleteOne(filter);
    if (result.deletedCount === 0) {
      return res.status(404).json({ error: 'Document not found' });
    }
    res.json({ success: true, deletedId: id });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
