import type {
  ActiveOperatorAssignment,
  MachineOperatorEntry,
  MachineOperatorSummary,
  MachineRow,
  MachineStatus,
  OperatorMachineSummary,
  ShiftAssignmentInfo,
} from '../../types/database';
import { newId } from '../../utils/id';
import { notifyDataChanged } from '../../store/dataRefreshStore';
import { startOfDay } from '../../utils/dateRange';
import { mongoApi } from '../client';

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
  } catch (err) {
    console.warn('MongoDB listMachines error:', err);
  }
  return [];
}

export async function getMachineById(id: string): Promise<MachineRow | null> {
  try {
    const remote = await mongoApi.getById<MachineRow>('machines', id);
    if (remote) {
      // enrich with line and product info if available
      const lines = await listLines();
      const line = lines.find((l) => l.id === remote.line_id);
      return {
        ...remote,
        line_code: line?.code || '',
        line_name: line?.name || '',
      };
    }
  } catch {
    const all = await listMachines();
    return all.find((m) => m.id === id || (m as any)._id === id) || null;
  }
  return null;
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
  try {
    const [entries, orders, products] = await Promise.all([
      mongoApi.getCollection<any>('production_entries', { machine_id: machineId }).catch(() => []),
      mongoApi.getCollection<any>('production_orders', { machine_id: machineId }).catch(() => []),
      mongoApi.getCollection<any>('products').catch(() => []),
    ]);

    let totalProduced = 0;
    let totalRejected = 0;
    for (const e of entries) {
      totalProduced += Number(e.good_quantity ?? e.quantity_produced ?? 0);
      totalRejected += Number(e.rejected_quantity ?? e.scrap_quantity ?? 0);
    }

    const activeOrder = orders.find(
      (o: any) => o.status === 'IN_PROGRESS' || o.status === 'RUNNING'
    );
    const prodMap = new Map(products.map((p: any) => [p.id || p._id, p]));
    const activeProd = activeOrder ? prodMap.get(activeOrder.product_id) : null;

    return {
      allTimeProduced: totalProduced,
      allTimeRejected: totalRejected,
      activeOrderNumber: activeOrder?.order_number || null,
      activeProductCode: activeProd?.code || null,
      activeProductName: activeProd?.name || null,
      activeTargetQuantity: activeOrder?.target_quantity || null,
      activeProducedQuantity: activeOrder?.produced_quantity || null,
    };
  } catch (err) {
    console.warn('MongoDB getMachineProductionTotals error:', err);
    return {
      allTimeProduced: 0,
      allTimeRejected: 0,
      activeOrderNumber: null,
      activeProductCode: null,
      activeProductName: null,
      activeTargetQuantity: null,
      activeProducedQuantity: null,
    };
  }
}

export async function listLines(): Promise<{ id: string; code: string; name: string }[]> {
  try {
    const lines = await mongoApi.getCollection<any>('production_lines');
    if (lines && Array.isArray(lines)) {
      return lines.map((l) => ({ id: l.id || l._id, code: l.code, name: l.name }));
    }
  } catch (err) {
    console.warn('MongoDB listLines error:', err);
  }
  return [];
}

export type CreateLineInput = {
  code: string;
  name: string;
  factory_id?: string;
  company_id?: string;
};

export async function createLine(input: CreateLineInput): Promise<string> {
  const id = newId();
  const factoryId = input.factory_id || 'fac-01';
  await mongoApi.insert('production_lines', {
    _id: id,
    id,
    factory_id: factoryId,
    code: input.code.trim().toUpperCase(),
    name: input.name.trim(),
    ...(input.company_id ? { company_id: input.company_id } : {}),
    created_at: Date.now(),
    updated_at: Date.now(),
  });
  notifyDataChanged();
  return id;
}

