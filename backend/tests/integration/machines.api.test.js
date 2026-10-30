import { createApp } from '../../server.js';
import { startTestDB, stopTestDB, clearTestDB, getTestDB, TEST_COMPANY_ID, TEST_API_KEY } from '../setup.js';

const TEST_COMPANY = TEST_COMPANY_ID;
const TEST_API_KEY_VALUE = TEST_API_KEY;
const HEADERS = { 
  'x-company-id': TEST_COMPANY,
  'x-api-key': TEST_API_KEY_VALUE,
  'Content-Type': 'application/json'
};

describe('Machines API Integration', () => {
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
  });

  const baseUrl = () => `http://localhost:${port}`;

  test('GET /api/v1/machines - should return paginated machines', async () => {
    await db.collection('machines').insertMany([
      {
        _id: 'machine-1', id: 'machine-1', company_id: TEST_COMPANY,
        code: 'M001', name: 'Machine 1', machine_type: 'CNC', line_id: 'line-001',
        status: 'RUNNING', current_product_id: null, efficiency: 85,
        runtime_seconds: 3600, downtime_seconds: 0,
        last_maintenance_at: null, next_maintenance_at: null,
        created_at: Date.now(), updated_at: Date.now()
      },
      {
        _id: 'machine-2', id: 'machine-2', company_id: TEST_COMPANY,
        code: 'M002', name: 'Machine 2', machine_type: 'LATHE', line_id: 'line-001',
        status: 'IDLE', current_product_id: null, efficiency: 75,
        runtime_seconds: 0, downtime_seconds: 0,
        last_maintenance_at: null, next_maintenance_at: null,
        created_at: Date.now(), updated_at: Date.now()
      }
    ]);

    const response = await fetch(`${baseUrl()}/api/v1/machines?limit=10`, { headers: HEADERS });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.data).toBeDefined();
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.length).toBe(2);
    expect(body.pagination).toBeDefined();
  });

  test('GET /api/v1/machines - should filter by status', async () => {
    await db.collection('machines').insertMany([
      {
        _id: 'machine-1', id: 'machine-1', company_id: TEST_COMPANY,
        code: 'M001', name: 'Machine 1', machine_type: 'CNC', line_id: 'line-001',
        status: 'RUNNING', current_product_id: null, efficiency: 85,
        runtime_seconds: 3600, downtime_seconds: 0,
        last_maintenance_at: null, next_maintenance_at: null,
        created_at: Date.now(), updated_at: Date.now()
      },
      {
        _id: 'machine-2', id: 'machine-2', company_id: TEST_COMPANY,
        code: 'M002', name: 'Machine 2', machine_type: 'LATHE', line_id: 'line-001',
        status: 'BREAKDOWN', current_product_id: null, efficiency: 75,
        runtime_seconds: 0, downtime_seconds: 3600,
        last_maintenance_at: null, next_maintenance_at: null,
        created_at: Date.now(), updated_at: Date.now()
      }
    ]);

    const response = await fetch(`${baseUrl()}/api/v1/machines?status=RUNNING`, { headers: HEADERS });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.data.length).toBe(1);
    expect(body.data[0].status).toBe('RUNNING');
  });

  test('POST /api/v1/machines/:id/status - should update machine status', async () => {
    const machine = {
      _id: 'machine-1', id: 'machine-1', company_id: TEST_COMPANY,
      code: 'M001', name: 'Machine 1', machine_type: 'CNC', line_id: 'line-001',
      status: 'IDLE', current_product_id: null, efficiency: 85,
      runtime_seconds: 0, downtime_seconds: 0,
      last_maintenance_at: null, next_maintenance_at: null,
      created_at: Date.now(), updated_at: Date.now()
    };
    await db.collection('machines').insertOne(machine);

    const response = await fetch(`${baseUrl()}/api/v1/machines/machine-1/status`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify({ status: 'RUNNING', reason: 'Started production' })
    });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.success).toBe(true);
    expect(body.status).toBe('RUNNING');

    const updated = await db.collection('machines').findOne({ id: 'machine-1' });
    expect(updated.status).toBe('RUNNING');

    const response2 = await fetch(`${baseUrl()}/api/v1/machines/machine-1/status`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify({ status: 'BREAKDOWN', reason: 'Tool broken' })
    });
    const body2 = await response2.json();
    expect(response2.status).toBe(200);
    
    const downtime = await db.collection('machine_downtime').findOne({ machine_id: 'machine-1' });
    expect(downtime).toBeDefined();
    expect(downtime.reason).toBe('Tool broken');

    const activity = await db.collection('activity_history').findOne({ reference_id: 'machine-1' });
    expect(activity).toBeDefined();
    expect(activity.event_type).toBe('MACHINE_BREAKDOWN');
  });

  test('POST /api/v1/machines/:id/status - should reject invalid status', async () => {
    const machine = {
      _id: 'machine-1', id: 'machine-1', company_id: TEST_COMPANY,
      code: 'M001', name: 'Machine 1', machine_type: 'CNC', line_id: 'line-001',
      status: 'IDLE', current_product_id: null, efficiency: 85,
      runtime_seconds: 0, downtime_seconds: 0,
      last_maintenance_at: null, next_maintenance_at: null,
      created_at: Date.now(), updated_at: Date.now()
    };
    await db.collection('machines').insertOne(machine);

    const response = await fetch(`${baseUrl()}/api/v1/machines/machine-1/status`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify({ status: 'INVALID_STATUS' })
    });
    
    expect(response.status).toBe(400);
  });

  test('POST /api/v1/machines/:id/status - should return 404 for non-existent machine', async () => {
    const response = await fetch(`${baseUrl()}/api/v1/machines/non-existent/status`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify({ status: 'RUNNING' })
    });
    
    expect(response.status).toBe(404);
  });
});

const baseUrl = () => `http://localhost:${port}`;