// Comprehensive automated test script for Production Render backend
const PROD_URL = 'https://manufacturing-i0lp.onrender.com';

async function runTests() {
  console.log(`\n======================================================`);
  console.log(`🌐 TESTING PRODUCTION BACKEND: ${PROD_URL}`);
  console.log(`======================================================\n`);

  const results = [];

  async function check(name, fn) {
    const t0 = Date.now();
    try {
      const data = await fn();
      const elapsed = Date.now() - t0;
      console.log(`✅ [PASS] ${name} (${elapsed}ms)`);
      if (data && typeof data === 'object') {
        const preview = JSON.stringify(data).slice(0, 120);
        console.log(`   Response: ${preview}...`);
      }
      results.push({ name, pass: true, elapsed });
    } catch (err) {
      const elapsed = Date.now() - t0;
      console.error(`❌ [FAIL] ${name} (${elapsed}ms): ${err.message}`);
      results.push({ name, pass: false, elapsed, error: err.message });
    }
  }

  // Helper request
  async function api(path, options = {}) {
    const url = `${PROD_URL}${path}`;
    const headers = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...(options.headers || {}),
    };
    const res = await fetch(url, { ...options, headers });
    let text;
    try {
      text = await res.text();
      return JSON.parse(text);
    } catch {
      throw new Error(`HTTP ${res.status}: ${text || res.statusText}`);
    }
  }

  // 1. Health check
  await check('GET /api/v1/health (System & Mongo status)', async () => {
    const res = await api('/api/v1/health');
    if (res.status !== 'ok') throw new Error(`Unexpected status: ${JSON.stringify(res)}`);
    return res;
  });

  // 2. List Companies
  let companyId = null;
  await check('GET /api/v1/companies (Public company listing for login)', async () => {
    const list = await api('/api/v1/companies');
    if (!Array.isArray(list)) throw new Error('Expected array of companies');
    if (list.length > 0) {
      companyId = list[0].id || list[0]._id || list[0].company_code;
    }
    return { count: list.length, sample: list[0]?.name };
  });

  // 3. Verify Admin Login endpoint
  await check('POST /api/v1/companies/verify-admin (Admin Authentication)', async () => {
    const res = await api('/api/v1/companies/verify-admin', {
      method: 'POST',
      body: JSON.stringify({ emailOrCode: 'GOOGLE', password: 'wrongpassword' }),
    });
    // We expect either { success: false } or 401/400 with invalid credentials - NOT 401 "Authentication required"
    if (res.error === 'Authentication required') {
      throw new Error('Blocked by API key middleware: Authentication required');
    }
    return res;
  });

  // 4. Test Tenant Route with x-company-id header
  const targetCompany = companyId || 'GOOGLE';
  await check(`GET /api/v1/dashboard/stats (Tenant: ${targetCompany})`, async () => {
    const res = await api('/api/v1/dashboard/stats', {
      headers: { 'x-company-id': targetCompany },
    });
    if (!res.kpis && !res.machines) throw new Error(`Malformed dashboard response: ${JSON.stringify(res)}`);
    return res;
  });

  // 5. Test Machines collection
  await check(`GET /api/v1/machines (Tenant: ${targetCompany})`, async () => {
    const res = await api('/api/v1/machines', {
      headers: { 'x-company-id': targetCompany },
    });
    if (!Array.isArray(res) && !res.data) throw new Error(`Expected array: ${JSON.stringify(res)}`);
    return { machinesCount: Array.isArray(res) ? res.length : res.data?.length };
  });

  // 6. Test Subscription Status
  await check(`GET /api/v1/subscription/status (Tenant: ${targetCompany})`, async () => {
    const res = await api(`/api/v1/subscription/status?companyId=${targetCompany}`);
    return res;
  });

  // Summary
  console.log(`\n======================================================`);
  const passed = results.filter((r) => r.pass).length;
  console.log(`📊 RESULTS: ${passed}/${results.length} PASSED`);
  console.log(`======================================================\n`);
}

runTests();
