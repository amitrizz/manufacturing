import {
  achievementPct,
  availabilityPct,
  computeOee,
  performancePct,
  qualityRatePct,
} from '../../utils/calculations';
import { getDatabase } from '../client';
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
  const db = await getDatabase();

  const producedRow = await db.getFirstAsync<{ total: number }>(
    `SELECT COALESCE(SUM(good_quantity), 0) as total FROM production_entries
     WHERE entry_timestamp >= ? AND entry_timestamp <= ?`,
    start,
    end,
  );
  const targetRow = await db.getFirstAsync<{ total: number }>(
    `SELECT COALESCE(SUM(target_quantity), 0) as total FROM production_orders
     WHERE start_date >= ? AND start_date <= ?`,
    start,
    end,
  );

  const qualityRow = await db.getFirstAsync<{ passed: number; total: number }>(
    `SELECT
       COALESCE(SUM(quantity - rejected_quantity), 0) as passed,
       COALESCE(SUM(quantity), 0) as total
     FROM quality_inspections WHERE inspected_at >= ? AND inspected_at <= ?`,
    start,
    end,
  );

  const runtimeRow = await db.getFirstAsync<{ runtime: number; downtime: number }>(
    `SELECT COALESCE(SUM(runtime_seconds), 0) as runtime, COALESCE(SUM(downtime_seconds), 0) as downtime FROM machines`,
  );

  const downtimeRange = await db.getFirstAsync<{ seconds: number }>(
    `SELECT COALESCE(SUM(
       CASE WHEN end_time IS NOT NULL THEN (end_time - start_time) / 1000
       ELSE (? - start_time) / 1000 END
     ), 0) as seconds
     FROM machine_downtime WHERE start_time >= ? AND start_time <= ?`,
    end,
    start,
    end,
  );

  const statusRows = await db.getAllAsync<{ status: string; count: number }>(
    `SELECT status, COUNT(*) as count FROM machines GROUP BY status`,
  );
  const machineStatusCounts: Record<string, number> = {};
  for (const row of statusRows) {
    machineStatusCounts[row.status] = row.count;
  }

  const lineRows = await db.getAllAsync<{ line_code: string; produced: number }>(
    `SELECT pl.code as line_code, COALESCE(SUM(pe.good_quantity), 0) as produced
     FROM production_lines pl
     LEFT JOIN production_orders po ON po.line_id = pl.id
     LEFT JOIN production_entries pe ON pe.production_order_id = po.id
       AND pe.entry_timestamp >= ? AND pe.entry_timestamp <= ?
     GROUP BY pl.id ORDER BY pl.code`,
    start,
    end,
  );

  const totalLineProduced = lineRows.reduce((s, r) => s + r.produced, 0);
  const lineProgress = lineRows.map((r) => ({
    lineCode: r.line_code,
    produced: r.produced,
    pct: totalLineProduced > 0 ? (r.produced / totalLineProduced) * 100 : 0,
  }));

  const produced = producedRow?.total ?? 0;
  const target = targetRow?.total ?? 0;

  return {
    target,
    produced,
    achievement: achievementPct(produced, target),
    qualityRate: qualityRatePct(qualityRow?.passed ?? 0, qualityRow?.total ?? 0),
    machineAvailability: availabilityPct(
      runtimeRow?.runtime ?? 0,
      runtimeRow?.downtime ?? 0,
    ),
    downtimeHours: (downtimeRange?.seconds ?? 0) / 3600,
    machineStatusCounts,
    lineProgress,
  };
}

