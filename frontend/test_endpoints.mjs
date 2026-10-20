// Using native fetch in Node 18+

const BASE_URL = 'https://manufacturing-i0lp.onrender.com';

const ALL_COLLECTIONS = [
  'companies',
  'company_roles',
  'staff',
  'staff_attendance',
  'factories',
  'production_lines',
  'machines',
  'machine_downtime',
  'materials',
  'product_categories',
  'products',
  'bom',
  'bom_items',
  'production_plans',
  'production_orders',
  'production_entries',
  'quality_inspections',
  'quality_results',
  'rework_orders',
  'maintenance_orders',
  'maintenance_history',
  'finished_goods',
  'dispatch_orders',
  'suppliers',
  'customers',
  'purchase_requests',
  'purchase_orders',
  'purchase_order_items',
  'grn_receipts',
  'stock_transactions',
  'activity_history',
  'notifications',
];

const results = [];

async function test(name, fn) {
  const start = Date.now();
  try {
    await fn();
    const duration = Date.now() - start;
    results.push({ name, status: 'PASS', duration: `${duration}ms` });
    console.log(`✅ PASS: ${name} (${duration}ms)`);
  } catch (err) {
    const duration = Date.now() - start;
    results.push({ name, status: 'FAIL', duration: `${duration}ms`, error: err.message });
    console.error(`❌ FAIL: ${name} (${duration}ms) - ${err.message}`);
  }
}

async function request(endpoint, options = {}) {
  const url = `${BASE_URL}${endpoint}`;
  const res = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'Bypass-Tunnel-Reminder': 'true',
      ...(options.headers || {}),
    },
  });
  if (!res.ok) {
    let msg = `HTTP ${res.status} ${res.statusText}`;
    try {
      const j = await res.json();
      if (j && j.error) msg = j.error;
    } catch {}
    throw new Error(msg);
  }
  return res.json();
}

