import type { MaintenanceOrderRow, Priority } from '../../types/database';
import { newId } from '../../utils/id';
import { getDatabase } from '../client';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { insertActivity } from './activityRepository';

export async function listMaintenanceOrders(
  status?: string,
): Promise<MaintenanceOrderRow[]> {
  const db = await getDatabase();
  if (status) {
    return db.getAllAsync<MaintenanceOrderRow>(
      `SELECT mo.*, m.code as machine_code FROM maintenance_orders mo
       JOIN machines m ON m.id = mo.machine_id
       WHERE mo.status = ? ORDER BY mo.created_at DESC`,
      status,
    );
  }
  return db.getAllAsync<MaintenanceOrderRow>(
    `SELECT mo.*, m.code as machine_code FROM maintenance_orders mo
     JOIN machines m ON m.id = mo.machine_id ORDER BY mo.created_at DESC`,
  );
}

export async function getMaintenanceOrderById(
  id: string,
): Promise<MaintenanceOrderRow | null> {
  const db = await getDatabase();
  return db.getFirstAsync<MaintenanceOrderRow>(
    `SELECT mo.*, m.code as machine_code FROM maintenance_orders mo
     JOIN machines m ON m.id = mo.machine_id WHERE mo.id = ?`,
    id,
  );
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
  const db = await getDatabase();
  const now = Date.now();

  await db.withTransactionAsync(async () => {
    const order = await db.getFirstAsync<{ machine_id: string }>(
      'SELECT machine_id FROM maintenance_orders WHERE id = ?',
      orderId,
    );
    if (!order) throw new Error('Maintenance order not found');

    await db.runAsync(
      `UPDATE maintenance_orders SET status = 'COMPLETED', completed_at = ?,
        root_cause = ?, action_taken = ?, parts_used = ?, technician_notes = ?
       WHERE id = ?`,
      now,
      input.root_cause,
      input.action_taken,
      input.parts_used ?? null,
      input.technician_notes ?? null,
      orderId,
    );

    await db.runAsync(
      `UPDATE machines SET status = 'RUNNING', updated_at = ? WHERE id = ?`,
      now,
      order.machine_id,
    );

    await db.runAsync(
      `UPDATE machine_downtime SET end_time = ? WHERE machine_id = ? AND end_time IS NULL`,
      now,
      order.machine_id,
    );

    await db.runAsync(
      `INSERT INTO maintenance_history (id, machine_id, maintenance_order_id, performed_at, summary)
       VALUES (?, ?, ?, ?, ?)`,
      newId(),
      order.machine_id,
      orderId,
      now,
      input.action_taken,
    );

    await insertActivity(
      {
        event_type: 'MAINTENANCE_COMPLETED',
        title: 'Maintenance completed',
        description: input.action_taken,
        reference_type: 'maintenance_order',
        reference_id: orderId,
        timestamp: now,
      },
      db,
    );
  });
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
  const db = await getDatabase();
  const id = newId();
  const now = Date.now();

  const countRow = await db.getFirstAsync<{ count: number }>(
    'SELECT count(*) as count FROM maintenance_orders',
  );
  const seq = ((countRow?.count ?? 0) + 1).toString().padStart(4, '0');
  const orderNumber = `MNT-${seq}`;

  await db.withTransactionAsync(async () => {
    await db.runAsync(
      `INSERT INTO maintenance_orders (
        id, order_number, machine_id, type, issue, priority, assigned_team,
        status, root_cause, action_taken, parts_used, technician_notes,
        created_at, completed_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 'OPEN', NULL, NULL, NULL, NULL, ?, NULL)`,
      id,
      orderNumber,
      input.machine_id,
      input.type,
      input.issue.trim(),
      input.priority,
      input.assigned_team?.trim() || null,
      now,
    );

    if (input.type === 'BREAKDOWN') {
      await db.runAsync(
        "UPDATE machines SET status = 'BREAKDOWN', updated_at = ? WHERE id = ?",
        now,
        input.machine_id,
      );
      await db.runAsync(
        `INSERT INTO machine_downtime (
          id, machine_id, reason, start_time, end_time, duration_minutes, recorded_by, created_at
        ) VALUES (?, ?, ?, ?, NULL, 0, 'Maintenance', ?)`,
        newId(),
        input.machine_id,
        input.issue.trim(),
        now,
        now,
      );
    }

    await insertActivity(
      {
        event_type: 'MAINTENANCE_CREATED',
        title: `Maintenance order ${orderNumber} created`,
        description: input.issue.trim(),
        reference_type: 'maintenance_order',
        reference_id: id,
        timestamp: now,
      },
      db,
    );
  });

  notifyDataChanged();
  return id;
}

export async function deleteMaintenanceOrder(id: string): Promise<void> {
  const db = await getDatabase();
  const existing = await getMaintenanceOrderById(id);
  if (!existing) throw new Error('Maintenance order not found');

  await db.withTransactionAsync(async () => {
    await db.runAsync('DELETE FROM maintenance_history WHERE maintenance_order_id = ?', id);
    await db.runAsync('DELETE FROM maintenance_orders WHERE id = ?', id);
    await insertActivity(
      {
        event_type: 'MAINTENANCE_DELETED',
        title: `Maintenance order ${existing.order_number} deleted`,
        description: `Order removed`,
        reference_type: 'maintenance_order',
        reference_id: id,
        timestamp: Date.now(),
      },
      db,
    );
  });

  notifyDataChanged();
}
