import { newId } from '../utils/id';
import { getDatabase } from '../database/client';
import { insertActivity } from '../database/repositories/activityRepository';
import { notifyDataChanged } from '../store/dataRefreshStore';
import { getBomForProduct } from '../database/repositories/materialRepository';
import { getMaterialAvailabilityForOrder } from '../database/repositories/productionOrderRepository';
import { requiredMaterial } from '../utils/calculations';

export class ProductionBlockedError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ProductionBlockedError';
  }
}

export async function startProduction(orderId: string, machineId: string): Promise<void> {
  const availability = await getMaterialAvailabilityForOrder(orderId);
  const shortages = availability.filter((a) => a.status === 'SHORTAGE');
  if (shortages.length > 0) {
    throw new ProductionBlockedError(
      `Insufficient material: ${shortages.map((s) => s.code).join(', ')}`,
    );
  }

  const db = await getDatabase();
  const now = Date.now();

  await db.withTransactionAsync(async () => {
    const order = await db.getFirstAsync<{
      product_id: string;
      status: string;
      order_number: string;
      plan_id: string | null;
      qc_status?: string | null;
      qc_inspector?: string | null;
    }>(
      'SELECT product_id, status, order_number, plan_id, qc_status, qc_inspector FROM production_orders WHERE id = ?',
      orderId,
    );

    if (!order) throw new Error('Order not found');
    if (order.status === 'COMPLETED' || order.status === 'CANCELLED') {
      throw new Error('Order cannot be started');
    }

    // Pre-production quality check requirement
    if (order.qc_status !== 'PASSED' && order.qc_status !== 'WAIVED') {
      throw new ProductionBlockedError(
        `Pre-production quality check is required before starting production. Current status: ${order.qc_status || 'PENDING'}. Please complete offline inspection and update the QC record to PASSED.`,
      );
    }

    await db.runAsync(
      `UPDATE production_orders SET status = 'IN_PROGRESS', machine_id = ?, started_at = COALESCE(started_at, ?),
        start_date = COALESCE(start_date, ?), updated_at = ? WHERE id = ?`,
      machineId,
      now,
      now,
      now,
      orderId,
    );

    if (order.plan_id) {
      await db.runAsync(
        `UPDATE production_plans SET status = 'IN_PROGRESS', updated_at = ? WHERE id = ? AND status != 'COMPLETED'`,
        now,
        order.plan_id,
      );
    }

    await db.runAsync(
      `UPDATE machines SET status = 'RUNNING', current_product_id = ?, updated_at = ? WHERE id = ?`,
      order.product_id,
      now,
      machineId,
    );

    await insertActivity(
      {
        event_type: 'PRODUCTION_STARTED',
        title: 'Production started',
        description: order.order_number,
        reference_type: 'production_order',
        reference_id: orderId,
        timestamp: now,
      },
      db,
    );
  });
  notifyDataChanged();
}

export type RecordProductionInput = {
  orderId: string;
  machineId: string;
  shift: string;
  goodQuantity: number;
  rejectedQuantity: number;
  operator?: string;
  notes?: string;
};

