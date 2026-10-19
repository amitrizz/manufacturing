import type { SQLiteDatabase } from 'expo-sqlite';

export const MIGRATION_VERSION = 2;

export async function up(db: SQLiteDatabase): Promise<void> {
  await db.execAsync(`
-- Customers
CREATE TABLE IF NOT EXISTS customers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  company TEXT NOT NULL,
  phone TEXT,
  email TEXT,
  billing_address TEXT,
  delivery_address TEXT,
  gst_number TEXT,
  notes TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Suppliers
CREATE TABLE IF NOT EXISTS suppliers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  contact_person TEXT,
  phone TEXT,
  email TEXT,
  address TEXT,
  gst_number TEXT,
  supplied_items TEXT,
  rating REAL DEFAULT 5.0,
  notes TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Workers / Staff
CREATE TABLE IF NOT EXISTS staff (
  id TEXT PRIMARY KEY,
  employee_id TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  role TEXT NOT NULL CHECK(role IN ('OPERATOR','SUPERVISOR','TECHNICIAN','QUALITY_INSPECTOR','MANAGER')),
  phone TEXT,
  skills TEXT,
  shift TEXT NOT NULL DEFAULT 'Morning',
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Daily Attendance
CREATE TABLE IF NOT EXISTS staff_attendance (
  id TEXT PRIMARY KEY,
  staff_id TEXT NOT NULL REFERENCES staff(id),
  date TEXT NOT NULL,
  shift TEXT NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('PRESENT','ABSENT','LEAVE','HALF_DAY')),
  overtime_hours REAL DEFAULT 0,
  notes TEXT,
  created_at INTEGER NOT NULL,
  UNIQUE(staff_id, date, shift)
);

-- Purchase Requests
CREATE TABLE IF NOT EXISTS purchase_requests (
  id TEXT PRIMARY KEY,
  request_number TEXT NOT NULL UNIQUE,
  material_id TEXT NOT NULL REFERENCES materials(id),
  quantity REAL NOT NULL,
  required_by_date INTEGER NOT NULL,
  linked_order_id TEXT REFERENCES production_orders(id),
  reason TEXT,
  status TEXT NOT NULL CHECK(status IN ('PENDING','APPROVED','REJECTED','ORDERED')),
  created_at INTEGER NOT NULL
);

-- Purchase Orders
CREATE TABLE IF NOT EXISTS purchase_orders (
  id TEXT PRIMARY KEY,
  po_number TEXT NOT NULL UNIQUE,
  supplier_id TEXT NOT NULL REFERENCES suppliers(id),
  status TEXT NOT NULL CHECK(status IN ('DRAFT','ISSUED','PARTIALLY_RECEIVED','RECEIVED','CANCELLED')),
  expected_date INTEGER NOT NULL,
  total_amount REAL NOT NULL DEFAULT 0,
  tax_amount REAL NOT NULL DEFAULT 0,
  terms TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Purchase Order Items
CREATE TABLE IF NOT EXISTS purchase_order_items (
  id TEXT PRIMARY KEY,
  po_id TEXT NOT NULL REFERENCES purchase_orders(id),
  material_id TEXT NOT NULL REFERENCES materials(id),
  quantity REAL NOT NULL,
  unit_rate REAL NOT NULL,
  tax_pct REAL NOT NULL DEFAULT 0,
  received_quantity REAL NOT NULL DEFAULT 0
);

-- Goods Received Note (GRN)
CREATE TABLE IF NOT EXISTS grn_receipts (
  id TEXT PRIMARY KEY,
  grn_number TEXT NOT NULL UNIQUE,
  po_id TEXT REFERENCES purchase_orders(id),
  supplier_id TEXT NOT NULL REFERENCES suppliers(id),
  received_date INTEGER NOT NULL,
  invoice_number TEXT,
  notes TEXT,
  created_at INTEGER NOT NULL
);

-- Detailed Stock Transactions Ledger
CREATE TABLE IF NOT EXISTS stock_transactions (
  id TEXT PRIMARY KEY,
  material_id TEXT REFERENCES materials(id),
  product_id TEXT REFERENCES products(id),
  transaction_type TEXT NOT NULL CHECK(transaction_type IN ('IN','OUT','ADJUSTMENT','SCRAP')),
  category TEXT NOT NULL CHECK(category IN ('RAW_MATERIAL','WIP','FINISHED_GOODS','SCRAP')),
  quantity REAL NOT NULL,
  batch_lot TEXT,
  reference_type TEXT,
  reference_id TEXT,
  performed_by TEXT,
  notes TEXT,
  created_at INTEGER NOT NULL
);
  `);

  // Optional alter columns for existing tables
  try {
    await db.execAsync(`
      ALTER TABLE production_orders ADD COLUMN customer_id TEXT REFERENCES customers(id);
      ALTER TABLE production_orders ADD COLUMN drawing_spec TEXT;
      ALTER TABLE dispatch_orders ADD COLUMN customer_id TEXT REFERENCES customers(id);
      ALTER TABLE dispatch_orders ADD COLUMN transporter TEXT;
      ALTER TABLE dispatch_orders ADD COLUMN vehicle_number TEXT;
      ALTER TABLE dispatch_orders ADD COLUMN tracking_number TEXT;
      ALTER TABLE dispatch_orders ADD COLUMN challan_number TEXT;
    `);
  } catch {
    // Columns might already exist if re-running
  }

  // Indices
  const indices = [
    'CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name);',
    'CREATE INDEX IF NOT EXISTS idx_suppliers_name ON suppliers(name);',
    'CREATE INDEX IF NOT EXISTS idx_staff_role ON staff(role);',
    'CREATE INDEX IF NOT EXISTS idx_staff_attendance_date ON staff_attendance(date);',
    'CREATE INDEX IF NOT EXISTS idx_purchase_requests_status ON purchase_requests(status);',
    'CREATE INDEX IF NOT EXISTS idx_purchase_orders_status ON purchase_orders(status);',
    'CREATE INDEX IF NOT EXISTS idx_purchase_order_items_po ON purchase_order_items(po_id);',
    'CREATE INDEX IF NOT EXISTS idx_grn_receipts_po ON grn_receipts(po_id);',
    'CREATE INDEX IF NOT EXISTS idx_stock_transactions_material ON stock_transactions(material_id);',
    'CREATE INDEX IF NOT EXISTS idx_stock_transactions_product ON stock_transactions(product_id);',
    'CREATE INDEX IF NOT EXISTS idx_stock_transactions_cat ON stock_transactions(category);',
  ];

  for (const sql of indices) {
    await db.execAsync(sql);
  }
}
