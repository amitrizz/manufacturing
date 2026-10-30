import { Router } from 'express';
import { connectToMongo, normalizeDoc } from '../config/db.js';
import { ALL_COLLECTIONS } from '../schemas/index.js';
import { runMigration } from '../migrate.js';
import { validate, destructiveRateLimiter } from '../middlewares/validation.js';
import { z } from 'zod';

const router = Router();

// Apply destructive rate limiter to all mutating endpoints
router.use('/database/clear', destructiveRateLimiter);
router.use('/database/seed', destructiveRateLimiter);
router.use('/database/reset', destructiveRateLimiter);

const confirmSchema = z.object({
  confirm: z.literal(true).refine(v => v === true, 'Must confirm with { "confirm": true }'),
});

// GET /database/all - Get all collections data (with pagination support)
router.get('/database/all', async (req, res) => {
  try {
    const database = await connectToMongo();
    const companyId = req.companyId;
    const GLOBAL_COLLECTIONS = new Set(['companies', 'units']);
    const data = {};
    
    // Limit to prevent memory issues
    const limit = Math.min(parseInt(req.query.limit) || 1000, 1000);
    
    for (const name of ALL_COLLECTIONS) {
      const filter = (!GLOBAL_COLLECTIONS.has(name) && companyId) ? { company_id: companyId } : {};
      const docs = await database.collection(name).find(filter).limit(limit).toArray();
      data[name] = docs.map(normalizeDoc);
    }
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /database/clear - Clear all business collections (requires confirmation)
router.post('/database/clear', validate(confirmSchema), async (req, res) => {
  try {
    const database = await connectToMongo();
    const companyId = req.companyId;
    const GLOBAL_COLLECTIONS = new Set(['companies', 'units']);
    
    const results = {};
    for (const name of ALL_COLLECTIONS) {
      if (GLOBAL_COLLECTIONS.has(name)) continue; // Never auto-clear global collections
      const filter = companyId ? { company_id: companyId } : {};
      const result = await database.collection(name).deleteMany(filter);
      results[name] = result.deletedCount;
    }
    
    res.json({
      success: true,
      message: 'Business collections cleared for current company',
      deletedCounts: results,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /database/seed - Seed database with demo data
router.post('/database/seed', validate(confirmSchema), async (req, res) => {
  try {
    const database = await connectToMongo();
    await runMigration(database);
    res.json({ success: true, message: 'Database seeded with manufacturing demo data' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /database/reset - Clear and reseed (requires confirmation)
router.post('/database/reset', validate(confirmSchema), async (req, res) => {
  try {
    const database = await connectToMongo();
    const companyId = req.companyId;
    const GLOBAL_COLLECTIONS = new Set(['companies', 'units']);
    
    const results = {};
    for (const name of ALL_COLLECTIONS) {
      if (GLOBAL_COLLECTIONS.has(name)) continue;
      const filter = companyId ? { company_id: companyId } : {};
      const result = await database.collection(name).deleteMany(filter);
      results[name] = result.deletedCount;
    }
    
    await runMigration(database);
    
    res.json({ 
      success: true, 
      message: 'Database reset & seeded with manufacturing demo data',
      clearedCounts: results,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
