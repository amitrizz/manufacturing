import { newId } from '../utils/id';
import { mongoApi } from '../api/client';
import { notifyDataChanged } from '../store/dataRefreshStore';
import {
  getMaterialAvailabilityForOrder,
  getProductionOrderById,
} from '../api/repositories/productionOrderRepository';
import { requiredMaterial } from '../utils/calculations';

export class ProductionBlockedError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'ProductionBlockedError';
  }
}

export type StartProductionInput = {
  orderId: string;
  machineIds: string[];
  workerIds?: string[];
  workerNames?: string[];
};

export async function startProduction(
  orderIdOrInput: string | StartProductionInput,
  maybeMachineId?: string,
): Promise<void> {
  const isInputObj = typeof orderIdOrInput === 'object';
  const orderId = isInputObj ? orderIdOrInput.orderId : orderIdOrInput;
  const machineIds = isInputObj
    ? orderIdOrInput.machineIds
    : maybeMachineId
    ? [maybeMachineId]
    : [];
  const workerNames = isInputObj ? orderIdOrInput.workerNames || [] : [];

  if (!machineIds || machineIds.length === 0) {
    throw new ProductionBlockedError('At least one machine must be assigned to start production.');
  }

  const availability = await getMaterialAvailabilityForOrder(orderId);
  const shortages = availability.filter((a) => a.status === 'SHORTAGE');
  if (shortages.length > 0) {
    throw new ProductionBlockedError(
      `Insufficient material: ${shortages.map((s) => s.code).join(', ')}`,
    );
  }

  const order = await getProductionOrderById(orderId);
  if (!order) throw new Error('Order not found');
  if (order.status === 'COMPLETED' || order.status === 'CANCELLED') {
    throw new Error('Order cannot be started');
  }

  // Pre-production quality check requirement
  if (order.qc_status !== 'PASSED' && order.qc_status !== 'WAIVED') {
    throw new ProductionBlockedError(
      `Pre-production quality check is required before starting production. Current status: ${order.qc_status || 'PENDING'}. Please complete offline inspection and approve QC first.`,
    );
  }

  const now = Date.now();
  const primaryMachineId = machineIds[0];

  await mongoApi.update('production_orders', orderId, {
    status: 'IN_PROGRESS',
    machine_id: primaryMachineId,
    assigned_machines: machineIds,
    assigned_workers: workerNames,
    started_at: order.started_at || now,
    start_date: order.start_date || now,
    updated_at: now,
  });

  if (order.plan_id) {
    await mongoApi
      .update('production_plans', order.plan_id, {
        status: 'IN_PROGRESS',
        updated_at: now,
      })
      .catch(() => {});
  }

  // Set all assigned machines to RUNNING and assign operator info
  const operatorLabel = workerNames.length > 0 ? workerNames.join(', ') : null;
  for (const mId of machineIds) {
    await mongoApi
      .update('machines', mId, {
        status: 'RUNNING',
        current_product_id: order.product_id,
        current_operator: operatorLabel,
        updated_at: now,
      })
      .catch(() => {});
  }

  await mongoApi
    .insert('activity_history', {
      event_type: 'PRODUCTION_STARTED',
      title: 'Production started',
      description: `${order.order_number} · Machines: ${machineIds.length} · Workers: ${operatorLabel || 'Assigned'}`,
      reference_type: 'production_order',
      reference_id: orderId,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

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
  const order = await getProductionOrderById(input.orderId);
  if (!order) throw new Error('Order not found');

  const now = Date.now();
  const outputUnits = input.goodQuantity + input.rejectedQuantity;

  if (outputUnits > 0) {
    try {
      const [boms, bomItems, materials] = await Promise.all([
        mongoApi.getCollection<any>('bom'),
        mongoApi.getCollection<any>('bom_items'),
        mongoApi.getCollection<any>('materials'),
      ]);

      const activeBom = boms.find(
        (b) => b.product_id === order.product_id && (b.is_active === 1 || b.is_active === true),
      );
      const items = activeBom
        ? bomItems.filter((bi) => bi.bom_id === activeBom.id || bi.bom_id === activeBom._id)
        : [];

      for (const item of items) {
        const mat = materials.find((m) => m.id === item.material_id || m._id === item.material_id);
        if (!mat) continue;
        const qtyPerUnit = Number(item.quantity ?? item.quantity_required ?? 1);
        const need = requiredMaterial(qtyPerUnit, outputUnits);
        const currentStock = Number(mat.current_stock ?? mat.stock_quantity ?? 0);
        if (currentStock < need) {
          throw new ProductionBlockedError(
            `Not enough ${mat.code}: need ${need} ${mat.unit || 'units'}, have ${currentStock}`,
          );
        }

        const newStock = Math.max(0, currentStock - need);
        await mongoApi.update('materials', mat.id || mat._id, {
          current_stock: newStock,
          stock_quantity: newStock,
          updated_at: now,
        });

        await mongoApi
          .insert('activity_history', {
            event_type: 'MATERIAL_ISSUED',
            title: `Used ${mat.code} on ${order.order_number}`,
            description: `${need} ${mat.unit || 'units'} for ${outputUnits} units output`,
            reference_type: 'material',
            reference_id: mat.id || mat._id,
            timestamp: now,
            created_at: now,
          })
          .catch(() => {});
      }
    } catch (err) {
      if (err instanceof ProductionBlockedError) throw err;
      console.warn('Material deduction error:', err);
    }
  }

  const entryId = newId();
  await mongoApi.insert('production_entries', {
    _id: entryId,
    id: entryId,
    production_order_id: input.orderId,
    machine_id: input.machineId,
    shift: input.shift,
    good_quantity: input.goodQuantity,
    rejected_quantity: input.rejectedQuantity,
    quantity_produced: input.goodQuantity,
    scrap_quantity: input.rejectedQuantity,
    operator: input.operator ?? null,
    notes: input.notes ?? null,
    entry_timestamp: now,
    created_at: now,
    updated_at: now,
  });

  const newProduced = (order.produced_quantity || 0) + input.goodQuantity;
  const newRejected = (order.rejected_quantity || 0) + input.rejectedQuantity;
  const completed = newProduced >= order.target_quantity;

  await mongoApi.update('production_orders', input.orderId, {
    produced_quantity: newProduced,
    rejected_quantity: newRejected,
    status: completed ? 'COMPLETED' : 'IN_PROGRESS',
    completed_at: completed ? now : null,
    updated_at: now,
  });

  try {
    const machines = await mongoApi.getCollection<any>('machines');
    const machine = machines.find((m) => m.id === input.machineId || m._id === input.machineId);
    if (machine) {
      await mongoApi.update('machines', input.machineId, {
        status: 'RUNNING',
        current_product_id: order.product_id,
        current_operator: input.operator || machine.current_operator,
        runtime_seconds: (machine.runtime_seconds || 0) + 3600,
        updated_at: now,
      });
    }
  } catch {}

  try {
    const fgList = await mongoApi.getCollection<any>('finished_goods');
    const fg = fgList.find((f) => f.product_id === order.product_id);
    if (fg) {
      const isQcPassed = order.qc_status === 'PASSED' || order.qc_status === 'WAIVED';
      await mongoApi.update('finished_goods', fg.id || fg._id, {
        produced_quantity: (fg.produced_quantity || 0) + input.goodQuantity,
        quality_passed_quantity: isQcPassed
          ? (fg.quality_passed_quantity || 0) + input.goodQuantity
          : (fg.quality_passed_quantity || 0),
        available_quantity: (fg.available_quantity || 0) + input.goodQuantity,
        rejected_quantity: (fg.rejected_quantity || 0) + (input.rejectedQuantity || 0),
        updated_at: now,
      });
    }
  } catch {}

  await mongoApi
    .insert('activity_history', {
      event_type: 'PRODUCTION_RECORDED',
      title: 'Production recorded',
      description: `${input.goodQuantity} good on ${order.order_number}${input.operator ? ` · Recorded by: ${input.operator}` : ''}`,
      reference_type: 'production_order',
      reference_id: input.orderId,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
}

export type UpdatePreProductionQcInput = {
  orderId: string;
  qcStatus: 'PASSED' | 'FAILED' | 'WAIVED';
  inspector: string;
  notes?: string;
  parameters?: {
    toolingChecked?: boolean;
    rawMaterialVerified?: boolean;
    firstPieceApproved?: boolean;
    machineParametersSet?: boolean;
    safetyGuardsActive?: boolean;
  };
};

export async function updatePreProductionQc(input: UpdatePreProductionQcInput): Promise<void> {
  const order = await getProductionOrderById(input.orderId);
  if (!order) throw new Error('Order not found');

  const now = Date.now();

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

  await mongoApi.update('production_orders', input.orderId, {
    qc_status: input.qcStatus,
    qc_inspected_at: now,
    qc_inspector: input.inspector.trim() || 'QC Inspector',
    qc_notes: notesSummary,
    updated_at: now,
  });

  // Record in quality_inspections table for full audit trace
  const inspectionId = newId();
  await mongoApi.insert('quality_inspections', {
    _id: inspectionId,
    id: inspectionId,
    batch_number: `PRE-QC-${order.order_number}`,
    inspection_number: `INS-${now.toString().slice(-6)}`,
    production_order_id: input.orderId,
    product_id: order.product_id,
    quantity: order.target_quantity || 1,
    inspector: input.inspector.trim() || 'QC Inspector',
    overall_result: input.qcStatus === 'PASSED' || input.qcStatus === 'WAIVED' ? 'PASS' : 'FAIL',
    status: 'COMPLETED',
    result: input.qcStatus === 'PASSED' || input.qcStatus === 'WAIVED' ? 'PASS' : 'FAIL',
    rejected_quantity: input.qcStatus === 'FAILED' ? 1 : 0,
    rejection_reason: input.qcStatus === 'FAILED' ? input.notes ?? 'Pre-production quality check failed' : null,
    rejection_action: input.qcStatus === 'FAILED' ? 'HOLD' : null,
    inspected_at: now,
    created_at: now,
    updated_at: now,
  });

  await mongoApi
    .insert('activity_history', {
      event_type: 'PRE_PRODUCTION_QC',
      title: `Pre-Production QC: ${input.qcStatus}`,
      description: `${order.order_number} (${input.inspector}): ${notesSummary || 'Verified offline'}`,
      reference_type: 'production_order',
      reference_id: input.orderId,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
}
