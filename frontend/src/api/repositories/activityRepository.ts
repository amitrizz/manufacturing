import { mongoApi } from '../client';
import type { ActivityRow } from '../../types/database';
import { newId } from '../../utils/id';

export async function insertActivity(input: {
  event_type: string;
  title: string;
  description?: string | null;
  reference_type?: string | null;
  reference_id?: string | null;
  timestamp?: number;
}): Promise<void> {
  const now = input.timestamp ?? Date.now();
  const id = newId();

  await mongoApi.insert('activity_history', {
    _id: id,
    id,
    event_type: input.event_type,
    title: input.title,
    description: input.description ?? null,
    reference_type: input.reference_type ?? null,
    reference_id: input.reference_id ?? null,
    timestamp: now,
    created_at: now,
  }).catch(() => {});
}

export async function listRecentActivity(
  limit = 10,
  start?: number,
  end?: number,
): Promise<ActivityRow[]> {
  try {
    const list = await mongoApi.getCollection<ActivityRow>('activity_history');
    if (!list || !Array.isArray(list)) return [];

    let filtered = list;
    if (start !== undefined && end !== undefined) {
      filtered = filtered.filter((a) => {
        const ts = a.timestamp || (a as any).created_at || 0;
        return ts >= start && ts <= end;
      });
    }

    return filtered
      .sort((a, b) => (b.timestamp || (b as any).created_at || 0) - (a.timestamp || (a as any).created_at || 0))
      .slice(0, limit);
  } catch (err) {
    console.warn('MongoDB listRecentActivity error:', err);
    return [];
  }
}

export async function listActivityFiltered(
  eventType: string | null,
  start: number,
  end: number,
): Promise<ActivityRow[]> {
  try {
    const list = await mongoApi.getCollection<ActivityRow>('activity_history');
    if (!list || !Array.isArray(list)) return [];

    let filtered = list.filter((a) => {
      const ts = a.timestamp || (a as any).created_at || 0;
      return ts >= start && ts <= end;
    });

    if (eventType) {
      filtered = filtered.filter((a) => a.event_type === eventType);
    }

    return filtered.sort(
      (a, b) => (b.timestamp || (b as any).created_at || 0) - (a.timestamp || (a as any).created_at || 0)
    );
  } catch (err) {
    console.warn('MongoDB listActivityFiltered error:', err);
    return [];
  }
}
