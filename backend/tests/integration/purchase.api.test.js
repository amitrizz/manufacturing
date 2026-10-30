import { createApp } from '../../server.js';
import { startTestDB, stopTestDB, clearTestDB, getTestDB, TEST_COMPANY_ID, TEST_API_KEY } from '../setup.js';

const TEST_COMPANY = TEST_COMPANY_ID;
const TEST_API_KEY_VALUE = TEST_API_KEY;
const HEADERS = { 
  'x-company-id': TEST_COMPANY,
  'x-api-key': TEST_API_KEY_VALUE,
  'Content-Type': 'application/json'
};

describe('Purchase/GRN API Integration', () => {
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
    await db.collection('grn_receipts').deleteMany({});
    await db.collection('purchase_orders').deleteMany({});
    await db.collection('purchase_order_items').deleteMany({});
    await db.collection('materials').deleteMany({});
    await db.collection('stock_transactions').deleteMany({});
    await db.collection('suppliers').deleteMany({});
    await db.collection('activity_history').deleteMany({});
    
    await db.collection('materials').insertOne({
      _id: 'mat-1', id: 'mat-1', company_id: TEST_COMPANY,
      code: 'MAT001', name: 'Steel Plate', category: 'RAW_MATERIAL', unit: 'KG',
      current_stock: 1000, minimum_stock: 100, maximum_stock: 5000,
      created_at: Date.now(), updated_at: Date.now()
    });
    
    await db.collection('suppliers').insertOne({
      _id: 'sup-1', id: 'sup-1', company_id: TEST_COMPANY,
      name: 'Steel Supplier Inc', contact_person: 'John', phone: '1234567890',
      email: 'john@steel.com', created_at: Date.now(), updated_at: Date.now()
    });
  });

  const baseUrl = () => `http://localhost:${port}`;

  test('GET /api/v1/purchase/grn-receipts - should return GRN list', async () => {
    await db.collection('grn_receipts').insertOne({
      _id: 'grn-1', id: 'grn-1', company_id: TEST_COMPANY,
      grn_number: 'GRN-0001', po_id: null, supplier_id: 'sup-1',
      received_date: Date.now(), invoice_number: 'INV-001',
      notes: 'Test GRN', created_at: Date.now(), updated_at: Date.now()
    });

    const response = await fetch(`${baseUrl()}/api/v1/purchase/grn-receipts`, { headers: HEADERS });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(Array.isArray(body)).toBe(true);
    expect(body.length).toBe(1);
    expect(body[0].grn_number).toBe('GRN-0001');
    expect(body[0].supplier_name).toBe('Steel Supplier Inc');
  });

  test('POST /api/v1/purchase/receive-grn - should create GRN with stock update', async () => {
    const grnPayload = {
      po_id: null,
      supplier_id: 'sup-1',
      invoice_number: 'INV-001',
      notes: 'Direct inward',
      received_items: [
        { material_id: 'mat-1', received_qty: 500 }
      ]
    };

    const response = await fetch(`${baseUrl()}/api/v1/purchase/receive-grn`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify(grnPayload)
    });
    const body = await response.json();
    
    expect(response.status).toBe(201);
    expect(body.success).toBe(true);
    expect(body.grnId).toBeDefined();
    expect(body.grnNumber).toMatch(/^GRN-\d{4}$/);

    const grn = await db.collection('grn_receipts').findOne({ id: body.grnId });
    expect(grn).toBeDefined();
    expect(grn.grn_number).toBe(body.grnNumber);

    const material = await db.collection('materials').findOne({ id: 'mat-1' });
    expect(material.current_stock).toBe(1500);

    const tx = await db.collection('stock_transactions').findOne({ reference_id: body.grnId });
    expect(tx).toBeDefined();
    expect(tx.transaction_type).toBe('IN');
    expect(tx.quantity).toBe(500);

    const activity = await db.collection('activity_history').findOne({ reference_id: body.grnId });
    expect(activity).toBeDefined();
    expect(activity.event_type).toBe('GRN_RECEIVED');
  });

  test('POST /api/v1/purchase/receive-grn - should update PO status when linked', async () => {
    await db.collection('purchase_orders').insertOne({
      _id: 'po-1', id: 'po-1', company_id: TEST_COMPANY,
      po_number: 'PO-0001', supplier_id: 'sup-1', status: 'ISSUED',
      total_amount: 50000, created_at: Date.now(), updated_at: Date.now()
    });
    
    await db.collection('purchase_order_items').insertOne({
      _id: 'poi-1', id: 'poi-1', company_id: TEST_COMPANY,
      po_id: 'po-1', material_id: 'mat-1', quantity: 500,
      unit_rate: 100, tax_pct: 18, received_quantity: 0,
      created_at: Date.now()
    });

    const grnPayload = {
      po_id: 'po-1',
      supplier_id: 'sup-1',
      invoice_number: 'INV-001',
      notes: 'PO receipt',
      received_items: [
        { material_id: 'mat-1', received_qty: 500 }
      ]
    };

    const response = await fetch(`${baseUrl()}/api/v1/purchase/receive-grn`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify(grnPayload)
    });
    const body = await response.json();
    
    expect(response.status).toBe(201);

    const po = await db.collection('purchase_orders').findOne({ id: 'po-1' });
    expect(po.status).toBe('RECEIVED');

    const poi = await db.collection('purchase_order_items').findOne({ id: 'poi-1' });
    expect(poi.received_quantity).toBe(500);
  });

  test('POST /api/v1/purchase/receive-grn - should reject invalid items', async () => {
    const grnPayload = {
      supplier_id: 'sup-1',
      received_items: [
        { material_id: 'non-existent', received_qty: 100 }
      ]
    };

    const response = await fetch(`${baseUrl()}/api/v1/purchase/receive-grn`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify(grnPayload)
    });
    
    expect(response.status).toBe(500);
  });

  test('POST /api/v1/purchase/receive-grn - should validate required fields', async () => {
    const response = await fetch(`${baseUrl()}/api/v1/purchase/receive-grn`, {
      method: 'POST',
      headers: HEADERS,
      body: JSON.stringify({ received_items: [] })
    });
    
    expect(response.status).toBe(400);
  });

  test('DELETE /api/v1/purchase/delete-grn/:id - should delete GRN and reverse stock', async () => {
    await db.collection('grn_receipts').insertOne({
      _id: 'grn-1', id: 'grn-1', company_id: TEST_COMPANY,
      grn_number: 'GRN-0001', po_id: null, supplier_id: 'sup-1',
      received_date: Date.now(), invoice_number: 'INV-001',
      notes: 'Test GRN', created_at: Date.now(), updated_at: Date.now()
    });
    
    await db.collection('stock_transactions').insertOne({
      _id: 'tx-1', id: 'tx-1', company_id: TEST_COMPANY,
      material_id: 'mat-1', transaction_type: 'IN', category: 'RAW_MATERIAL',
      quantity: 500, reference_type: 'GRN', reference_id: 'grn-1',
      notes: 'Received via GRN-0001', created_at: Date.now()
    });
    
    await db.collection('materials').updateOne(
      { id: 'mat-1' },
      { $set: { current_stock: 1500 } }
    );

    const response = await fetch(`${baseUrl()}/api/v1/purchase/delete-grn/grn-1`, {
      method: 'DELETE',
      headers: HEADERS
    });
    const body = await response.json();
    
    expect(response.status).toBe(200);
    expect(body.success).toBe(true);

    const grn = await db.collection('grn_receipts').findOne({ id: 'grn-1' });
    expect(grn).toBeNull();

    const tx = await db.collection('stock_transactions').findOne({ reference_id: 'grn-1' });
    expect(tx).toBeNull();

    const material = await db.collection('materials').findOne({ id: 'mat-1' });
    expect(material.current_stock).toBe(1000);

    const activity = await db.collection('activity_history').findOne({ reference_id: 'grn-1' });
    expect(activity).toBeDefined();
    expect(activity.event_type).toBe('GRN_DELETED');
  });

  test('DELETE /api/v1/purchase/delete-grn/:id - should update PO status when linked', async () => {
    await db.collection('purchase_orders').insertOne({
      _id: 'po-1', id: 'po-1', company_id: TEST_COMPANY,
      po_number: 'PO-0001', supplier_id: 'sup-1', status: 'RECEIVED',
      total_amount: 50000, created_at: Date.now(), updated_at: Date.now()
    });
    
    await db.collection('purchase_order_items').insertOne({
      _id: 'poi-1', id: 'poi-1', company_id: TEST_COMPANY,
      po_id: 'po-1', material_id: 'mat-1', quantity: 500,
      unit_rate: 100, received_quantity: 500, created_at: Date.now()
    });

    await db.collection('grn_receipts').insertOne({
      _id: 'grn-1', id: 'grn-1', company_id: TEST_COMPANY,
      grn_number: 'GRN-0001', po_id: 'po-1', supplier_id: 'sup-1',
      received_date: Date.now(), created_at: Date.now(), updated_at: Date.now()
    });
    
    await db.collection('stock_transactions').insertOne({
      _id: 'tx-1', id: 'tx-1', company_id: TEST_COMPANY,
      material_id: 'mat-1', transaction_type: 'IN', category: 'RAW_MATERIAL',
      quantity: 500, reference_type: 'GRN', reference_id: 'grn-1',
      created_at: Date.now()
    });

    const response = await fetch(`${baseUrl()}/api/v1/purchase/delete-grn/grn-1`, {
      method: 'DELETE',
      headers: HEADERS
    });
    const body = await response.json();
    
    expect(response.status).toBe(200);

    const po = await db.collection('purchase_orders').findOne({ id: 'po-1' });
    expect(po.status).toBe('ISSUED');
  });
});

const baseUrl = () => `http://localhost:${port}`;