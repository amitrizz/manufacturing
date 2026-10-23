import type { NotificationRow } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { mongoApi } from '../client';

export async function listNotifications(unreadOnly = false): Promise<NotificationRow[]> {
  try {
    const list = await mongoApi.getCollection<NotificationRow>('notifications');
    if (!list || !Array.isArray(list)) return [];

    let filtered = list.map((n) => ({
      ...n,
      id: n.id || (n as any)._id,
      is_read: n.is_read ? 1 : 0,
    }));

    if (unreadOnly) {
      filtered = filtered.filter((n) => !n.is_read);
    }

    return filtered.sort((a, b) => (b.created_at || 0) - (a.created_at || 0));
  } catch (err) {
    console.warn('listNotifications error:', err);
    return [];
  }
}

export async function countUnreadNotifications(): Promise<number> {
  const all = await listNotifications(true);
  return all.length;
}

export async function markNotificationRead(id: string): Promise<void> {
  await mongoApi.update('notifications', id, { is_read: 1, updated_at: Date.now() });
  notifyDataChanged();
}

export async function markAllNotificationsRead(): Promise<void> {
  const unread = await listNotifications(true);
  for (const n of unread) {
    if (n.id) {
      await mongoApi.update('notifications', n.id, { is_read: 1, updated_at: Date.now() }).catch(() => {});
    }
  }
  notifyDataChanged();
}

export async function insertNotification(input: {
  title: string;
  body: string;
  severity: NotificationRow['severity'];
  reference_type?: string;
  reference_id?: string;
}): Promise<void> {
  const id = newId();
  const now = Date.now();
  await mongoApi.insert('notifications', {
    _id: id,
    id,
    title: input.title,
    body: input.body,
    severity: input.severity,
    is_read: 0,
    reference_type: input.reference_type ?? null,
    reference_id: input.reference_id ?? null,
    created_at: now,
    updated_at: now,
  });
  notifyDataChanged();
}
