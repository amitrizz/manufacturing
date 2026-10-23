export type MaterialAvailabilityStatus = 'AVAILABLE' | 'NEAR_MINIMUM' | 'SHORTAGE';

export function achievementPct(produced: number, target: number): number {
  return target > 0 ? (produced / target) * 100 : 0;
}

export function progressPct(produced: number, target: number): number {
  return achievementPct(produced, target);
}

export function remaining(target: number, produced: number): number {
  return Math.max(target - produced, 0);
}

export function qualityRatePct(passed: number, total: number): number {
  return total > 0 ? (passed / total) * 100 : 0;
}

export function requiredMaterial(bomQty: number, orderQty: number): number {
  return bomQty * orderQty;
}

export function inventoryLevel(
  currentStock: number,
  minimumStock: number,
): MaterialAvailabilityStatus {
  if (currentStock <= minimumStock) return 'SHORTAGE';
  if (currentStock <= minimumStock * 1.2) return 'NEAR_MINIMUM';
  return 'AVAILABLE';
}

export function materialStatus(
  required: number,
  available: number,
  minStock: number,
): MaterialAvailabilityStatus {
  if (available >= required) {
    return 'AVAILABLE';
  }
  if (available <= minStock) {
    return 'SHORTAGE';
  }
  return 'NEAR_MINIMUM';
}

export function availabilityPct(
  runtimeSeconds: number,
  downtimeSeconds: number,
): number {
  const total = runtimeSeconds + downtimeSeconds;
  return total > 0 ? (runtimeSeconds / total) * 100 : 0;
}

/**
 * Performance % uses each machine's historical best output per hour as the ideal cycle baseline
 * when no engineering ideal cycle time is stored (spec gap). expectedOutput = idealRate * hoursRun.
 */
export function performancePct(actualOutput: number, expectedOutput: number): number {
  return expectedOutput > 0 ? (actualOutput / expectedOutput) * 100 : 0;
}

export function computeOee(
  runtimeSeconds: number,
  downtimeSeconds: number,
  actualOutput: number,
  expectedOutput: number,
  goodOutput: number,
  rejectOutput: number,
): number {
  const avail = availabilityPct(runtimeSeconds, downtimeSeconds);
  const perf = performancePct(actualOutput, expectedOutput);
  const qual = qualityRatePct(goodOutput, goodOutput + rejectOutput);
  return (avail * perf * qual) / 10000;
}