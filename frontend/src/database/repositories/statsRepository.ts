import { getDatabase } from '../client';
import { mongoApi } from '../../api/client';

export type DatabaseStats = {
  factories: number;
  lines: number;
  machines: number;
  staff: number;
  suppliers: number;
  customers: number;
  materials: number;
  products: number;
  productionOrders: number;
  inspections: number;
  dispatches: number;
  activityRows: number;
};

export async function getDatabaseStats(): Promise<DatabaseStats> {
  try {
    const [
      factories,
      lines,
      machines,
      staff,
      suppliers,
      customers,
      materials,
      products,
      productionOrders,
      inspections,
      dispatches,
      activities,
    ] = await Promise.all([
      mongoApi.getCollection('factories').catch(() => []),
      mongoApi.getCollection('production_lines').catch(() => []),
      mongoApi.getCollection('machines').catch(() => []),
      mongoApi.getCollection('staff').catch(() => []),
      mongoApi.getCollection('suppliers').catch(() => []),
      mongoApi.getCollection('customers').catch(() => []),
      mongoApi.getCollection('materials').catch(() => []),
      mongoApi.getCollection('products').catch(() => []),
      mongoApi.getCollection('production_orders').catch(() => []),
      mongoApi.getCollection('quality_inspections').catch(() => []),
      mongoApi.getCollection('dispatch_orders').catch(() => []),
      mongoApi.getCollection('activity_history').catch(() => []),
    ]);

    return {
      factories: factories.length,
      lines: lines.length,
      machines: machines.length,
      staff: staff.length,
      suppliers: suppliers.length,
      customers: customers.length,
      materials: materials.length,
      products: products.length,
      productionOrders: productionOrders.length,
      inspections: inspections.length,
      dispatches: dispatches.length,
      activityRows: activities.length,
    };
  } catch {
    // Fallback if backend offline
  }

  const db = await getDatabase();
  const [
    factories,
    lines,
    machines,
    staff,
    suppliers,
    customers,
    materials,
    products,
    productionOrders,
    inspections,
    dispatches,
    activityRows,
  ] = await Promise.all([
    db.getFirstAsync<{ count: number }>('SELECT COUNT(*) as count FROM factories').catch(() => ({ count: 0 })),
    db.getFirstAsync<{ count: number }>('SELECT COUNT(*) as count FROM production_lines').catch(() => ({ count: 0 })),
    db.getFirstAsync<{ count: number }>('SELECT COUNT(*) as count FROM machines').catch(() => ({ count: 0 })),
    db.getFirstAsync<{ count: number }>('SELECT COUNT(*) as count FROM staff').catch(() => ({ count: 0 })),
    db.getFirstAsync<{ count: number }>('SELECT COUNT(*) as count FROM suppliers').catch(() => ({ count: 0 })),
    db.getFirstAsync<{ count: number }>('SELECT COUNT(*) as count FROM customers').catch(() => ({ count: 0 })),
    db.getFirstAsync<{ count: number }>('SELECT COUNT(*) as count FROM materials').catch(() => ({ count: 0 })),
    db.getFirstAsync<{ count: number }>('SELECT COUNT(*) as count FROM products').catch(() => ({ count: 0 })),
    db.getFirstAsync<{ count: number }>('SELECT COUNT(*) as count FROM production_orders').catch(() => ({ count: 0 })),
    db.getFirstAsync<{ count: number }>('SELECT COUNT(*) as count FROM quality_inspections').catch(() => ({ count: 0 })),
    db.getFirstAsync<{ count: number }>('SELECT COUNT(*) as count FROM dispatch_orders').catch(() => ({ count: 0 })),
    db.getFirstAsync<{ count: number }>('SELECT COUNT(*) as count FROM activity_history').catch(() => ({ count: 0 })),
  ]);

  return {
    factories: factories?.count ?? 0,
    lines: lines?.count ?? 0,
    machines: machines?.count ?? 0,
    staff: staff?.count ?? 0,
    suppliers: suppliers?.count ?? 0,
    customers: customers?.count ?? 0,
    materials: materials?.count ?? 0,
    products: products?.count ?? 0,
    productionOrders: productionOrders?.count ?? 0,
    inspections: inspections?.count ?? 0,
    dispatches: dispatches?.count ?? 0,
    activityRows: activityRows?.count ?? 0,
  };
}
