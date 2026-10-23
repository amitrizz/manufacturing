import {
  achievementPct,
  availabilityPct,
  computeOee,
  performancePct,
  qualityRatePct,
} from '../../utils/calculations';
import { mongoApi } from '../client';
import { listMaterials } from './materialRepository';
import { listNotifications } from './notificationRepository';

export type DashboardKpis = {
  target: number;
  produced: number;
  achievement: number;
  qualityRate: number;
  machineAvailability: number;
  downtimeHours: number;
  machineStatusCounts: Record<string, number>;
  lineProgress: { lineCode: string; produced: number; pct: number }[];
};

export type DashboardAlert = {
  id: string;
  type: string;
  title: string;
  body: string;
  severity: string;
};

export async function getDashboardKpis(start: number, end: number): Promise<DashboardKpis> {
  try {
    const stats = await mongoApi.getDashboardStats();
    if (stats && stats.kpis) {
      return {
        target: stats.kpis.target || 0,
        produced: stats.kpis.produced || 0,
        achievement: stats.kpis.achievement || 0,
        qualityRate: stats.kpis.qualityRate || 0,
        machineAvailability: stats.kpis.machineAvailability || 0,
        downtimeHours: stats.kpis.downtimeHours || 0,
        machineStatusCounts: stats.kpis.machineStatusCounts || {},
        lineProgress: (stats.kpis.lineProgress || []).map((lp) => ({
          lineCode: lp.lineCode,
          produced: lp.produced,
          pct: lp.pct,
        })),
      };
    }
  } catch (err) {
    console.warn('MongoDB getDashboardStats error, calculating locally from collections:', err);
  }

  // Local calculation from MongoDB collections if backend endpoint is unavailable
  try {
    const [entries, orders, inspections, machines, downtime, lines] = await Promise.all([
      mongoApi.getCollection<any>('production_entries').catch(() => []),
      mongoApi.getCollection<any>('production_orders').catch(() => []),
      mongoApi.getCollection<any>('quality_inspections').catch(() => []),
      mongoApi.getCollection<any>('machines').catch(() => []),
      mongoApi.getCollection<any>('machine_downtime').catch(() => []),
      mongoApi.getCollection<any>('production_lines').catch(() => []),
    ]);

    const filteredEntries = entries.filter(
      (e) => (e.entry_timestamp || e.created_at || 0) >= start && (e.entry_timestamp || e.created_at || 0) <= end
    );
    const produced = filteredEntries.reduce((s, e) => s + Number(e.good_quantity ?? 0), 0);

    const filteredOrders = orders.filter(
      (o) => (o.start_date || o.created_at || 0) >= start && (o.start_date || o.created_at || 0) <= end
    );
    const target = filteredOrders.reduce((s, o) => s + Number(o.target_quantity ?? 0), 0);

    const filteredInsp = inspections.filter(
      (i) => (i.inspected_at || i.created_at || 0) >= start && (i.inspected_at || i.created_at || 0) <= end
    );
    let passedInsp = 0;
    let totalInsp = 0;
    for (const i of filteredInsp) {
      totalInsp += Number(i.quantity ?? 0);
      passedInsp += Math.max(0, Number(i.quantity ?? 0) - Number(i.rejected_quantity ?? 0));
    }

    const machineStatusCounts: Record<string, number> = {};
    let totalRuntime = 0;
    let totalDowntime = 0;
    for (const m of machines) {
      const st = m.status || 'IDLE';
      machineStatusCounts[st] = (machineStatusCounts[st] || 0) + 1;
      totalRuntime += Number(m.runtime_seconds || 0);
      totalDowntime += Number(m.downtime_seconds || 0);
    }

    let rangeDowntimeSeconds = 0;
    for (const d of downtime) {
      const st = d.start_time || d.created_at || 0;
      if (st >= start && st <= end) {
        const et = d.end_time || end;
        rangeDowntimeSeconds += Math.max(0, (et - st) / 1000);
      }
    }

    const lineMap = new Map(lines.map((l) => [l.id || l._id, l.code]));
    const orderLineMap = new Map(orders.map((o) => [o.id || o._id, o.line_id]));
    const lineProducedMap = new Map<string, number>();

    for (const e of filteredEntries) {
      const lineId = orderLineMap.get(e.production_order_id);
      const lineCode = (lineId ? lineMap.get(lineId) : null) || 'Unknown';
      lineProducedMap.set(lineCode, (lineProducedMap.get(lineCode) || 0) + Number(e.good_quantity ?? 0));
    }

    const totalLineProduced = Array.from(lineProducedMap.values()).reduce((s, v) => s + v, 0);
    const lineProgress = Array.from(lineProducedMap.entries()).map(([code, p]) => ({
      lineCode: code,
      produced: p,
      pct: totalLineProduced > 0 ? (p / totalLineProduced) * 100 : 0,
    }));

    return {
      target,
      produced,
      achievement: achievementPct(produced, target),
      qualityRate: qualityRatePct(passedInsp, totalInsp),
      machineAvailability: availabilityPct(totalRuntime, totalDowntime),
      downtimeHours: Math.round((rangeDowntimeSeconds / 3600) * 10) / 10,
      machineStatusCounts,
      lineProgress,
    };
  } catch (err) {
    console.warn('Dashboard KPI calculation fallback error:', err);
    return {
      target: 0,
      produced: 0,
      achievement: 0,
      qualityRate: 0,
      machineAvailability: 0,
      downtimeHours: 0,
      machineStatusCounts: {},
      lineProgress: [],
    };
  }
}

