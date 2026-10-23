import { mongoApi } from '../client';

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
  finishedGoods: number;
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
      finishedGoods,
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
      mongoApi.getCollection('finished_goods').catch(() => []),
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
      finishedGoods: finishedGoods.length,
      dispatches: dispatches.length,
      activityRows: activities.length,
    };
  } catch (err) {
    console.warn('MongoDB getDatabaseStats error:', err);
    return {
      factories: 0,
      lines: 0,
      machines: 0,
      staff: 0,
      suppliers: 0,
      customers: 0,
      materials: 0,
      products: 0,
      productionOrders: 0,
      inspections: 0,
      finishedGoods: 0,
      dispatches: 0,
      activityRows: 0,
    };
  }
}
