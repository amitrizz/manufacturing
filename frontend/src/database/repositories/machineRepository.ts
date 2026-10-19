import type {
  ActiveOperatorAssignment,
  MachineOperatorEntry,
  MachineOperatorSummary,
  MachineRow,
  MachineStatus,
  OperatorMachineSummary,
  ShiftAssignmentInfo,
} from '../../types/database';
import { getDatabase } from '../client';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { startOfDay } from '../../utils/dateRange';
import { mongoApi } from '../../api/client';

export type MachineFilters = {
  status?: MachineStatus;
  lineId?: string;
  search?: string;
};

export async function listMachines(filters: MachineFilters = {}): Promise<MachineRow[]> {
  try {
    const remote = await mongoApi.listMachines(filters);
    if (remote && Array.isArray(remote)) {
      return remote as MachineRow[];
    }
  } catch {
    // Fallback if backend temporarily offline
  }

  const db = await getDatabase();
  const clauses: string[] = [];
  const params: (string | number)[] = [];

  if (filters.status) {
    clauses.push('m.status = ?');
    params.push(filters.status);
  }
  if (filters.lineId) {
    clauses.push('m.line_id = ?');
    params.push(filters.lineId);
  }
  if (filters.search) {
    clauses.push('(m.name LIKE ? OR m.code LIKE ?)');
    const q = `%${filters.search}%`;
    params.push(q, q);
  }

  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
  return db.getAllAsync<MachineRow>(
    `SELECT m.*, pl.code as line_code, pl.name as line_name, p.code as product_code
     FROM machines m
     JOIN production_lines pl ON pl.id = m.line_id
     LEFT JOIN products p ON p.id = m.current_product_id
     ${where}
     ORDER BY pl.code, m.code`,
    ...params,
  );
}

export async function getMachineById(id: string): Promise<MachineRow | null> {
  try {
    const remote = await mongoApi.getById<MachineRow>('machines', id);
    if (remote) return remote;
  } catch {
    // Fallback
  }

  const db = await getDatabase();
  return db.getFirstAsync<MachineRow>(
    `SELECT m.*, pl.code as line_code, pl.name as line_name, p.code as product_code
     FROM machines m
     JOIN production_lines pl ON pl.id = m.line_id
     LEFT JOIN products p ON p.id = m.current_product_id
     WHERE m.id = ?`,
    id,
  );
}

export type MachineProductionTotals = {
  allTimeProduced: number;
  allTimeRejected: number;
  activeOrderNumber: string | null;
  activeProductCode: string | null;
  activeProductName: string | null;
  activeTargetQuantity: number | null;
  activeProducedQuantity: number | null;
};

export async function getMachineProductionTotals(machineId: string): Promise<MachineProductionTotals> {
  const db = await getDatabase();
  const totals = await db.getFirstAsync<{ total_good: number; total_rejected: number }>(
    `SELECT COALESCE(SUM(good_quantity), 0) as total_good,
            COALESCE(SUM(rejected_quantity), 0) as total_rejected
     FROM production_entries
     WHERE machine_id = ?`,
    machineId,
  );

  const activeOrder = await db.getFirstAsync<{
    order_number: string;
    product_code: string;
    product_name: string;
    target_quantity: number;
    produced_quantity: number;
  }>(
    `SELECT po.order_number, p.code as product_code, p.name as product_name,
            po.target_quantity, po.produced_quantity
     FROM production_orders po
     LEFT JOIN products p ON p.id = po.product_id
     WHERE po.machine_id = ? AND po.status = 'IN_PROGRESS'
     ORDER BY po.updated_at DESC LIMIT 1`,
    machineId,
  );

  return {
    allTimeProduced: totals?.total_good || 0,
    allTimeRejected: totals?.total_rejected || 0,
    activeOrderNumber: activeOrder?.order_number || null,
    activeProductCode: activeOrder?.product_code || null,
    activeProductName: activeOrder?.product_name || null,
    activeTargetQuantity: activeOrder?.target_quantity || null,
    activeProducedQuantity: activeOrder?.produced_quantity || null,
  };
}

