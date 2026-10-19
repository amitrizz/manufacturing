import type {
  MaterialAvailabilityRow,
  MaterialConsumptionLine,
  OrderStatus,
  Priority,
  ProductionOrderRow,
} from '../../types/database';
import { newId } from '../../utils/id';
import { materialStatus, requiredMaterial } from '../../utils/calculations';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { getDatabase } from '../client';
import { insertActivity } from './activityRepository';
import { getBomForProduct } from './materialRepository';
import { mongoApi } from '../../api/client';

export type OrderFilters = {
  status?: OrderStatus;
  productId?: string;
  lineId?: string;
  priority?: Priority;
  search?: string;
};

export async function listProductionOrders(
  filters: OrderFilters = {},
): Promise<ProductionOrderRow[]> {
  // Live MongoDB Backend API
  try {
    const remote = await mongoApi.listProductionOrders(filters.status);
    if (remote && Array.isArray(remote)) {
      let filtered = remote as ProductionOrderRow[];
      if (filters.productId) filtered = filtered.filter((o) => o.product_id === filters.productId);
      if (filters.lineId) filtered = filtered.filter((o) => o.line_id === filters.lineId);
      if (filters.priority) filtered = filtered.filter((o) => o.priority === filters.priority);
      if (filters.search) {
        const q = filters.search.toLowerCase();
        filtered = filtered.filter(
          (o) =>
            (o.order_number && o.order_number.toLowerCase().includes(q)) ||
            (o.product_name && o.product_name.toLowerCase().includes(q)) ||
            (o.product_code && o.product_code.toLowerCase().includes(q))
        );
      }
      return filtered;
    }
  } catch {
    // Fallback if backend offline
  }

  const db = await getDatabase();
  const clauses: string[] = [];
  const params: (string | number)[] = [];

  if (filters.status) {
    clauses.push('o.status = ?');
    params.push(filters.status);
  }
  if (filters.productId) {
    clauses.push('o.product_id = ?');
    params.push(filters.productId);
  }
  if (filters.lineId) {
    clauses.push('o.line_id = ?');
    params.push(filters.lineId);
  }
  if (filters.priority) {
    clauses.push('o.priority = ?');
    params.push(filters.priority);
  }
  if (filters.search) {
    clauses.push('(o.order_number LIKE ? OR p.name LIKE ? OR p.code LIKE ?)');
    const q = `%${filters.search}%`;
    params.push(q, q, q);
  }

  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
  return db.getAllAsync<ProductionOrderRow>(
    `SELECT o.*, p.code as product_code, p.name as product_name, pl.code as line_code,
            m.code as machine_code
     FROM production_orders o
     JOIN products p ON p.id = o.product_id
     JOIN production_lines pl ON pl.id = o.line_id
     LEFT JOIN machines m ON m.id = o.machine_id
     ${where}
     ORDER BY o.created_at DESC`,
    ...params,
  );
}

export async function getProductionOrderById(
  id: string,
): Promise<ProductionOrderRow | null> {
  const db = await getDatabase();
  return db.getFirstAsync<ProductionOrderRow>(
    `SELECT o.*, p.code as product_code, p.name as product_name, pl.code as line_code,
            m.code as machine_code
     FROM production_orders o
     JOIN products p ON p.id = o.product_id
     JOIN production_lines pl ON pl.id = o.line_id
     LEFT JOIN machines m ON m.id = o.machine_id
     WHERE o.id = ?`,
    id,
  );
}

export async function getMaterialAvailabilityForOrder(
  orderId: string,
): Promise<MaterialAvailabilityRow[]> {
  const order = await getProductionOrderById(orderId);
  if (!order) return [];

  const bom = await getBomForProduct(order.product_id);
  const db = await getDatabase();
  const remainingQty = Math.max(order.target_quantity - order.produced_quantity, 0);

  const rows: MaterialAvailabilityRow[] = [];
  for (const item of bom) {
    const mat = await db.getFirstAsync<{
      id: string;
      code: string;
      name: string;
      current_stock: number;
      minimum_stock: number;
      unit: string;
    }>('SELECT id, code, name, current_stock, minimum_stock, unit FROM materials WHERE id = ?', item.material_id);

    if (!mat) continue;
    const required = requiredMaterial(item.quantity, remainingQty || order.target_quantity);
    const usedTotal = requiredMaterial(item.quantity, order.produced_quantity);
    rows.push({
      material_id: mat.id,
      code: mat.code,
      name: mat.name,
      per_unit: item.quantity,
      used_total: usedTotal,
      required,
      available: mat.current_stock,
      minimum_stock: mat.minimum_stock,
      unit: mat.unit,
      status: materialStatus(required, mat.current_stock, mat.minimum_stock),
    });
  }
  return rows;
}

