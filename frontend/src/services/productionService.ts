import { newId } from '../utils/id';
import { mongoApi } from '../api/client';
import { notifyDataChanged } from '../store/dataRefreshStore';
import {
  getMaterialAvailabilityForOrder,
  getProductionOrderById,
} from '../database/repositories/productionOrderRepository';
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

  const order = await getProductionOrderById(orderId);
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

  const now = Date.now();

  await mongoApi.update('production_orders', orderId, {
    status: 'IN_PROGRESS',
    machine_id: machineId,
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

  await mongoApi
    .update('machines', machineId, {
      status: 'RUNNING',
      current_product_id: order.product_id,
      updated_at: now,
    })
    .catch(() => {});

  await mongoApi
    .insert('activity_history', {
      event_type: 'PRODUCTION_STARTED',
      title: 'Production started',
      description: order.order_number,
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
        const need = requiredMaterial(item.quantity, outputUnits);
        if ((mat.current_stock || 0) < need) {
          throw new ProductionBlockedError(
            `Not enough ${mat.code}: need ${need} ${mat.unit || 'units'}, have ${mat.current_stock || 0}`,
          );
        }

        await mongoApi.update('materials', mat.id || mat._id, {
          current_stock: Math.max(0, (mat.current_stock || 0) - need),
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
        runtime_seconds: (machine.runtime_seconds || 0) + 3600,
        updated_at: now,
      });
    }
  } catch {}

  try {
    const fgList = await mongoApi.getCollection<any>('finished_goods');
    const fg = fgList.find((f) => f.product_id === order.product_id);
    if (fg) {
      await mongoApi.update('finished_goods', fg.id || fg._id, {
        produced_quantity: (fg.produced_quantity || 0) + input.goodQuantity,
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

  if (input.startProductionNow && (input.qcStatus === 'PASSED' || input.qcStatus === 'WAIVED')) {
    let targetMachineId = input.machineId || order.machine_id;
    if (!targetMachineId) {
      try {
        const machines = await mongoApi.getCollection<any>('machines');
        const idleM = machines.find((m) => m.status === 'IDLE');
        const runningM = machines.find((m) => m.status === 'RUNNING');
        targetMachineId =
          idleM?.id ||
          idleM?._id ||
          runningM?.id ||
          runningM?._id ||
          machines[0]?.id ||
          machines[0]?._id ||
          null;
      } catch {}
    }

    await mongoApi.update('production_orders', input.orderId, {
      status: 'IN_PROGRESS',
      machine_id: targetMachineId ?? order.machine_id,
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

    if (targetMachineId) {
      await mongoApi
        .update('machines', targetMachineId, {
          status: 'RUNNING',
          current_product_id: order.product_id,
          updated_at: now,
        })
        .catch(() => {});
    }

    await mongoApi
      .insert('activity_history', {
        event_type: 'PRODUCTION_STARTED',
        title: 'Production started',
        description: order.order_number,
        reference_type: 'production_order',
        reference_id: input.orderId,
        timestamp: now,
        created_at: now,
      })
      .catch(() => {});
  }

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