export async function listLines(): Promise<
  { id: string; code: string; name: string }[]
> {
  const db = await getDatabase();
  return db.getAllAsync('SELECT id, code, name FROM production_lines ORDER BY code');
}

export type CreateLineInput = {
  code: string;
  name: string;
  factory_id?: string;
};

export async function createLine(input: CreateLineInput): Promise<string> {
  const db = await getDatabase();
  const id = newId();
  let factoryId = input.factory_id;
  if (!factoryId) {
    const f = await db.getFirstAsync<{ id: string }>('SELECT id FROM factories LIMIT 1');
    factoryId = f?.id;
    if (!factoryId) {
      factoryId = newId();
      await db.runAsync(
        'INSERT INTO factories (id, name, code, location) VALUES (?, ?, ?, ?)',
        factoryId,
        'Main Plant',
        'PLANT-01',
        'HQ',
      );
    }
  }

  await db.runAsync(
    'INSERT INTO production_lines (id, factory_id, code, name) VALUES (?, ?, ?, ?)',
    id,
    factoryId,
    input.code.trim().toUpperCase(),
    input.name.trim(),
  );

  notifyDataChanged();
  return id;
}

export async function updateLine(
  id: string,
  input: { code?: string; name?: string },
): Promise<void> {
  const db = await getDatabase();
  const existing = await db.getFirstAsync<{ id: string }>(
    'SELECT id FROM production_lines WHERE id = ?',
    id,
  );
  if (!existing) throw new Error('Production line not found');

  const updates: string[] = [];
  const params: string[] = [];
  if (input.code) {
    updates.push('code = ?');
    params.push(input.code.trim().toUpperCase());
  }
  if (input.name) {
    updates.push('name = ?');
    params.push(input.name.trim());
  }
  if (updates.length > 0) {
    params.push(id);
    await db.runAsync(
      `UPDATE production_lines SET ${updates.join(', ')} WHERE id = ?`,
      ...params,
    );
    notifyDataChanged();
  }
}

export async function deleteLine(id: string): Promise<void> {
  const db = await getDatabase();
  const machineCount = await db.getFirstAsync<{ count: number }>(
    'SELECT COUNT(*) as count FROM machines WHERE line_id = ?',
    id,
  );
  if (machineCount && machineCount.count > 0) {
    throw new Error(
      `Cannot delete line: ${machineCount.count} machine(s) are assigned to this line. Reassign them first.`,
    );
  }
  const orderCount = await db.getFirstAsync<{ count: number }>(
    'SELECT COUNT(*) as count FROM production_orders WHERE line_id = ?',
    id,
  );
  if (orderCount && orderCount.count > 0) {
    throw new Error(
      `Cannot delete line: ${orderCount.count} production order(s) are linked to this line.`,
    );
  }

  await db.runAsync('DELETE FROM production_lines WHERE id = ?', id);
  notifyDataChanged();
}

export async function searchMachines(query: string, limit = 20): Promise<MachineRow[]> {
  return listMachines({ search: query }).then((r) => r.slice(0, limit));
}

export type OperatorPeriodFilter = {
  startDate?: number;
  endDate?: number;
  search?: string;
};

