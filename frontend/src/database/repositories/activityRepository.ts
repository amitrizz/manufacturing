import type { SQLiteDatabase } from 'expo-sqlite';
import type { ActivityRow } from '../../types/database';
import { newId } from '../../utils/id';
import { getDatabase } from '../client';

export async function insertActivity(
  input: {
    event_type: string;
    title: string;
    description?: string | null;
    reference_type?: string | null;
    reference_id?: string | null;
    timestamp?: number;
  },
  db?: SQLiteDatabase,
): Promise<void> {
  const connection = db ?? await getDatabase();
  await connection.runAsync(
    `INSERT INTO activity_history (id, event_type, title, description, reference_type, reference_id, timestamp)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    newId(),
    input.event_type,
    input.title,
    input.description ?? null,
    input.reference_type ?? null,
    input.reference_id ?? null,
    input.timestamp ?? Date.now(),
  );
}

export async function listRecentActivity(
  limit = 10,
  start?: number,
  end?: number,
): Promise<ActivityRow[]> {
  const db = await getDatabase();
  if (start !== undefined && end !== undefined) {
    return db.getAllAsync<ActivityRow>(
      `SELECT * FROM activity_history WHERE timestamp >= ? AND timestamp <= ?
       ORDER BY timestamp DESC LIMIT ?`,
      start,
      end,
      limit,
    );
  }
  return db.getAllAsync<ActivityRow>(
    'SELECT * FROM activity_history ORDER BY timestamp DESC LIMIT ?',
    limit,
  );
}

export async function listActivityFiltered(
  eventType: string | null,
  start: number,
  end: number,
): Promise<ActivityRow[]> {
  const db = await getDatabase();
  if (eventType) {
    return db.getAllAsync<ActivityRow>(
      `SELECT * FROM activity_history WHERE event_type = ? AND timestamp >= ? AND timestamp <= ?
       ORDER BY timestamp DESC`,
      eventType,
      start,
      end,
    );
  }
  return db.getAllAsync<ActivityRow>(
    `SELECT * FROM activity_history WHERE timestamp >= ? AND timestamp <= ? ORDER BY timestamp DESC`,
    start,
    end,
  );
}
