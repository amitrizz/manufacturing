import type {
  InspectionResult,
  ProductionOrderRow,
  QualityInspectionRow,
  ReworkOrderRow,
} from '../../types/database';
import { newId } from '../../utils/id';
import { getDatabase } from '../client';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { insertActivity } from './activityRepository';

export async function listQualityInspections(
  start?: number,
  end?: number,
): Promise<QualityInspectionRow[]> {
  const db = await getDatabase();
  if (start !== undefined && end !== undefined) {
    return db.getAllAsync<QualityInspectionRow>(
      `SELECT qi.*, po.order_number, p.code as product_code
       FROM quality_inspections qi
       JOIN production_orders po ON po.id = qi.production_order_id
       JOIN products p ON p.id = qi.product_id
       WHERE qi.inspected_at >= ? AND qi.inspected_at <= ?
       ORDER BY qi.inspected_at DESC`,
      start,
      end,
    );
  }
  return db.getAllAsync<QualityInspectionRow>(
    `SELECT qi.*, po.order_number, p.code as product_code
     FROM quality_inspections qi
     JOIN production_orders po ON po.id = qi.production_order_id
     JOIN products p ON p.id = qi.product_id
     ORDER BY qi.inspected_at DESC`,
  );
}

export async function listReworkOrders(): Promise<ReworkOrderRow[]> {
  const db = await getDatabase();
  return db.getAllAsync<ReworkOrderRow>(
    `SELECT r.*, p.code as product_code FROM rework_orders r
     JOIN products p ON p.id = r.product_id ORDER BY r.created_at DESC`,
  );
}

export type InspectionParameter = {
  parameter: string;
  expected_value: string;
  actual_value: string;
  result: 'PASS' | 'FAIL';
};

export type CreateInspectionInput = {
  batch_number: string;
  production_order_id: string;
  product_id: string;
  quantity: number;
  inspector: string;
  parameters: InspectionParameter[];
  rejection_action?: 'SCRAP' | 'REWORK' | 'HOLD';
  rejection_reason?: string;
};

export async function createQualityInspection(
  input: CreateInspectionInput,
): Promise<string> {
  const db = await getDatabase();
  const id = newId();
  const now = Date.now();

  const failCount = input.parameters.filter((p) => p.result === 'FAIL').length;
  let overall: InspectionResult = 'PASS';
  if (failCount === input.parameters.length) overall = 'FAIL';
  else if (failCount > 0) overall = 'PARTIAL_PASS';
  const reworkLeak =
    input.rejection_action === 'REWORK' &&
    input.parameters.some((p) => p.parameter === 'LEAK_TEST' && p.result === 'FAIL');
  if (reworkLeak) overall = 'FAIL';

  const rejectedQty =
    overall === 'PASS' ? 0 : Math.max(1, Math.round(input.quantity * (failCount / input.parameters.length)));
  const passedQty = input.quantity - rejectedQty;

  await db.withTransactionAsync(async () => {
    await db.runAsync(
      `INSERT INTO quality_inspections (
        id, batch_number, production_order_id, product_id, quantity, inspector, overall_result,
        rejected_quantity, rejection_reason, rejection_action, inspected_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      id,
      input.batch_number,
      input.production_order_id,
      input.product_id,
      input.quantity,
      input.inspector,
      overall,
      rejectedQty,
      input.rejection_reason ?? null,
      overall === 'FAIL' ? input.rejection_action ?? 'REWORK' : null,
      now,
    );

    for (const param of input.parameters) {
      await db.runAsync(
        `INSERT INTO quality_results (id, inspection_id, parameter, expected_value, actual_value, result, remarks)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        newId(),
        id,
        param.parameter,
        param.expected_value,
        param.actual_value,
        param.result,
        null,
      );
    }

    if (passedQty > 0) {
      await db.runAsync(
        `UPDATE finished_goods SET
          quality_passed_quantity = quality_passed_quantity + ?,
          available_quantity = available_quantity + ?,
          rejected_quantity = rejected_quantity + ?,
          updated_at = ?
         WHERE product_id = ?`,
        passedQty,
        passedQty,
        rejectedQty,
        now,
        input.product_id,
      );
    }

    if (overall === 'FAIL' && input.rejection_action === 'REWORK') {
      const order = await db.getFirstAsync<{ line_id: string }>(
        'SELECT line_id FROM production_orders WHERE id = ?',
        input.production_order_id,
      );
      await db.runAsync(
        `INSERT INTO rework_orders (
          id, rework_number, product_id, quantity, reason, assigned_line_id, status,
          source_inspection_id, created_at, completed_at
        ) VALUES (?, ?, ?, ?, ?, ?, 'PENDING', ?, ?, NULL)`,
        newId(),
        `RW-${input.batch_number}`,
        input.product_id,
        rejectedQty,
        input.rejection_reason ?? 'Quality failure',
        order?.line_id ?? null,
        id,
        now,
      );
    }

    await insertActivity(
      {
        event_type: 'QUALITY_INSPECTION',
        title: 'Inspection completed',
        description: `${input.batch_number}: ${overall}`,
        reference_type: 'quality_inspection',
        reference_id: id,
        timestamp: now,
      },
      db,
    );
  });

  notifyDataChanged();
  return id;
}

export async function completeReworkOrder(reworkId: string): Promise<void> {
  const db = await getDatabase();
  const now = Date.now();
  await db.withTransactionAsync(async () => {
    await db.runAsync(
      `UPDATE rework_orders SET status = 'COMPLETED', completed_at = ? WHERE id = ?`,
      now,
      reworkId,
    );
    await insertActivity(
      {
        event_type: 'REWORK_COMPLETED',
        title: 'Rework completed',
        reference_type: 'rework_order',
        reference_id: reworkId,
        timestamp: now,
      },
      db,
    );
  });
  notifyDataChanged();
}

export async function searchInspectionsByBatch(
  query: string,
  limit = 20,
): Promise<QualityInspectionRow[]> {
  const db = await getDatabase();
  const q = `%${query}%`;
  return db.getAllAsync<QualityInspectionRow>(
    `SELECT qi.*, po.order_number, p.code as product_code
     FROM quality_inspections qi
     JOIN production_orders po ON po.id = qi.production_order_id
     JOIN products p ON p.id = qi.product_id
     WHERE qi.batch_number LIKE ? OR po.order_number LIKE ?
     ORDER BY qi.inspected_at DESC LIMIT ?`,
    q,
    q,
    limit,
  );
}

export async function listOrdersWaitingForQc(): Promise<ProductionOrderRow[]> {
  const db = await getDatabase();
  return db.getAllAsync<ProductionOrderRow>(
    `SELECT o.*, p.code as product_code, p.name as product_name, pl.code as line_code,
            m.code as machine_code, m.name as machine_name
     FROM production_orders o
     JOIN products p ON p.id = o.product_id
     JOIN production_lines pl ON pl.id = o.line_id
     LEFT JOIN machines m ON m.id = o.machine_id
     WHERE (o.status = 'PENDING' OR o.status = 'PLANNED')
       AND (o.qc_status IS NULL OR o.qc_status = 'PENDING' OR o.qc_status = 'FAILED')
     ORDER BY 
       CASE o.priority
         WHEN 'CRITICAL' THEN 1
         WHEN 'HIGH' THEN 2
         WHEN 'MEDIUM' THEN 3
         ELSE 4
       END,
       o.created_at DESC`,
  );
}
