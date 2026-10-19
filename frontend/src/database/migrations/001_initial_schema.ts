import type { SQLiteDatabase } from 'expo-sqlite';

export const MIGRATION_VERSION = 1;

export async function up(db: SQLiteDatabase): Promise<void> {
  await db.execAsync(`
CREATE TABLE IF NOT EXISTS factories (
  id TEXT PRIMARY KEY, name TEXT NOT NULL, code TEXT NOT NULL, location TEXT
);

CREATE TABLE IF NOT EXISTS production_lines (
  id TEXT PRIMARY KEY, factory_id TEXT NOT NULL REFERENCES factories(id),
  code TEXT NOT NULL, name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS product_categories (id TEXT PRIMARY KEY, name TEXT NOT NULL);

CREATE TABLE IF NOT EXISTS products (
  id TEXT PRIMARY KEY, code TEXT NOT NULL UNIQUE, name TEXT NOT NULL,
  category_id TEXT REFERENCES product_categories(id),
  unit TEXT NOT NULL, description TEXT,
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS materials (
  id TEXT PRIMARY KEY, code TEXT NOT NULL UNIQUE, name TEXT NOT NULL,
  category TEXT NOT NULL CHECK(category IN ('RAW_MATERIAL','COMPONENT','CONSUMABLE','PACKAGING','SPARE_PART')),
  unit TEXT NOT NULL,
  current_stock REAL NOT NULL DEFAULT 0,
  minimum_stock REAL NOT NULL DEFAULT 0,
  maximum_stock REAL NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS bom (
  id TEXT PRIMARY KEY, product_id TEXT NOT NULL REFERENCES products(id),
  version TEXT NOT NULL DEFAULT 'v1', is_active INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS bom_items (
  id TEXT PRIMARY KEY, bom_id TEXT NOT NULL REFERENCES bom(id),
  material_id TEXT NOT NULL REFERENCES materials(id),
  quantity REAL NOT NULL, unit TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS machines (
  id TEXT PRIMARY KEY,
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  machine_type TEXT NOT NULL,
  line_id TEXT NOT NULL REFERENCES production_lines(id),
  status TEXT NOT NULL CHECK(status IN ('RUNNING','IDLE','BREAKDOWN','MAINTENANCE','OFFLINE')),
  current_product_id TEXT REFERENCES products(id),
  efficiency REAL DEFAULT 0,
  runtime_seconds INTEGER DEFAULT 0,
  downtime_seconds INTEGER DEFAULT 0,
  last_maintenance_at INTEGER,
  next_maintenance_at INTEGER,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS production_plans (
  id TEXT PRIMARY KEY, plan_number TEXT NOT NULL UNIQUE,
  product_id TEXT NOT NULL REFERENCES products(id),
  target_quantity REAL NOT NULL,
  line_id TEXT NOT NULL REFERENCES production_lines(id),
  start_date INTEGER NOT NULL, expected_completion INTEGER NOT NULL,
  priority TEXT NOT NULL CHECK(priority IN ('LOW','MEDIUM','HIGH','CRITICAL')),
  status TEXT NOT NULL CHECK(status IN ('PLANNED','IN_PROGRESS','COMPLETED','DELAYED','CANCELLED')),
  notes TEXT, created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS production_orders (
  id TEXT PRIMARY KEY, order_number TEXT NOT NULL UNIQUE,
  plan_id TEXT REFERENCES production_plans(id),
  product_id TEXT NOT NULL REFERENCES products(id),
  line_id TEXT NOT NULL REFERENCES production_lines(id),
  machine_id TEXT REFERENCES machines(id),
  target_quantity REAL NOT NULL,
  produced_quantity REAL NOT NULL DEFAULT 0,
  rejected_quantity REAL NOT NULL DEFAULT 0,
  priority TEXT NOT NULL CHECK(priority IN ('LOW','MEDIUM','HIGH','CRITICAL')),
  status TEXT NOT NULL CHECK(status IN ('PENDING','IN_PROGRESS','COMPLETED','DELAYED','CANCELLED')),
  start_date INTEGER, due_date INTEGER, started_at INTEGER, completed_at INTEGER,
  created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS production_entries (
  id TEXT PRIMARY KEY, production_order_id TEXT NOT NULL REFERENCES production_orders(id),
  machine_id TEXT NOT NULL REFERENCES machines(id),
  shift TEXT NOT NULL, good_quantity REAL NOT NULL, rejected_quantity REAL NOT NULL DEFAULT 0,
  operator TEXT, notes TEXT, entry_timestamp INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS machine_downtime (
  id TEXT PRIMARY KEY, machine_id TEXT NOT NULL REFERENCES machines(id),
  start_time INTEGER NOT NULL, end_time INTEGER,
  reason TEXT NOT NULL CHECK(reason IN ('MECHANICAL_FAILURE','ELECTRICAL_FAILURE','MATERIAL_SHORTAGE','OPERATOR_ISSUE','QUALITY_ISSUE','PLANNED_MAINTENANCE','OTHER')),
  description TEXT, created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS quality_inspections (
  id TEXT PRIMARY KEY, batch_number TEXT NOT NULL,
  production_order_id TEXT NOT NULL REFERENCES production_orders(id),
  product_id TEXT NOT NULL REFERENCES products(id),
  quantity REAL NOT NULL, inspector TEXT NOT NULL,
  overall_result TEXT NOT NULL CHECK(overall_result IN ('PASS','FAIL','REWORK','PARTIAL_PASS')),
  rejected_quantity REAL DEFAULT 0, rejection_reason TEXT,
  rejection_action TEXT CHECK(rejection_action IN ('SCRAP','REWORK','HOLD')),
  inspected_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS quality_results (
  id TEXT PRIMARY KEY, inspection_id TEXT NOT NULL REFERENCES quality_inspections(id),
  parameter TEXT NOT NULL CHECK(parameter IN ('DIMENSION','WEIGHT','PRESSURE','LEAK_TEST','SURFACE_FINISH')),
  expected_value TEXT, actual_value TEXT,
  result TEXT NOT NULL CHECK(result IN ('PASS','FAIL')), remarks TEXT
);

CREATE TABLE IF NOT EXISTS rework_orders (
  id TEXT PRIMARY KEY, rework_number TEXT NOT NULL UNIQUE,
  product_id TEXT NOT NULL REFERENCES products(id),
  quantity REAL NOT NULL, reason TEXT NOT NULL,
  assigned_line_id TEXT REFERENCES production_lines(id),
  status TEXT NOT NULL CHECK(status IN ('PENDING','IN_PROGRESS','COMPLETED','CANCELLED')),
  source_inspection_id TEXT REFERENCES quality_inspections(id),
  created_at INTEGER NOT NULL, completed_at INTEGER
);

CREATE TABLE IF NOT EXISTS maintenance_orders (
  id TEXT PRIMARY KEY, order_number TEXT NOT NULL UNIQUE,
  machine_id TEXT NOT NULL REFERENCES machines(id),
  type TEXT NOT NULL CHECK(type IN ('PREVENTIVE','CORRECTIVE','BREAKDOWN')),
  issue TEXT, priority TEXT NOT NULL CHECK(priority IN ('LOW','MEDIUM','HIGH','CRITICAL')),
  assigned_team TEXT,
  status TEXT NOT NULL CHECK(status IN ('OPEN','IN_PROGRESS','COMPLETED','CANCELLED')),
  root_cause TEXT, action_taken TEXT, parts_used TEXT, technician_notes TEXT,
  created_at INTEGER NOT NULL, completed_at INTEGER
);

CREATE TABLE IF NOT EXISTS maintenance_history (
  id TEXT PRIMARY KEY, machine_id TEXT NOT NULL REFERENCES machines(id),
  maintenance_order_id TEXT REFERENCES maintenance_orders(id),
  performed_at INTEGER NOT NULL, summary TEXT
);

CREATE TABLE IF NOT EXISTS finished_goods (
  id TEXT PRIMARY KEY, product_id TEXT NOT NULL REFERENCES products(id),
  produced_quantity REAL NOT NULL DEFAULT 0,
  quality_passed_quantity REAL NOT NULL DEFAULT 0,
  rejected_quantity REAL NOT NULL DEFAULT 0,
  rework_quantity REAL NOT NULL DEFAULT 0,
  available_quantity REAL NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS dispatch_orders (
  id TEXT PRIMARY KEY, dispatch_number TEXT NOT NULL UNIQUE,
  customer_name TEXT NOT NULL, product_id TEXT NOT NULL REFERENCES products(id),
  quantity REAL NOT NULL,
  status TEXT NOT NULL CHECK(status IN ('DRAFT','READY','DISPATCHED','DELIVERED','CANCELLED')),
  created_at INTEGER NOT NULL, dispatched_at INTEGER
);

CREATE TABLE IF NOT EXISTS notifications (
  id TEXT PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL,
  severity TEXT NOT NULL CHECK(severity IN ('INFO','WARNING','CRITICAL')),
  is_read INTEGER NOT NULL DEFAULT 0,
  reference_type TEXT, reference_id TEXT, created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS activity_history (
  id TEXT PRIMARY KEY, event_type TEXT NOT NULL, title TEXT NOT NULL, description TEXT,
  reference_type TEXT, reference_id TEXT, timestamp INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS app_meta (key TEXT PRIMARY KEY, value TEXT);
`);

  const indices = [
    'CREATE INDEX IF NOT EXISTS idx_production_lines_factory ON production_lines(factory_id);',
    'CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);',
    'CREATE INDEX IF NOT EXISTS idx_bom_product ON bom(product_id);',
    'CREATE INDEX IF NOT EXISTS idx_bom_items_bom ON bom_items(bom_id);',
    'CREATE INDEX IF NOT EXISTS idx_bom_items_material ON bom_items(material_id);',
    'CREATE INDEX IF NOT EXISTS idx_machines_line ON machines(line_id);',
    'CREATE INDEX IF NOT EXISTS idx_machines_status ON machines(status);',
    'CREATE INDEX IF NOT EXISTS idx_machines_product ON machines(current_product_id);',
    'CREATE INDEX IF NOT EXISTS idx_production_plans_product ON production_plans(product_id);',
    'CREATE INDEX IF NOT EXISTS idx_production_plans_line ON production_plans(line_id);',
    'CREATE INDEX IF NOT EXISTS idx_production_orders_status ON production_orders(status);',
    'CREATE INDEX IF NOT EXISTS idx_production_orders_line ON production_orders(line_id);',
    'CREATE INDEX IF NOT EXISTS idx_production_orders_plan ON production_orders(plan_id);',
    'CREATE INDEX IF NOT EXISTS idx_production_orders_product ON production_orders(product_id);',
    'CREATE INDEX IF NOT EXISTS idx_production_orders_machine ON production_orders(machine_id);',
    'CREATE INDEX IF NOT EXISTS idx_production_entries_order ON production_entries(production_order_id);',
    'CREATE INDEX IF NOT EXISTS idx_production_entries_machine ON production_entries(machine_id);',
    'CREATE INDEX IF NOT EXISTS idx_machine_downtime_machine ON machine_downtime(machine_id);',
    'CREATE INDEX IF NOT EXISTS idx_quality_inspections_order ON quality_inspections(production_order_id);',
    'CREATE INDEX IF NOT EXISTS idx_quality_results_inspection ON quality_results(inspection_id);',
    'CREATE INDEX IF NOT EXISTS idx_rework_product ON rework_orders(product_id);',
    'CREATE INDEX IF NOT EXISTS idx_maintenance_orders_machine ON maintenance_orders(machine_id);',
    'CREATE INDEX IF NOT EXISTS idx_maintenance_history_machine ON maintenance_history(machine_id);',
    'CREATE INDEX IF NOT EXISTS idx_finished_goods_product ON finished_goods(product_id);',
    'CREATE INDEX IF NOT EXISTS idx_dispatch_product ON dispatch_orders(product_id);',
    'CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);',
    'CREATE INDEX IF NOT EXISTS idx_activity_timestamp ON activity_history(timestamp);',
  ];

  for (const sql of indices) {
    await db.execAsync(sql);
  }
}
