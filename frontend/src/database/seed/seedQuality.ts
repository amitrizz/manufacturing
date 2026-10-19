import { newId } from '../../utils/id';
import type { SeedContext } from './seedContext';
import type { SeededOrder } from './seedHistoricalProduction';

const RESULTS = ['PASS', 'FAIL', 'REWORK', 'PARTIAL_PASS'] as const;
const PARAMS = ['DIMENSION', 'WEIGHT', 'PRESSURE', 'LEAK_TEST', 'SURFACE_FINISH'] as const;

export async function seedQuality(
  ctx: SeedContext,
  orders: SeededOrder[],
): Promise<Map<string, { produced: number; passed: number; rejected: number; rework: number }>> {
  const { db, now } = ctx;
  const fgByProduct = new Map<
    string,
    { produced: number; passed: number; rejected: number; rework: number }
  >();

  const sampleOrders = orders.filter((o) => o.goodTotal > 0).slice(0, 28);

  for (let i = 0; i < sampleOrders.length; i++) {
    const order = sampleOrders[i];
    const overall = RESULTS[i % RESULTS.length];
    const inspectionId = newId();
    const batchNumber = `BATCH-${String(i + 1).padStart(4, '0')}`;
    const inspectedAt = now - (sampleOrders.length - i) * 6 * 60 * 60 * 1000;
    const rejectedQty =
      overall === 'PASS' ? 0 : Math.max(1, Math.round(order.goodTotal * 0.08));
    const passedQty =
      overall === 'FAIL' ? 0 : order.goodTotal - rejectedQty;

    await db.runAsync(
      `INSERT INTO quality_inspections (
        id, batch_number, production_order_id, product_id, quantity, inspector, overall_result,
        rejected_quantity, rejection_reason, rejection_action, inspected_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      inspectionId,
      batchNumber,
      order.id,
      order.productId,
      order.goodTotal,
      `Inspector ${(i % 4) + 1}`,
      overall,
      rejectedQty,
      overall === 'FAIL' || overall === 'REWORK' ? 'Out of tolerance on leak test' : null,
      overall === 'FAIL' ? 'REWORK' : overall === 'PARTIAL_PASS' ? 'HOLD' : null,
      inspectedAt,
    );

    for (const param of PARAMS) {
      const pass = overall === 'FAIL' && param === 'LEAK_TEST' ? 'FAIL' : 'PASS';
      await db.runAsync(
        `INSERT INTO quality_results (id, inspection_id, parameter, expected_value, actual_value, result, remarks)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        newId(),
        inspectionId,
        param,
        'per spec',
        pass === 'PASS' ? 'within spec' : 'out of spec',
        pass,
        null,
      );
    }

    if (overall === 'FAIL') {
      ctx.failedInspectionId = inspectionId;
      await db.runAsync(
        `INSERT INTO rework_orders (
          id, rework_number, product_id, quantity, reason, assigned_line_id, status,
          source_inspection_id, created_at, completed_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        newId(),
        `RW-${String(i + 1).padStart(4, '0')}`,
        order.productId,
        rejectedQty,
        'Leak test failure',
        order.lineId,
        i % 2 === 0 ? 'PENDING' : 'IN_PROGRESS',
        inspectionId,
        inspectedAt,
        null,
      );
    }

    const bucket = fgByProduct.get(order.productId) ?? {
      produced: 0,
      passed: 0,
      rejected: 0,
      rework: 0,
    };
    bucket.produced += order.goodTotal;
    bucket.passed += passedQty;
    bucket.rejected += rejectedQty;
    if (overall === 'FAIL' || overall === 'REWORK') {
      bucket.rework += rejectedQty;
    }
    fgByProduct.set(order.productId, bucket);

    await db.runAsync(
      `INSERT INTO activity_history (id, event_type, title, description, reference_type, reference_id, timestamp)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      newId(),
      'QUALITY_INSPECTION',
      'Inspection completed',
      `${batchNumber}: ${overall}`,
      'quality_inspection',
      inspectionId,
      inspectedAt,
    );
  }

  return fgByProduct;
}

export async function seedFinishedGoodsAndDispatch(
  ctx: SeedContext,
  fgByProduct: Map<string, { produced: number; passed: number; rejected: number; rework: number }>,
): Promise<void> {
  const { db, now, productIds } = ctx;

  for (const productId of productIds) {
    const stats = fgByProduct.get(productId) ?? {
      produced: 0,
      passed: 0,
      rejected: 0,
      rework: 0,
    };
    await db.runAsync(
      `INSERT INTO finished_goods (
        id, product_id, produced_quantity, quality_passed_quantity, rejected_quantity,
        rework_quantity, available_quantity, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      newId(),
      productId,
      stats.produced,
      stats.passed,
      stats.rejected,
      stats.rework,
      stats.passed,
      now,
    );
  }

  const dispatchProduct = productIds[0];
  const fgRow = await db.getFirstAsync<{ available_quantity: number }>(
    'SELECT available_quantity FROM finished_goods WHERE product_id = ?',
    dispatchProduct,
  );
  const available = fgRow?.available_quantity ?? 0;
  const dispatchedQty = Math.min(120, Math.floor(available * 0.15));

  const readyId = newId();
  await db.runAsync(
    `INSERT INTO dispatch_orders (id, dispatch_number, customer_name, product_id, quantity, status, created_at, dispatched_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    readyId,
    'DSP-00001',
    'Reliance Industrial Supply',
    dispatchProduct,
    80,
    'READY',
    now - 2 * 24 * 60 * 60 * 1000,
    null,
  );

  const dispatchId = newId();
  await db.runAsync(
    `INSERT INTO dispatch_orders (id, dispatch_number, customer_name, product_id, quantity, status, created_at, dispatched_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    dispatchId,
    'DSP-00002',
    'Tata Plant Services',
    dispatchProduct,
    dispatchedQty,
    'DISPATCHED',
    now - 5 * 24 * 60 * 60 * 1000,
    now - 4 * 24 * 60 * 60 * 1000,
  );

  await db.runAsync(
    `UPDATE finished_goods SET available_quantity = available_quantity - ?, updated_at = ? WHERE product_id = ?`,
    dispatchedQty,
    now,
    dispatchProduct,
  );

  await db.runAsync(
    `INSERT INTO activity_history (id, event_type, title, description, reference_type, reference_id, timestamp)
     VALUES (?, ?, ?, ?, ?, ?, ?)`,
    newId(),
    'DISPATCH_CREATED',
    'Dispatch order created',
    'DSP-00002 dispatched to Tata Plant Services',
    'dispatch_order',
    dispatchId,
    now - 4 * 24 * 60 * 60 * 1000,
  );
}
