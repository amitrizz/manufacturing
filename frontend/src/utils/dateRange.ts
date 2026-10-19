export type DatePreset = 'today' | 'week' | 'month' | 'custom';

export function startOfDay(ts: number): number {
  const d = new Date(ts);
  d.setHours(0, 0, 0, 0);
  return d.getTime();
}

export function endOfDay(ts: number): number {
  const d = new Date(ts);
  d.setHours(23, 59, 59, 999);
  return d.getTime();
}

export function getRangeForPreset(
  preset: DatePreset,
  customStart?: number,
  customEnd?: number,
): { start: number; end: number } {
  const now = Date.now();
  if (preset === 'custom' && customStart !== undefined && customEnd !== undefined) {
    return { start: startOfDay(customStart), end: endOfDay(customEnd) };
  }
  if (preset === 'today') {
    return { start: startOfDay(now), end: endOfDay(now) };
  }
  if (preset === 'week') {
    return { start: startOfDay(now - 6 * 24 * 60 * 60 * 1000), end: endOfDay(now) };
  }
  return { start: startOfDay(now - 29 * 24 * 60 * 60 * 1000), end: endOfDay(now) };
}
