import type { MaintenanceOrderRow, Priority } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { mongoApi } from '../../api/client';

export async function listMaintenanceOrders(
  status?: string,
): Promise<MaintenanceOrderRow[]> {
  try {
    const [orders, machines] = await Promise.all([
      mongoApi.getCollection<any>('maintenance_orders'),
      mongoApi.listMachines(),
    ]);

    const mchMap = new Map(machines.map((m) => [m.id || m._id, m.code]));

    let result = orders.map((mo) => ({
      ...mo,
      id: mo.id || mo._id,
      machine_code: mchMap.get(mo.machine_id) || '',
    }));

    if (status) {
      result = result.filter((mo) => mo.status === status);
    }

    return result.sort((a, b) => (b.created_at || 0) - (a.created_at || 0));
  } catch (err) {
    console.warn('MongoDB listMaintenanceOrders error:', err);
    return [];
  }
}

export async function getMaintenanceOrderById(
  id: string,
): Promise<MaintenanceOrderRow | null> {
  const all = await listMaintenanceOrders();
  return all.find((mo) => mo.id === id || (mo as any)._id === id) || null;
}

export type CompleteMaintenanceInput = {
  root_cause: string;
  action_taken: string;
  parts_used?: string;
  technician_notes?: string;
};

export async function completeMaintenanceOrder(
  orderId: string,
  input: CompleteMaintenanceInput,
): Promise<void> {
  const now = Date.now();
  const order = await getMaintenanceOrderById(orderId);

  await mongoApi.update('maintenance_orders', orderId, {
    status: 'COMPLETED',
    completed_at: now,
    root_cause: input.root_cause,
    action_taken: input.action_taken,
    parts_used: input.parts_used ?? null,
    technician_notes: input.technician_notes ?? null,
    updated_at: now,
  });

  if (order?.machine_id) {
    await mongoApi.updateMachineStatus(order.machine_id, 'RUNNING', 'Maintenance completed').catch(() => {});
  }

  await mongoApi.insert('maintenance_history', {
    _id: newId(),
    id: newId(),
    machine_id: order?.machine_id || '',
    maintenance_order_id: orderId,
    performed_at: now,
    summary: input.action_taken,
    created_at: now,
  });

  await mongoApi
    .insert('activity_history', {
      event_type: 'MAINTENANCE_COMPLETED',
      title: 'Maintenance completed',
      description: input.action_taken,
      reference_type: 'maintenance_order',
      reference_id: orderId,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
}

export type CreateMaintenanceOrderInput = {
  machine_id: string;
  type: 'PREVENTIVE' | 'CORRECTIVE' | 'BREAKDOWN';
  issue: string;
  priority: Priority;
  assigned_team?: string;
};

export async function createMaintenanceOrder(input: CreateMaintenanceOrderInput): Promise<string> {
  const id = newId();
  const now = Date.now();
  const existing = await mongoApi.getCollection<any>('maintenance_orders').catch(() => []);
  const seq = (existing.length + 1).toString().padStart(4, '0');
  const orderNumber = `MNT-${seq}`;

  await mongoApi.insert('maintenance_orders', {
    _id: id,
    id,
    order_number: orderNumber,
    machine_id: input.machine_id,
    type: input.type,
    issue: input.issue.trim(),
    priority: input.priority,
    assigned_team: input.assigned_team?.trim() || null,
    status: 'OPEN',
    created_at: now,
    updated_at: now,
  });

  if (input.type === 'BREAKDOWN') {
    await mongoApi.updateMachineStatus(input.machine_id, 'BREAKDOWN', input.issue.trim()).catch(() => {});
  }

  await mongoApi
    .insert('activity_history', {
      event_type: 'MAINTENANCE_CREATED',
      title: `Maintenance order ${orderNumber} created`,
      description: input.issue.trim(),
      reference_type: 'maintenance_order',
      reference_id: id,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
  return id;
}

export async function deleteMaintenanceOrder(id: string): Promise<void> {
  await mongoApi.delete('maintenance_orders', id);

  await mongoApi
    .insert('activity_history', {
      event_type: 'MAINTENANCE_DELETED',
      title: `Maintenance order deleted`,
      description: id,
      reference_type: 'maintenance_order',
      reference_id: id,
      timestamp: Date.now(),
      created_at: Date.now(),
    })
    .catch(() => {});

  notifyDataChanged();
}
