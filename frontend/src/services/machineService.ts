import { newId } from '../utils/id';
import { getDatabase } from '../database/client';
import { insertActivity } from '../database/repositories/activityRepository';
import { notifyDataChanged } from '../store/dataRefreshStore';
import type { MachineStatus } from '../types/database';

const ALL_STATUSES: MachineStatus[] = [
  'RUNNING',
  'IDLE',
  'BREAKDOWN',
  'MAINTENANCE',
  'OFFLINE',
];

export function machineStatusOptions(): MachineStatus[] {
  return ALL_STATUSES;
}

export async function setMachineStatus(
  machineId: string,
  status: MachineStatus,
  notes?: string,
): Promise<void> {
  if (!ALL_STATUSES.includes(status)) {
    throw new Error('Invalid status');
  }

  const db = await getDatabase();
  const now = Date.now();

  await db.withTransactionAsync(async () => {
    const machine = await db.getFirstAsync<{
      code: string;
      status: MachineStatus;
    }>('SELECT code, status FROM machines WHERE id = ?', machineId);

    if (!machine) throw new Error('Machine not found');
    if (machine.status === status) return;

    const prev = machine.status;

    if (prev === 'BREAKDOWN' && status !== 'BREAKDOWN') {
      const open = await db.getFirstAsync<{ id: string; start_time: number }>(
        `SELECT id, start_time FROM machine_downtime
         WHERE machine_id = ? AND end_time IS NULL ORDER BY start_time DESC LIMIT 1`,
        machineId,
      );
      if (open) {
        const durationSec = Math.max(0, Math.floor((now - open.start_time) / 1000));
        await db.runAsync(
          'UPDATE machine_downtime SET end_time = ? WHERE id = ?',
          now,
          open.id,
        );
        await db.runAsync(
          'UPDATE machines SET downtime_seconds = downtime_seconds + ? WHERE id = ?',
          durationSec,
          machineId,
        );
      }
    }

    if (status === 'BREAKDOWN' && prev !== 'BREAKDOWN') {
      await db.runAsync(
        `INSERT INTO machine_downtime (id, machine_id, start_time, end_time, reason, description, created_at)
         VALUES (?, ?, ?, NULL, 'OTHER', ?, ?)`,
        newId(),
        machineId,
        now,
        notes?.trim() || 'Status changed to breakdown',
        now,
      );
    }

    const clearProduct = status === 'IDLE' || status === 'OFFLINE' || status === 'MAINTENANCE';
    if (clearProduct) {
      await db.runAsync(
        'UPDATE machines SET status = ?, current_product_id = NULL, updated_at = ? WHERE id = ?',
        status,
        now,
        machineId,
      );
    } else {
      await db.runAsync(
        'UPDATE machines SET status = ?, updated_at = ? WHERE id = ?',
        status,
        now,
        machineId,
      );
    }

    await insertActivity(
      {
        event_type: 'MACHINE_STATUS_CHANGED',
        title: `${machine.code} → ${status}`,
        description: notes?.trim() || `Changed from ${prev}`,
        reference_type: 'machine',
        reference_id: machineId,
        timestamp: now,
      },
      db,
    );
  });

  notifyDataChanged();
}
