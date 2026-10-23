import type { PlanStatus, Priority, ProductionPlanRow } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { mongoApi } from '../client';

export type PlanFilters = {
  status?: PlanStatus;
  productId?: string;
  lineId?: string;
  priority?: Priority;
  startFrom?: number;
  startTo?: number;
  search?: string;
};

export async function listProductionPlans(
  filters: PlanFilters = {},
): Promise<ProductionPlanRow[]> {
  try {
    const [plans, products, lines] = await Promise.all([
      mongoApi.getCollection<any>('production_plans'),
      mongoApi.getCollection<any>('products'),
      mongoApi.getCollection<any>('production_lines'),
    ]);

    const prodMap = new Map(products.map((p) => [p.id || p._id, p]));
    const lineMap = new Map(lines.map((l) => [l.id || l._id, l]));

    let result: ProductionPlanRow[] = plans.map((p) => {
      const prod = prodMap.get(p.product_id);
      const line = lineMap.get(p.line_id);
      const targetQty = Number(p.target_quantity ?? p.planned_quantity ?? 0);
      return {
        ...p,
        id: p.id || p._id,
        target_quantity: targetQty,
        planned_quantity: targetQty,
        priority: p.priority || 'MEDIUM',
        status: (p.status === 'DRAFT' ? 'PLANNED' : (p.status || 'PLANNED')),
        product_code: prod?.code || '',
        product_name: prod?.name || 'Product',
        line_code: line?.code || '',
        line_name: line?.name || 'Line',
      };
    });

    if (filters.status) result = result.filter((p) => p.status === filters.status);
    if (filters.productId) result = result.filter((p) => p.product_id === filters.productId);
    if (filters.lineId) result = result.filter((p) => p.line_id === filters.lineId);
    if (filters.priority) result = result.filter((p) => p.priority === filters.priority);
    if (filters.startFrom !== undefined) result = result.filter((p) => (p.start_date || 0) >= filters.startFrom!);
    if (filters.startTo !== undefined) result = result.filter((p) => (p.start_date || 0) <= filters.startTo!);
    if (filters.search) {
      const q = filters.search.toLowerCase();
      result = result.filter(
        (p) =>
          p.plan_number?.toLowerCase().includes(q) ||
          p.product_name?.toLowerCase().includes(q) ||
          p.product_code?.toLowerCase().includes(q)
      );
    }

    return result.sort((a, b) => (b.start_date || 0) - (a.start_date || 0));
  } catch (err) {
    console.warn('MongoDB listProductionPlans error:', err);
    return [];
  }
}

export async function getProductionPlanById(
  id: string,
): Promise<ProductionPlanRow | null> {
  const all = await listProductionPlans();
  const target = String(id || '').trim().toLowerCase();
  const found = all.find(
    (p) =>
      String(p.id || '').toLowerCase() === target ||
      String((p as any)._id || '').toLowerCase() === target ||
      String(p.plan_number || '').toLowerCase() === target
  );
  if (found) return found;

  try {
    const raw = await mongoApi.getById<any>('production_plans', id);
    if (!raw) return null;
    const targetQty = Number(raw.target_quantity ?? raw.planned_quantity ?? 0);
    return {
      ...raw,
      id: raw.id || raw._id,
      target_quantity: targetQty,
      planned_quantity: targetQty,
      priority: raw.priority || 'MEDIUM',
      status: raw.status === 'DRAFT' ? 'PLANNED' : (raw.status || 'PLANNED'),
    };
  } catch {
    return null;
  }
}

export type CreatePlanInput = {
  plan_number: string;
  product_id: string;
  line_id: string;
  planned_quantity?: number;
  target_quantity?: number;
  priority?: Priority;
  start_date?: number;
  end_date?: number;
  expected_completion?: number;
  notes?: string;
  company_id?: string;
};

export async function createProductionPlan(input: CreatePlanInput): Promise<string> {
  const id = newId();
  const now = Date.now();
  const targetQty = Number(input.target_quantity ?? input.planned_quantity ?? 0);

  const doc: any = {
    _id: id,
    id,
    plan_number: input.plan_number.trim(),
    product_id: input.product_id,
    line_id: input.line_id,
    target_quantity: targetQty,
    planned_quantity: targetQty,
    priority: input.priority || 'MEDIUM',
    status: 'PLANNED' as PlanStatus,
    start_date: input.start_date || now,
    end_date: input.end_date || (now + 7 * 86400000),
    expected_completion: input.expected_completion || input.end_date || (now + 7 * 86400000),
    notes: input.notes?.trim() ?? null,
    created_at: now,
    updated_at: now,
  };
  if (input.company_id) {
    doc.company_id = input.company_id;
  }

  await mongoApi.insert('production_plans', doc);

  await mongoApi
    .insert('activity_history', {
      event_type: 'PLAN_CREATED',
      title: 'Production plan created',
      description: input.plan_number.trim(),
      reference_type: 'production_plan',
      reference_id: id,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
  return id;
}

export type UpdatePlanInput = {
  product_id?: string;
  line_id?: string;
  planned_quantity?: number;
  target_quantity?: number;
  priority?: Priority;
  status?: PlanStatus;
  start_date?: number;
  end_date?: number;
  expected_completion?: number;
  notes?: string;
};
export type UpdateProductionPlanInput = UpdatePlanInput;

export async function updateProductionPlan(
  id: string,
  input: UpdatePlanInput,
): Promise<void> {
  const now = Date.now();
  const updateData: any = {
    ...input,
    updated_at: now,
  };
  if (input.target_quantity !== undefined && input.planned_quantity === undefined) {
    updateData.planned_quantity = input.target_quantity;
  } else if (input.planned_quantity !== undefined && input.target_quantity === undefined) {
    updateData.target_quantity = input.planned_quantity;
  }

  await mongoApi.update('production_plans', id, updateData);

  notifyDataChanged();
}

export async function deleteProductionPlan(id: string): Promise<void> {
  await mongoApi.delete('production_plans', id);

  await mongoApi
    .insert('activity_history', {
      event_type: 'PLAN_DELETED',
      title: 'Production plan deleted',
      description: id,
      reference_type: 'production_plan',
      reference_id: id,
      timestamp: Date.now(),
      created_at: Date.now(),
    })
    .catch(() => {});

  notifyDataChanged();
}
