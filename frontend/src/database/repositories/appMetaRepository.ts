import type { SQLiteDatabase } from 'expo-sqlite';
import { getDatabase } from '../client';

export async function getMetaValue(
  key: string,
  db?: SQLiteDatabase,
): Promise<string | null> {
  const connection = db ?? await getDatabase();
  const row = await connection.getFirstAsync<{ value: string }>(
    'SELECT value FROM app_meta WHERE key = ?',
    key,
  );
  return row?.value ?? null;
}

export async function setMetaValue(
  key: string,
  value: string,
  db?: SQLiteDatabase,
): Promise<void> {
  const connection = db ?? await getDatabase();
  await connection.runAsync(
    'INSERT INTO app_meta (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value',
    key,
    value,
  );
}
