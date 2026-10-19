import { newId } from '../../utils/id';
import type { SeedContext } from './seedContext';
import { daysAgo } from './seedContext';

export async function seedMaintenance(ctx: SeedContext): Promise<void> {
  const { db, now, machineIds } = ctx;
  const breakdownMachine = machineIds.find((_, i) => i === 10) ?? machineIds[0];
  const maintMachine = machineIds[5];

  const openId = newId();
  await db.runAsync(
    `INSERT INTO maintenance_orders (
      id, order_number, machine_id, type, issue, priority, assigned_team, status,
      root_cause, action_taken, parts_used, technician_notes, created_at, completed_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    openId,
    'MO-00001',
    breakdownMachine,
    'BREAKDOWN',
    'Hydraulic pump failure',
    'CRITICAL',
    'Team Alpha',
    'IN_PROGRESS',
    null,
    null,
    null,
    'Awaiting spare seal kit',
    now - 4 * 60 * 60 * 1000,
    null,
  );

  const completedId = newId();
  const completedAt = daysAgo(now, 8) + 6 * 60 * 60 * 1000;
  await db.runAsync(
    `INSERT INTO maintenance_orders (
      id, order_number, machine_id, type, issue, priority, assigned_team, status,
      root_cause, action_taken, parts_used, technician_notes, created_at, completed_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    completedId,
    'MO-00002',
    maintMachine,
    'PREVENTIVE',
    'Quarterly PM',
    'MEDIUM',
    'Team Beta',
    'COMPLETED',
    'Wear on drive belt',
    'Replaced V-belt and recalibrated',
    'SP-V-BELT-A68 x1',
    'Machine returned to service',
    daysAgo(now, 9),
    completedAt,
  );

  await db.runAsync(
    `INSERT INTO maintenance_history (id, machine_id, maintenance_order_id, performed_at, summary)
     VALUES (?, ?, ?, ?, ?)`,
    newId(),
    maintMachine,
    completedId,
    completedAt,
    'Preventive maintenance completed',
  );

  await db.runAsync(
    `INSERT INTO activity_history (id, event_type, title, description, reference_type, reference_id, timestamp)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    newId(),
    'MAINTENANCE_COMPLETED',
    'Maintenance completed',
    'MO-00002 closed',
    'maintenance_order',
    completedId,
    completedAt,
  );
}
