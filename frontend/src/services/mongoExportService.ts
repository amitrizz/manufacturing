import * as FileSystem from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';
import { getDatabase } from '../database/client';

export async function exportLocalDatabaseToJson(): Promise<{
  path: string;
  tableCounts: Record<string, number>;
}> {
  const db = await getDatabase();

  const tables = [
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

  const fullDump: Record<string, unknown[]> = {};
  const tableCounts: Record<string, number> = {};

  for (const table of tables) {
    try {
      const rows = await db.getAllAsync(`SELECT * FROM ${table}`);
      fullDump[table] = rows;
      tableCounts[table] = rows.length;
    } catch {
      // Table may not exist yet or be empty
      fullDump[table] = [];
      tableCounts[table] = 0;
    }
  }

  const jsonStr = JSON.stringify(fullDump, null, 2);
  const fileName = `manufacturing-local-db-${Date.now()}.json`;
  const filePath = `${FileSystem.documentDirectory}${fileName}`;

  await FileSystem.writeAsStringAsync(filePath, jsonStr, {
    encoding: FileSystem.EncodingType.UTF8,
  });

  if (await Sharing.isAvailableAsync()) {
    await Sharing.shareAsync(filePath, {
      mimeType: 'application/json',
      dialogTitle: 'Export Manufacturing Database for MongoDB Migration',
    });
  }

  return { path: filePath, tableCounts };
}