export async function recordProduction(input: RecordProductionInput): Promise<void> {
  const db = await getDatabase();
  const now = Date.now();

  await db.withTransactionAsync(async () => {
    const order = await db.getFirstAsync<{
      product_id: string;
      target_quantity: number;
      produced_quantity: number;
      rejected_quantity: number;
      order_number: string;
    }>(
      `SELECT product_id, target_quantity, produced_quantity, rejected_quantity, order_number
       FROM production_orders WHERE id = ?`,
      input.orderId,
    );
    if (!order) throw new Error('Order not found');

    const outputUnits = input.goodQuantity + input.rejectedQuantity;
    if (outputUnits > 0) {
      const bom = await getBomForProduct(order.product_id);
      for (const item of bom) {
        const need = requiredMaterial(item.quantity, outputUnits);
        const mat = await db.getFirstAsync<{ current_stock: number; code: string; unit: string }>(
          'SELECT current_stock, code, unit FROM materials WHERE id = ?',
          item.material_id,
        );
        if (!mat) continue;
        if (mat.current_stock < need) {
          throw new ProductionBlockedError(
            `Not enough ${mat.code}: need ${need} ${mat.unit}, have ${mat.current_stock}`,
          );
        }
        await db.runAsync(
          'UPDATE materials SET current_stock = current_stock - ?, updated_at = ? WHERE id = ?',
          need,
          now,
          item.material_id,
        );
        await insertActivity(
          {
            event_type: 'MATERIAL_ISSUED',
            title: `Used ${mat.code} on ${order.order_number}`,
            description: `${need} ${mat.unit} for ${outputUnits} units output`,
            reference_type: 'material',
            reference_id: item.material_id,
            timestamp: now,
          },
          db,
        );
      }
    }

    await db.runAsync(
      `INSERT INTO production_entries (
        id, production_order_id, machine_id, shift, good_quantity, rejected_quantity,
        operator, notes, entry_timestamp
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      newId(),
      input.orderId,
      input.machineId,
      input.shift,
      input.goodQuantity,
      input.rejectedQuantity,
      input.operator ?? null,
      input.notes ?? null,
      now,
    );

    const newProduced = order.produced_quantity + input.goodQuantity;
    const newRejected = order.rejected_quantity + input.rejectedQuantity;
    const completed = newProduced >= order.target_quantity;

    await db.runAsync(
      `UPDATE production_orders SET produced_quantity = ?, rejected_quantity = ?,
        status = ?, completed_at = ?, updated_at = ? WHERE id = ?`,
      newProduced,
      newRejected,
      completed ? 'COMPLETED' : 'IN_PROGRESS',
      completed ? now : null,
      now,
      input.orderId,
    );

    await db.runAsync(
      `UPDATE machines SET runtime_seconds = runtime_seconds + 3600, updated_at = ? WHERE id = ?`,
      now,
      input.machineId,
    );

    await db.runAsync(
      `UPDATE finished_goods SET produced_quantity = produced_quantity + ?, updated_at = ?
       WHERE product_id = (SELECT product_id FROM production_orders WHERE id = ?)`,
      input.goodQuantity,
      now,
      input.orderId,
    );

    await insertActivity(
      {
        event_type: 'PRODUCTION_RECORDED',
        title: 'Production recorded',
        description: `${input.goodQuantity} good on ${order.order_number}${input.operator ? ` · Recorded by: ${input.operator}` : ''}`,
        reference_type: 'production_order',
        reference_id: input.orderId,
        timestamp: now,
      },
      db,
    );
  });
  notifyDataChanged();
}

export type UpdatePreProductionQcInput = {
  orderId: string;
  qcStatus: 'PASSED' | 'FAILED' | 'WAIVED';
  inspector: string;
  notes?: string;
  startProductionNow?: boolean;
  machineId?: string;
  parameters?: {
    toolingChecked?: boolean;
    rawMaterialVerified?: boolean;
    firstPieceApproved?: boolean;
    machineParametersSet?: boolean;
    safetyGuardsActive?: boolean;
  };
};

export async function updatePreProductionQc(input: UpdatePreProductionQcInput): Promise<void> {
  const db = await getDatabase();
  const now = Date.now();
  await db.withTransactionAsync(async () => {
    const order = await db.getFirstAsync<{
      order_number: string;
      product_id: string;
      machine_id: string | null;
      plan_id: string | null;
    }>(
      'SELECT order_number, product_id, machine_id, plan_id FROM production_orders WHERE id = ?',
      input.orderId,
    );
    if (!order) throw new Error('Order not found');

    const checklistParts: string[] = [];
    if (input.parameters) {
      if (input.parameters.toolingChecked) checklistParts.push('Tooling Verified');
      if (input.parameters.rawMaterialVerified) checklistParts.push('Raw Material Batch OK');
      if (input.parameters.firstPieceApproved) checklistParts.push('1st Piece Sample Approved');
      if (input.parameters.machineParametersSet) checklistParts.push('Parameters Calibrated');
      if (input.parameters.safetyGuardsActive) checklistParts.push('Safety Verified');
    }

    const notesSummary = [
      input.notes?.trim(),
      checklistParts.length > 0 ? `[${checklistParts.join(', ')}]` : null,
    ]
      .filter(Boolean)
      .join(' - ');

    await db.runAsync(
      `UPDATE production_orders SET
        qc_status = ?,
        qc_inspected_at = ?,
        qc_inspector = ?,
        qc_notes = ?,
        updated_at = ?
       WHERE id = ?`,
      input.qcStatus,
      now,
      input.inspector.trim() || 'QC Inspector',
      notesSummary,
      now,
      input.orderId,
    );

    if (input.startProductionNow && (input.qcStatus === 'PASSED' || input.qcStatus === 'WAIVED')) {
      let targetMachineId = input.machineId || order.machine_id;
      if (!targetMachineId) {
        const idleM = await db.getFirstAsync<{ id: string }>(
          `SELECT id FROM machines WHERE status = 'IDLE' ORDER BY code ASC LIMIT 1`,
        );
        const runningM = await db.getFirstAsync<{ id: string }>(
          `SELECT id FROM machines WHERE status = 'RUNNING' ORDER BY code ASC LIMIT 1`,
        );
        const anyM = await db.getFirstAsync<{ id: string }>(
          `SELECT id FROM machines ORDER BY code ASC LIMIT 1`,
        );
        targetMachineId = idleM?.id || runningM?.id || anyM?.id || null;
      }

      await db.runAsync(
        `UPDATE production_orders SET
           status = 'IN_PROGRESS',
           machine_id = COALESCE(?, machine_id),
           started_at = COALESCE(started_at, ?),
           start_date = COALESCE(start_date, ?),
           updated_at = ?
         WHERE id = ?`,
        targetMachineId,
        now,
        now,
        now,
        input.orderId,
      );

      if (order.plan_id) {
        await db.runAsync(
          `UPDATE production_plans SET status = 'IN_PROGRESS', updated_at = ? WHERE id = ? AND status != 'COMPLETED'`,
          now,
          order.plan_id,
        );
      }

      if (targetMachineId) {
        await db.runAsync(
          `UPDATE machines SET status = 'RUNNING', current_product_id = ?, updated_at = ? WHERE id = ?`,
          order.product_id,
          now,
          targetMachineId,
        );
      }

      await insertActivity(
        {
          event_type: 'PRODUCTION_STARTED',
          title: 'Production started',
          description: order.order_number,
          reference_type: 'production_order',
          reference_id: input.orderId,
          timestamp: now,
        },
        db,
      );
    }

    // Also record in quality_inspections table for full audit trace
    await db.runAsync(
      `INSERT INTO quality_inspections (
        id, batch_number, production_order_id, product_id, quantity, inspector, overall_result,
        rejected_quantity, rejection_reason, rejection_action, inspected_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      newId(),
      `PRE-QC-${order.order_number}`,
      input.orderId,
      order.product_id,
      1,
      input.inspector.trim() || 'QC Inspector',
      input.qcStatus === 'PASSED' || input.qcStatus === 'WAIVED' ? 'PASS' : 'FAIL',
      input.qcStatus === 'FAILED' ? 1 : 0,
      input.qcStatus === 'FAILED' ? input.notes ?? 'Pre-production quality check failed' : null,
      input.qcStatus === 'FAILED' ? 'HOLD' : null,
      now,
    );

    await insertActivity(
      {
        event_type: 'PRE_PRODUCTION_QC',
        title: `Pre-Production QC: ${input.qcStatus}`,
        description: `${order.order_number} (${input.inspector}): ${notesSummary || 'Verified offline'}`,
        reference_type: 'production_order',
        reference_id: input.orderId,
        timestamp: now,
      },
      db,
    );
  });
  notifyDataChanged();
}

