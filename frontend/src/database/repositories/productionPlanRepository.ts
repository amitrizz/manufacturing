import type { PlanStatus, Priority, ProductionPlanRow } from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { mongoApi } from '../../api/client';

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
      return {
        ...p,
        id: p.id || p._id,
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

export async function getProductionPlanById(id: string): Promise<ProductionPlanRow | null> {
  const plans = await listProductionPlans();
  return plans.find((p) => p.id === id || (p as any)._id === id) || null;
}

export type CreatePlanInput = {
  plan_number: string;
  product_id: string;
  target_quantity: number;
  line_id: string;
  start_date: number;
  expected_completion: number;
  priority: Priority;
  notes?: string;
};

export async function createProductionPlan(input: CreatePlanInput): Promise<string> {
  const id = newId();
  const now = Date.now();

  const doc = {
    _id: id,
    id,
    plan_number: input.plan_number.trim(),
    product_id: input.product_id,
    line_id: input.line_id,
    target_quantity: input.target_quantity,
    start_date: input.start_date,
    expected_completion: input.expected_completion,
    priority: input.priority,
    status: 'PLANNED' as PlanStatus,
    notes: input.notes?.trim() ?? null,
    created_at: now,
    updated_at: now,
  };

  await mongoApi.insert('production_plans', doc);

  await mongoApi
    .insert('activity_history', {
      event_type: 'PLAN_CREATED',
      title: 'Production plan created',
      description: input.plan_number,
      reference_type: 'production_plan',
      reference_id: id,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
  return id;
}

export type UpdateProductionPlanInput = {
  product_id?: string;
  target_quantity?: number;
  line_id?: string;
  start_date?: number;
  expected_completion?: number;
  priority?: Priority;
  status?: PlanStatus;
  notes?: string | null;
};

export async function updateProductionPlan(
  id: string,
  input: UpdateProductionPlanInput,
): Promise<void> {
  const now = Date.now();
  await mongoApi.update('production_plans', id, {
    ...input,
    updated_at: now,
  });

  await mongoApi
    .insert('activity_history', {
      event_type: 'PLAN_UPDATED',
      title: `Production plan updated`,
      description: `Status: ${input.status ?? 'Updated'}`,
      reference_type: 'production_plan',
      reference_id: id,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
}

export async function deleteProductionPlan(id: string): Promise<void> {
  await mongoApi.delete('production_plans', id);

  await mongoApi
    .insert('activity_history', {
      event_type: 'PLAN_DELETED',
      title: `Production plan deleted`,
      description: 'Plan removed',
      reference_type: 'production_plan',
      reference_id: id,
      timestamp: Date.now(),
      created_at: Date.now(),
    })
    .catch(() => {});

  notifyDataChanged();
}