export async function listMachineOperatorSummaries(
  filters: OperatorPeriodFilter = {},
): Promise<MachineOperatorSummary[]> {
  const db = await getDatabase();
  const machines = await listMachines({ search: filters.search });

  const clauses: string[] = [];
  const params: (string | number)[] = [];

  if (filters.startDate !== undefined) {
    clauses.push('pe.entry_timestamp >= ?');
    params.push(filters.startDate);
  }
  if (filters.endDate !== undefined) {
    clauses.push('pe.entry_timestamp <= ?');
    params.push(filters.endDate);
  }

  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';

  const entries = await db.getAllAsync<MachineOperatorEntry>(
    `SELECT pe.id, pe.machine_id, m.code as machine_code, m.name as machine_name,
            m.status as machine_status, pl.code as line_code, pe.operator, pe.shift,
            pe.good_quantity, pe.rejected_quantity, pe.entry_timestamp,
            po.order_number, p.code as product_code, p.name as product_name
     FROM production_entries pe
     JOIN machines m ON m.id = pe.machine_id
     JOIN production_lines pl ON pl.id = m.line_id
     JOIN production_orders po ON po.id = pe.production_order_id
     LEFT JOIN products p ON p.id = po.product_id
     ${where}
     ORDER BY pe.entry_timestamp DESC`,
    ...params,
  );

  // Group entries by machine_id
  const entriesByMachine = new Map<string, MachineOperatorEntry[]>();
  for (const entry of entries) {
    const list = entriesByMachine.get(entry.machine_id) || [];
    list.push(entry);
    entriesByMachine.set(entry.machine_id, list);
  }

  // Also query latest entries per machine & shift across all time as fallback for unworked shifts
  const allLatestShiftEntries = await db.getAllAsync<{
    machine_id: string;
    shift: string;
    operator: string;
    entry_timestamp: number;
  }>(
    `SELECT machine_id, shift, operator, entry_timestamp
     FROM production_entries
     WHERE operator IS NOT NULL AND operator != ''
     ORDER BY entry_timestamp DESC`
  );
  const latestByMachineShift = new Map<string, { operator: string; entry_timestamp: number }>();
  for (const row of allLatestShiftEntries) {
    const key = `${row.machine_id}_${row.shift}`;
    if (!latestByMachineShift.has(key)) {
      latestByMachineShift.set(key, { operator: row.operator, entry_timestamp: row.entry_timestamp });
    }
  }

  return machines.map((m) => {
    const machineEntries = entriesByMachine.get(m.id) || [];
    let totalProduced = 0;
    let totalRejected = 0;
    const operatorMap = new Map<string, {
      name: string;
      shift: string;
      produced: number;
      rejected: number;
      last_seen: number;
      order_number: string;
    }>();

    const shiftMap = new Map<'Morning' | 'Evening' | 'Night', {
      operator: string | null;
      total_produced: number;
      last_active_at: number | null;
    }>([
      ['Morning', { operator: null, total_produced: 0, last_active_at: null }],
      ['Evening', { operator: null, total_produced: 0, last_active_at: null }],
      ['Night', { operator: null, total_produced: 0, last_active_at: null }],
    ]);

    for (const e of machineEntries) {
      totalProduced += e.good_quantity;
      totalRejected += e.rejected_quantity;
      const opName = e.operator || 'Unassigned Worker';
      const existing = operatorMap.get(opName);
      if (existing) {
        existing.produced += e.good_quantity;
        existing.rejected += e.rejected_quantity;
        if (e.entry_timestamp > existing.last_seen) {
          existing.last_seen = e.entry_timestamp;
          existing.shift = e.shift;
          existing.order_number = e.order_number;
        }
      } else {
        operatorMap.set(opName, {
          name: opName,
          shift: e.shift,
          produced: e.good_quantity,
          rejected: e.rejected_quantity,
          last_seen: e.entry_timestamp,
          order_number: e.order_number,
        });
      }

      const rawShift = (e.shift || '').trim();
      const sKey = (
        rawShift === 'Evening' || rawShift === 'B'
          ? 'Evening'
          : rawShift === 'Night' || rawShift === 'C'
            ? 'Night'
            : 'Morning'
      ) as 'Morning' | 'Evening' | 'Night';
      const sData = shiftMap.get(sKey)!;
      sData.total_produced += e.good_quantity;
      if (!sData.operator && e.operator) {
        sData.operator = e.operator;
        sData.last_active_at = e.entry_timestamp;
      }
    }

    const shift_assignments: ShiftAssignmentInfo[] = (['Morning', 'Evening', 'Night'] as const).map(
      (sh) => {
        const data = shiftMap.get(sh)!;
        let op = data.operator;
        let lastSeen = data.last_active_at;
        if (!op) {
          const fallback = latestByMachineShift.get(`${m.id}_${sh}`);
          if (fallback) {
            op = fallback.operator;
            lastSeen = fallback.entry_timestamp;
          }
        }
        return {
          shift: sh,
          operator: op,
          total_produced: data.total_produced,
          last_active_at: lastSeen,
        };
      },
    );

    const latestEntry = machineEntries[0]; // Ordered by entry_timestamp DESC

    return {
      machine_id: m.id,
      machine_code: m.code,
      machine_name: m.name,
      machine_status: m.status,
      machine_type: m.machine_type || 'General',
      line_id: m.line_id,
      line_code: m.line_code || '',
      line_name: m.line_name || '',
      current_operator: latestEntry?.operator || null,
      current_shift: latestEntry?.shift || null,
      current_product: latestEntry?.product_code || m.product_code || null,
      last_active_at: latestEntry?.entry_timestamp || null,
      total_produced: totalProduced,
      total_rejected: totalRejected,
      shift_assignments,
      operators: Array.from(operatorMap.values()).sort((a, b) => b.last_seen - a.last_seen),
    };
  });
}

