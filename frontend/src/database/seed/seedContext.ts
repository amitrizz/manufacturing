import type { SQLiteDatabase } from 'expo-sqlite';

export type SeedContext = {
  db: SQLiteDatabase;
  now: number;
  historyDays: number;
  factoryId: string;
  lineIds: Record<'A' | 'B' | 'C' | 'D', string>;
  productIds: string[];
  materialIds: string[];
  machineIds: string[];
  delayedOrderId: string | null;
  lowStockMaterialIds: string[];
  maintenanceDueMachineId: string | null;
  failedInspectionId: string | null;
};

export function startOfDay(ts: number): number {
  const d = new Date(ts);
  d.setHours(0, 0, 0, 0);
  return d.getTime();
}

export function daysAgo(now: number, days: number): number {
  return startOfDay(now) - days * 24 * 60 * 60 * 1000;
}