export async function getDashboardAlerts(): Promise<DashboardAlert[]> {
  const alerts: DashboardAlert[] = [];

  try {
    const [materials, orders, machines] = await Promise.all([
      listMaterials(),
      mongoApi.getCollection<any>('production_orders').catch(() => []),
      mongoApi.getCollection<any>('machines').catch(() => []),
    ]);

    // Low stock alerts
    const lowStock = materials.filter((m) => (m.current_stock ?? 0) <= (m.minimum_stock ?? 0));
    for (const m of lowStock.slice(0, 3)) {
      alerts.push({
        id: `stock-${m.id}`,
        type: 'low_stock',
        title: 'Low stock warning',
        body: `${m.name} (${m.code})`,
        severity: 'WARNING',
      });
    }

    // Delayed orders
    const now = Date.now();
    const delayed = orders.filter(
      (o) => o.status === 'IN_PROGRESS' && o.due_date && o.due_date < now
    );
    for (const d of delayed.slice(0, 3)) {
      alerts.push({
        id: `delay-${d.id || d._id}`,
        type: 'delayed_order',
        title: 'Production delayed',
        body: d.order_number || 'Order delayed',
        severity: 'CRITICAL',
      });
    }

    // Maintenance due machines
    const maintDue = machines.filter(
      (m) => m.next_maintenance_at && m.next_maintenance_at <= now + 7 * 24 * 60 * 60 * 1000
    );
    for (const m of maintDue.slice(0, 3)) {
      alerts.push({
        id: `maint-${m.id || m._id}`,
        type: 'maintenance_due',
        title: 'Maintenance due',
        body: `${m.name || m.code}`,
        severity: 'INFO',
      });
    }
  } catch (err) {
    console.warn('getDashboardAlerts error:', err);
  }

  return alerts;
}

export type ReportType =
  | 'production'
  | 'quality'
  | 'downtime'
  | 'maintenance'
  | 'materials'
  | 'finished_goods'
  | 'dispatch'
  | 'oee_summary'
  | 'attendance';