export async function listOperatorMachineSummaries(
  filters: OperatorPeriodFilter = {},
): Promise<OperatorMachineSummary[]> {
  const db = await getDatabase();
  const clauses: string[] = [];
  const params: (string | number)[] = [];

  if (filters.startDate !== undefined) {
    clauses.push('pe.entry_timestamp >= ?');
    params.push(filters.startDate);
  }
  if (filters.endDate !== undefined) {
    clauses.push('pe.entry_timestamp <= ?');
    params.push(filters.endDate);
  }
  if (filters.search) {
    clauses.push('(pe.operator LIKE ? OR m.code LIKE ? OR m.name LIKE ?)');
    const q = `%${filters.search}%`;
    params.push(q, q, q);
  }

  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';

  const entries = await db.getAllAsync<MachineOperatorEntry>(
    `SELECT pe.id, pe.machine_id, m.code as machine_code, m.name as machine_name,
            m.status as machine_status, pl.code as line_code, pe.operator, pe.shift,
            pe.good_quantity, pe.rejected_quantity, pe.entry_timestamp,
            po.order_number, p.code as product_code, p.name as product_name
     FROM production_entries pe
     JOIN machines m ON m.id = pe.machine_id
     JOIN production_lines pl ON pl.id = m.line_id
     JOIN production_orders po ON po.id = pe.production_order_id
     LEFT JOIN products p ON p.id = po.product_id
     ${where}
     ORDER BY pe.entry_timestamp DESC`,
    ...params,
  );

  const map = new Map<string, {
    operator_name: string;
    machines: Set<string>;
    total_produced: number;
    total_rejected: number;
    shifts: Set<string>;
    entry_count: number;
    last_active_at: number;
    latest_machine: string;
    latest_order: string;
  }>();

  for (const e of entries) {
    const op = e.operator || 'Unassigned Worker';
    const cur = map.get(op);
    if (cur) {
      cur.machines.add(e.machine_code);
      cur.shifts.add(e.shift);
      cur.total_produced += e.good_quantity;
      cur.total_rejected += e.rejected_quantity;
      cur.entry_count += 1;
      if (e.entry_timestamp > cur.last_active_at) {
        cur.last_active_at = e.entry_timestamp;
        cur.latest_machine = e.machine_code;
        cur.latest_order = e.order_number;
      }
    } else {
      map.set(op, {
        operator_name: op,
        machines: new Set([e.machine_code]),
        shifts: new Set([e.shift]),
        total_produced: e.good_quantity,
        total_rejected: e.rejected_quantity,
        entry_count: 1,
        last_active_at: e.entry_timestamp,
        latest_machine: e.machine_code,
        latest_order: e.order_number,
      });
    }
  }

  return Array.from(map.values())
    .map((v) => ({
      operator_name: v.operator_name,
      machines: Array.from(v.machines),
      total_produced: v.total_produced,
      total_rejected: v.total_rejected,
      shifts: Array.from(v.shifts),
      entry_count: v.entry_count,
      last_active_at: v.last_active_at,
      latest_machine: v.latest_machine,
      latest_order: v.latest_order,
    }))
    .sort((a, b) => b.last_active_at - a.last_active_at);
}

