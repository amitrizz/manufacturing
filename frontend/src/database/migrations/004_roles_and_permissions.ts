import type { SQLiteDatabase } from 'expo-sqlite';
import { newId } from '../../utils/id';

export const MIGRATION_VERSION = 4;

export async function up(db: SQLiteDatabase): Promise<void> {
  // 1. Create company_roles table
  await db.execAsync(`
CREATE TABLE IF NOT EXISTS company_roles (
  id TEXT PRIMARY KEY,
  company_id TEXT NOT NULL REFERENCES companies(id),
  name TEXT NOT NULL,
  description TEXT,
  permissions TEXT NOT NULL,
  is_system INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  UNIQUE(company_id, name)
);
`);

  // 2. Add role_id to staff table if missing
  const staffCols = await db.getAllAsync<{ name: string }>('PRAGMA table_info(staff);');
  const colNames = staffCols.map((c) => c.name);

  if (!colNames.includes('role_id')) {
    await db.execAsync('ALTER TABLE staff ADD COLUMN role_id TEXT REFERENCES company_roles(id);');
  }

  // 3. Seed default roles for all existing companies
  const companies = await db.getAllAsync<{ id: string }>('SELECT id FROM companies;');
  const now = Date.now();

  const standardRoles = [
    {
      name: 'OPERATOR',
      description: 'Machine operations, live production output logging & breakdown view',
      permissions: [
        'home_production',
        'home_machines',
        'home_orders',
        'tasks_production',
        'tasks_machines',
        'mgmt_alerts',
      ],
      isSystem: 1,
    },
    {
      name: 'SUPERVISOR',
      description: 'Floor supervision, attendance, orders, task dispatch & inspections',
      permissions: [
        'home_orders',
        'home_production',
        'home_stock',
        'home_machines',
        'home_quality',
        'home_maintenance',
        'home_products',
        'tasks_production',
        'tasks_machines',
        'tasks_materials',
        'tasks_maintenance',
        'tasks_quality',
        'tasks_dispatch',
        'tasks_quick_actions',
        'mgmt_staff',
        'mgmt_reports',
        'mgmt_dispatch',
        'mgmt_alerts',
      ],
      isSystem: 1,
    },
    {
      name: 'TECHNICIAN',
      description: 'Machine repairs, routine maintenance servicing & breakdown response',
      permissions: [
        'home_machines',
        'home_maintenance',
        'home_production',
        'tasks_machines',
        'tasks_maintenance',
        'mgmt_alerts',
      ],
      isSystem: 1,
    },
    {
      name: 'QUALITY_INSPECTOR',
      description: 'Part inspections, defect recording & rework order verification',
      permissions: [
        'home_quality',
        'home_production',
        'home_products',
        'tasks_quality',
        'tasks_quick_actions',
        'mgmt_alerts',
      ],
      isSystem: 1,
    },
    {
      name: 'MANAGER',
      description: 'Full plant operations, purchase, dispatch, roles & configuration',
      permissions: [
        'home_orders',
        'home_production',
        'home_stock',
        'home_machines',
        'home_quality',
        'home_maintenance',
        'home_products',
        'tasks_production',
        'tasks_machines',
        'tasks_materials',
        'tasks_maintenance',
        'tasks_quality',
        'tasks_dispatch',
        'tasks_quick_actions',
        'mgmt_purchase',
        'mgmt_staff',
        'mgmt_reports',
        'mgmt_dispatch',
        'mgmt_contacts',
        'mgmt_alerts',
        'mgmt_settings',
        'mgmt_roles',
      ],
      isSystem: 1,
    },
  ];

  for (const comp of companies) {
    for (const r of standardRoles) {
      const id = newId();
      await db.runAsync(
        `INSERT OR IGNORE INTO company_roles (
          id, company_id, name, description, permissions, is_system, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?);`,
        id,
        comp.id,
        r.name,
        r.description,
        JSON.stringify(r.permissions),
        r.isSystem,
        now,
        now,
      );
    }

    // Link staff to roles
    await db.execAsync(`
      UPDATE staff SET role_id = (
        SELECT id FROM company_roles 
        WHERE company_roles.company_id = staff.company_id 
          AND UPPER(company_roles.name) = UPPER(staff.role)
        LIMIT 1
      ) WHERE role_id IS NULL OR role_id = '';
    `);
  }
}
