import { Router } from 'express';
import { connectToMongo, normalizeDoc } from '../config/db.js';
import { DEFAULT_UNITS } from '../seed/units.seed.js';

const router = Router();

/**
 * GET /api/units
 * Retrieve all units from the collection.
 * Automatically seeds default units if the collection is empty.
 */
router.get('/units', async (req, res) => {
  try {
    const database = await connectToMongo();
    const col = database.collection('units');
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

    res.json(units.map(normalizeDoc));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * POST /api/units
 * Create or update a unit.
 */
router.post('/units', async (req, res) => {
  try {
    const database = await connectToMongo();
    const col = database.collection('units');
    const { code, name, symbol, category = 'Other', precision = 0 } = req.body;

    if (!code || !name) {
      return res.status(400).json({ error: 'Code and Name are required for unit' });
    }

    const cleanCode = String(code).trim().toUpperCase();
    const cleanSymbol = (symbol || cleanCode).trim();
    const cleanName = String(name).trim();
    const now = Date.now();
    const unitId = `unit-${cleanCode.toLowerCase()}`;

    const doc = {
      _id: unitId,
      id: unitId,
      code: cleanCode,
      name: cleanName,
      symbol: cleanSymbol,
      category: category || 'Other',
      precision: Number(precision) || 0,
      is_active: true,
      created_at: now,
      updated_at: now,
    };

    await col.updateOne({ $or: [{ id: unitId }, { _id: unitId }, { code: cleanCode }] }, { $set: doc }, { upsert: true });

    res.status(201).json(normalizeDoc(doc));
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

/**
 * POST /api/units/seed
 * Seed / reset default manufacturing units.
 */
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
