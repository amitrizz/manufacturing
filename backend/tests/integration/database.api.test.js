import { createApp } from '../../server.js';
import { startTestDB, stopTestDB, clearTestDB, getTestDB, TEST_COMPANY_ID, TEST_API_KEY } from '../setup.js';

const TEST_COMPANY = TEST_COMPANY_ID;
const TEST_API_KEY_VALUE = TEST_API_KEY;
const HEADERS = { 
  'x-company-id': TEST_COMPANY,
  'x-api-key': TEST_API_KEY_VALUE,
  'Content-Type': 'application/json'
};

describe('Database API Integration', () => {
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
    await db.collection('materials').deleteMany({});
    await db.collection('products').deleteMany({});
    await db.collection('machines').deleteMany({});
    await db.collection('production_orders').deleteMany({});
  });

  const baseUrl = () => `http://localhost:${port}`;

  test('GET /api/v1/database/all - should return all collections data', async () => {
    await db.collection('materials').insertOne({
      _id: 'm1', id: 'm1', company_id: TEST_COMPANY, code: 'MAT1', name: 'Test', current_stock: 100
    });
    await db.collection('products').insertOne({
      _id: 'p1', id: 'p1', company_id: TEST_COMPANY, code: 'PRD1', name: 'Product', unit: 'PCS'
    });
    await db.collection('machines').insertOne({
      _id: 'mac1', id: 'mac1', company_id: TEST_COMPANY, code: 'M1', name: 'Machine', status: 'RUNNING'
    });

    const response = await fetch(`${baseUrl()}/api/v1/database/all`, { headers: HEADERS });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.success).toBe(true);
    expect(body.data).toBeDefined();
    expect(body.data.materials).toBeDefined();
    expect(body.data.products).toBeDefined();
    expect(body.data.machines).toBeDefined();
    expect(body.data.materials.length).toBe(1);
  });

  test('POST /api/v1/database/clear - should clear company data', async () => {
    await db.collection('materials').insertOne({
      _id: 'm1', id: 'm1', company_id: TEST_COMPANY, code: 'MAT1', name: 'Test', current_stock: 100
    });
    await db.collection('products').insertOne({
      _id: 'p1', id: 'p1', company_id: TEST_COMPANY, code: 'PRD1', name: 'Product', unit: 'PCS'
    });
    await db.collection('machines').insertOne({
      _id: 'mac1', id: 'mac1', company_id: TEST_COMPANY, code: 'M1', name: 'Machine', status: 'RUNNING'
    });

    const response = await fetch(`${baseUrl()}/api/v1/database/clear`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify({ confirm: true })
    });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.success).toBe(true);
    expect(body.deletedCounts).toBeDefined();

    const materials = await db.collection('materials').find({ company_id: TEST_COMPANY }).toArray();
    const products = await db.collection('products').find({ company_id: TEST_COMPANY }).toArray();
    expect(materials.length).toBe(0);
    expect(products.length).toBe(0);
  });

  test('POST /api/v1/database/clear - should require confirmation', async () => {
    const response = await fetch(`${baseUrl()}/api/v1/database/clear`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify({ confirm: false })
    });
    
    expect(response.status).toBe(400);
  });

  test('POST /api/v1/database/seed - should seed database', async () => {
    const response = await fetch(`${baseUrl()}/api/v1/database/seed`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify({ confirm: true })
    });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.success).toBe(true);
  });

  test('POST /api/v1/database/reset - should clear and seed', async () => {
    await db.collection('materials').insertOne({
      _id: 'm1', id: 'm1', company_id: TEST_COMPANY, code: 'MAT1', name: 'Test', current_stock: 100
    });

    const response = await fetch(`${baseUrl()}/api/v1/database/reset`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify({ confirm: true })
    });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.success).toBe(true);
    expect(body.clearedCounts).toBeDefined();
  });

  test('POST /api/v1/database/reset - should require confirmation', async () => {
    const response = await fetch(`${baseUrl()}/api/v1/database/reset`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify({ confirm: false })
    });
    
    expect(response.status).toBe(400);
  });
});

const baseUrl = () => `http://localhost:${port}`;