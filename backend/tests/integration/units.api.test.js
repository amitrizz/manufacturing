import { createApp } from '../../server.js';
import { startTestDB, stopTestDB, clearTestDB, getTestDB, TEST_COMPANY_ID, TEST_API_KEY } from '../setup.js';

const TEST_COMPANY = TEST_COMPANY_ID;
const TEST_API_KEY_VALUE = TEST_API_KEY;
const HEADERS = { 
  'x-company-id': TEST_COMPANY,
  'x-api-key': TEST_API_KEY_VALUE,
  'Content-Type': 'application/json'
};

describe('Health Endpoint Integration', () => {
  let mongod = null;
  let app = null;
  let server = null;
  let port = 0;

  beforeAll(async () => {
    const result = await startTestDB();
    mongod = result.mongod;
    
    process.env.NODE_ENV = 'test';
    process.env.API_KEY = TEST_API_KEY;
    
    const app = await createApp();
    server = app.listen(0);
    await new Promise(resolve => server.on('listening', resolve));
    port = server.address().port;
  });

  afterAll(async () => {
    if (server) await new Promise(resolve => server.close(resolve));
    await stopTestDB(mongod);
  });

  beforeEach(async () => {
    await clearTestDB();
  });

  const baseUrl = () => `http://localhost:${port}`;

  test('GET /health - should return health status without auth', async () => {
    const response = await fetch(`${baseUrl()}/health`);
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.status).toBe('ok');
    expect(body.database).toBe('manufacturing');
    expect(body.collectionsCount).toBeGreaterThan(0);
    expect(body.version).toBe('2.0.0');
    expect(body.timestamp).toBeDefined();
  });

  test('GET /api/v1/health - should return health status with auth', async () => {
    const response = await fetch(`${baseUrl()}/api/v1/health`, {
      headers: { 'x-company-id': TEST_COMPANY_ID, 'x-api-key': TEST_API_KEY }
    });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.status).toBe('ok');
  });

  test('GET /api/v1/health - should fail without auth', async () => {
    const response = await fetch(`${baseUrl()}/api/v1/health`);
    const body = await response.json();
    
    expect(response.status).toBe(401);
  });
});

describe('Units API Integration', () => {
  let mongod = null;
  let app = null;
  let server = null;
  let port = 0;

  beforeAll(async () => {
    const { mongod: mongodInstance, db } = await startTestDB();
    mongod = mongodInstance;
    
    process.env.NODE_ENV = 'test';
    process.env.API_KEY = 'test-api-key-1234567890abcdef';
    
    app = await createApp();
    server = app.listen(0);
    await new Promise(resolve => server.on('listening', resolve));
    port = server.address().port;
  });

  afterAll(async () => {
    if (server) await new Promise(resolve => server.close(resolve));
    await stopTestDB(mongod);
  });

  beforeEach(async () => {
    await clearTestDB();
  });

  const baseUrl = () => `http://localhost:${port}`;

  test('GET /api/v1/units - should return paginated units', async () => {
    const response = await fetch(`${baseUrl()}/api/v1/units?limit=10`, { headers: HEADERS });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.data).toBeDefined();
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.pagination).toBeDefined();
    expect(body.pagination.limit).toBe(10);
  });

  test('POST /api/v1/units - should create new unit', async () => {
    const newUnit = {
      code: 'TEST',
      name: 'Test Unit',
      symbol: 'TST',
      category: 'Test',
      precision: 2
    };
    
    const response = await fetch(`${baseUrl()}/api/v1/units`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify(newUnit)
    });
    const body = await response.json();
    
    expect(response.status).toBe(201);
    expect(body.code).toBe('TEST');
    expect(body.name).toBe('Test Unit');
  });

  test('POST /api/v1/units - should reject duplicate code', async () => {
    const unit = { code: 'DUP', name: 'Duplicate', category: 'Test' };
    
    await fetch(`${baseUrl()}/api/v1/units`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify(unit)
    });
    
    const response = await fetch(`${baseUrl()}/api/v1/units`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify(unit)
    });
    
    expect(response.status).toBe(409);
  });

  test('POST /api/v1/units - should validate required fields', async () => {
    const response = await fetch(`${baseUrl()}/api/v1/units`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify({ name: 'No Code' })
    });
    
    expect(response.status).toBe(400);
  });

  test('POST /api/v1/units/seed - should seed default units', async () => {
    const response = await fetch(`${baseUrl()}/api/v1/units/seed`, {
      method: 'POST',
      headers: HEADERS
    });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.success).toBe(true);
    expect(body.count).toBeGreaterThan(0);
  });
});