/** BOM × output units (good + reject) for one production entry */
export async function getMaterialConsumptionPreview(
  productId: string,
  outputUnits: number,
): Promise<MaterialConsumptionLine[]> {
  if (outputUnits <= 0) return [];
  const bom = await getBomForProduct(productId);
  return bom.map((item) => ({
    material_id: item.material_id,
    code: item.material_code,
    name: item.material_name,
    unit: item.unit,
    per_unit: item.quantity,
    quantity: requiredMaterial(item.quantity, outputUnits),
  }));
}

export async function searchProductionOrders(
  query: string,
  limit = 20,
): Promise<ProductionOrderRow[]> {
  return listProductionOrders({ search: query }).then((r) => r.slice(0, limit));
}

export type CreateOrderInput = {
  order_number: string;
  product_id: string;
  line_id: string;
  target_quantity: number;
  priority: Priority;
  plan_id?: string | null;
  due_date?: number;
};

export async function createProductionOrder(input: CreateOrderInput): Promise<string> {
  const db = await getDatabase();
  const id = newId();
  const now = Date.now();
  const dueDate = input.due_date ?? now + 7 * 24 * 60 * 60 * 1000;

  await db.withTransactionAsync(async () => {
    await db.runAsync(
      `INSERT INTO production_orders (
        id, order_number, plan_id, product_id, line_id, machine_id, target_quantity,
        produced_quantity, rejected_quantity, priority, status, start_date, due_date,
        started_at, completed_at, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, NULL, ?, 0, 0, ?, 'PENDING', ?, ?, NULL, NULL, ?, ?)`,
      id,
      input.order_number,
      input.plan_id ?? null,
      input.product_id,
      input.line_id,
      input.target_quantity,
      input.priority,
      now,
      dueDate,
      now,
      now,
    );

    await insertActivity(
      {
        event_type: 'ORDER_CREATED',
        title: 'Production order created',
        description: input.order_number,
        reference_type: 'production_order',
        reference_id: id,
        timestamp: now,
      },
      db,
    );
  });

  notifyDataChanged();
  return id;
}

export type UpdateProductionOrderInput = {
  product_id?: string;
  line_id?: string;
  machine_id?: string | null;
  target_quantity?: number;
  priority?: Priority;
  status?: OrderStatus;
  due_date?: number;
};

export async function updateProductionOrder(
  id: string,
  input: UpdateProductionOrderInput,
): Promise<void> {
  const db = await getDatabase();
  const existing = await getProductionOrderById(id);
  if (!existing) throw new Error('Production order not found');

  const now = Date.now();
  await db.withTransactionAsync(async () => {
    await db.runAsync(
      `UPDATE production_orders SET
        product_id = ?, line_id = ?, machine_id = ?, target_quantity = ?,
        priority = ?, status = ?, due_date = ?, updated_at = ?
       WHERE id = ?`,
      input.product_id ?? existing.product_id,
      input.line_id ?? existing.line_id,
      input.machine_id !== undefined ? input.machine_id : existing.machine_id,
      input.target_quantity ?? existing.target_quantity,
      input.priority ?? existing.priority,
      input.status ?? existing.status,
      input.due_date ?? existing.due_date,
      now,
      id,
    );

    await insertActivity(
      {
        event_type: 'ORDER_UPDATED',
        title: `Production order ${existing.order_number} updated`,
        description: `Target: ${input.target_quantity ?? existing.target_quantity}`,
        reference_type: 'production_order',
        reference_id: id,
        timestamp: now,
      },
      db,
    );
  });

  notifyDataChanged();
}

export async function deleteProductionOrder(id: string): Promise<void> {
  const db = await getDatabase();
  const existing = await getProductionOrderById(id);
  if (!existing) throw new Error('Production order not found');

  if (existing.status === 'IN_PROGRESS') {
    throw new Error(`Cannot delete order ${existing.order_number} while it is IN_PROGRESS.`);
  }

  await db.withTransactionAsync(async () => {
    await db.runAsync('DELETE FROM production_entries WHERE production_order_id = ?', id);
    await db.runAsync('DELETE FROM quality_inspections WHERE production_order_id = ?', id);
    await db.runAsync('DELETE FROM production_orders WHERE id = ?', id);

    await insertActivity(
      {
        event_type: 'ORDER_DELETED',
        title: `Production order ${existing.order_number} deleted`,
        description: 'Order removed',
        reference_type: 'production_order',
        reference_id: id,
        timestamp: Date.now(),
      },
      db,
    );
  });

  notifyDataChanged();
}
