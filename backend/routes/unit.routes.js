import { Router } from 'express';
import { connectToMongo, normalizeDoc } from '../config/db.js';
import { DEFAULT_UNITS } from '../seed/units.seed.js';
import { validate, paginationSchema } from '../middlewares/validation.js';
import { z } from 'zod';

const router = Router();

const unitSchema = z.object({
  code: z.string().min(1).max(20).toUpperCase(),
  name: z.string().min(1).max(100),
  symbol: z.string().max(20).optional(),
  category: z.string().max(50).default('Other'),
  precision: z.number().int().min(0).max(10).default(0),
});

// GET /units - with pagination
router.get('/units', validate(paginationSchema), async (req, res) => {
  try {
    const database = await connectToMongo();
    const col = database.collection('units');
    const { limit, skip, sort, order } = req.validatedQuery || {};

    let units = await col.find({}).sort({ category: 1, name: 1 }).toArray();

    if (units.length === 0) {
      const now = Date.now();
      const docs = DEFAULT_UNITS.map((u, idx) => ({
        _id: `unit-${u.code.toLowerCase()}`,
        id: `unit-${u.code.toLowerCase()}`,
        ...u,
        is_active: true,
        created_at: now + idx,
        updated_at: now + idx,
      }));
      await col.insertMany(docs);
      units = docs;
    }

    // Apply pagination
    const total = units.length;
    const paginated = units.slice(skip, skip + limit);

    res.json({
      data: paginated.map(normalizeDoc),
      pagination: {
        total,
        limit,
        skip,
        hasMore: skip + limit < total,
      },
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /units - Create a unit (relies on unique index)
router.post('/units', validate(unitSchema), async (req, res) => {
  try {
    const database = await connectToMongo();
    const col = database.collection('units');
    const { code, name, symbol, category = 'Other', precision = 0 } = req.validatedBody;
    const now = Date.now();
    const unitId = `unit-${code.toLowerCase()}`;

    const doc = {
      _id: unitId,
      id: unitId,
      code,
      name,
      symbol: symbol || code,
      category: category || 'Other',
      precision: Number(precision) || 0,
      is_active: true,
      created_at: now,
      updated_at: now,
    };

    await col.insertOne(doc);

    res.status(201).json(normalizeDoc(doc));
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ error: 'Unit code already exists' });
    }
    res.status(500).json({ error: err.message });
  }
});

// POST /units/seed - Seed / reset default manufacturing units
router.post('/units/seed', async (req, res) => {
  try {
    const database = await connectToMongo();
    const col = database.collection('units');
    const now = Date.now();

    for (let idx = 0; idx < DEFAULT_UNITS.length; idx++) {
      const u = DEFAULT_UNITS[idx];
      const unitId = `unit-${u.code.toLowerCase()}`;
      await col.updateOne(
        { $or: [{ id: unitId }, { _id: unitId }, { code: u.code }] },
        {
          $set: {
            _id: unitId,
            id: unitId,
            ...u,
            is_active: true,
            updated_at: now + idx,
          },
          $setOnInsert: {
            created_at: now + idx,
          },
        },
        { upsert: true }
      );
    }

    const all = await col.find({}).sort({ category: 1, name: 1 }).toArray();
    res.json({ success: true, count: all.length, units: all.map(normalizeDoc) });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
