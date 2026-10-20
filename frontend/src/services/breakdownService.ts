import { newId } from '../utils/id';
import { mongoApi } from '../api/client';
import { notifyDataChanged } from '../store/dataRefreshStore';

export async function reportBreakdown(
  machineId: string,
  reason: string,
  description: string,
): Promise<void> {
  const now = Date.now();

  const machines = await mongoApi.getCollection<any>('machines');
  const machine = machines.find((m) => m.id === machineId || m._id === machineId);
  if (!machine) throw new Error('Machine not found');

  await mongoApi.update('machines', machineId, {
    status: 'BREAKDOWN',
    updated_at: now,
  });

  const downtimeId = newId();
  await mongoApi
    .insert('machine_downtime', {
      _id: downtimeId,
      id: downtimeId,
      machine_id: machineId,
      start_time: now,
      end_time: null,
      reason,
      description,
      created_at: now,
    })
    .catch(() => {});

  await mongoApi
    .insert('activity_history', {
      event_type: 'BREAKDOWN_REPORTED',
      title: 'Breakdown reported',
      description: `${machine.code}: ${description}`,
      reference_type: 'machine',
      reference_id: machineId,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  const notifId = newId();
  await mongoApi
    .insert('notifications', {
      _id: notifId,
      id: notifId,
      title: 'Machine breakdown',
      body: `${machine.code} — ${description}`,
      severity: 'CRITICAL',
      reference_type: 'machine',
      reference_id: machineId,
      is_read: false,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
}
