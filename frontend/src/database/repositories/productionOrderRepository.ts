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
  try {
    const remote = await mongoApi.listProductionOrders(filters.status);
    let filtered = (remote || []) as ProductionOrderRow[];
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
  } catch (err) {
    console.warn('MongoDB listProductionOrders error:', err);
    return [];
  }
}

export async function getProductionOrderById(
  id: string,
): Promise<ProductionOrderRow | null> {
  try {
    const orders = await mongoApi.listProductionOrders();
    const target = String(id || '').trim().toLowerCase();
    const found = orders.find(
      (o) =>
        String(o.id || '').toLowerCase() === target ||
        String(o._id || '').toLowerCase() === target ||
        String(o.order_number || '').toLowerCase() === target
    );
    if (found) return found as ProductionOrderRow;

    return await mongoApi.getById<ProductionOrderRow>('production_orders', id);
  } catch {
    return null;
  }
}

export async function getMaterialAvailabilityForOrder(
  orderId: string,
): Promise<MaterialAvailabilityRow[]> {
  const order = await getProductionOrderById(orderId);
  if (!order) return [];

  try {
    const [boms, bomItems, materials] = await Promise.all([
      mongoApi.getCollection<any>('bom'),
      mongoApi.getCollection<any>('bom_items'),
      mongoApi.getCollection<any>('materials'),
    ]);

    const activeBom = boms.find((b) => b.product_id === order.product_id && (b.is_active === 1 || b.is_active === true));
    const relevantItems = activeBom ? bomItems.filter((bi) => bi.bom_id === activeBom.id || bi.bom_id === activeBom._id) : bomItems;
    const matMap = new Map(materials.map((m) => [m.id || m._id, m]));
    const remainingQty = Math.max(order.target_quantity - (order.produced_quantity || 0), 0);

    const rows: MaterialAvailabilityRow[] = [];
    for (const item of relevantItems) {
      const mat = matMap.get(item.material_id);
      if (!mat) continue;
      const required = requiredMaterial(item.quantity, remainingQty || order.target_quantity);
      const usedTotal = requiredMaterial(item.quantity, order.produced_quantity || 0);
      rows.push({
        material_id: mat.id || mat._id,
        code: mat.code,
        name: mat.name,
        per_unit: item.quantity,
        used_total: usedTotal,
        required,
        available: mat.current_stock || 0,
        minimum_stock: mat.minimum_stock || 0,
        unit: mat.unit || 'units',
        status: materialStatus(required, mat.current_stock || 0, mat.minimum_stock || 0),
      });
    }
    return rows;
  } catch (err) {
    console.warn('MongoDB getMaterialAvailabilityForOrder error:', err);
    return [];
  }
}

/** BOM × output units (good + reject) for one production entry */
export async function getMaterialConsumptionPreview(
  productId: string,
  outputUnits: number,
): Promise<MaterialConsumptionLine[]> {
  if (outputUnits <= 0) return [];
  try {
    const [boms, bomItems, materials] = await Promise.all([
      mongoApi.getCollection<any>('bom'),
      mongoApi.getCollection<any>('bom_items'),
      mongoApi.getCollection<any>('materials'),
    ]);
    const activeBom = boms.find((b) => b.product_id === productId && (b.is_active === 1 || b.is_active === true));
    const items = activeBom ? bomItems.filter((bi) => bi.bom_id === activeBom.id || bi.bom_id === activeBom._id) : [];
    const matMap = new Map(materials.map((m) => [m.id || m._id, m]));

    return items.map((item) => {
      const m = matMap.get(item.material_id);
      return {
        material_id: item.material_id,
        code: m?.code || '',
        name: m?.name || 'Material',
        unit: item.unit || m?.unit || 'units',
        per_unit: item.quantity,
        quantity: requiredMaterial(item.quantity, outputUnits),
      };
    });
  } catch {
    return [];
  }
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
  const id = newId();
  const now = Date.now();
  const dueDate = input.due_date ?? now + 7 * 24 * 60 * 60 * 1000;

  const doc = {
    _id: id,
    id,
    order_number: input.order_number.trim(),
    plan_id: input.plan_id ?? null,
    product_id: input.product_id,
    line_id: input.line_id,
    machine_id: null,
    target_quantity: input.target_quantity,
    produced_quantity: 0,
    rejected_quantity: 0,
    priority: input.priority,
    status: 'PENDING' as OrderStatus,
    qc_status: 'PENDING',
    qc_inspector: null,
    qc_inspected_at: null,
    qc_notes: null,
    start_date: now,
    due_date: dueDate,
    started_at: null,
    completed_at: null,
    created_at: now,
    updated_at: now,
  };

  // Direct MongoDB Atlas insert
  await mongoApi.insert('production_orders', doc);

  await mongoApi
    .insert('activity_history', {
      event_type: 'ORDER_CREATED',
      title: 'Production order created',
      description: input.order_number.trim(),
      reference_type: 'production_order',
      reference_id: id,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

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
  const now = Date.now();
  await mongoApi.update('production_orders', id, {
    ...input,
    updated_at: now,
  });

  await mongoApi
    .insert('activity_history', {
      event_type: 'ORDER_UPDATED',
      title: `Production order updated`,
      description: `Target: ${input.target_quantity ?? 'Updated'}`,
      reference_type: 'production_order',
      reference_id: id,
      timestamp: now,
      created_at: now,
    })
    .catch(() => {});

  notifyDataChanged();
}

export async function deleteProductionOrder(id: string): Promise<void> {
  const existing = await getProductionOrderById(id);
  if (existing && existing.status === 'IN_PROGRESS') {
    throw new Error(`Cannot delete order ${existing.order_number} while it is IN_PROGRESS.`);
  }

  await mongoApi.delete('production_orders', id);

  await mongoApi
    .insert('activity_history', {
      event_type: 'ORDER_DELETED',
      title: `Production order deleted`,
      description: existing ? existing.order_number : id,
      reference_type: 'production_order',
      reference_id: id,
      timestamp: Date.now(),
      created_at: Date.now(),
    })
    .catch(() => {});

  notifyDataChanged();
}
