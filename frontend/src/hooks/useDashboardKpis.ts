import { useCallback, useState } from 'react';
import { useLiveQuery } from './useLiveQuery';
import {
  getDashboardAlerts,
  getDashboardKpis,
  type DashboardAlert,
  type DashboardKpis,
} from '../api/repositories/reportsRepository';
import { listRecentActivity } from '../api/repositories/activityRepository';
import type { ActivityRow } from '../types/database';
import { useFilterStore } from '../store/filterStore';
import { getRangeForPreset } from '../utils/dateRange';
import { mongoApi } from '../api/client';

export function useDashboardKpis() {
  const preset = useFilterStore((s) => s.dashboardDatePreset);
  const customStart = useFilterStore((s) => s.customRangeStart);
  const customEnd = useFilterStore((s) => s.customRangeEnd);

  const [kpis, setKpis] = useState<DashboardKpis | null>(null);
  const [alerts, setAlerts] = useState<DashboardAlert[]>([]);
  const [activity, setActivity] = useState<ActivityRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const refresh = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      // 1. Prioritize live MongoDB backend
      try {
        const stats = await mongoApi.getDashboardStats();
        if (stats && stats.kpis) {
          setKpis({
            target: stats.kpis.target,
            produced: stats.kpis.produced,
            achievement: stats.kpis.achievement,
            qualityRate: stats.kpis.qualityRate,
            machineAvailability: stats.kpis.machineAvailability,
            downtimeHours: stats.kpis.downtimeHours,
            machineStatusCounts: stats.kpis.machineStatusCounts || {},
            lineProgress: (stats.kpis.lineProgress || []).map((l: any) => ({
              lineCode: l.lineCode,
              produced: l.produced,
              pct: l.pct,
            })),
          });
          setActivity(stats.recentActivities || []);
          setLoading(false);
          return;
        }
      } catch {
        // Backend temporarily unavailable, fallback
      }

      const { start, end } = getRangeForPreset(preset, customStart ?? undefined, customEnd ?? undefined);
      const [k, a, act] = await Promise.all([
        getDashboardKpis(start, end).catch(() => null),
        getDashboardAlerts().catch(() => []),
        listRecentActivity(10, start, end).catch(() => []),
      ]);
      if (k) setKpis(k);
      setAlerts(a);
      setActivity(act);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to load dashboard');
    } finally {
      setLoading(false);
    }
  }, [preset, customStart, customEnd]);

  useLiveQuery(refresh);

  return { kpis, alerts, activity, loading, error, refresh };
}