async function run() {
  console.log(`\n======================================================`);
  console.log(`🚀 COMPREHENSIVE ENDPOINT AUDIT FOR RENDER BACKEND`);
  console.log(`🌐 Base URL: ${BASE_URL}`);
  console.log(`======================================================\n`);

  // 1. Health
  await test('GET /api/health', async () => {
    const data = await request('/api/health');
    if (data.status !== 'ok') throw new Error(`Unexpected status: ${data.status}`);
    if (!data.database) throw new Error('Missing database name');
  });

  // 2. Dashboard stats
  await test('GET /api/dashboard/stats', async () => {
    const data = await request('/api/dashboard/stats');
    if (!data.kpis) throw new Error('Missing kpis object');
    if (!data.machines) throw new Error('Missing machines object');
    if (!Array.isArray(data.monthlyData)) throw new Error('Missing monthlyData array');
  });

  // 3. Machines list & status update
  let testMachineId = null;
  await test('GET /api/machines', async () => {
    const data = await request('/api/machines');
    if (!Array.isArray(data)) throw new Error('Expected array of machines');
    if (data.length > 0) testMachineId = data[0].id || data[0]._id;
  });

  if (testMachineId) {
    await test(`POST /api/machines/:id/status (Machine: ${testMachineId})`, async () => {
      const data = await request(`/api/machines/${testMachineId}/status`, {
        method: 'POST',
        body: JSON.stringify({ status: 'RUNNING', reason: 'Automated endpoint audit verification' }),
      });
      if (!data.success) throw new Error('Machine status update failed');
    });
  }

  // 4. Production Orders list & start
  let testOrderId = null;
  await test('GET /api/production-orders', async () => {
    const data = await request('/api/production-orders');
    if (!Array.isArray(data)) throw new Error('Expected array of production orders');
    if (data.length > 0) testOrderId = data[0].id || data[0]._id;
  });

  if (testOrderId) {
    await test(`POST /api/production-orders/:id/start (Order: ${testOrderId})`, async () => {
      const data = await request(`/api/production-orders/${testOrderId}/start`, {
        method: 'POST',
      });
      if (!data.success) throw new Error('Order start failed');
    });
  }

  // 5. Purchase & Goods Receipt (GRN) workflow
  let testGrnId = null;
  await test('GET /api/purchase/grn-receipts', async () => {
    const data = await request('/api/purchase/grn-receipts');
    if (!Array.isArray(data)) throw new Error('Expected array of GRN receipts');
  });

  // Find a material to use for GRN test
  let testMaterialId = null;
  const materials = await request('/api/collections/materials');
  if (materials && materials.length > 0) {
    testMaterialId = materials[0].id || materials[0]._id;
  }

  if (testMaterialId) {
    await test('POST /api/purchase/receive-grn (Create dynamic GRN)', async () => {
      const payload = {
        supplier_id: null,
        po_id: null,
        invoice_number: 'TEST-INV-999',
        notes: 'Automated test GRN',
        received_items: [
          { material_id: testMaterialId, received_qty: 5 },
        ],
      };
      const data = await request('/api/purchase/receive-grn', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
      if (!data.success || !data.grnId) throw new Error('GRN creation failed');
      testGrnId = data.grnId;
    });

    if (testGrnId) {
      await test(`DELETE /api/purchase/delete-grn/:id (Revert GRN: ${testGrnId})`, async () => {
        const data = await request(`/api/purchase/delete-grn/${testGrnId}`, {
          method: 'DELETE',
        });
        if (!data.success) throw new Error('GRN deletion failed');
      });
    }
  }

  // 6. Generic Collection CRUD test (Create, Read, Update, Delete)
  const crudCollection = 'notifications';
  let createdDocId = null;

  await test(`POST /api/collections/${crudCollection} (Insert document)`, async () => {
    const doc = {
      title: 'Audit Test Notification',
      message: 'Verifying collection insert endpoint',
      is_read: false,
    };
    const data = await request(`/api/collections/${crudCollection}`, {
      method: 'POST',
      body: JSON.stringify(doc),
    });
    if (!data.id && !data._id) throw new Error('Missing ID in created document');
    createdDocId = data.id || data._id;
  });

  if (createdDocId) {
    await test(`GET /api/collections/${crudCollection}/:id (Get single document)`, async () => {
      const data = await request(`/api/collections/${crudCollection}/${createdDocId}`);
      if (!data || (data.id !== createdDocId && data._id !== createdDocId)) {
        throw new Error('Retrieved document ID does not match');
      }
    });

    await test(`PUT /api/collections/${crudCollection}/:id (Update document)`, async () => {
      const data = await request(`/api/collections/${crudCollection}/${createdDocId}`, {
        method: 'PUT',
        body: JSON.stringify({ is_read: true, message: 'Updated via test' }),
      });
      if (!data || data.is_read !== true) {
        throw new Error('Document update was not reflected');
      }
    });

    await test(`DELETE /api/collections/${crudCollection}/:id (Delete document)`, async () => {
      const data = await request(`/api/collections/${crudCollection}/${createdDocId}`, {
        method: 'DELETE',
      });
      if (!data.success) throw new Error('Delete operation failed');
    });
  }

  // 7. Test all 32 collections GET endpoints
  console.log(`\n--- Auditing all 32 MongoDB Collections ---`);
  for (const col of ALL_COLLECTIONS) {
    await test(`GET /api/collections/${col}`, async () => {
      const data = await request(`/api/collections/${col}`);
      if (!Array.isArray(data)) throw new Error(`Collection ${col} did not return an array`);
    });
  }

  // Summary
  console.log(`\n======================================================`);
  const passed = results.filter((r) => r.status === 'PASS').length;
  const failed = results.filter((r) => r.status === 'FAIL').length;
  console.log(`📊 SUMMARY: Total: ${results.length} | Passed: ${passed} | Failed: ${failed}`);
  console.log(`======================================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

run().catch((e) => {
  console.error('Fatal audit failure:', e);
  process.exit(1);
});
