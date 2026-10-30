import { Router } from 'express';
import { connectToMongo, normalizeDoc } from '../config/db.js';
import { validate, validateObjectId, paginationSchema } from '../middlewares/validation.js';
import { z } from 'zod';

const router = Router();

const machineStatusSchema = z.object({
  status: z.enum(['RUNNING', 'IDLE', 'BREAKDOWN', 'MAINTENANCE', 'OFFLINE', 'STOPPED']),
  reason: z.string().max(500).optional(),
});

// GET /machines - with pagination
router.get('/machines', validate(paginationSchema), async (req, res) => {
  try {
    const database = await connectToMongo();
    const { status, lineId, search } = req.query;
    const { limit, skip, sort, order } = req.validatedQuery || {};
    const companyId = req.companyId;
    console.log('[DEBUG] GET /machines: companyId=%s, type=%s, hasHeader=%s', companyId, typeof companyId, !!req.headers['x-company-id']);
    console.log('[DEBUG] GET /machines: validatedQuery=', JSON.stringify(req.validatedQuery));
    const scope = companyId ? { $or: [{ company_id: companyId }, { company_id: null }, { company_id: { $exists: false } }] } : {};
    console.log('[DEBUG] GET /machines: scope=', JSON.stringify(scope));

    const [machines, lines, products] = await Promise.all([
      database.collection('machines').find(scope).toArray(),
      database.collection('production_lines').find(scope).toArray(),
      database.collection('products').find(scope).toArray(),
    ]);

    console.log('[DEBUG] GET /machines: found %d machines', machines.length);
    if (machines.length > 0) {
      console.log('[DEBUG] First machine: %s (company_id: %s)', machines[0].code, machines[0].company_id);
    }

    const lineMap = new Map(lines.map((l) => [l.id || String(l._id), l]));
    const prodMap = new Map(products.map((p) => [p.id || String(p._id), p]));

    let result = machines.map((m) => {
      const pl = lineMap.get(m.line_id);
      const pr = prodMap.get(m.current_product_id);
      return {
        ...normalizeDoc(m),
        line_code: pl?.code || '',
        line_name: pl?.name || '',
        product_code: pr?.code || '',
        product_name: pr?.name || '',
      };
    });

    if (status) {
      result = result.filter((m) => m.status === status);
    }
    if (lineId) {
      result = result.filter((m) => m.line_id === lineId);
    }
    if (search) {
      const q = String(search).toLowerCase();
      result = result.filter(
        (m) =>
          (m.name && m.name.toLowerCase().includes(q)) ||
          (m.code && m.code.toLowerCase().includes(q)) ||
          (m.line_code && m.line_code.toLowerCase().includes(q))
      );
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

// POST /machines/:id/status
router.post('/machines/:id/status', validateObjectId('id'), validate(machineStatusSchema), async (req, res) => {
  try {
    const database = await connectToMongo();
    const { id } = req.params;
    const { status, reason } = req.validatedBody;
    const now = Date.now();

    const companyId = req.companyId;
    const machineFilter = { 
      $or: [{ id }, { _id: id }] 
    };
    if (companyId) machineFilter.company_id = companyId;

    const machine = await database.collection('machines').findOne(machineFilter);
    if (!machine) return res.status(404).json({ error: 'Machine not found' });

    const prevStatus = machine.status;
    await database.collection('machines').updateOne(
      machineFilter,
      { $set: { status, updated_at: now } }
    );

    if (status === 'BREAKDOWN' || status === 'MAINTENANCE') {
      const dtDoc = {
        _id: `dt-${now}`,
        id: `dt-${now}`,
        machine_id: machine.id || machine._id,
        reason: reason || `Status changed to ${status}`,
        start_time: now,
        created_at: now,
        company_id: companyId,
      };
      await database.collection('machine_downtime').insertOne(dtDoc);
    }

    const actDoc = {
      _id: `act-${now}`,
      id: `act-${now}`,
      event_type: status === 'BREAKDOWN' ? 'MACHINE_BREAKDOWN' : 'MACHINE_STATUS_CHANGE',
      title: `${machine.name} (${machine.code}) -> ${status}`,
      description: reason || `Machine status updated from ${prevStatus} to ${status}`,
      reference_type: 'MACHINE',
      reference_id: machine.id || machine._id,
      timestamp: now,
      created_at: now,
      company_id: companyId,
    };
    await database.collection('activity_history').insertOne(actDoc);

    res.json({ success: true, machineId: id, status });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
