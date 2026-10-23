import { Router } from 'express';
import { connectToMongo, normalizeDoc } from '../config/db.js';

const router = Router();

router.get('/production-orders', async (req, res) => {
  try {
    const database = await connectToMongo();
    const { status } = req.query;
    const companyId = req.companyId;
    const scope = companyId ? { $or: [{ company_id: companyId }, { company_id: null }, { company_id: { $exists: false } }] } : {};

    const [orders, products, lines] = await Promise.all([
      database.collection('production_orders').find(scope).sort({ created_at: -1 }).toArray(),
      database.collection('products').find(scope).toArray(),
      database.collection('production_lines').find(scope).toArray(),
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

router.post('/production-orders/:id/start', async (req, res) => {
  try {
    const database = await connectToMongo();
    const { id } = req.params;
    const now = Date.now();

    const order = await database.collection('production_orders').findOne({ $or: [{ id }, { _id: id }] });
    if (!order) return res.status(404).json({ error: 'Production order not found' });

    const companyId = order.company_id || req.companyId || null;

    await database.collection('production_orders').updateOne(
      { $or: [{ id }, { _id: id }] },
      { $set: { status: 'IN_PROGRESS', start_date: order.start_date || now, updated_at: now } }
    );

    const actDoc = {
      _id: `act-${now}`,
      id: `act-${now}`,
      event_type: 'PRODUCTION_STARTED',
      title: `Order ${order.order_number} started`,
      description: `Production began for order ${order.order_number}`,
      reference_type: 'PRODUCTION_ORDER',
      reference_id: order.id || order._id,
      timestamp: now,
      created_at: now,
    };
    if (companyId) actDoc.company_id = companyId;
    await database.collection('activity_history').insertOne(actDoc);

    res.json({ success: true, orderId: id, status: 'IN_PROGRESS' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
