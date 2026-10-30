import { connectToMongo, closeConnection, getDb } from '../config/db.js';
import { runMigration } from '../migrate.js';

let isTestDbInitialized = false;

export async function startTestDB() {
  // Use the actual MongoDB database from environment (not in-memory)
  // Uses the actual DATABASE_URL from .env or .env.development
  process.env.MONGODB_DB_NAME = process.env.MONGODB_DB_NAME || 'manufacturing_dev';
  
  const db = await connectToMongo();
  
  // Run migration to set up collections and indexes
  await runMigration(db);
  
  isTestDbInitialized = true;
  
  return { db };
}

export async function stopTestDB() {
  await closeConnection();
  isTestDbInitialized = false;
}

export async function clearTestDB() {
  const db = getDb();
  if (db) {
    const collections = await db.listCollections().toArray();
    for (const col of collections) {
      // Don't drop system collections
      if (!col.name.startsWith('system.')) {
        await db.collection(col.name).deleteMany({});
      }
    }
  }
}

export function getTestDB() {
  return getDb();
}

export function isTestDbReady() {
  return isTestDbInitialized;
}

export const TEST_COMPANY_ID = '05cf18e5-026d-4cb1-a312-e831dcd30e6b';
export const TEST_COMPANY_ID_2 = 'test-company-0987654321ba';
export const TEST_API_KEY = 'dev-api-key-1234567890abcdefghijklmnop';

export function createAuthHeaders(companyId = TEST_COMPANY_ID) {
  return {
    'x-company-id': companyId,
    'x-api-key': TEST_API_KEY
  };
}

export function createTestCompany(overrides = {}) {
  const now = Date.now();
  return {
    _id: `company-${now}`,
    id: `company-${now}`,
    company_code: 'TEST',
    name: 'Test Company',
    address: '123 Test St',
    contact_email: 'test@example.com',
    admin_email: 'admin@example.com',
    contact_phone: '+1234567890',
    tax_id: 'TAX123',
    created_at: now,
    updated_at: now,
    ...overrides
  };
}

export function createTestUser(overrides = {}) {
  const now = Date.now();
  return {
    _id: `user-${now}`,
    id: `user-${now}`,
    company_id: TEST_COMPANY_ID,
    employee_id: 'EMP001',
    name: 'Test User',
    role: 'OPERATOR',
    phone: '+1234567890',
    shift: 'A',
    login_pin: '1234',
    is_active: 1,
    created_at: now,
    updated_at: now,
    ...overrides
  };
}

export function createTestMachine(overrides = {}) {
  const now = Date.now();
  return {
    _id: `machine-${now}`,
    id: `machine-${now}`,
    company_id: TEST_COMPANY_ID,
    code: 'M001',
    name: 'Test Machine',
    machine_type: 'CNC',
    line_id: 'line-001',
    status: 'IDLE',
    current_product_id: null,
    current_operator: null,
    efficiency: 85,
    runtime_seconds: 0,
    downtime_seconds: 0,
    last_maintenance_at: null,
    next_maintenance_at: null,
    created_at: now,
    updated_at: now,
    ...overrides
  };
}

export function createTestMaterial(overrides = {}) {
  const now = Date.now();
  return {
    _id: `material-${now}`,
    id: `material-${now}`,
    company_id: TEST_COMPANY_ID,
    code: 'MAT001',
    name: 'Test Material',
    category: 'RAW_MATERIAL',
    unit: 'PCS',
    current_stock: 1000,
    minimum_stock: 100,
    maximum_stock: 5000,
    created_at: now,
    updated_at: now,
    ...overrides
  };
}

export function createTestProduct(overrides = {}) {
  const now = Date.now();
  return {
    _id: `product-${now}`,
    id: `product-${now}`,
    company_id: TEST_COMPANY_ID,
    code: 'PRD001',
    name: 'Test Product',
    category_id: null,
    unit: 'PCS',
    description: 'Test product description',
    created_at: now,
    ...overrides
  };
}

export function createTestProductionOrder(overrides = {}) {
  const now = Date.now();
  return {
    _id: `order-${now}`,
    id: `order-${now}`,
    company_id: TEST_COMPANY_ID,
    order_number: `ORD-${now}`,
    plan_id: null,
    product_id: 'product-001',
    line_id: 'line-001',
    machine_id: null,
    assigned_machines: null,
    assigned_workers: null,
    target_quantity: 1000,
    produced_quantity: 0,
    rejected_quantity: 0,
    priority: 'MEDIUM',
    status: 'PENDING',
    start_date: null,
    due_date: now + 86400000,
    started_at: null,
    completed_at: null,
    qc_status: 'PENDING',
    qc_inspected_at: null,
    qc_inspector: null,
    qc_notes: null,
    created_at: now,
    updated_at: now,
    ...overrides
  };
}

export function createTestProductionEntry(overrides = {}) {
  const now = Date.now();
  return {
    _id: `entry-${now}`,
    id: `entry-${now}`,
    company_id: TEST_COMPANY_ID,
    production_order_id: 'order-001',
    machine_id: 'machine-001',
    operator_id: 'user-001',
    good_quantity: 100,
    rejected_quantity: 5,
    scrap_quantity: 2,
    rejection_reason: null,
    entry_timestamp: now,
    created_at: now,
    ...overrides
  };
}

export function createTestGRN(overrides = {}) {
  const now = Date.now();
  return {
    _id: `grn-${now}`,
    id: `grn-${now}`,
    company_id: TEST_COMPANY_ID,
    grn_number: `GRN-${now}`,
    po_id: null,
    supplier_id: 'supplier-001',
    received_date: now,
    invoice_number: 'INV-001',
    notes: 'Test GRN',
    created_at: now,
    updated_at: now,
    ...overrides
  };
}

export function createTestSupplier(overrides = {}) {
  const now = Date.now();
  return {
    _id: `supplier-${now}`,
    id: `supplier-${now}`,
    company_id: TEST_COMPANY_ID,
    name: 'Test Supplier',
    contact_person: 'John Doe',
    phone: '+1234567890',
    email: 'supplier@example.com',
    address: '456 Supplier Ave',
    gst_number: 'GST123456',
    supplied_items: 'Raw Materials',
    rating: 4.5,
    notes: 'Reliable supplier',
    is_active: 1,
    created_at: now,
    updated_at: now,
    ...overrides
  };
}