export async function getMachineOperatorEntries(
  machineId: string,
  startDate?: number,
  endDate?: number,
): Promise<MachineOperatorEntry[]> {
  const db = await getDatabase();
  const clauses: string[] = ['pe.machine_id = ?'];
  const params: (string | number)[] = [machineId];

  if (startDate !== undefined) {
    clauses.push('pe.entry_timestamp >= ?');
    params.push(startDate);
  }
  if (endDate !== undefined) {
    clauses.push('pe.entry_timestamp <= ?');
    params.push(endDate);
  }

  return db.getAllAsync<MachineOperatorEntry>(
    `SELECT pe.id, pe.machine_id, m.code as machine_code, m.name as machine_name,
            m.status as machine_status, pl.code as line_code, pe.operator, pe.shift,
            pe.good_quantity, pe.rejected_quantity, pe.entry_timestamp,
            po.order_number, p.code as product_code, p.name as product_name
     FROM production_entries pe
     JOIN machines m ON m.id = pe.machine_id
     JOIN production_lines pl ON pl.id = m.line_id
     JOIN production_orders po ON po.id = pe.production_order_id
     LEFT JOIN products p ON p.id = po.product_id
     WHERE ${clauses.join(' AND ')}
     ORDER BY pe.entry_timestamp DESC`,
    ...params,
  );
}

export async function assignOperatorToMachine(
  machineId: string,
  operatorName: string,
  shift = 'Morning',
  notes = 'Operator assigned to machine',
): Promise<void> {
  const db = await getDatabase();
  const now = Date.now();

  // Find any active order on machine or latest order
  let order = await db.getFirstAsync<{ id: string; product_id: string }>(
    `SELECT id, product_id FROM production_orders
     WHERE machine_id = ? AND status IN ('IN_PROGRESS', 'PENDING')
     ORDER BY updated_at DESC LIMIT 1`,
    machineId,
  );

  if (!order) {
    order = await db.getFirstAsync<{ id: string; product_id: string }>(
      `SELECT id, product_id FROM production_orders ORDER BY updated_at DESC LIMIT 1`,
    );
  }

  if (!order) {
    throw new Error('No production order available to attach allocation.');
  }

  await db.withTransactionAsync(async () => {
    // Record allocation in production_entries
    await db.runAsync(
      `INSERT INTO production_entries (
        id, production_order_id, machine_id, shift, good_quantity, rejected_quantity,
        operator, notes, entry_timestamp
      ) VALUES (?, ?, ?, ?, 0, 0, ?, ?, ?)`,
      newId(),
      order.id,
      machineId,
      shift,
      operatorName,
      notes,
      now,
    );

    // Update machine status to RUNNING if it was idle
    await db.runAsync(
      `UPDATE machines SET status = 'RUNNING', updated_at = ? WHERE id = ? AND status = 'IDLE'`,
      now,
      machineId,
    );

    await db.runAsync(
      `INSERT INTO activity_history (
        id, event_type, title, description, reference_type, reference_id, timestamp
      ) VALUES (?, 'PRODUCTION_STARTED', ?, ?, 'machine', ?, ?)`,
      newId(),
      `Operator assigned: ${operatorName}`,
      `Assigned to machine on ${shift} shift`,
      machineId,
      now,
    );
  });

  notifyDataChanged();
}