export async function updateLine(
  id: string,
  input: { code?: string; name?: string },
): Promise<void> {
  const updates: Record<string, unknown> = { updated_at: Date.now() };
  if (input.code) updates.code = input.code.trim().toUpperCase();
  if (input.name) updates.name = input.name.trim();
  await mongoApi.update('production_lines', id, updates);
  notifyDataChanged();
}

export async function deleteLine(id: string): Promise<void> {
  await mongoApi.delete('production_lines', id);
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
  try {
    const [machines, entries, orders, products] = await Promise.all([
      listMachines({ search: filters.search }),
      mongoApi.getCollection<any>('production_entries').catch(() => []),
      mongoApi.getCollection<any>('production_orders').catch(() => []),
      mongoApi.getCollection<any>('products').catch(() => []),
    ]);

    const orderMap = new Map(orders.map((o: any) => [o.id || o._id, o]));
    const prodMap = new Map(products.map((p: any) => [p.id || p._id, p]));

    let filteredEntries = entries;
    if (filters.startDate !== undefined) {
      filteredEntries = filteredEntries.filter(
        (e: any) => (e.entry_timestamp || e.created_at || 0) >= filters.startDate!
      );
    }
    if (filters.endDate !== undefined) {
      filteredEntries = filteredEntries.filter(
        (e: any) => (e.entry_timestamp || e.created_at || 0) <= filters.endDate!
      );
    }

    const entriesByMachine = new Map<string, any[]>();
    for (const e of filteredEntries) {
      const ord = orderMap.get(e.production_order_id);
      const pr = ord ? prodMap.get(ord.product_id) : null;
      const normalized = {
        ...e,
        id: e.id || e._id,
        order_number: ord?.order_number || '',
        product_code: pr?.code || '',
        product_name: pr?.name || '',
      };
      const list = entriesByMachine.get(e.machine_id) || [];
      list.push(normalized);
      entriesByMachine.set(e.machine_id, list);
    }

    return machines.map((m) => {
      const machineEntries = (entriesByMachine.get(m.id) || []).sort(
        (a, b) => (b.entry_timestamp || 0) - (a.entry_timestamp || 0)
      );
      let totalProduced = 0;
      let totalRejected = 0;
      const operatorMap = new Map<string, any>();

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
        totalProduced += Number(e.good_quantity ?? 0);
        totalRejected += Number(e.rejected_quantity ?? 0);

        const opName = e.operator || 'Unassigned Worker';
        const existing = operatorMap.get(opName);
        if (existing) {
          existing.produced += Number(e.good_quantity ?? 0);
          existing.rejected += Number(e.rejected_quantity ?? 0);
          if (e.entry_timestamp > existing.last_seen) {
            existing.last_seen = e.entry_timestamp;
            existing.shift = e.shift;
            existing.order_number = e.order_number;
          }
        } else {
          operatorMap.set(opName, {
            name: opName,
            shift: e.shift,
            produced: Number(e.good_quantity ?? 0),
            rejected: Number(e.rejected_quantity ?? 0),
            last_seen: e.entry_timestamp || 0,
            order_number: e.order_number,
          });
        }

        const rawShift = (e.shift || '').trim();
        const sKey: 'Morning' | 'Evening' | 'Night' =
          rawShift === 'Evening' || rawShift === 'B'
            ? 'Evening'
            : rawShift === 'Night' || rawShift === 'C'
            ? 'Night'
            : 'Morning';
        const sData = shiftMap.get(sKey)!;
        sData.total_produced += Number(e.good_quantity ?? 0);
        if (!sData.operator && e.operator) {
          sData.operator = e.operator;
          sData.last_active_at = e.entry_timestamp;
        }
      }

      const shift_assignments: ShiftAssignmentInfo[] = (['Morning', 'Evening', 'Night'] as const).map(
        (sh) => {
          const data = shiftMap.get(sh)!;
          return {
            shift: sh,
            operator: data.operator,
            total_produced: data.total_produced,
            last_active_at: data.last_active_at,
          };
        }
      );

      const latestEntry = machineEntries[0];

      return {
        machine_id: m.id,
        machine_code: m.code,
        machine_name: m.name,
        machine_status: m.status,
        machine_type: m.machine_type || 'General',
        line_id: m.line_id,
        line_code: m.line_code || '',
        line_name: m.line_name || '',
        current_operator: latestEntry?.operator || m.current_operator || null,
        current_shift: latestEntry?.shift || null,
        current_product: latestEntry?.product_code || m.product_code || null,
        last_active_at: latestEntry?.entry_timestamp || null,
        total_produced: totalProduced,
        total_rejected: totalRejected,
        shift_assignments,
        operators: Array.from(operatorMap.values()).sort((a, b) => b.last_seen - a.last_seen),
      };
    });
  } catch (err) {
    console.warn('listMachineOperatorSummaries error:', err);
    return [];
  }
}