export async function getDashboardAlerts(): Promise<DashboardAlert[]> {
  const db = await getDatabase();
  const alerts: DashboardAlert[] = [];

  const lowStock = await listMaterials({ lowStockOnly: true });
  for (const m of lowStock.slice(0, 5)) {
    alerts.push({
      id: m.id,
      type: 'low_stock',
      title: 'Low stock',
      body: `${m.code} below minimum`,
      severity: 'WARNING',
    });
  }

  const delayed = await db.getAllAsync<{ id: string; order_number: string }>(
    `SELECT id, order_number FROM production_orders
     WHERE status = 'IN_PROGRESS' AND due_date < ?`,
    Date.now(),
  );
  for (const d of delayed) {
    alerts.push({
      id: d.id,
      type: 'delayed_po',
      title: 'Delayed order',
      body: d.order_number,
      severity: 'CRITICAL',
    });
  }

  const maintDue = await db.getAllAsync<{ id: string; code: string }>(
    `SELECT id, code FROM machines WHERE next_maintenance_at IS NOT NULL AND next_maintenance_at <= ?`,
    Date.now() + 7 * 24 * 60 * 60 * 1000,
  );
  for (const m of maintDue.slice(0, 3)) {
    alerts.push({
      id: m.id,
      type: 'maintenance_due',
      title: 'Maintenance due',
      body: m.code,
      severity: 'INFO',
    });
  }

  const pendingInsp = await db.getAllAsync<{ id: string; order_number: string }>(
    `SELECT po.id, po.order_number FROM production_orders po
     LEFT JOIN quality_inspections qi ON qi.production_order_id = po.id
     WHERE po.status = 'COMPLETED' AND qi.id IS NULL AND po.completed_at >= ?`,
    Date.now() - 14 * 24 * 60 * 60 * 1000,
  );
  for (const p of pendingInsp.slice(0, 3)) {
    alerts.push({
      id: p.id,
      type: 'pending_inspection',
      title: 'Pending inspection',
      body: p.order_number,
      severity: 'WARNING',
    });
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
  const db = await getDatabase();

  switch (type) {
    case 'production':
      return db.getAllAsync(
        `SELECT po.order_number, p.code as product, pl.code as line,
                po.target_quantity, po.produced_quantity, po.status, po.start_date
         FROM production_orders po
         JOIN products p ON p.id = po.product_id
         JOIN production_lines pl ON pl.id = po.line_id
         WHERE po.start_date >= ? AND po.start_date <= ?`,
        start,
        end,
      );
    case 'quality':
      return db.getAllAsync(
        `SELECT batch_number, overall_result, quantity, rejected_quantity, inspected_at
         FROM quality_inspections WHERE inspected_at >= ? AND inspected_at <= ?`,
        start,
        end,
      );
    case 'downtime':
      return db.getAllAsync(
        `SELECT m.code as machine, md.reason, md.start_time, md.end_time, md.description
         FROM machine_downtime md JOIN machines m ON m.id = md.machine_id
         WHERE md.start_time >= ? AND md.start_time <= ?`,
        start,
        end,
      );
    case 'maintenance':
      return db.getAllAsync(
        `SELECT mo.order_number, m.code as machine, mo.type, mo.status, mo.created_at, mo.completed_at
         FROM maintenance_orders mo JOIN machines m ON m.id = mo.machine_id
         WHERE mo.created_at >= ? AND mo.created_at <= ?`,
        start,
        end,
      );
    case 'materials':
      return db.getAllAsync(
        `SELECT code, name, category, current_stock, minimum_stock, maximum_stock FROM materials`,
      );
    case 'finished_goods':
      return db.getAllAsync(
        `SELECT p.code, fg.produced_quantity, fg.quality_passed_quantity, fg.available_quantity
         FROM finished_goods fg JOIN products p ON p.id = fg.product_id`,
      );
    case 'dispatch':
      return db.getAllAsync(
        `SELECT dispatch_number, customer_name, quantity, status, created_at, dispatched_at
         FROM dispatch_orders WHERE created_at >= ? AND created_at <= ?`,
        start,
        end,
      );
    case 'oee_summary':
      return getOeeReportRows();
    case 'attendance': {
      const startDateStr = new Date(start).toISOString().slice(0, 10);
      const endDateStr = new Date(end).toISOString().slice(0, 10);
      return db.getAllAsync(
        `SELECT a.date, s.employee_id, s.name as staff_name, s.role, a.shift, a.status, a.overtime_hours,
                datetime(a.created_at/1000, 'unixepoch', 'localtime') as marked_time, a.notes
         FROM staff_attendance a
         JOIN staff s ON a.staff_id = s.id
         WHERE a.date >= ? AND a.date <= ?
         ORDER BY a.date DESC, s.employee_id ASC`,
        startDateStr,
        endDateStr,
      );
    }
    default:
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
  const db = await getDatabase();
  const machines = await db.getAllAsync<{
    id: string;
    code: string;
    runtime_seconds: number;
    downtime_seconds: number;
  }>('SELECT id, code, runtime_seconds, downtime_seconds FROM machines');

  const rows: OeeRow[] = [];
  for (const m of machines) {
    const output = await db.getFirstAsync<{ good: number; reject: number }>(
      `SELECT COALESCE(SUM(good_quantity),0) as good, COALESCE(SUM(rejected_quantity),0) as reject
       FROM production_entries WHERE machine_id = ?`,
      m.id,
    );
    const good = output?.good ?? 0;
    const reject = output?.reject ?? 0;
    const hours = m.runtime_seconds / 3600;
    const idealRate = hours > 0 ? good / hours : good || 1;
    const expected = idealRate * hours;
    const avail = availabilityPct(m.runtime_seconds, m.downtime_seconds);
    const perf = performancePct(good, expected);
    const qual = qualityRatePct(good, good + reject);
    const oee = computeOee(
      m.runtime_seconds,
      m.downtime_seconds,
      good,
      expected,
      good,
      reject,
    );
    rows.push({
      machine_code: m.code,
      availability: avail,
      performance: perf,
      quality: qual,
      oee,
    });
  }
  return rows;
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
  const db = await getDatabase();
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

    const [prodRow, ordersRow, machineRows] = await Promise.all([
      db.getFirstAsync<{ total: number }>(
        `SELECT COALESCE(SUM(good_quantity), 0) as total FROM production_entries
         WHERE entry_timestamp >= ? AND entry_timestamp <= ?`,
        startTs,
        endTs,
      ),
      db.getFirstAsync<{ count: number }>(
        `SELECT COUNT(*) as count FROM production_orders
         WHERE start_date >= ? AND start_date <= ?`,
        startTs,
        endTs,
      ),
      db.getAllAsync<{
        machineId: string;
        machineCode: string;
        machineName: string;
        machineType: string;
        status: string;
        itemsProduced: number;
        rejectedCount: number;
        entriesCount: number;
      }>(
        `SELECT 
           m.id as machineId,
           m.code as machineCode,
           m.name as machineName,
           m.machine_type as machineType,
           m.status as status,
           COALESCE(SUM(pe.good_quantity), 0) as itemsProduced,
           COALESCE(SUM(pe.rejected_quantity), 0) as rejectedCount,
           COUNT(pe.id) as entriesCount
         FROM machines m
         LEFT JOIN production_entries pe ON pe.machine_id = m.id
           AND pe.entry_timestamp >= ? AND pe.entry_timestamp <= ?
         GROUP BY m.id
         ORDER BY itemsProduced DESC, m.code ASC`,
        startTs,
        endTs,
      ),
    ]);

    const produced = prodRow?.total ?? 0;
    const ordersCount = ordersRow?.count ?? 0;
    const machinesBreakdown: MachineMonthlyOutput[] = (machineRows ?? []).map((m) => ({
      machineId: m.machineId,
      machineCode: m.machineCode,
      machineName: m.machineName,
      machineType: m.machineType,
      status: m.status,
      itemsProduced: m.itemsProduced,
      rejectedCount: m.rejectedCount,
      entriesCount: m.entriesCount,
      pctOfTotal: produced > 0 ? Math.round((m.itemsProduced / produced) * 100) : 0,
    }));

    results.push({
      monthKey,
      monthLabel,
      monthFull,
      year: d.getFullYear(),
      produced,
      ordersCount,
      machinesBreakdown,
    });
  }

  return results;
}
