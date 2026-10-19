import { newId } from '../../utils/id';
import type { SeedContext } from './seedContext';
import { daysAgo } from './seedContext';

type MachineDef = {
  code: string;
  name: string;
  type: string;
  line: 'A' | 'B' | 'C' | 'D';
  status: 'RUNNING' | 'IDLE' | 'BREAKDOWN' | 'MAINTENANCE' | 'OFFLINE';
  productIndex?: number;
};

const MACHINES: MachineDef[] = [
  { code: 'CNC-A1', name: 'CNC Mill A1', type: 'CNC_MILL', line: 'A', status: 'RUNNING', productIndex: 0 },
  { code: 'CNC-A2', name: 'CNC Mill A2', type: 'CNC_MILL', line: 'A', status: 'RUNNING', productIndex: 1 },
  { code: 'LATHE-A1', name: 'CNC Lathe A1', type: 'LATHE', line: 'A', status: 'IDLE' },
  { code: 'ASM-B1', name: 'Assembly Station B1', type: 'ASSEMBLY', line: 'B', status: 'RUNNING', productIndex: 0 },
  { code: 'ASM-B2', name: 'Assembly Station B2', type: 'ASSEMBLY', line: 'B', status: 'RUNNING', productIndex: 2 },
  { code: 'WELD-B1', name: 'Robotic Welder B1', type: 'WELDER', line: 'B', status: 'MAINTENANCE' },
  { code: 'PRESS-C1', name: 'Hydraulic Press C1', type: 'PRESS', line: 'C', status: 'RUNNING', productIndex: 3 },
  { code: 'PRESS-C2', name: 'Hydraulic Press C2', type: 'PRESS', line: 'C', status: 'RUNNING', productIndex: 4 },
  { code: 'PKG-C1', name: 'Packaging Line C1', type: 'PACKAGING', line: 'C', status: 'IDLE' },
  { code: 'TEST-D1', name: 'Leak Test Bench D1', type: 'TEST', line: 'D', status: 'RUNNING', productIndex: 5 },
  { code: 'PAINT-D1', name: 'Paint Booth D1', type: 'PAINT', line: 'D', status: 'BREAKDOWN' },
];

export async function seedMachines(ctx: SeedContext): Promise<void> {
  const { db, now, productIds } = ctx;
  const weekMs = 7 * 24 * 60 * 60 * 1000;

  for (const m of MACHINES) {
    const id = newId();
    ctx.machineIds.push(id);
    const runtime = 120_000 + Math.floor(Math.random() * 80_000);
    const downtime = 8_000 + Math.floor(Math.random() * 12_000);
    const lastMaint = daysAgo(now, 14 + Math.floor(Math.random() * 20));
    const nextMaint = m.code === 'WELD-B1' ? now + 2 * 24 * 60 * 60 * 1000 : now + weekMs * 3;
    if (m.code === 'WELD-B1') {
      ctx.maintenanceDueMachineId = id;
    }

    await db.runAsync(
      `INSERT INTO machines (
        id, code, name, machine_type, line_id, status, current_product_id,
        efficiency, runtime_seconds, downtime_seconds, last_maintenance_at, next_maintenance_at,
        created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      id,
      m.code,
      m.name,
      m.type,
      ctx.lineIds[m.line],
      m.status,
      m.productIndex !== undefined ? productIds[m.productIndex] : null,
      72 + Math.random() * 22,
      runtime,
      downtime,
      lastMaint,
      nextMaint,
      daysAgo(now, 120),
      now,
    );

    if (m.status === 'BREAKDOWN') {
      await db.runAsync(
        `INSERT INTO machine_downtime (id, machine_id, start_time, end_time, reason, description, created_at)
         VALUES (?, ?, ?, NULL, ?, ?, ?)`,
        newId(),
        id,
        now - 3 * 60 * 60 * 1000,
        'MECHANICAL_FAILURE',
        'Hydraulic pressure loss — awaiting maintenance',
        now,
      );
    }
  }
}