export async function getReportData(
  type: ReportType,
  start: number,
  end: number,
): Promise<Record<string, unknown>[]> {
  try {
    switch (type) {
      case 'production': {
        const [orders, products, lines] = await Promise.all([
          mongoApi.getCollection<any>('production_orders'),
          mongoApi.getCollection<any>('products'),
          mongoApi.getCollection<any>('production_lines'),
        ]);
        const prodMap = new Map(products.map((p) => [p.id || p._id, p.code]));
        const lineMap = new Map(lines.map((l) => [l.id || l._id, l.code]));

        return orders
          .filter((o) => (o.start_date || o.created_at || 0) >= start && (o.start_date || o.created_at || 0) <= end)
          .map((o) => ({
            order_number: o.order_number,
            product: prodMap.get(o.product_id) || '',
            line: lineMap.get(o.line_id) || '',
            target_quantity: o.target_quantity,
            produced_quantity: o.produced_quantity,
            status: o.status,
            start_date: o.start_date,
          }));
      }

      case 'quality': {
        const inspections = await mongoApi.getCollection<any>('quality_inspections');
        return inspections
          .filter((i) => (i.inspected_at || i.created_at || 0) >= start && (i.inspected_at || i.created_at || 0) <= end)
          .map((i) => ({
            batch_number: i.batch_number,
            overall_result: i.result,
            quantity: i.quantity,
            rejected_quantity: i.rejected_quantity,
            inspected_at: i.inspected_at,
          }));
      }

      case 'downtime': {
        const [downtimes, machines] = await Promise.all([
          mongoApi.getCollection<any>('machine_downtime'),
          mongoApi.getCollection<any>('machines'),
        ]);
        const machMap = new Map(machines.map((m) => [m.id || m._id, m.code]));
        return downtimes
          .filter((d) => (d.start_time || d.created_at || 0) >= start && (d.start_time || d.created_at || 0) <= end)
          .map((d) => ({
            machine: machMap.get(d.machine_id) || '',
            reason: d.reason,
            start_time: d.start_time,
            end_time: d.end_time,
            description: d.description || '',
          }));
      }

      case 'maintenance': {
        const [orders, machines] = await Promise.all([
          mongoApi.getCollection<any>('maintenance_orders'),
          mongoApi.getCollection<any>('machines'),
        ]);
        const machMap = new Map(machines.map((m) => [m.id || m._id, m.code]));
        return orders
          .filter((o) => (o.created_at || 0) >= start && (o.created_at || 0) <= end)
          .map((o) => ({
            order_number: o.order_number,
            machine: machMap.get(o.machine_id) || '',
            type: o.type,
            status: o.status,
            created_at: o.created_at,
            completed_at: o.completed_at,
          }));
      }

      case 'materials': {
        const materials = await mongoApi.getCollection<any>('materials');
        return materials.map((m) => ({
          code: m.code,
          name: m.name,
          category: m.category,
          current_stock: m.current_stock,
          minimum_stock: m.minimum_stock,
          maximum_stock: m.maximum_stock,
        }));
      }

      case 'finished_goods': {
        const [fgList, products] = await Promise.all([
          mongoApi.getCollection<any>('finished_goods'),
          mongoApi.getCollection<any>('products'),
        ]);
        const prodMap = new Map(products.map((p) => [p.id || p._id, p.code]));
        return fgList.map((fg) => ({
          code: prodMap.get(fg.product_id) || '',
          produced_quantity: fg.produced_quantity,
          quality_passed_quantity: fg.quality_passed_quantity,
          available_quantity: fg.available_quantity,
        }));
      }

      case 'dispatch': {
        const dispatches = await mongoApi.getCollection<any>('dispatch_orders');
        return dispatches
          .filter((d) => (d.created_at || 0) >= start && (d.created_at || 0) <= end)
          .map((d) => ({
            dispatch_number: d.dispatch_number,
            customer_name: d.customer_name,
            quantity: d.quantity,
            status: d.status,
            created_at: d.created_at,
            dispatched_at: d.dispatched_at,
          }));
      }

      case 'oee_summary': {
        return await getOeeReportRows();
      }

      case 'attendance': {
        const [attendance, staff] = await Promise.all([
          mongoApi.getCollection<any>('staff_attendance'),
          mongoApi.getCollection<any>('staff'),
        ]);
        const staffMap = new Map(staff.map((s) => [s.id || s._id, s]));
        const startDateStr = new Date(start).toISOString().slice(0, 10);
        const endDateStr = new Date(end).toISOString().slice(0, 10);

        return attendance
          .filter((a) => (a.date >= startDateStr && a.date <= endDateStr))
          .map((a) => {
            const s = staffMap.get(a.staff_id);
            return {
              date: a.date,
              employee_id: s?.employee_id || '',
              staff_name: s?.name || '',
              role: s?.role || '',
              shift: a.shift,
              status: a.status,
              overtime_hours: a.overtime_hours || 0,
              marked_time: a.created_at ? new Date(a.created_at).toLocaleString() : '',
              notes: a.notes || '',
            };
          })
          .sort((a, b) => (b.date || '').localeCompare(a.date || ''));
      }

      default:
        return [];
    }
  } catch (err) {
    console.warn(`getReportData(${type}) error:`, err);
    return [];
  }
}

export type OeeRow = {
  machine_code: string;
  availability: number;
  performance: number;
  quality: number;
  oee: number;
};

