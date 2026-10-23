import type {
  InspectionResult,
  ProductionOrderRow,
  QualityInspectionRow,
  ReworkOrderRow,
} from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { mongoApi } from '../client';
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
        product_name: prodMap.get(r.product_id)?.name || 'Product',
      }))
      .sort((a, b) => (b.created_at || 0) - (a.created_at || 0));
  } catch (err) {
    console.warn('MongoDB listReworkOrders error:', err);
    return [];
  }
}

export type InspectionParameter = {
  name: string;
  expected: string;
  actual: string;
  passed: boolean;
};

export type CreateInspectionInput = {
  production_order_id: string;
  product_id: string;
  batch_number: string;
  inspector: string;
  sample_size: number;
  result: InspectionResult;
  defects_found?: number;
  defect_notes?: string;
  parameters?: InspectionParameter[];
  company_id?: string;
};

export async function createQualityInspection(input: CreateInspectionInput): Promise<string> {
  const id = newId();
  const now = Date.now();
  const defects = input.defects_found ?? 0;
  const passedQty = Math.max(0, input.sample_size - defects);

  const doc: any = {
    _id: id,
    id,
    production_order_id: input.production_order_id,
    product_id: input.product_id,
    batch_number: input.batch_number.trim(),
    inspector: input.inspector.trim(),
    quantity: input.sample_size,
    rejected_quantity: defects,
    result: input.result,
    notes: input.defect_notes?.trim() ?? null,
    parameters_json: input.parameters ? JSON.stringify(input.parameters) : null,
    inspected_at: now,
    created_at: now,
  };
  if (input.company_id) {
    doc.company_id = input.company_id;
  }

  await mongoApi.insert('quality_inspections', doc);

  // Update order QC status
  await mongoApi.update('production_orders', input.production_order_id, {
    qc_status: input.result === 'PASSED' ? 'PASSED' : input.result === 'REWORK' ? 'REWORK' : 'FAILED',
    qc_inspector: input.inspector.trim(),
    qc_inspected_at: now,
    qc_notes: input.defect_notes?.trim() ?? null,
    updated_at: now,
  });

  // Update finished goods if passed
  if (input.result === 'PASSED') {
    const fgList = await mongoApi.getCollection<any>('finished_goods', { product_id: input.product_id }).catch(() => []);
    if (fgList.length > 0) {
      const fg = fgList[0];
      const fgId = fg.id || fg._id;
      await mongoApi.update('finished_goods', fgId, {
        quality_passed_quantity: (fg.quality_passed_quantity || 0) + passedQty,
        available_quantity: (fg.available_quantity || 0) + passedQty,
        updated_at: now,
      });
    }
  }

  // Create rework order if rework required
  if (input.result === 'REWORK') {
    const reworkId = newId();
    const existing = await mongoApi.getCollection<any>('rework_orders').catch(() => []);
    const reworkNumber = `RWK-${(existing.length + 1).toString().padStart(4, '0')}`;
    await mongoApi.insert('rework_orders', {
      _id: reworkId,
      id: reworkId,
      rework_number: reworkNumber,
      production_order_id: input.production_order_id,
      product_id: input.product_id,
      batch_number: input.batch_number.trim(),
      quantity: defects,
      defect_reason: input.defect_notes?.trim() || 'QC flagged for rework',
      status: 'OPEN',
      created_at: now,
      updated_at: now,
    });
  }

  await mongoApi
    .insert('activity_history', {
      event_type: 'QC_INSPECTION',
      title: `QC Inspection: ${input.result}`,
      description: `Batch ${input.batch_number} - ${input.result} by ${input.inspector}`,
      reference_type: 'quality_inspection',
      reference_id: id,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
  return id;
}

export async function completeReworkOrder(orderId: string, notes?: string): Promise<void> {
  const now = Date.now();
  await mongoApi.update('rework_orders', orderId, {
    status: 'COMPLETED',
    notes: notes?.trim() ?? null,
    completed_at: now,
    updated_at: now,
  });

  notifyDataChanged();
}

export async function searchInspectionsByBatch(
  batchNumber: string,
  limit = 20,
): Promise<QualityInspectionRow[]> {
  const all = await listQualityInspections();
  const q = batchNumber.toLowerCase();
  return all
    .filter(
      (qi) =>
        qi.batch_number?.toLowerCase().includes(q) ||
        qi.order_number?.toLowerCase().includes(q) ||
        qi.inspector?.toLowerCase().includes(q)
    )
    .slice(0, limit);
}

export async function listOrdersWaitingForQc(): Promise<ProductionOrderRow[]> {
  const all = await listProductionOrders();
  return all.filter(
    (o) =>
      (o.status === 'COMPLETED' || o.produced_quantity > 0) &&
      (o.qc_status === 'PENDING' || !o.qc_status)
  );
}
