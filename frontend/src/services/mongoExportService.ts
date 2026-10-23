import * as FileSystem from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';
import { mongoApi } from '../api/client';

export async function exportLocalDatabaseToJson(): Promise<{
  path: string;
  tableCounts: Record<string, number>;
}> {
  let fullDump: Record<string, any[]> = {};
  const tableCounts: Record<string, number> = {};

  try {
    const res = await mongoApi.getAllData();
    if (res && res.data) {
      fullDump = res.data;
      for (const [table, rows] of Object.entries(res.data)) {
        tableCounts[table] = Array.isArray(rows) ? rows.length : 0;
      }
    }
  } catch (err) {
    console.warn('exportLocalDatabaseToJson error:', err);
  }

  const exportPayload = {
    exportedAt: new Date().toISOString(),
    version: '2.0.0-mongodb-atlas',
    source: 'MongoDB Atlas',
    collections: fullDump,
    tableCounts,
  };

  const jsonString = JSON.stringify(exportPayload, null, 2);
  const fileName = `mfg_database_backup_${Date.now()}.json`;
  const filePath = `${FileSystem.documentDirectory}${fileName}`;

  await FileSystem.writeAsStringAsync(filePath, jsonString, {
    encoding: FileSystem.EncodingType.UTF8,
  });

  return {
    path: filePath,
    tableCounts,
  };
}

export async function shareDatabaseExport(filePath: string): Promise<void> {
  const isAvailable = await Sharing.isAvailableAsync();
  if (!isAvailable) {
    throw new Error('Sharing is not available on this device');
  }
  await Sharing.shareAsync(filePath, {
    mimeType: 'application/json',
    dialogTitle: 'Export Manufacturing Database JSON',
    UTI: 'public.json',
  });
}
