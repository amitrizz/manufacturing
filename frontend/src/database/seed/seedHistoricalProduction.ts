import { newId } from '../../utils/id';
import type { SeedContext } from './seedContext';
import { daysAgo, startOfDay } from './seedContext';

export type SeededOrder = {
  id: string;
  productId: string;
  lineId: string;
  machineId: string;
  status: string;
  goodTotal: number;
  rejectTotal: number;
};

export async function seedHistoricalProduction(
  ctx: SeedContext,
): Promise<SeededOrder[]> {
  const { db, now, historyDays, productIds, machineIds, lineIds } = ctx;
  const lines = [lineIds.A, lineIds.B, lineIds.C, lineIds.D];
  const priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'] as const;
  const shifts = ['A', 'B', 'C'];
  const operators = ['Arun Kumar', 'Ramesh Verma', 'Manoj Tiwari', 'Deepak Patil', 'Sneha Nair'];
  const orders: SeededOrder[] = [];
  let planCounter = 1;
  let orderCounter = 1;

  for (let dayOffset = historyDays; dayOffset >= 0; dayOffset--) {
    const dayStart = daysAgo(now, dayOffset);
    const ordersToday = dayOffset % 3 === 0 ? 2 : 1;

    for (let o = 0; o < ordersToday; o++) {
      const productId = productIds[(dayOffset + o) % productIds.length];
      const lineId = lines[(dayOffset + o) % lines.length];
      const machineId = machineIds[(dayOffset + o) % machineIds.length];
      const target = 80 + (dayOffset % 7) * 15 + o * 10;
      const planId = newId();
      const planNumber = `PLN-${String(planCounter++).padStart(5, '0')}`;
      const isPast = dayOffset > 3;
      const isToday = dayOffset === 0;
      const planStatus = isPast ? 'COMPLETED' : isToday ? 'IN_PROGRESS' : 'PLANNED';

      await db.runAsync(
        `INSERT INTO production_plans (
          id, plan_number, product_id, target_quantity, line_id, start_date, expected_completion,
          priority, status, notes, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        planId,
        planNumber,
        productId,
        target,
        lineId,
        dayStart,
        dayStart + 2 * 24 * 60 * 60 * 1000,
        priorities[dayOffset % priorities.length],
        planStatus,
        null,
        dayStart,
        now,
      );

      const orderId = newId();
      const orderNumber = `PO-${String(orderCounter++).padStart(5, '0')}`;
      let status: SeededOrder['status'] = 'COMPLETED';
      if (isToday && o === 0) {
        status = 'IN_PROGRESS';
      } else if (!isPast && !isToday) {
        status = 'PENDING';
      }

      const dueDate = dayStart + 3 * 24 * 60 * 60 * 1000;
      let startedAt: number | null = isPast || isToday ? dayStart + 2 * 60 * 60 * 1000 : null;
      let completedAt: number | null = status === 'COMPLETED' ? dayStart + 10 * 60 * 60 * 1000 : null;

      if (isToday && o === 1) {
        status = 'IN_PROGRESS';
        ctx.delayedOrderId = orderId;
        startedAt = daysAgo(now, 5);
        completedAt = null;
      }

      const producedRatio = status === 'COMPLETED' ? 1 : isToday ? 0.55 + o * 0.1 : 0;
      const goodTotal = Math.round(target * producedRatio);
      const rejectTotal = Math.max(1, Math.round(goodTotal * 0.02));

      await db.runAsync(
        `INSERT INTO production_orders (
          id, order_number, plan_id, product_id, line_id, machine_id, target_quantity,
          produced_quantity, rejected_quantity, priority, status, start_date, due_date,
          started_at, completed_at, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        orderId,
        orderNumber,
        planId,
        productId,
        lineId,
        machineId,
        target,
        goodTotal,
        rejectTotal,
        priorities[(dayOffset + 1) % priorities.length],
        status,
        dayStart,
        isToday && o === 1 ? daysAgo(now, 1) : dueDate,
        startedAt,
        completedAt,
        dayStart,
        now,
      );

      if (goodTotal > 0) {
        const entryChunks = status === 'COMPLETED' ? 3 : 2;
        let remainingGood = goodTotal;
        let remainingReject = rejectTotal;
        for (let c = 0; c < entryChunks; c++) {
          const chunkGood =
            c === entryChunks - 1
              ? remainingGood
              : Math.floor(goodTotal / entryChunks);
          const chunkReject =
            c === entryChunks - 1
              ? remainingReject
              : Math.floor(rejectTotal / entryChunks);
          remainingGood -= chunkGood;
          remainingReject -= chunkReject;
          const ts = dayStart + (8 + c * 4) * 60 * 60 * 1000;
          await db.runAsync(
            `INSERT INTO production_entries (
              id, production_order_id, machine_id, shift, good_quantity, rejected_quantity,
              operator, notes, entry_timestamp
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            newId(),
            orderId,
            machineId,
            shifts[c % shifts.length],
            chunkGood,
            chunkReject,
            operators[(c + dayOffset) % operators.length],
            null,
            ts,
          );

          await db.runAsync(
            `INSERT INTO activity_history (id, event_type, title, description, reference_type, reference_id, timestamp)
             VALUES (?, ?, ?, ?, ?, ?, ?)`,
            newId(),
            'PRODUCTION_RECORDED',
            'Production recorded',
            `${chunkGood} good / ${chunkReject} rejected on ${orderNumber}`,
            'production_order',
            orderId,
            ts,
          );
        }
      }

      if (startedAt) {
        await db.runAsync(
          `INSERT INTO activity_history (id, event_type, title, description, reference_type, reference_id, timestamp)
           VALUES (?, ?, ?, ?, ?, ?, ?)`,
          newId(),
          'PRODUCTION_STARTED',
          'Production started',
          `Order ${orderNumber} started on line`,
          'production_order',
          orderId,
          startedAt,
        );
      }

      orders.push({
        id: orderId,
        productId,
        lineId,
        machineId,
        status,
        goodTotal,
        rejectTotal,
      });
    }
  }

  for (let d = 5; d < historyDays; d += 6) {
    const machineId = machineIds[d % machineIds.length];
    const start = startOfDay(daysAgo(now, d)) + 14 * 60 * 60 * 1000;
    const end = start + 90 * 60 * 1000;
    await db.runAsync(
      `INSERT INTO machine_downtime (id, machine_id, start_time, end_time, reason, description, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      newId(),
      machineId,
      start,
      end,
      'PLANNED_MAINTENANCE',
      'Scheduled lubrication and calibration',
      start,
    );
  }

  return orders;
}
