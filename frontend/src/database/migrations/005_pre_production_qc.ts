import type { SQLiteDatabase } from 'expo-sqlite';

export const MIGRATION_VERSION = 5;

export async function up(db: SQLiteDatabase): Promise<void> {
  const cols = await db.getAllAsync<{ name: string }>('PRAGMA table_info(production_orders);');
  const colNames = cols.map((c) => c.name);

  if (!colNames.includes('qc_status')) {
    await db.execAsync(
      `ALTER TABLE production_orders ADD COLUMN qc_status TEXT DEFAULT 'PENDING';`,
    );
  }
  if (!colNames.includes('qc_inspected_at')) {
    await db.execAsync(
      `ALTER TABLE production_orders ADD COLUMN qc_inspected_at INTEGER;`,
    );
  }
  if (!colNames.includes('qc_inspector')) {
    await db.execAsync(
      `ALTER TABLE production_orders ADD COLUMN qc_inspector TEXT;`,
    );
  }
  if (!colNames.includes('qc_notes')) {
    await db.execAsync(
      `ALTER TABLE production_orders ADD COLUMN qc_notes TEXT;`,
    );
  }

  // Auto-mark existing running/finished orders as PASSED so historical orders remain valid
  await db.execAsync(`
    UPDATE production_orders
    SET qc_status = 'PASSED', qc_inspector = 'SYSTEM / SETUP APPROVED'
    WHERE status IN ('IN_PROGRESS', 'COMPLETED') AND (qc_status IS NULL OR qc_status = 'PENDING');
  `);
}
