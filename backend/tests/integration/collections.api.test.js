import { createApp } from '../../server.js';
import { startTestDB, stopTestDB, clearTestDB, getTestDB, TEST_COMPANY_ID, TEST_API_KEY } from '../setup.js';

const TEST_COMPANY = TEST_COMPANY_ID;
const TEST_API_KEY_VALUE = TEST_API_KEY;
const HEADERS = { 
  'x-company-id': TEST_COMPANY,
  'x-api-key': TEST_API_KEY_VALUE,
  'Content-Type': 'application/json'
};

describe('Collections API Integration', () => {
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
  });

  const baseUrl = () => `http://localhost:${port}`;

  test('GET /api/v1/collections/:name - should return paginated collection', async () => {
    await db.collection('materials').insertMany([
      { _id: 'm1', id: 'm1', company_id: TEST_COMPANY, code: 'MAT1', name: 'Material 1', current_stock: 100, created_at: Date.now() },
      { _id: 'm2', id: 'm2', company_id: TEST_COMPANY, code: 'MAT2', name: 'Material 2', current_stock: 200, created_at: Date.now() },
      { _id: 'm3', id: 'm3', company_id: TEST_COMPANY, code: 'MAT3', name: 'Material 3', current_stock: 300, created_at: Date.now() }
    ]);

    const response = await fetch(`${baseUrl()}/api/v1/collections/materials?limit=2`, { headers: HEADERS });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.data).toBeDefined();
    expect(Array.isArray(body.data)).toBe(true);
    expect(body.data.length).toBe(2);
    expect(body.pagination).toBeDefined();
    expect(body.pagination.limit).toBe(2);
    expect(body.pagination.total).toBe(3);
    expect(body.pagination.hasMore).toBe(true);
  });

  test('GET /api/v1/collections/:name - should filter by query params', async () => {
    await db.collection('materials').insertMany([
      { _id: 'm1', id: 'm1', company_id: TEST_COMPANY, code: 'MAT1', name: 'Steel', category: 'RAW_MATERIAL', current_stock: 100, created_at: Date.now() },
      { _id: 'm2', id: 'm2', company_id: TEST_COMPANY, code: 'MAT2', name: 'Aluminum', category: 'RAW_MATERIAL', current_stock: 200, created_at: Date.now() },
      { _id: 'm3', id: 'm3', company_id: TEST_COMPANY, code: 'MAT3', name: 'Plastic', category: 'PACKAGING', current_stock: 300, created_at: Date.now() }
    ]);

    const response = await fetch(`${baseUrl()}/api/v1/collections/materials?category=RAW_MATERIAL`, { headers: HEADERS });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.data.length).toBe(2);
    expect(body.data.every(d => d.category === 'RAW_MATERIAL')).toBe(true);
  });

  test('GET /api/v1/collections/:name/:id - should return single document', async () => {
    await db.collection('materials').insertOne({
      _id: 'mat-1', id: 'mat-1', company_id: TEST_COMPANY,
      code: 'MAT1', name: 'Test Material', current_stock: 100,
      created_at: Date.now(), updated_at: Date.now()
    });

    const response = await fetch(`${baseUrl()}/api/v1/collections/materials/mat-1`, { headers: HEADERS });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.id).toBe('mat-1');
    expect(body.name).toBe('Test Material');
  });

  test('GET /api/v1/collections/:name/:id - should return 404 for non-existent', async () => {
    const response = await fetch(`${baseUrl()}/api/v1/collections/materials/non-existent`, { headers: HEADERS });
    const body = await response.json();
    
    expect(response.status).toBe(404);
  });

  test('POST /api/v1/collections/:name - should create document', async () => {
    const newMaterial = {
      code: 'NEW1',
      name: 'New Material',
      category: 'RAW_MATERIAL',
      unit: 'KG',
      current_stock: 500,
      minimum_stock: 50
    };

    const response = await fetch(`${baseUrl()}/api/v1/collections/materials`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify(newMaterial)
    });
    const body = await response.json();
    
    expect(response.status).toBe(201);
    expect(body.code).toBe('NEW1');
    expect(body.name).toBe('New Material');
    expect(body.company_id).toBe(TEST_COMPANY);
  });

  test('PUT /api/v1/collections/:name/:id - should update document', async () => {
    await db.collection('materials').insertOne({
      _id: 'mat-1', id: 'mat-1', company_id: TEST_COMPANY,
      code: 'MAT1', name: 'Original', current_stock: 100,
      created_at: Date.now(), updated_at: Date.now()
    });

    const response = await fetch(`${baseUrl()}/api/v1/collections/materials/mat-1`, {
      method: 'PUT',
      headers: HEADERS,
      body: JSON.stringify({ name: 'Updated', current_stock: 200 })
    });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.name).toBe('Updated');
    expect(body.current_stock).toBe(200);

    const updated = await db.collection('materials').findOne({ id: 'mat-1' });
    expect(updated.name).toBe('Updated');
  });

  test('DELETE /api/v1/collections/:name/:id - should delete document', async () => {
    await db.collection('materials').insertOne({
      _id: 'mat-1', id: 'mat-1', company_id: TEST_COMPANY,
      code: 'MAT1', name: 'To Delete', current_stock: 100,
      created_at: Date.now(), updated_at: Date.now()
    });

    const response = await fetch(`${baseUrl()}/api/v1/collections/materials/mat-1`, {
      method: 'DELETE',
      headers: HEADERS
    });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.success).toBe(true);

    const deleted = await db.collection('materials').findOne({ id: 'mat-1' });
    expect(deleted).toBeNull();
  });

  test('POST /api/v1/collections/:name - should reject duplicate unique field', async () => {
    const material = { code: 'DUP1', name: 'Duplicate 1', category: 'RAW_MATERIAL' };
    
    await fetch(`${baseUrl()}/api/v1/collections/materials`, {
      method: 'POST', headers: HEADERS, body: JSON.stringify(material)
    });
    
    const response = await fetch(`${baseUrl()}/api/v1/collections/materials`, {
      method: 'POST', headers: HEADERS, body: JSON.stringify(material)
    });
    
    expect(response.status).toBe(409);
  });
});

const baseUrl = () => `http://localhost:${port}`;