async function getOeeReportRows(): Promise<OeeRow[]> {
  try {
    const [machines, entries] = await Promise.all([
      mongoApi.getCollection<any>('machines'),
      mongoApi.getCollection<any>('production_entries'),
    ]);

    const entriesByMachine = new Map<string, { good: number; reject: number }>();
    for (const e of entries) {
      const cur = entriesByMachine.get(e.machine_id) || { good: 0, reject: 0 };
      cur.good += Number(e.good_quantity ?? 0);
      cur.reject += Number(e.rejected_quantity ?? 0);
      entriesByMachine.set(e.machine_id, cur);
    }

    const rows: OeeRow[] = [];
    for (const m of machines) {
      const mId = m.id || m._id;
      const counts = entriesByMachine.get(mId) || { good: 0, reject: 0 };
      const runtime = Number(m.runtime_seconds || 0);
      const downtime = Number(m.downtime_seconds || 0);
      const good = counts.good;
      const reject = counts.reject;
      const hours = runtime / 3600;
      const idealRate = hours > 0 ? good / hours : good || 1;
      const expected = idealRate * hours;
      const avail = availabilityPct(runtime, downtime);
      const perf = performancePct(good, expected);
      const qual = qualityRatePct(good, good + reject);
      const oee = computeOee(runtime, downtime, good, expected, good, reject);

      rows.push({
        machine_code: m.code,
        availability: avail,
        performance: perf,
        quality: qual,
        oee,
      });
    }
    return rows;
  } catch (err) {
    console.warn('getOeeReportRows error:', err);
    return [];
  }
}

export async function getUnreadNotificationCount(): Promise<number> {
  const items = await listNotifications(true);
  return items.length;
}

export type MachineMonthlyOutput = {
  machineId: string;
  machineCode: string;
  machineName: string;
  machineType: string;
  status: string;
  itemsProduced: number;
  rejectedCount: number;
  entriesCount: number;
  pctOfTotal: number;
};

export type MonthlyComparisonRow = {
  monthKey: string;
  monthLabel: string;
  monthFull: string;
  year: number;
  produced: number;
  ordersCount: number;
  machinesBreakdown: MachineMonthlyOutput[];
};

export async function getMonthlyProductionComparison(monthsCount = 6): Promise<MonthlyComparisonRow[]> {
  try {
    const stats = await mongoApi.getDashboardStats();
    if (stats && Array.isArray(stats.monthlyData)) {
      const [machines, entries, orders] = await Promise.all([
        mongoApi.getCollection<any>('machines').catch(() => []),
        mongoApi.getCollection<any>('production_entries').catch(() => []),
        mongoApi.getCollection<any>('production_orders').catch(() => []),
      ]);

      const now = new Date();
      const results: MonthlyComparisonRow[] = [];

      for (let i = monthsCount - 1; i >= 0; i--) {
        const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const startTs = new Date(d.getFullYear(), d.getMonth(), 1, 0, 0, 0, 0).getTime();
        const endTs = new Date(d.getFullYear(), d.getMonth() + 1, 0, 23, 59, 59, 999).getTime();

        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const monthLabel = monthNames[d.getMonth()];
        const monthFull = `${monthLabel} ${d.getFullYear()}`;
        const monthKey = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;

        const monthEntries = entries.filter((e) => {
          const ts = e.entry_timestamp || e.created_at || 0;
          return ts >= startTs && ts <= endTs;
        });

        const monthOrders = orders.filter((o) => {
          const ts = o.start_date || o.created_at || 0;
          return ts >= startTs && ts <= endTs;
        });

        const totalMonthProduced = monthEntries.reduce((s, e) => s + Number(e.good_quantity ?? 0), 0);

        const machineMap = new Map<string, { good: number; reject: number; count: number }>();
        for (const e of monthEntries) {
          const cur = machineMap.get(e.machine_id) || { good: 0, reject: 0, count: 0 };
          cur.good += Number(e.good_quantity ?? 0);
          cur.reject += Number(e.rejected_quantity ?? 0);
          cur.count += 1;
          machineMap.set(e.machine_id, cur);
        }

        const machinesBreakdown: MachineMonthlyOutput[] = machines.map((m) => {
          const mId = m.id || m._id;
          const stats = machineMap.get(mId) || { good: 0, reject: 0, count: 0 };
          return {
            machineId: mId,
            machineCode: m.code,
            machineName: m.name,
            machineType: m.machine_type || 'General',
            status: m.status || 'IDLE',
            itemsProduced: stats.good,
            rejectedCount: stats.reject,
            entriesCount: stats.count,
            pctOfTotal: totalMonthProduced > 0 ? (stats.good / totalMonthProduced) * 100 : 0,
          };
        });

        results.push({
          monthKey,
          monthLabel,
          monthFull,
          year: d.getFullYear(),
          produced: totalMonthProduced,
          ordersCount: monthOrders.length,
          machinesBreakdown,
        });
      }

      return results;
    }
  } catch (err) {
    console.warn('getMonthlyProductionComparison error:', err);
  }

  return [];
}