export async function listOperatorMachineSummaries(
  filters: OperatorPeriodFilter = {},
): Promise<OperatorMachineSummary[]> {
  try {
    const [entries, machines, orders] = await Promise.all([
      mongoApi.getCollection<any>('production_entries').catch(() => []),
      listMachines(),
      mongoApi.getCollection<any>('production_orders').catch(() => []),
    ]);

    const machMap = new Map(machines.map((m) => [m.id, m]));
    const orderMap = new Map(orders.map((o: any) => [o.id || o._id, o]));

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
      const ts = e.entry_timestamp || e.created_at || 0;
      if (filters.startDate !== undefined && ts < filters.startDate) continue;
      if (filters.endDate !== undefined && ts > filters.endDate) continue;

      const op = e.operator || 'Unassigned Worker';
      const mach = machMap.get(e.machine_id);
      const machCode = mach?.code || '';
      const ord = orderMap.get(e.production_order_id);
      const orderNum = ord?.order_number || '';

      const cur = map.get(op);
      if (cur) {
        if (machCode) cur.machines.add(machCode);
        if (e.shift) cur.shifts.add(e.shift);
        cur.total_produced += Number(e.good_quantity ?? 0);
        cur.total_rejected += Number(e.rejected_quantity ?? 0);
        cur.entry_count += 1;
        if (ts > cur.last_active_at) {
          cur.last_active_at = ts;
          cur.latest_machine = machCode;
          cur.latest_order = orderNum;
        }
      } else {
        map.set(op, {
          operator_name: op,
          machines: new Set(machCode ? [machCode] : []),
          shifts: new Set(e.shift ? [e.shift] : []),
          total_produced: Number(e.good_quantity ?? 0),
          total_rejected: Number(e.rejected_quantity ?? 0),
          entry_count: 1,
          last_active_at: ts,
          latest_machine: machCode,
          latest_order: orderNum,
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
  } catch (err) {
    console.warn('listOperatorMachineSummaries error:', err);
    return [];
  }
}

export async function getMachineOperatorEntries(
  machineId: string,
  startDate?: number,
  endDate?: number,
): Promise<MachineOperatorEntry[]> {
  try {
    const [entries, machine, orders, products] = await Promise.all([
      mongoApi.getCollection<any>('production_entries', { machine_id: machineId }).catch(() => []),
      getMachineById(machineId),
      mongoApi.getCollection<any>('production_orders').catch(() => []),
      mongoApi.getCollection<any>('products').catch(() => []),
    ]);

    const orderMap = new Map(orders.map((o: any) => [o.id || o._id, o]));
    const prodMap = new Map(products.map((p: any) => [p.id || p._id, p]));

    return entries
      .filter((e) => {
        const ts = e.entry_timestamp || e.created_at || 0;
        if (startDate !== undefined && ts < startDate) return false;
        if (endDate !== undefined && ts > endDate) return false;
        return true;
      })
      .map((e) => {
        const ord = orderMap.get(e.production_order_id);
        const pr = ord ? prodMap.get(ord.product_id) : null;
        return {
          id: e.id || e._id,
          machine_id: machineId,
          machine_code: machine?.code || '',
          machine_name: machine?.name || '',
          machine_status: machine?.status || 'IDLE',
          line_code: machine?.line_code || '',
          operator: e.operator || '',
          shift: e.shift || '',
          good_quantity: Number(e.good_quantity ?? 0),
          rejected_quantity: Number(e.rejected_quantity ?? 0),
          entry_timestamp: e.entry_timestamp || e.created_at || Date.now(),
          order_number: ord?.order_number || '',
          product_code: pr?.code || '',
          product_name: pr?.name || '',
        };
      })
      .sort((a, b) => b.entry_timestamp - a.entry_timestamp);
  } catch (err) {
    console.warn('getMachineOperatorEntries error:', err);
    return [];
  }
}

export async function assignOperatorToMachine(
  machineId: string,
  operatorName: string,
  shift = 'Morning',
  notes = 'Operator assigned to machine',
): Promise<void> {
  const now = Date.now();

  try {
    const orders = await mongoApi.listProductionOrders();
    let order = orders.find(
      (o) =>
        (o.machine_id === machineId ||
          (o.assigned_machines && o.assigned_machines.includes(machineId))) &&
        (o.status === 'IN_PROGRESS' || o.status === 'PENDING'),
    );

    if (!order) {
      order = orders.find((o) => o.status === 'IN_PROGRESS') || orders[0];
    }

    const orderId = order ? order.id || order._id : null;

    const entryId = newId();
    await mongoApi.insert('production_entries', {
      _id: entryId,
      id: entryId,
      production_order_id: orderId,
      machine_id: machineId,
      shift,
      good_quantity: 0,
      rejected_quantity: 0,
      quantity_produced: 0,
      scrap_quantity: 0,
      operator: operatorName,
      notes,
      entry_timestamp: now,
      created_at: now,
      updated_at: now,
    });

    await mongoApi.update('machines', machineId, {
      current_operator: operatorName,
      status: 'RUNNING',
      updated_at: now,
    });

    if (orderId && order) {
      const currentWorkers: string[] = Array.isArray(order.assigned_workers) ? order.assigned_workers : [];
      if (!currentWorkers.includes(operatorName)) {
        await mongoApi
          .update('production_orders', orderId, {
            assigned_workers: [...currentWorkers, operatorName],
            updated_at: now,
          })
          .catch(() => {});
      }
    }

    await mongoApi
      .insert('activity_history', {
        event_type: 'WORKER_ASSIGNED',
        title: `Operator assigned: ${operatorName}`,
        description: `Assigned to machine on ${shift} shift`,
        reference_type: 'machine',
        reference_id: machineId,
        timestamp: now,
        created_at: now,
      })
      .catch(() => {});

    notifyDataChanged();
  } catch (err) {
    console.warn('assignOperatorToMachine error:', err);
  }
}

export async function getActiveOperatorAssignments(
  sinceTimestamp?: number,
): Promise<Record<string, ActiveOperatorAssignment>> {
  const now = Date.now();
  const since = sinceTimestamp ?? Math.min(startOfDay(now), now - 18 * 60 * 60 * 1000);

  try {
    const [entries, machines, lines] = await Promise.all([
      mongoApi.getCollection<any>('production_entries'),
      mongoApi.getCollection<any>('machines'),
      mongoApi.getCollection<any>('production_lines'),
    ]);

    const machMap = new Map(machines.map((m) => [m.id || m._id, m]));
    const lineMap = new Map(lines.map((l) => [l.id || l._id, l]));

    const recent = entries.filter(
      (e) => (e.entry_timestamp || e.created_at || 0) >= since && e.operator && String(e.operator).trim(),
    );

    const machineShiftOperator = new Map<string, any>();
    for (const e of recent) {
      const key = `${e.machine_id}_${e.shift || 'Morning'}`;
      if (!machineShiftOperator.has(key)) {
        const m = machMap.get(e.machine_id);
        const l = m ? lineMap.get(m.line_id) : null;
        machineShiftOperator.set(key, {
          operator: e.operator,
          machine_id: e.machine_id,
          machine_code: m?.code || '',
          machine_name: m?.name || 'Machine',
          line_code: l?.code || '',
          shift: e.shift || 'Morning',
          entry_timestamp: e.entry_timestamp || e.created_at || now,
        });
      }
    }

    for (const m of machines) {
      if (m.current_operator && String(m.current_operator).trim()) {
        const key = `${m.id || m._id}_Morning`;
        if (!machineShiftOperator.has(key)) {
          const l = lineMap.get(m.line_id);
          machineShiftOperator.set(key, {
            operator: m.current_operator,
            machine_id: m.id || m._id,
            machine_code: m.code || '',
            machine_name: m.name || 'Machine',
            line_code: l?.code || '',
            shift: 'Morning',
            entry_timestamp: m.updated_at || now,
          });
        }
      }
    }

    const assignments: Record<string, ActiveOperatorAssignment> = {};
    for (const item of machineShiftOperator.values()) {
      const op = item.operator;
      let currentAssign = assignments[op];
      if (!currentAssign) {
        currentAssign = {
          operatorName: op,
          machines: [],
          totalMachines: 0,
        };
        assignments[op] = currentAssign;
      }
      if (!currentAssign.machines) {
        currentAssign.machines = [];
      }
      currentAssign.machines.push({
        machineId: item.machine_id,
        machineCode: item.machine_code,
        machineName: item.machine_name,
        lineCode: item.line_code,
        shift: item.shift,
        assignedAt: item.entry_timestamp,
      });
      currentAssign.totalMachines = currentAssign.machines.length;
    }

    return assignments;
  } catch (err) {
    console.warn('getActiveOperatorAssignments error:', err);
    return {};
  }
}

export type CreateMachineInput = {
  code: string;
  name: string;
  machine_type?: string;
  line_id: string;
  status?: MachineStatus;
  current_product_id?: string | null;
  company_id?: string;
};

export async function createMachine(input: CreateMachineInput): Promise<string> {
  const id = newId();
  const now = Date.now();
  const status = input.status || 'IDLE';
  const type = input.machine_type?.trim() || 'General';

  await mongoApi.insert('machines', {
    _id: id,
    id,
    code: input.code.trim().toUpperCase(),
    name: input.name.trim(),
    machine_type: type,
    line_id: input.line_id,
    status,
    current_product_id: input.current_product_id || null,
    ...(input.company_id ? { company_id: input.company_id } : {}),
    efficiency: 0,
    runtime_seconds: 0,
    downtime_seconds: 0,
    created_at: now,
    updated_at: now,
  });

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
  const now = Date.now();
  const updates: Record<string, unknown> = { updated_at: now };
  if (input.code !== undefined) updates.code = input.code.trim().toUpperCase();
  if (input.name !== undefined) updates.name = input.name.trim();
  if (input.machine_type !== undefined) updates.machine_type = input.machine_type.trim();
  if (input.line_id !== undefined) updates.line_id = input.line_id;
  if (input.status !== undefined) updates.status = input.status;
  if (input.current_product_id !== undefined) updates.current_product_id = input.current_product_id;

  await mongoApi.update('machines', id, updates);
  notifyDataChanged();
}

export async function deleteMachine(id: string): Promise<void> {
  const activeOrders = await mongoApi.listProductionOrders();
  const activeOrder = activeOrders.find(
    (o) => o.machine_id === id && o.status === 'IN_PROGRESS'
  );
  if (activeOrder) {
    throw new Error(`Cannot delete machine while production order ${activeOrder.order_number} is in progress.`);
  }

  await mongoApi.delete('machines', id);
  notifyDataChanged();
}
