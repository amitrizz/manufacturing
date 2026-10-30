#!/usr/bin/env node
// Quick API test script

const API_BASE = 'http://localhost:5000/api/v1';

async function testEndpoint(name, url, options = {}) {
  try {
    const res = await fetch(`${API_BASE}${url}`, {
      headers: {
        'Content-Type': 'application/json',
        'x-company-id': '3ef1fe07-1908-45ac-8b2f-3b774835be83',
        ...options.headers,
      },
      ...options,
    });
    const data = await res.json();
    console.log(`✅ ${name}: ${res.status} ${res.statusText}`);
    if (res.status >= 400) {
      console.log(`   Error:`, JSON.stringify(data, null, 2));
    }
    return { status: res.status, data };
  } catch (err) {
    console.log(`❌ ${name}: ${err.message}`);
    return { error: err.message };
  }
}

async function runTests() {
  console.log('🧪 Testing Manufacturing API Endpoints\n');
  
  // Test health
  await testEndpoint('Health Check', '/health');
  
  // Test units
  await testEndpoint('GET Units', '/units?limit=5');
  
  // Test machines
  await testEndpoint('GET Machines', '/machines?limit=5');
  
  // Test production orders
  await testEndpoint('GET Production Orders', '/production-orders?limit=5');
  
  // Test dashboard stats
  await testEndpoint('GET Dashboard Stats', '/dashboard/stats');
  
  // Test collections
  await testEndpoint('GET Collections (materials)', '/collections/materials?limit=5');
  
  // Test GRN receipts
  await testEndpoint('GET GRN Receipts', '/purchase/grn-receipts');
  
  console.log('\n✅ API Tests Complete');
}

runTests().catch(console.error);