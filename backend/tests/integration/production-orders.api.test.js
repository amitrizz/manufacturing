import { createApp } from '../../server.js';
import { startTestDB, stopTestDB, clearTestDB, getTestDB, TEST_COMPANY_ID, TEST_API_KEY } from '../setup.js';

const TEST_COMPANY = TEST_COMPANY_ID;
const TEST_API_KEY_VALUE = TEST_API_KEY;
const HEADERS = { 
  'x-company-id': TEST_COMPANY,
  'x-api-key': TEST_API_KEY_VALUE,
  'Content-Type': 'application/json'
};

describe('Production Orders API Integration', () => {
  let mongod = null;
  let client = null;
  let db = null;
  let app = null;
  let server = null;
  let port = 0;

  beforeAll(async () => {
    const result = await startTestDB();
    mongod = result.mongod;
    db = result.db;
    
    process.env.NODE_ENV = 'test';
    process.env.API_KEY = TEST_API_KEY;
    
    app = await createApp();
    server = app.listen(0);
    await new Promise(resolve => server.on('listening', resolve));
    port = server.address().port;
  });

  afterAll(async () => {
    if (server) await new Promise(resolve => server.close(resolve));
    await stopTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
    
    await db.collection('production_lines').insertOne({
      _id: 'line-001', id: 'line-001', company_id: TEST_COMPANY,
      code: 'LINE1', name: 'Test Line',
      created_at: Date.now(), updated_at: Date.now()
    });
    await db.collection('products').insertOne({
      _id: 'product-001', id: 'product-001', company_id: TEST_COMPANY,
      code: 'PRD001', name: 'Test Product', unit: 'PCS',
      created_at: Date.now(), updated_at: Date.now()
    });
  });

  const baseUrl = () => `http://localhost:${port}`;

  test('GET /api/v1/production-orders - should return paginated orders', async () => {
    await db.collection('production_orders').insertMany([
      {
        _id: 'order-1', id: 'order-1', company_id: TEST_COMPANY,
        order_number: 'ORD-001', plan_id: null, product_id: 'product-001',
        line_id: 'line-001', machine_id: null, assigned_machines: null,
        assigned_workers: null, target_quantity: 1000, produced_quantity: 0,
        rejected_quantity: 0, priority: 'HIGH', status: 'PENDING',
        start_date: null, due_date: Date.now() + 86400000,
        started_at: null, completed_at: null, qc_status: 'PENDING',
        qc_inspected_at: null, qc_inspector: null, qc_notes: null,
        created_at: Date.now(), updated_at: Date.now()
      },
      {
        _id: 'order-2', id: 'order-2', company_id: TEST_COMPANY,
        order_number: 'ORD-002', plan_id: null, product_id: 'product-001',
        line_id: 'line-001', machine_id: null, assigned_machines: null,
        assigned_workers: null, target_quantity: 500, produced_quantity: 250,
        rejected_quantity: 10, priority: 'MEDIUM', status: 'IN_PROGRESS',
        start_date: Date.now(), due_date: Date.now() + 86400000,
        started_at: Date.now(), completed_at: null, qc_status: 'PENDING',
        qc_inspected_at: null, qc_inspector: null, qc_notes: null,
        created_at: Date.now(), updated_at: Date.now()
      }
    ]);

    const response = await fetch(`${baseUrl()}/api/v1/production-orders?limit=10`, { headers: HEADERS });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.data.length).toBe(2);
    expect(body.pagination).toBeDefined();
  });

  test('GET /api/v1/production-orders - should filter by status', async () => {
    await db.collection('production_orders').insertMany([
      { _id: 'order-1', id: 'order-1', company_id: TEST_COMPANY, order_number: 'ORD-001', product_id: 'product-001', line_id: 'line-001', target_quantity: 1000, produced_quantity: 0, rejected_quantity: 0, priority: 'HIGH', status: 'PENDING', created_at: Date.now(), updated_at: Date.now() },
      { _id: 'order-2', id: 'order-2', company_id: TEST_COMPANY, order_number: 'ORD-002', product_id: 'product-001', line_id: 'line-001', target_quantity: 500, produced_quantity: 250, rejected_quantity: 10, priority: 'MEDIUM', status: 'IN_PROGRESS', created_at: Date.now(), updated_at: Date.now() }
    ]);

    const response = await fetch(`${baseUrl()}/api/v1/production-orders?status=IN_PROGRESS`, { headers: HEADERS });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.data.length).toBe(1);
    expect(body.data[0].status).toBe('IN_PROGRESS');
  });

  test('POST /api/v1/production-orders/:id/start - should start production order', async () => {
    const order = {
      _id: 'order-1', id: 'order-1', company_id: TEST_COMPANY,
      order_number: 'ORD-001', plan_id: null, product_id: 'product-001',
      line_id: 'line-001', machine_id: null, assigned_machines: null,
      assigned_workers: null, target_quantity: 1000, produced_quantity: 0,
      rejected_quantity: 0, priority: 'HIGH', status: 'PENDING',
      start_date: null, due_date: Date.now() + 86400000,
      started_at: null, completed_at: null, qc_status: 'PENDING',
      qc_inspected_at: null, qc_inspector: null, qc_notes: null,
      created_at: Date.now(), updated_at: Date.now()
    };
    await db.collection('production_orders').insertOne(order);

    const response = await fetch(`${baseUrl()}/api/v1/production-orders/order-1/start`, {
      method: 'POST',
      headers: HEADERS
    });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.success).toBe(true);
    expect(body.status).toBe('IN_PROGRESS');

    const updated = await db.collection('production_orders').findOne({ id: 'order-1' });
    expect(updated.status).toBe('IN_PROGRESS');
    expect(updated.started_at).toBeDefined();

    const activity = await db.collection('activity_history').findOne({ reference_id: 'order-1' });
    expect(activity).toBeDefined();
    expect(activity.event_type).toBe('PRODUCTION_STARTED');
  });

  test('POST /api/v1/production-orders/:id/start - should return 404 for non-existent order', async () => {
    const response = await fetch(`${baseUrl()}/api/v1/production-orders/non-existent/start`, {
      method: 'POST',
      headers: HEADERS
    });
    
    expect(response.status).toBe(404);
  });
});

const baseUrl = () => `http://localhost:${port}`;