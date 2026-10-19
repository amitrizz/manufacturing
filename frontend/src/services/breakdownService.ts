import { newId } from '../utils/id';
import { getDatabase } from '../database/client';
import { insertActivity } from '../database/repositories/activityRepository';
import { insertNotification } from '../database/repositories/notificationRepository';
import { notifyDataChanged } from '../store/dataRefreshStore';

export async function reportBreakdown(
  machineId: string,
  reason: string,
  description: string,
): Promise<void> {
  const db = await getDatabase();
  const now = Date.now();

  await db.withTransactionAsync(async () => {
    const machine = await db.getFirstAsync<{ code: string }>(
      'SELECT code FROM machines WHERE id = ?',
      machineId,
    );
    if (!machine) throw new Error('Machine not found');

    await db.runAsync(
      `UPDATE machines SET status = 'BREAKDOWN', updated_at = ? WHERE id = ?`,
      now,
      machineId,
    );

    const downtimeId = newId();
    await db.runAsync(
      `INSERT INTO machine_downtime (id, machine_id, start_time, end_time, reason, description, created_at)
       VALUES (?, ?, ?, NULL, ?, ?, ?)`,
      downtimeId,
      machineId,
      now,
      reason,
      description,
      now,
    );

    await insertActivity(
      {
        event_type: 'BREAKDOWN_REPORTED',
        title: 'Breakdown reported',
        description: `${machine.code}: ${description}`,
        reference_type: 'machine',
        reference_id: machineId,
        timestamp: now,
      },
      db,
    );

    await insertNotification(
      {
        title: 'Machine breakdown',
        body: `${machine.code} — ${description}`,
        severity: 'CRITICAL',
        reference_type: 'machine',
        reference_id: machineId,
      },
      db,
    );
  });
  notifyDataChanged();
}
