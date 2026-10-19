import { newId } from '../utils/id';
import { getDatabase } from './client';
import { setMetaValue } from './repositories/appMetaRepository';
import { runSeed } from './seed';

export const BUSINESS_TABLES = [
  'stock_transactions',
  'grn_receipts',
  'purchase_order_items',
  'purchase_orders',
  'purchase_requests',
  'staff_attendance',
  'staff',
  'suppliers',
  'customers',
  'activity_history',
  'notifications',
  'dispatch_orders',
  'finished_goods',
  'maintenance_history',
  'maintenance_orders',
  'rework_orders',
  'quality_results',
  'quality_inspections',
  'machine_downtime',
  'production_entries',
  'production_orders',
  'production_plans',
  'bom_items',
  'bom',
  'machines',
  'materials',
  'products',
  'product_categories',
  'production_lines',
  'factories',
];

export async function resetDemoData(): Promise<void> {
  const db = await getDatabase();

  await db.withTransactionAsync(async () => {
    await db.execAsync('PRAGMA foreign_keys = OFF');
    for (const table of BUSINESS_TABLES) {
      await db.runAsync(`DELETE FROM ${table}`);
    }
    await db.execAsync('PRAGMA foreign_keys = ON');
  });

  await runSeed(db);
}

export async function clearAllDatabaseData(): Promise<void> {
  const db = await getDatabase();

  await db.withTransactionAsync(async () => {
    await db.execAsync('PRAGMA foreign_keys = OFF');
    for (const table of BUSINESS_TABLES) {
      await db.runAsync(`DELETE FROM ${table}`);
    }
    await db.execAsync('PRAGMA foreign_keys = ON');

    // Create a base factory and initial production lines so the system is ready to add real machines & orders
    const factoryId = newId();
    await db.runAsync(
      'INSERT INTO factories (id, name, code, location) VALUES (?, ?, ?, ?)',
      factoryId,
      'Main Manufacturing Plant',
      'PLANT-01',
      'Factory Floor',
    );

    const lines = [
      { code: 'LINE-A', name: 'Production Line A' },
      { code: 'LINE-B', name: 'Production Line B' },
      { code: 'LINE-C', name: 'Production Line C' },
      { code: 'LINE-D', name: 'Production Line D' },
    ];
    for (const line of lines) {
      await db.runAsync(
        'INSERT INTO production_lines (id, factory_id, code, name) VALUES (?, ?, ?, ?)',
        newId(),
        factoryId,
        line.code,
        line.name,
      );
    }

    // Insert baseline product categories
    const categories = ['Electronics', 'Automotive', 'Machined Parts', 'Packaging', 'Raw Materials'];
    for (const cat of categories) {
      await db.runAsync(
        'INSERT OR IGNORE INTO product_categories (id, name) VALUES (?, ?)',
        newId(),
        cat,
      );
    }

    await setMetaValue('first_launch_done', 'true', db);
  });
}
