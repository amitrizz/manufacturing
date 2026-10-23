import * as FileSystem from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';
import type { ReportType } from '../api/repositories/reportsRepository';
import { getReportData } from '../api/repositories/reportsRepository';

function rowsToCsv(rows: Record<string, unknown>[]): string {
  if (rows.length === 0) return '';
  const headers = Object.keys(rows[0]);
  const lines = [headers.join(',')];
  for (const row of rows) {
    lines.push(
      headers
        .map((h) => {
          const v = row[h];
          const s = v === null || v === undefined ? '' : String(v);
          return s.includes(',') ? `"${s.replace(/"/g, '""')}"` : s;
        })
        .join(','),
    );
  }
  return lines.join('\n');
}

export async function exportReport(
  type: ReportType,
  start: number,
  end: number,
  format: 'csv' | 'json',
): Promise<void> {
  const data = await getReportData(type, start, end);
  const content =
    format === 'json' ? JSON.stringify(data, null, 2) : rowsToCsv(data as Record<string, unknown>[]);
  const fileName = `${type}-report-${Date.now()}.${format}`;
  const path = `${FileSystem.documentDirectory}${fileName}`;
  await FileSystem.writeAsStringAsync(path, content, {
    encoding: FileSystem.EncodingType.UTF8,
  });
  if (await Sharing.isAvailableAsync()) {
    await Sharing.shareAsync(path);
  }
}
