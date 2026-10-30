import { Router } from 'express';
import { connectToMongo, DB_NAME } from '../config/db.js';

const router = Router();

router.get('/health', async (req, res) => {
  try {
    const database = await connectToMongo();
    const cols = await database.listCollections().toArray();
    res.json({
      status: 'ok',
      database: DB_NAME,
      collectionsCount: cols.length,
      version: '2.0.0',
      timestamp: Date.now(),
    });
  } catch (err) {
    res.status(503).json({ status: 'error', error: err.message });
  }
});

export default router;