export async function getActiveOperatorAssignments(
  sinceTimestamp?: number,
): Promise<Record<string, ActiveOperatorAssignment>> {
  const db = await getDatabase();
  const now = Date.now();
  // By default check entries from start of today or past 18 hours
  const since = sinceTimestamp ?? Math.min(startOfDay(now), now - 18 * 60 * 60 * 1000);

  const entries = await db.getAllAsync<{
    operator: string;
    machine_id: string;
    machine_code: string;
    machine_name: string;
    line_code: string;
    shift: string;
    entry_timestamp: number;
  }>(
    `SELECT pe.operator, pe.machine_id, m.code as machine_code, m.name as machine_name,
            pl.code as line_code, pe.shift, pe.entry_timestamp
     FROM production_entries pe
     JOIN machines m ON m.id = pe.machine_id
     JOIN production_lines pl ON pl.id = m.line_id
     WHERE pe.entry_timestamp >= ? AND pe.operator IS NOT NULL AND pe.operator != ''
     ORDER BY pe.entry_timestamp DESC`,
    since,
  );

  const machineShiftOperator = new Map<string, {
    operator: string;
    machine_id: string;
    machine_code: string;
    machine_name: string;
    line_code: string;
    shift: string;
    entry_timestamp: number;
  }>();

  for (const e of entries) {
    const key = `${e.machine_id}_${e.shift}`;
    if (!machineShiftOperator.has(key)) {
      machineShiftOperator.set(key, e);
    }
  }

  const assignments: Record<string, ActiveOperatorAssignment> = {};
  for (const item of machineShiftOperator.values()) {
    const op = item.operator;
    if (!assignments[op]) {
      assignments[op] = {
        operatorName: op,
        machines: [],
        totalMachines: 0,
      };
    }
    assignments[op].machines.push({
      machineId: item.machine_id,
      machineCode: item.machine_code,
      machineName: item.machine_name,
      lineCode: item.line_code,
      shift: item.shift,
      assignedAt: item.entry_timestamp,
    });
    assignments[op].totalMachines = assignments[op].machines.length;
  }

  return assignments;
}

export type CreateMachineInput = {
  code: string;
  name: string;
  machine_type?: string;
  line_id: string;
  status?: MachineStatus;
  current_product_id?: string | null;
};

export async function createMachine(input: CreateMachineInput): Promise<string> {
  const db = await getDatabase();
  const id = newId();
  const now = Date.now();
  const status = input.status || 'IDLE';
  const type = input.machine_type?.trim() || 'General';

  await db.runAsync(
    `INSERT INTO machines (
      id, code, name, machine_type, line_id, status, current_product_id,
      efficiency, runtime_seconds, downtime_seconds, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, 0, ?, ?)`,
    id,
    input.code.trim().toUpperCase(),
    input.name.trim(),
    type,
    input.line_id,
    status,
    input.current_product_id || null,
    now,
    now,
  );

  notifyDataChanged();
  return id;
}

export type UpdateMachineInput = {
  code?: string;
  name?: string;
  machine_type?: string;
  line_id?: string;
  status?: MachineStatus;
  current_product_id?: string | null;
};

export async function updateMachine(id: string, input: UpdateMachineInput): Promise<void> {
  const db = await getDatabase();
  const existing = await getMachineById(id);
  if (!existing) throw new Error('Machine not found');

  const now = Date.now();
  await db.runAsync(
    `UPDATE machines SET
      code = ?, name = ?, machine_type = ?, line_id = ?, status = ?,
      current_product_id = ?, updated_at = ?
     WHERE id = ?`,
    input.code !== undefined ? input.code.trim().toUpperCase() : existing.code,
    input.name !== undefined ? input.name.trim() : existing.name,
    input.machine_type !== undefined ? input.machine_type.trim() : existing.machine_type,
    input.line_id !== undefined ? input.line_id : existing.line_id,
    input.status !== undefined ? input.status : existing.status,
    input.current_product_id !== undefined ? input.current_product_id : existing.current_product_id,
    now,
    id,
  );

  notifyDataChanged();
}

export async function deleteMachine(id: string): Promise<void> {
  const db = await getDatabase();
  await db.withTransactionAsync(async () => {
    // Check if there is an active running order on this machine
    const activeOrder = await db.getFirstAsync<{ order_number: string }>(
      "SELECT order_number FROM production_orders WHERE machine_id = ? AND status = 'IN_PROGRESS'",
      id,
    );
    if (activeOrder) {
      throw new Error(`Cannot delete machine while production order ${activeOrder.order_number} is in progress.`);
    }

    // Clear machine references
    await db.runAsync('UPDATE production_orders SET machine_id = NULL WHERE machine_id = ? AND status != ?', id, 'COMPLETED');
    await db.runAsync('DELETE FROM machine_downtime WHERE machine_id = ?', id);
    await db.runAsync('DELETE FROM machines WHERE id = ?', id);
  });

  notifyDataChanged();
}

