import type {
  InspectionResult,
  ProductionOrderRow,
  QualityInspectionRow,
  ReworkOrderRow,
} from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { mongoApi } from '../../api/client';
import { listProductionOrders } from './productionOrderRepository';

export async function listQualityInspections(
  start?: number,
  end?: number,
): Promise<QualityInspectionRow[]> {
  try {
    const [inspections, orders, products] = await Promise.all([
      mongoApi.getCollection<any>('quality_inspections'),
      mongoApi.getCollection<any>('production_orders'),
      mongoApi.getCollection<any>('products'),
    ]);

    const orderMap = new Map(orders.map((o) => [o.id || o._id, o]));
    const prodMap = new Map(products.map((p) => [p.id || p._id, p]));

    let result = inspections.map((qi) => {
      const ord = orderMap.get(qi.production_order_id);
      const pr = prodMap.get(qi.product_id);
      return {
        ...qi,
        id: qi.id || qi._id,
        order_number: ord?.order_number || '',
        product_code: pr?.code || '',
        product_name: pr?.name || '',
      };
    });

    if (start !== undefined && end !== undefined) {
      result = result.filter(
        (qi) => (qi.inspected_at || qi.created_at || 0) >= start && (qi.inspected_at || qi.created_at || 0) <= end
      );
    }

    return result.sort((a, b) => (b.inspected_at || b.created_at || 0) - (a.inspected_at || a.created_at || 0));
  } catch (err) {
    console.warn('MongoDB listQualityInspections error:', err);
    return [];
  }
}

export async function listReworkOrders(): Promise<ReworkOrderRow[]> {
  try {
    const [reworks, products] = await Promise.all([
      mongoApi.getCollection<any>('rework_orders'),
      mongoApi.getCollection<any>('products'),
    ]);
    const prodMap = new Map(products.map((p) => [p.id || p._id, p]));
    return reworks
      .map((r) => ({
        ...r,
        id: r.id || r._id,
        product_code: prodMap.get(r.product_id)?.code || '',
      }))
      .sort((a, b) => (b.created_at || 0) - (a.created_at || 0));
  } catch {
    return [];
  }
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

  await mongoApi.insert('quality_inspections', {
    _id: id,
    id,
    batch_number: input.batch_number,
    inspection_number: `INS-${now.toString().slice(-6)}`,
    production_order_id: input.production_order_id,
    product_id: input.product_id,
    quantity: input.quantity,
    inspector: input.inspector,
    overall_result: overall,
    status: 'COMPLETED',
    result: overall,
    rejected_quantity: rejectedQty,
    rejection_reason: input.rejection_reason ?? null,
    rejection_action: overall === 'FAIL' ? input.rejection_action ?? 'REWORK' : null,
    inspected_at: now,
    created_at: now,
    updated_at: now,
  });

  for (const param of input.parameters) {
    await mongoApi.insert('quality_results', {
      _id: newId(),
      id: newId(),
      inspection_id: id,
      parameter: param.parameter,
      expected_value: param.expected_value,
      actual_value: param.actual_value,
      result: param.result,
      remarks: null,
      created_at: now,
    });
  }

  if (overall === 'FAIL' && input.rejection_action === 'REWORK') {
    await mongoApi.insert('rework_orders', {
      _id: newId(),
      id: newId(),
      rework_number: `RW-${input.batch_number}`,
      inspection_id: id,
      product_id: input.product_id,
      quantity: rejectedQty,
      reason: input.rejection_reason ?? 'Quality failure',
      status: 'PENDING',
      source_inspection_id: id,
      created_at: now,
      updated_at: now,
    });
  }

  await mongoApi
    .insert('activity_history', {
      event_type: 'QUALITY_INSPECTION',
      title: 'Inspection completed',
      description: `${input.batch_number}: ${overall}`,
      reference_type: 'quality_inspection',
      reference_id: id,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
  return id;
}

export async function completeReworkOrder(reworkId: string): Promise<void> {
  const now = Date.now();
  await mongoApi.update('rework_orders', reworkId, {
    status: 'COMPLETED',
    completed_at: now,
    updated_at: now,
  });

  await mongoApi
    .insert('activity_history', {
      event_type: 'REWORK_COMPLETED',
      title: 'Rework completed',
      reference_type: 'rework_order',
      reference_id: reworkId,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
}

export async function searchInspectionsByBatch(
  query: string,
  limit = 20,
): Promise<QualityInspectionRow[]> {
  const all = await listQualityInspections();
  const q = query.toLowerCase();
  return all
    .filter(
      (qi) =>
        qi.batch_number?.toLowerCase().includes(q) ||
        (qi as any).order_number?.toLowerCase().includes(q)
    )
    .slice(0, limit);
}

export async function listOrdersWaitingForQc(): Promise<ProductionOrderRow[]> {
  try {
    const orders = (await listProductionOrders()) || [];
    return orders.filter(
      (o) =>
        o.status !== 'CANCELLED' &&
        o.status !== 'COMPLETED' &&
        (!o.qc_status || o.qc_status === 'PENDING' || o.qc_status === 'FAILED')
    );
  } catch (err) {
    console.warn('MongoDB listOrdersWaitingForQc error:', err);
    return [];
  }
}

