import type { SQLiteDatabase } from 'expo-sqlite';

export const MIGRATION_VERSION = 3;

export async function up(db: SQLiteDatabase): Promise<void> {
  // 1. Create Companies Table
  await db.execAsync(`
CREATE TABLE IF NOT EXISTS companies (
  id TEXT PRIMARY KEY,
  company_code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  admin_email TEXT NOT NULL UNIQUE,
  admin_password TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
`);

  // 2. Add columns to staff table if not existing
  const staffCols = await db.getAllAsync<{ name: string }>('PRAGMA table_info(staff);');
  const colNames = staffCols.map((c) => c.name);

  if (!colNames.includes('company_id')) {
    await db.execAsync('ALTER TABLE staff ADD COLUMN company_id TEXT REFERENCES companies(id);');
  }
  if (!colNames.includes('login_pin')) {
    await db.execAsync("ALTER TABLE staff ADD COLUMN login_pin TEXT NOT NULL DEFAULT '1234';");
  }

  // 3. Seed default demo company
  const now = Date.now();
  await db.runAsync(
    `INSERT OR IGNORE INTO companies (
      id, company_code, name, admin_email, admin_password, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?)`,
    'comp-apex-01',
    'APEX01',
    'Apex Manufacturing Ltd',
    'admin@apex.com',
    'admin123',
    now,
    now,
  );

  // 4. Ensure all existing staff are linked to the default company
  await db.runAsync(
    "UPDATE staff SET company_id = 'comp-apex-01', login_pin = '1234' WHERE company_id IS NULL OR company_id = '';",
  );
}
