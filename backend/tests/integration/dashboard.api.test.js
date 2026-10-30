import { createApp } from '../../server.js';
import { startTestDB, stopTestDB, clearTestDB, getTestDB, TEST_COMPANY_ID, TEST_API_KEY } from '../setup.js';

const TEST_COMPANY = TEST_COMPANY_ID;
const TEST_API_KEY_VALUE = TEST_API_KEY;
const HEADERS = { 
  'x-company-id': TEST_COMPANY,
  'x-api-key': TEST_API_KEY_VALUE,
  'Content-Type': 'application/json'
};

describe('Dashboard API Integration', () => {
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
    
    await db.collection('machines').insertMany([
      { _id: 'm1', id: 'm1', company_id: TEST_COMPANY, code: 'M1', name: 'M1', machine_type: 'CNC', line_id: 'l1', status: 'RUNNING', efficiency: 85, runtime_seconds: 3600, downtime_seconds: 0, created_at: Date.now(), updated_at: Date.now() },
      { _id: 'm2', id: 'm2', company_id: TEST_COMPANY, code: 'M2', name: 'M2', machine_type: 'LATHE', line_id: 'l1', status: 'BREAKDOWN', efficiency: 75, runtime_seconds: 0, downtime_seconds: 3600, created_at: Date.now(), updated_at: Date.now() },
      { _id: 'm3', id: 'm3', company_id: TEST_COMPANY, code: 'M3', name: 'M3', machine_type: 'MILL', line_id: 'l1', status: 'IDLE', efficiency: 80, runtime_seconds: 1800, downtime_seconds: 0, created_at: Date.now(), updated_at: Date.now() }
    ]);

    await db.collection('production_lines').insertOne({
      _id: 'l1', id: 'l1', company_id: TEST_COMPANY, code: 'L1', name: 'Line 1',
      created_at: Date.now(), updated_at: Date.now()
    });

    await db.collection('production_orders').insertOne({
      _id: 'o1', id: 'o1', company_id: TEST_COMPANY, order_number: 'ORD-001', product_id: 'p1', line_id: 'l1', target_quantity: 1000, produced_quantity: 500, status: 'IN_PROGRESS', start_date: Date.now(), created_at: Date.now(), updated_at: Date.now()
    });

    await db.collection('production_entries').insertOne({
      _id: 'e1', id: 'e1', company_id: TEST_COMPANY, production_order_id: 'o1', machine_id: 'm1', good_quantity: 500, rejected_quantity: 10, entry_timestamp: Date.now(), created_at: Date.now()
    });

    await db.collection('quality_inspections').insertOne({
      _id: 'q1', id: 'q1', company_id: TEST_COMPANY, quantity: 500, rejected_quantity: 10, status: 'PASSED', inspected_at: Date.now(), created_at: Date.now()
    });

    await db.collection('materials').insertOne({
      _id: 'mat1', id: 'mat1', company_id: TEST_COMPANY, code: 'MAT1', name: 'Material 1', current_stock: 100, minimum_stock: 50, maximum_stock: 1000, created_at: Date.now(), updated_at: Date.now()
    });

    await db.collection('maintenance_orders').insertOne({
      _id: 'mo1', id: 'mo1', company_id: TEST_COMPANY, status: 'OPEN', created_at: Date.now(), updated_at: Date.now()
    });

    await db.collection('staff_attendance').insertMany([
      { _id: 'a1', id: 'a1', company_id: TEST_COMPANY, staff_id: 's1', status: 'PRESENT', date: new Date().toISOString().slice(0, 10), created_at: Date.now() },
      { _id: 'a2', id: 'a2', company_id: TEST_COMPANY, staff_id: 's2', status: 'PRESENT', date: new Date().toISOString().slice(0, 10), created_at: Date.now() },
      { _id: 'a3', id: 'a3', company_id: TEST_COMPANY, staff_id: 's3', status: 'ABSENT', date: new Date().toISOString().slice(0, 10), created_at: Date.now() }
    ]);

    await db.collection('activity_history').insertOne({
      _id: 'act1', id: 'act1', company_id: TEST_COMPANY, event_type: 'TEST_EVENT', title: 'Test', description: 'Test activity', timestamp: Date.now(), created_at: Date.now()
    });

    const response = await fetch(`${baseUrl()}/api/v1/dashboard/stats`, { headers: HEADERS });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.kpis).toBeDefined();
    expect(body.kpis.target).toBe(1000);
    expect(body.kpis.produced).toBe(500);
    expect(body.kpis.achievement).toBe(50);
    expect(body.kpis.qualityRate).toBeDefined();
    expect(body.kpis.machineAvailability).toBeDefined();
    expect(body.kpis.machineStatusCounts).toBeDefined();
    expect(body.kpis.machineStatusCounts.RUNNING).toBe(1);
    expect(body.kpis.machineStatusCounts.BREAKDOWN).toBe(1);
    expect(body.kpis.machineStatusCounts.IDLE).toBe(1);
    expect(body.machines).toBeDefined();
    expect(body.machines.total).toBe(3);
    expect(body.machines.running).toBe(1);
    expect(body.machines.breakdown).toBe(1);
    expect(body.attendance).toBeDefined();
    expect(body.attendance.total).toBe(3);
    expect(body.attendance.present).toBe(2);
    expect(body.pendingTasksCount).toBeDefined();
    expect(body.recentActivities).toBeDefined();
    expect(body.monthlyData).toBeDefined();
  });

  test('GET /api/v1/dashboard/stats - should handle date range', async () => {
    const start = Date.now() - 7 * 86400000;
    const end = Date.now();
    
    const response = await fetch(`${baseUrl()}/api/v1/dashboard/stats?start=${start}&end=${end}`, { headers: HEADERS });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.kpis).toBeDefined();
  });
});

const baseUrl = () => `http://localhost:${port}`;