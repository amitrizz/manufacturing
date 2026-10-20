import { newId } from '../utils/id';
import { mongoApi } from '../api/client';
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

  const now = Date.now();

  try {
    // Call server dedicated machine status endpoint
    await mongoApi.updateMachineStatus(machineId, status, notes);
  } catch {
    // Direct MongoDB fallback update
    const machines = await mongoApi.getCollection<any>('machines');
    const machine = machines.find((m) => m.id === machineId || m._id === machineId);
    if (!machine) throw new Error('Machine not found');
    if (machine.status === status) return;

    const clearProduct = status === 'IDLE' || status === 'OFFLINE' || status === 'MAINTENANCE';

    await mongoApi.update('machines', machineId, {
      status,
      current_product_id: clearProduct ? null : machine.current_product_id,
      updated_at: now,
    });

    if (status === 'BREAKDOWN') {
      const dtId = newId();
      await mongoApi
        .insert('machine_downtime', {
          _id: dtId,
          id: dtId,
          machine_id: machineId,
          start_time: now,
          end_time: null,
          reason: 'OTHER',
          description: notes?.trim() || 'Status changed to breakdown',
          created_at: now,
        })
        .catch(() => {});
    }

    await mongoApi
      .insert('activity_history', {
        event_type: 'MACHINE_STATUS_CHANGED',
        title: `${machine.code} → ${status}`,
        description: notes?.trim() || `Changed from ${machine.status}`,
        reference_type: 'machine',
        reference_id: machineId,
        timestamp: now,
        created_at: now,
      })
      .catch(() => {});
  }

  notifyDataChanged();
}
