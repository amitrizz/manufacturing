import { Router } from 'express';
import { connectToMongo, normalizeDoc } from '../config/db.js';
import { ALL_COLLECTIONS } from '../schemas/index.js';
import { runMigration } from '../migrate.js';

const router = Router();

router.get('/database/all', async (req, res) => {
  try {
    const database = await connectToMongo();
    const companyId = req.companyId;
    const GLOBAL_COLLECTIONS = new Set(['companies', 'units']);
    const data = {};
    for (const name of ALL_COLLECTIONS) {
      const filter = (!GLOBAL_COLLECTIONS.has(name) && companyId) ? { company_id: companyId } : {};
      const docs = await database.collection(name).find(filter).toArray();
      data[name] = docs.map(normalizeDoc);
    }
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/database/clear', async (req, res) => {
  try {
    const database = await connectToMongo();
    for (const name of ALL_COLLECTIONS) {
      await database.collection(name).deleteMany({});
    }
    res.json({
      success: true,
      message: `All ${ALL_COLLECTIONS.length} collections cleared in MongoDB Atlas`,
      collections: ALL_COLLECTIONS,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/database/seed', async (req, res) => {
  try {
    const database = await connectToMongo();
    await runMigration(database);
    res.json({ success: true, message: 'Database seeded with manufacturing demo data' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/database/reset', async (req, res) => {
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

export default router;
