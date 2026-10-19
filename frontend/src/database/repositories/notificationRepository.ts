import type { SQLiteDatabase } from 'expo-sqlite';
import type { NotificationRow } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { getDatabase } from '../client';

export async function listNotifications(unreadOnly = false): Promise<NotificationRow[]> {
  const db = await getDatabase();
  if (unreadOnly) {
    return db.getAllAsync<NotificationRow>(
      'SELECT * FROM notifications WHERE is_read = 0 ORDER BY created_at DESC',
    );
  }
  return db.getAllAsync<NotificationRow>(
    'SELECT * FROM notifications ORDER BY created_at DESC',
  );
}

export async function countUnreadNotifications(): Promise<number> {
  const db = await getDatabase();
  const row = await db.getFirstAsync<{ count: number }>(
    'SELECT count(*) as count FROM notifications WHERE is_read = 0',
  );
  return row?.count ?? 0;
}

export async function markNotificationRead(id: string): Promise<void> {
  const db = await getDatabase();
  await db.runAsync('UPDATE notifications SET is_read = 1 WHERE id = ?', id);
  notifyDataChanged();
}

export async function markAllNotificationsRead(): Promise<void> {
  const db = await getDatabase();
  await db.runAsync('UPDATE notifications SET is_read = 1');
  notifyDataChanged();
}

export async function insertNotification(
  input: {
    title: string;
    body: string;
    severity: NotificationRow['severity'];
    reference_type?: string;
    reference_id?: string;
  },
  db?: SQLiteDatabase,
): Promise<void> {
  const connection = db ?? await getDatabase();
  await connection.runAsync(
    `INSERT INTO notifications (id, title, body, severity, is_read, reference_type, reference_id, created_at)
     VALUES (?, ?, ?, ?, 0, ?, ?, ?)`,
    newId(),
    input.title,
    input.body,
    input.severity,
    input.reference_type ?? null,
    input.reference_id ?? null,
    Date.now(),
  );
}
