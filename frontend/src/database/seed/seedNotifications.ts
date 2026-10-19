import { newId } from '../../utils/id';
import type { SeedContext } from './seedContext';

export async function seedNotifications(ctx: SeedContext): Promise<void> {
  const { db, now } = ctx;

  for (const materialId of ctx.lowStockMaterialIds.slice(0, 3)) {
    const row = await db.getFirstAsync<{ name: string; code: string }>(
      'SELECT name, code FROM materials WHERE id = ?',
      materialId,
    );
    if (!row) continue;
    await db.runAsync(
      `INSERT INTO notifications (id, title, body, severity, is_read, reference_type, reference_id, created_at)
       VALUES (?, ?, ?, ?, 0, ?, ?, ?)`,
      newId(),
      'Low stock alert',
      `${row.code} (${row.name}) is below minimum stock`,
      'WARNING',
      'material',
      materialId,
      now - 60 * 60 * 1000,
    );
  }

  if (ctx.delayedOrderId) {
    await db.runAsync(
      `INSERT INTO notifications (id, title, body, severity, is_read, reference_type, reference_id, created_at)
       VALUES (?, ?, ?, ?, 0, ?, ?, ?)`,
      newId(),
      'Delayed production order',
      'A production order is past due and still in progress',
      'CRITICAL',
      'production_order',
      ctx.delayedOrderId,
      now - 30 * 60 * 1000,
    );
  }

  if (ctx.maintenanceDueMachineId) {
    await db.runAsync(
      `INSERT INTO notifications (id, title, body, severity, is_read, reference_type, reference_id, created_at)
       VALUES (?, ?, ?, ?, 0, ?, ?, ?)`,
      newId(),
      'Maintenance due soon',
      'Preventive maintenance scheduled within 48 hours',
      'INFO',
      'machine',
      ctx.maintenanceDueMachineId,
      now - 15 * 60 * 1000,
    );
  }

  if (ctx.failedInspectionId) {
    await db.runAsync(
      `INSERT INTO notifications (id, title, body, severity, is_read, reference_type, reference_id, created_at)
       VALUES (?, ?, ?, ?, 0, ?, ?, ?)`,
      newId(),
      'Failed quality inspection',
      'Inspection failed — rework may be required',
      'CRITICAL',
      'quality_inspection',
      ctx.failedInspectionId,
      now - 45 * 60 * 1000,
    );
  }

  await db.runAsync(
    `INSERT INTO activity_history (id, event_type, title, description, reference_type, reference_id, timestamp)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    newId(),
    'BREAKDOWN_REPORTED',
    'Machine breakdown reported',
    'PAINT-D1 reported hydraulic failure',
    'machine',
    ctx.machineIds[10] ?? ctx.machineIds[0],
    now - 3 * 60 * 60 * 1000,
  );
}
