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
      cluster: 'cluster0.tysk0hr.mongodb.net',
    });
  } catch (err) {
    res.status(500).json({ status: 'error', error: err.message });
  }
});

export default router;
