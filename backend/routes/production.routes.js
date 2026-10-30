import { Router } from 'express';
import { connectToMongo, normalizeDoc } from '../config/db.js';
import { validate, validateObjectId, paginationSchema } from '../middlewares/validation.js';
import { z } from 'zod';

const router = Router();

// GET /production-orders - with pagination
router.get('/production-orders', validate(paginationSchema), async (req, res) => {
  try {
    const database = await connectToMongo();
    const { status } = req.query;
    const { limit = 50, skip = 0, sort = 'created_at', order = 'desc' } = req.validatedQuery || {};
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

    // Apply pagination
    const total = result.length;
    const paginated = result.slice(skip, skip + limit);

    res.json({
      data: paginated,
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

// POST /production-orders/:id/start
router.post('/production-orders/:id/start', validateObjectId('id'), async (req, res) => {
  try {
    const database = await connectToMongo();
    const { id } = req.params;
    const now = Date.now();

    const companyId = req.companyId;
    const orderFilter = { $or: [{ id }, { _id: id }] };
    if (companyId) orderFilter.company_id = companyId;

    const order = await database.collection('production_orders').findOne(orderFilter);
    if (!order) return res.status(404).json({ error: 'Production order not found' });

    await database.collection('production_orders').updateOne(
      orderFilter,
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
      company_id: companyId,
    };
    await database.collection('activity_history').insertOne(actDoc);

    res.json({ success: true, orderId: id, status: 'IN_PROGRESS' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
