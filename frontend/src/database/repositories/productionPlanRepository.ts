import type { PlanStatus, Priority, ProductionPlanRow } from '../../types/database';
import { newId } from '../../utils/id';
import { getDatabase } from '../client';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { insertActivity } from './activityRepository';

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
  const db = await getDatabase();
  const clauses: string[] = [];
  const params: (string | number)[] = [];

  if (filters.status) {
    clauses.push('p.status = ?');
    params.push(filters.status);
  }
  if (filters.productId) {
    clauses.push('p.product_id = ?');
    params.push(filters.productId);
  }
  if (filters.lineId) {
    clauses.push('p.line_id = ?');
    params.push(filters.lineId);
  }
  if (filters.priority) {
    clauses.push('p.priority = ?');
    params.push(filters.priority);
  }
  if (filters.startFrom !== undefined) {
    clauses.push('p.start_date >= ?');
    params.push(filters.startFrom);
  }
  if (filters.startTo !== undefined) {
    clauses.push('p.start_date <= ?');
    params.push(filters.startTo);
  }
  if (filters.search) {
    clauses.push('(p.plan_number LIKE ? OR pr.name LIKE ?)');
    const q = `%${filters.search}%`;
    params.push(q, q);
  }

  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
  return db.getAllAsync<ProductionPlanRow>(
    `SELECT p.*, pr.code as product_code, pr.name as product_name, pl.code as line_code
     FROM production_plans p
     JOIN products pr ON pr.id = p.product_id
     JOIN production_lines pl ON pl.id = p.line_id
     ${where}
     ORDER BY p.start_date DESC`,
    ...params,
  );
}

export async function getProductionPlanById(id: string): Promise<ProductionPlanRow | null> {
  const db = await getDatabase();
  return db.getFirstAsync<ProductionPlanRow>(
    `SELECT p.*, pr.code as product_code, pr.name as product_name, pl.code as line_code
     FROM production_plans p
     JOIN products pr ON pr.id = p.product_id
     JOIN production_lines pl ON pl.id = p.line_id
     WHERE p.id = ?`,
    id,
  );
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
  const db = await getDatabase();
  const id = newId();
  const now = Date.now();

  await db.withTransactionAsync(async () => {
    await db.runAsync(
      `INSERT INTO production_plans (
        id, plan_number, product_id, target_quantity, line_id, start_date, expected_completion,
        priority, status, notes, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'PLANNED', ?, ?, ?)`,
      id,
      input.plan_number,
      input.product_id,
      input.target_quantity,
      input.line_id,
      input.start_date,
      input.expected_completion,
      input.priority,
      input.notes ?? null,
      now,
      now,
    );
    await insertActivity(
      {
        event_type: 'PLAN_CREATED',
        title: 'Production plan created',
        description: input.plan_number,
        reference_type: 'production_plan',
        reference_id: id,
        timestamp: now,
      },
      db,
    );
  });

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
  const db = await getDatabase();
  const existing = await getProductionPlanById(id);
  if (!existing) throw new Error('Production plan not found');

  const now = Date.now();
  await db.withTransactionAsync(async () => {
    await db.runAsync(
      `UPDATE production_plans SET
        product_id = ?, target_quantity = ?, line_id = ?, start_date = ?,
        expected_completion = ?, priority = ?, status = ?, notes = ?, updated_at = ?
       WHERE id = ?`,
      input.product_id ?? existing.product_id,
      input.target_quantity ?? existing.target_quantity,
      input.line_id ?? existing.line_id,
      input.start_date ?? existing.start_date,
      input.expected_completion ?? existing.expected_completion,
      input.priority ?? existing.priority,
      input.status ?? existing.status,
      input.notes !== undefined ? input.notes : existing.notes,
      now,
      id,
    );

    await insertActivity(
      {
        event_type: 'PLAN_UPDATED',
        title: `Production plan ${existing.plan_number} updated`,
        description: `Status: ${input.status ?? existing.status}`,
        reference_type: 'production_plan',
        reference_id: id,
        timestamp: now,
      },
      db,
    );
  });

  notifyDataChanged();
}

export async function deleteProductionPlan(id: string): Promise<void> {
  const db = await getDatabase();
  const existing = await getProductionPlanById(id);
  if (!existing) throw new Error('Production plan not found');

  await db.withTransactionAsync(async () => {
    await db.runAsync('UPDATE production_orders SET plan_id = NULL WHERE plan_id = ?', id);
    await db.runAsync('DELETE FROM production_plans WHERE id = ?', id);

    await insertActivity(
      {
        event_type: 'PLAN_DELETED',
        title: `Production plan ${existing.plan_number} deleted`,
        description: 'Plan removed',
        reference_type: 'production_plan',
        reference_id: id,
        timestamp: Date.now(),
      },
      db,
    );
  });

  notifyDataChanged();
}
