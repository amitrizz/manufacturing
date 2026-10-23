import { listDispatchOrders } from '../api/repositories/dispatchRepository';
import { listMaterials } from '../api/repositories/materialRepository';
import { listMachines } from '../api/repositories/machineRepository';
import { listMaintenanceOrders } from '../api/repositories/maintenanceRepository';
import { listProductionOrders } from '../api/repositories/productionOrderRepository';
import { listReworkOrders } from '../api/repositories/qualityRepository';
import type { ActionableTask } from '../types/tasks';
import { formatStatusLabel } from '../utils/format';

export async function listActionableTasks(): Promise<ActionableTask[]> {
  const tasks: ActionableTask[] = [];

  const [orders, maintenance, rework, dispatches, breakdowns, lowMaterials] = await Promise.all([
    listProductionOrders(),
    listMaintenanceOrders(),
    listReworkOrders(),
    listDispatchOrders(),
    listMachines({ status: 'BREAKDOWN' }),
    listMaterials({ lowStockOnly: true }),
  ]);

  for (const o of orders) {
    if (o.status !== 'PENDING' && o.status !== 'IN_PROGRESS') continue;
    const inProgress = o.status === 'IN_PROGRESS';
    tasks.push({
      id: `order-${o.id}`,
      category: 'Production',
      title: o.order_number,
      subtitle: `${o.product_name ?? o.product_code} · ${formatStatusLabel(o.status)}`,
      status: o.status,
      referenceId: o.id,
      route: inProgress
        ? {
            tab: 'Home',
            screen: 'RecordProduction',
            params: { orderId: o.id },
          }
        : {
            tab: 'Home',
            screen: 'ProductionOrderDetail',
            params: { orderId: o.id },
          },
    });
  }

  for (const mo of maintenance) {
    if (mo.status === 'COMPLETED' || mo.status === 'CANCELLED') continue;
    tasks.push({
      id: `maint-${mo.id}`,
      category: 'Maintenance',
      title: mo.order_number,
      subtitle: `${mo.machine_code} · ${mo.status}`,
      status: mo.status,
      referenceId: mo.id,
      route: {
        tab: 'Home',
        screen: 'MachineList',
      },
    });
  }

  for (const r of rework) {
    if (r.status === 'COMPLETED' || r.status === 'CANCELLED') continue;
    tasks.push({
      id: `rework-${r.id}`,
      category: 'Quality',
      title: r.rework_number,
      subtitle: `${r.product_code} · ${r.status}`,
      status: r.status,
      referenceId: r.id,
      quickAction: 'complete_rework',
      route: { tab: 'Home', screen: 'ReworkList' },
    });
  }

  for (const d of dispatches) {
    if (d.status !== 'READY') continue;
    tasks.push({
      id: `dispatch-${d.id}`,
      category: 'Dispatch',
      title: d.dispatch_number,
      subtitle: `${d.customer_name} · qty ${d.quantity}`,
      status: d.status,
      referenceId: d.id,
      quickAction: 'dispatch',
      route: { tab: 'Home', screen: 'Dispatch' },
    });
  }

  for (const m of breakdowns) {
    tasks.push({
      id: `machine-${m.id}`,
      category: 'Machines',
      title: m.code,
      subtitle: `${m.name} · BREAKDOWN`,
      status: 'BREAKDOWN',
      referenceId: m.id,
      route: {
        tab: 'Home',
        screen: 'MachineDetail',
        params: { machineId: m.id },
      },
    });
  }

  for (const mat of lowMaterials) {
    tasks.push({
      id: `material-${mat.id}`,
      category: 'Materials',
      title: mat.code,
      subtitle: `${mat.name} · stock ${mat.current_stock} ${mat.unit} (min ${mat.minimum_stock})`,
      status: 'SHORTAGE',
      referenceId: mat.id,
      route: {
        tab: 'Home',
        screen: 'MaterialDetail',
        params: { materialId: mat.id },
      },
    });
  }

  const rank = (t: ActionableTask) => {
    if (t.status === 'BREAKDOWN') return 0;
    if (t.category === 'Materials' && t.status === 'SHORTAGE') return 1;
    if (t.quickAction === 'dispatch') return 2;
    if (t.status === 'IN_PROGRESS' || t.status === 'OPEN') return 3;
    return 4;
  };

  return tasks.sort((a, b) => rank(a) - rank(b));
}

export async function countActionableTasks(): Promise<number> {
  const tasks = await listActionableTasks();
  return tasks.length;
}

