import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { useCallback, useMemo, useState } from 'react';
import {
  Modal,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import Svg, { Circle, Path } from 'react-native-svg';
import { AppHeader } from '../../components/common/AppHeader';
import { Card } from '../../components/common/Card';
import { Screen } from '../../components/common/Screen';
import { listRecentActivity } from '../../api/repositories/activityRepository';
import { listMachines } from '../../api/repositories/machineRepository';
import { listMaterials } from '../../api/repositories/materialRepository';
import { listProductionOrders } from '../../api/repositories/productionOrderRepository';
import {
  getMonthlyProductionComparison,
  type MonthlyComparisonRow,
} from '../../api/repositories/reportsRepository';
import { listAttendanceForDate } from '../../api/repositories/staffRepository';
import { useDashboardKpis } from '../../hooks/useDashboardKpis';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { listActionableTasks } from '../../services/actionableTasksService';
import { useAuthStore } from '../../store/authStore';
import { useThemeStore } from '../../store/themeStore';
import { useTranslation } from '../../store/languageStore';
import { colors, typography } from '../../theme';
import type { ActivityRow, MachineRow } from '../../types/database';
import { formatNumber } from '../../utils/format';
import { mongoApi } from '../../api/client';

function CircularProgress({
  percent,
  size = 68,
  strokeWidth = 6.5,
  isDark = false,
  textColor = '#0F172A',
}: {
  percent: number;
  size?: number;
  strokeWidth?: number;
  isDark?: boolean;
  textColor?: string;
}) {
  const intPercent = Math.round(percent);
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;
  const strokeDashoffset =
    circumference - (circumference * Math.min(100, Math.max(0, intPercent))) / 100;

  return (
    <View style={{ width: size, height: size, justifyContent: 'center', alignItems: 'center' }}>
      <Svg width={size} height={size}>
        <Circle
          stroke={isDark ? '#334155' : '#E2E8F0'}
          fill="none"
          cx={size / 2}
          cy={size / 2}
          r={radius}
          strokeWidth={strokeWidth}
        />
        <Circle
          stroke="#059669"
          fill="none"
          cx={size / 2}
          cy={size / 2}
          r={radius}
          strokeWidth={strokeWidth}
          strokeDasharray={`${circumference} ${circumference}`}
          strokeDashoffset={strokeDashoffset}
          strokeLinecap="round"
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </Svg>
      <View style={{ position: 'absolute' }}>
        <Text style={{ fontSize: 13, fontWeight: '800', color: textColor }}>
          {intPercent}%
        </Text>
      </View>
    </View>
  );
}

export function DashboardScreen() {
  const navigation = useNavigation<any>();
  const user = useAuthStore((s) => s.user);
  const isDark = useThemeStore((s) => s.isDark);
  const themeColors = useThemeStore((s) => s.colors);
  const { language, t } = useTranslation();
  const { kpis, loading, refresh } = useDashboardKpis();

  const [machineAlertsCount, setMachineAlertsCount] = useState(0);
  const [pendingTasksCount, setPendingTasksCount] = useState(0);

  const [machineStats, setMachineStats] = useState({
    running: 0,
    breakdown: 0,
    maintenance: 0,
    total: 0,
  });

  const [recentActivities, setRecentActivities] = useState<
    { id: string; text: string; timeAgo: string; dotColor: string }[]
  >([]);

  // Attendance Overview state
  const [attendanceStats, setAttendanceStats] = useState({
    total: 0,
    present: 0,
    halfDay: 0,
    leave: 0,
    absent: 0,
    rate: 0,
  });

  // Monthly comparison graph state
  const [monthlyData, setMonthlyData] = useState<MonthlyComparisonRow[]>([]);
  const [selectedMonthIndex, setSelectedMonthIndex] = useState(0);
  const [showMachineModal, setShowMachineModal] = useState(false);

  const formatRelativeTime = useCallback((ts: number): string => {
    const diffMs = Date.now() - ts;
    const diffMin = Math.floor(diffMs / 60000);
    if (diffMin < 1) return t('justNow');
    if (diffMin < 60) return `${diffMin} ${t('minAgo')}`;
    const diffHours = Math.floor(diffMin / 60);
    if (diffHours < 24) return `${diffHours} ${t('hoursAgo')}`;
    const diffDays = Math.floor(diffHours / 24);
    return `${diffDays} ${t('daysAgo')}`;
  }, [t]);

  const refreshAll = useCallback(async () => {
    // 1. Live Backend MongoDB API (Single source of truth)
    try {
      const stats = await mongoApi.getDashboardStats();
      if (stats && stats.machines) {
        setPendingTasksCount(stats.pendingTasksCount ?? 0);
        setMachineStats(stats.machines);
        setMachineAlertsCount((stats.machines.breakdown || 0) + (stats.machines.maintenance || 0));
        setAttendanceStats(stats.attendance);

        const dynamicActivities: { id: string; text: string; timeAgo: string; dotColor: string }[] = [];
        if (stats.recentActivities && stats.recentActivities.length > 0) {
          stats.recentActivities.slice(0, 4).forEach((act: any) => {
            let dotColor = '#2563EB';
            const evt = act.event_type || '';
            if (evt.includes('BREAKDOWN')) dotColor = '#EF4444';
            else if (evt.includes('MATERIAL') || evt.includes('STOCK')) dotColor = '#F59E0B';
            else if (evt.includes('DISPATCH')) dotColor = '#10B981';
            dynamicActivities.push({
              id: act.id || act._id,
              text: act.title || act.description || evt.replace(/_/g, ' ') || 'Activity',
              timeAgo: formatRelativeTime(act.timestamp || act.created_at || Date.now()),
              dotColor,
            });
          });
        }
        setRecentActivities(dynamicActivities);

        if (stats.monthlyData && stats.monthlyData.length > 0) {
          const mData: MonthlyComparisonRow[] = stats.monthlyData.map((m) => ({
            monthKey: `${m.year}-${m.month}`,
            monthLabel: m.month,
            monthFull: `${m.month} ${m.year}`,
            year: m.year,
            produced: m.produced,
            ordersCount: m.target,
            machinesBreakdown: [],
          }));
          setMonthlyData(mData);
          setSelectedMonthIndex(mData.length - 1);
        }
        return;
      }
    } catch {
      // Backend temporarily offline, fallback below
    }

    const todayStr = new Date().toISOString().slice(0, 10);
    const [, , machines, attendanceList, monthlyComparison, tasks, activities] =
      await Promise.all([
        listProductionOrders().catch(() => []),
        listMaterials({ lowStockOnly: true }).catch(() => []),
        listMachines().catch(() => []),
        listAttendanceForDate(todayStr).catch(() => []),
        getMonthlyProductionComparison(6).catch(() => []),
        listActionableTasks().catch(() => []),
        listRecentActivity(4).catch(() => []),
      ]);

    setPendingTasksCount(tasks.length);

    // Machines (Strict Integers)
    const running = machines.filter((m: MachineRow) => m.status === 'RUNNING').length;
    const breakdown = machines.filter((m: MachineRow) => m.status === 'BREAKDOWN').length;
    const maintenance = machines.filter((m: MachineRow) => m.status === 'MAINTENANCE').length;
    const totalM = machines.length;
    setMachineStats({ running, breakdown, maintenance, total: totalM });
    setMachineAlertsCount(breakdown + maintenance);

    // Attendance (Strict Integers)
    const totalStaff = attendanceList.length;
    const present = attendanceList.filter((a: any) => a.status === 'PRESENT').length;
    const halfDay = attendanceList.filter((a: any) => a.status === 'HALF_DAY').length;
    const leave = attendanceList.filter((a: any) => a.status === 'LEAVE').length;
    const absent = attendanceList.filter((a: any) => a.status === 'ABSENT').length;
    const rate = totalStaff > 0 ? Math.round(((present + halfDay * 0.5) / totalStaff) * 100) : 0;
    setAttendanceStats({
      total: totalStaff,
      present,
      halfDay,
      leave,
      absent,
      rate,
    });

    // Activities
    const dynamicActivities: { id: string; text: string; timeAgo: string; dotColor: string }[] = [];
    if (activities && activities.length > 0) {
      activities.slice(0, 4).forEach((act: ActivityRow) => {
        let dotColor = '#2563EB';
        if (act.event_type.includes('BREAKDOWN')) dotColor = '#EF4444';
        else if (act.event_type.includes('MATERIAL') || act.event_type.includes('STOCK'))
          dotColor = '#F59E0B';
        else if (act.event_type.includes('DISPATCH')) dotColor = '#10B981';
        dynamicActivities.push({
          id: act.id,
          text: act.title || act.description || act.event_type.replace(/_/g, ' '),
          timeAgo: formatRelativeTime(act.timestamp),
          dotColor,
        });
      });
    }
    setRecentActivities(dynamicActivities);

    // Monthly data
    if (monthlyComparison.length > 0) {
      setMonthlyData(monthlyComparison);
      setSelectedMonthIndex(monthlyComparison.length - 1);
    } else {
      const now = new Date();
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      const fallbackMonths: MonthlyComparisonRow[] = [];
      for (let i = 5; i >= 0; i--) {
        const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
        const monthLabel = monthNames[d.getMonth()];
        const monthFull = `${monthLabel} ${d.getFullYear()}`;
        const monthKey = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
        fallbackMonths.push({
          monthKey,
          monthLabel,
          monthFull,
          year: d.getFullYear(),
          produced: 0,
          ordersCount: 0,
          machinesBreakdown: [],
        });
      }
      setMonthlyData(fallbackMonths);
      setSelectedMonthIndex(5);
    }
  }, [formatRelativeTime]);

  useLiveQuery(refreshAll);

  // Scale for bar graph
  const maxGraphValue = useMemo(() => {
    if (monthlyData.length === 0) return 100;
    const max = Math.max(...monthlyData.map((m) => m.produced));
    return Math.max(max * 1.15, 100);
  }, [monthlyData]);

  const selectedMonth = monthlyData[selectedMonthIndex] ?? null;


  const greetingTime = useMemo(() => {
    const h = new Date().getHours();
    if (h < 12) return t('goodMorning');
    if (h < 17) return t('goodAfternoon');
    return t('goodEvening');
  }, [t]);

  const todayDateBadge = useMemo(() => {
    return new Date().toLocaleDateString(language === 'HI' ? 'hi-IN' : 'en-GB', {
      weekday: 'short',
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    });
  }, [language]);

  // Display KPI calculations - Strictly Integers (no decimals)
  const todayOutputProduced = Math.round(kpis?.produced ?? 0);
  const todayOutputTarget = Math.round(kpis?.target ?? 0);
  const achievementPct =
    todayOutputTarget > 0 ? Math.round((todayOutputProduced / todayOutputTarget) * 100) : 0;
  const qualityRatePct = Math.round(kpis?.qualityRate ?? 0);
  const openAlerts = Math.round(machineAlertsCount);
  const totalMachinesCount = Math.round(machineStats.total);
  const activeMachinesCount = Math.round(machineStats.running);
  const breakdownMachinesCount = Math.round(machineStats.breakdown);

  return (
    <Screen
      scroll
      padded={false}
      refreshControl={
        <RefreshControl
          refreshing={loading}
          onRefresh={() => {
            void refresh();
            void refreshAll();
          }}
          tintColor={colors.primary}
        />
      }
    >
      {/* 1. App Header */}
      <AppHeader />

      <View style={[styles.contentBody, { backgroundColor: themeColors.background }]}>
        {/* 2. Greeting Header with Illustration & Date Badge */}
        <View style={[styles.greetingContainer, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}>
          <Svg
            width={130}
            height={80}
            viewBox="0 0 130 80"
            style={styles.factoryWatermark}
          >
            <Path
              d="M10 80 L10 45 L30 55 L30 45 L50 55 L50 35 L68 35 L68 80 Z"
              fill={isDark ? '#38BDF8' : '#0284C7'}
              opacity={isDark ? 0.08 : 0.12}
            />
            <Path
              d="M68 80 L68 25 L80 25 L80 80 Z"
              fill={isDark ? '#38BDF8' : '#0284C7'}
              opacity={isDark ? 0.12 : 0.16}
            />
            <Path
              d="M85 80 L85 40 L102 50 L102 40 L120 50 L120 30 L130 30 L130 80 Z"
              fill={isDark ? '#38BDF8' : '#0284C7'}
              opacity={isDark ? 0.08 : 0.12}
            />
          </Svg>

          <View style={styles.greetingTopRow}>
            <View style={{ flex: 1 }}>
              <Text style={[styles.greetingSub, { color: themeColors.textSecondary }]}>{greetingTime}</Text>
              <Text style={[styles.greetingTitle, { color: themeColors.text }]}>
                {user?.name || 'Admin'} <Text style={{ fontSize: 24 }}>👋</Text>
              </Text>
              <Text style={[styles.greetingHint, { color: themeColors.textSecondary }]}>
                {t('greetingHint')}
              </Text>
            </View>

            <View style={[styles.dateBadge, { backgroundColor: isDark ? '#0F172A' : '#F8FAFC', borderColor: themeColors.border }]}>
              <Ionicons name="calendar-outline" size={13} color={themeColors.textSecondary} />
              <Text style={[styles.dateBadgeText, { color: themeColors.textSecondary }]}>{todayDateBadge}</Text>
            </View>
          </View>
        </View>

        {/* 3. Top 4 KPI Metric Cards in a Row (Strict Integers) */}
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.kpiRow}
        >
          {/* Card 1: Today's Output */}
          <Pressable
            style={[
              styles.kpiCard,
              {
                borderColor: isDark ? '#14532D' : '#BBF7D0',
                backgroundColor: isDark ? '#064E3B' : '#F0FDF4',
              },
            ]}
            onPress={() => navigation.navigate('ProductionFloor', { viewOnly: true })}
          >
            <View style={[styles.kpiIconBox, { backgroundColor: isDark ? '#052E16' : '#DCFCE7' }]}>
              <Ionicons name="business" size={17} color={isDark ? '#4ADE80' : '#16A34A'} />
            </View>
            <Text style={[styles.kpiLabel, { color: isDark ? '#86EFAC' : '#64748B' }]}>{t('todaysOutput')}</Text>
            <Text style={[styles.kpiValue, { color: isDark ? '#F0FDF4' : '#0F172A' }]}>
              {todayOutputProduced} <Text style={[styles.kpiValueSub, { color: isDark ? '#BBF7D0' : '#64748B' }]}>/ {todayOutputTarget}</Text>
            </Text>
            <Text style={[styles.kpiFootText, { color: isDark ? '#4ADE80' : '#16A34A' }]}>
              {achievementPct}% {t('achieved')}
            </Text>
            <View style={styles.kpiProgressBarBg}>
              <View
                style={[
                  styles.kpiProgressBarFill,
                  { width: `${Math.min(100, achievementPct)}%`, backgroundColor: isDark ? '#4ADE80' : '#16A34A' },
                ]}
              />
            </View>
          </Pressable>

          {/* Card 2: Quality Rate */}
          <Pressable
            style={[
              styles.kpiCard,
              {
                borderColor: isDark ? '#1E3A8A' : '#BAE6FD',
                backgroundColor: isDark ? '#172554' : '#F0F9FF',
              },
            ]}
            onPress={() => navigation.navigate('QualityDashboard', { viewOnly: true })}
          >
            <View style={[styles.kpiIconBox, { backgroundColor: isDark ? '#1E1B4B' : '#E0F2FE' }]}>
              <Ionicons name="disc" size={17} color={isDark ? '#60A5FA' : '#2563EB'} />
            </View>
            <Text style={[styles.kpiLabel, { color: isDark ? '#93C5FD' : '#64748B' }]}>{t('qualityRate')}</Text>
            <Text style={[styles.kpiValue, { color: isDark ? '#F0F9FF' : '#0F172A' }]}>{qualityRatePct}%</Text>
            <Text style={[styles.kpiFootText, { color: isDark ? '#60A5FA' : '#2563EB' }]}>{t('good')}</Text>
            <View style={styles.kpiProgressBarBg}>
              <View
                style={[
                  styles.kpiProgressBarFill,
                  { width: `${Math.min(100, qualityRatePct)}%`, backgroundColor: isDark ? '#60A5FA' : '#2563EB' },
                ]}
              />
            </View>
          </Pressable>

          {/* Card 3: Active Machines */}
          <Pressable
            style={[
              styles.kpiCard,
              {
                borderColor: isDark ? '#581C87' : '#E9D5FF',
                backgroundColor: isDark ? '#3B0764' : '#FAF5FF',
              },
            ]}
            onPress={() => navigation.navigate('MachineList', { viewOnly: true })}
          >
            <View style={[styles.kpiIconBox, { backgroundColor: isDark ? '#2E1065' : '#F3E8FF' }]}>
              <Ionicons name="hardware-chip" size={17} color={isDark ? '#C084FC' : '#7C3AED'} />
            </View>
            <Text style={[styles.kpiLabel, { color: isDark ? '#D8B4FE' : '#64748B' }]}>{t('activeMachines')}</Text>
            <Text style={[styles.kpiValue, { color: isDark ? '#FAF5FF' : '#0F172A' }]}>
              {activeMachinesCount} <Text style={[styles.kpiValueSub, { color: isDark ? '#E9D5FF' : '#64748B' }]}>/ {totalMachinesCount}</Text>
            </Text>
            <Text style={[styles.kpiFootText, { color: isDark ? '#F87171' : '#DC2626' }]}>
              {breakdownMachinesCount} {t('breakdown')}
            </Text>
            <View style={styles.kpiProgressBarBg}>
              <View
                style={[
                  styles.kpiProgressBarFill,
                  {
                    width: `${totalMachinesCount > 0 ? Math.min(100, Math.round((activeMachinesCount / totalMachinesCount) * 100)) : 0}%`,
                    backgroundColor: isDark ? '#C084FC' : '#7C3AED',
                  },
                ]}
              />
            </View>
          </Pressable>

          {/* Card 4: Open Alerts */}
          <Pressable
            style={[
              styles.kpiCard,
              {
                borderColor: isDark ? '#7F1D1D' : '#FECACA',
                backgroundColor: isDark ? '#450A0A' : '#FEF2F2',
              },
            ]}
            onPress={() => (navigation as any).navigate('MyTasks')}
          >
            <View style={[styles.kpiIconBox, { backgroundColor: isDark ? '#300808' : '#FEE2E2' }]}>
              <Ionicons name="notifications" size={17} color={isDark ? '#F87171' : '#DC2626'} />
            </View>
            <Text style={[styles.kpiLabel, { color: isDark ? '#FCA5A5' : '#64748B' }]}>{t('openAlerts')}</Text>
            <Text style={[styles.kpiValue, { color: isDark ? '#FEF2F2' : '#0F172A' }]}>{openAlerts}</Text>
            <Text style={[styles.kpiFootText, { color: isDark ? '#F87171' : '#DC2626' }]}>{t('needAttention')}</Text>
            <View style={styles.kpiProgressBarBg}>
              <View
                style={[
                  styles.kpiProgressBarFill,
                  {
                    width: `${openAlerts > 0 ? Math.min(100, openAlerts * 25) : 0}%`,
                    backgroundColor: isDark ? '#F87171' : '#DC2626',
                  },
                ]}
              />
            </View>
          </Pressable>
        </ScrollView>

        {/* 4. Production Progress Card (Strict Integers) */}
        <View style={styles.sectionBlock}>
          <View style={styles.sectionHeaderLine}>
            <Text style={[styles.sectionMainTitle, { color: themeColors.text }]}>{t('productionProgress')}</Text>
            <Pressable
              onPress={() => navigation.navigate('ProductionFloor', { viewOnly: true })}
              style={styles.viewAllRow}
            >
              <Text style={styles.viewAllText}>{t('viewDetails')}</Text>
              <Ionicons name="arrow-forward" size={13} color="#2563EB" />
            </Pressable>
          </View>

          <Card style={[styles.productionProgressCard, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}>
            <View style={styles.progressCardBody}>
              <CircularProgress
                percent={achievementPct}
                size={68}
                strokeWidth={6.5}
                isDark={isDark}
                textColor={themeColors.text}
              />

              <View style={{ flex: 1, marginLeft: 14 }}>
                <Text style={[styles.progressTargetTitle, { color: themeColors.text }]}>{t('dailyTarget')}</Text>
                <Text style={[styles.progressTargetMeta, { color: themeColors.textSecondary }]}>
                  {t('target')}: {todayOutputTarget} pcs   |   {t('produced')}: {todayOutputProduced} pcs
                </Text>
                <Text style={[styles.progressQualityMeta, { color: isDark ? '#93C5FD' : '#2563EB' }]}>
                  {t('qualityRate')}: {qualityRatePct}%
                </Text>
              </View>

              <View style={styles.progressDeltaContainer}>
                <View
                  style={[
                    styles.deltaPill,
                    {
                      backgroundColor:
                        achievementPct >= 100
                          ? isDark ? '#064E3B' : '#ECFDF5'
                          : achievementPct > 0
                          ? isDark ? '#1E3A8A' : '#EFF6FF'
                          : isDark ? '#1E293B' : '#F1F5F9',
                    },
                  ]}
                >
                  <Text
                    style={[
                      styles.deltaPillText,
                      {
                        color:
                          achievementPct >= 100
                            ? isDark ? '#6EE7B7' : '#10B981'
                            : achievementPct > 0
                            ? isDark ? '#93C5FD' : '#2563EB'
                            : isDark ? '#94A3B8' : '#64748B',
                      },
                    ]}
                  >
                    {achievementPct}%
                  </Text>
                </View>
                <Text style={styles.deltaFootText}>{t('achieved')}</Text>
              </View>
            </View>
          </Card>
        </View>

        {/* 5. Machine Status (Full Width Row-Wise) */}
        <View style={styles.sectionBlock}>
          <View style={styles.sectionHeaderLine}>
            <Text style={[styles.sectionMainTitle, { color: themeColors.text }]}>{t('machineStatus')}</Text>
            <Pressable
              onPress={() => navigation.navigate('MachineList', { viewOnly: true })}
              style={styles.viewAllRow}
            >
              <Text style={styles.viewAllText}>{t('viewAll')}</Text>
              <Ionicons name="arrow-forward" size={13} color="#2563EB" />
            </Pressable>
          </View>

          <Card style={[styles.fullWidthCard, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}>
            <View style={styles.machineStatusRow}>
              {/* Running */}
              <View
                style={[
                  styles.machineRowCell,
                  {
                    backgroundColor: isDark ? '#064E3B' : '#F0FDF4',
                    borderColor: isDark ? '#14532D' : '#BBF7D0',
                  },
                ]}
              >
                <Ionicons name="play-circle" size={20} color={isDark ? '#4ADE80' : '#16A34A'} />
                <Text style={[styles.machineCellCount, { color: isDark ? '#4ADE80' : '#16A34A' }]}>
                  {activeMachinesCount}
                </Text>
                <Text style={[styles.machineCellLabel, { color: isDark ? '#A7F3D0' : '#64748B' }]}>{t('running')}</Text>
              </View>

              {/* Breakdown */}
              <View
                style={[
                  styles.machineRowCell,
                  {
                    backgroundColor: isDark ? '#450A0A' : '#FEF2F2',
                    borderColor: isDark ? '#7F1D1D' : '#FECACA',
                  },
                ]}
              >
                <Ionicons name="alert-circle" size={20} color={isDark ? '#F87171' : '#DC2626'} />
                <Text style={[styles.machineCellCount, { color: isDark ? '#F87171' : '#DC2626' }]}>
                  {breakdownMachinesCount}
                </Text>
                <Text style={[styles.machineCellLabel, { color: isDark ? '#FECACA' : '#64748B' }]}>{t('breakdown')}</Text>
              </View>

              {/* Maintenance */}
              <View
                style={[
                  styles.machineRowCell,
                  {
                    backgroundColor: isDark ? '#78350F' : '#FFFBEB',
                    borderColor: isDark ? '#92400E' : '#FDE68A',
                  },
                ]}
              >
                <Ionicons name="construct" size={19} color={isDark ? '#FBBF24' : '#D97706'} />
                <Text style={[styles.machineCellCount, { color: isDark ? '#FBBF24' : '#D97706' }]}>
                  {machineStats.maintenance}
                </Text>
                <Text style={[styles.machineCellLabel, { color: isDark ? '#FDE68A' : '#64748B' }]}>{t('maintenance')}</Text>
              </View>

              {/* Total */}
              <View
                style={[
                  styles.machineRowCell,
                  {
                    backgroundColor: isDark ? '#0F172A' : '#F8FAFC',
                    borderColor: isDark ? '#334155' : '#E2E8F0',
                  },
                ]}
              >
                <Ionicons name="power" size={19} color={isDark ? '#94A3B8' : '#64748B'} />
                <Text style={[styles.machineCellCount, { color: themeColors.text }]}>
                  {totalMachinesCount}
                </Text>
                <Text style={[styles.machineCellLabel, { color: themeColors.textSecondary }]}>{t('total')}</Text>
              </View>
            </View>
          </Card>
        </View>

        {/* 6. Today's Activity (Full Width Row-Wise) */}
        <View style={styles.sectionBlock}>
          <View style={styles.sectionHeaderLine}>
            <Text style={[styles.sectionMainTitle, { color: themeColors.text }]}>{t('todaysActivity')}</Text>
            <Pressable
              onPress={() => (navigation as any).navigate('MyTasks')}
              style={styles.viewAllRow}
            >
              <Text style={styles.viewAllText}>{t('viewAll')}</Text>
              <Ionicons name="arrow-forward" size={13} color="#2563EB" />
            </Pressable>
          </View>

          <Card style={[styles.fullWidthCard, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}>
            {recentActivities.length > 0 ? (
              <View style={styles.activityListContainer}>
                {recentActivities.slice(0, 4).map((act, index) => (
                  <View
                    key={act.id}
                    style={[
                      styles.activityItemFullRow,
                      index < Math.min(recentActivities.length, 4) - 1 && {
                        borderBottomWidth: 1,
                        borderBottomColor: isDark ? '#334155' : '#F1F5F9',
                      },
                    ]}
                  >
                    <View style={[styles.activityDot, { backgroundColor: act.dotColor }]} />
                    <Text style={[styles.activityTextFull, { color: themeColors.text }]} numberOfLines={1}>
                      {act.text}
                    </Text>
                    <Text style={[styles.activityTimeText, { color: themeColors.textSecondary }]}>{act.timeAgo}</Text>
                  </View>
                ))}
              </View>
            ) : (
              <View style={{ paddingVertical: 18, alignItems: 'center', justifyContent: 'center' }}>
                <Ionicons name="time-outline" size={24} color={themeColors.textSecondary} style={{ marginBottom: 6 }} />
                <Text style={{ fontSize: 13, color: themeColors.textSecondary }}>
                  {t('noRecentActivity')}
                </Text>
              </View>
            )}
          </Card>
        </View>

        {/* 7. Monthly Production Trend */}
        <View style={styles.sectionBlock}>
          <View style={styles.sectionHeaderLine}>
            <Text style={[styles.sectionMainTitle, { color: themeColors.text }]}>{t('monthlyTrend')}</Text>
            <Pressable
              onPress={() => setShowMachineModal(true)}
              style={styles.viewAllRow}
            >
              <Text style={styles.viewAllText}>{t('viewDetails')}</Text>
              <Ionicons name="arrow-forward" size={13} color="#2563EB" />
            </Pressable>
          </View>

          <Card style={[styles.chartCard, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}>
            <View style={styles.chartContainer}>
              {monthlyData.map((m, idx) => {
                const isSelected = idx === selectedMonthIndex;
                const isOct = m.monthLabel === 'Oct' || isSelected;
                const heightPct =
                  m.produced > 0
                    ? Math.max(8, Math.round((m.produced / maxGraphValue) * 100))
                    : 0;

                const displayVal =
                  m.produced >= 1000
                    ? `${Math.round(m.produced / 1000)}k`
                    : `${Math.round(m.produced)}`;

                return (
                  <Pressable
                    key={m.monthKey}
                    style={styles.chartColumn}
                    onPress={() => setSelectedMonthIndex(idx)}
                  >
                    <Text
                      style={[
                        styles.barValueText,
                        { color: isOct ? themeColors.text : themeColors.textSecondary },
                        isOct && styles.barValueTextActive,
                      ]}
                    >
                      {displayVal}
                    </Text>

                    <View style={[styles.barSlot, { backgroundColor: isDark ? '#0F172A' : '#F1F5F9', borderRadius: 4 }]}>
                      <View
                        style={[
                          styles.barFill,
                          { height: `${heightPct}%` },
                          isOct ? styles.barFillActive : (isDark ? { backgroundColor: '#1E3A8A' } : styles.barFillInactive),
                        ]}
                      />
                    </View>

                    <Text
                      style={[
                        styles.chartMonthLabel,
                        { color: isOct ? '#38BDF8' : themeColors.textSecondary },
                        isOct && styles.chartMonthLabelActive,
                      ]}
                    >
                      {m.monthLabel}
                    </Text>
                  </Pressable>
                );
              })}
            </View>
          </Card>
        </View>

        {/* 8. Bottom Two Wide Cards: Attendance Overview & Pending Tasks */}
        <View style={styles.bottomPillRow}>
          {/* Attendance Overview */}
          <Pressable
            style={[styles.bottomPillCard, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}
            onPress={() => navigation.navigate('Staff', { viewOnly: true })}
          >
            <View style={styles.bottomPillLeft}>
              <View style={[styles.bottomPillIconBox, { backgroundColor: isDark ? '#1E3A8A' : '#EFF6FF' }]}>
                <Ionicons name="people" size={18} color="#2563EB" />
              </View>
              <View>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                  <Text style={[styles.bottomPillTitle, { color: themeColors.text }]}>{t('attendance')}</Text>
                  <View style={[styles.turnoutPill, { backgroundColor: isDark ? '#064E3B' : '#DCFCE7' }]}>
                    <Text style={[styles.turnoutPillText, { color: isDark ? '#6EE7B7' : '#16A34A' }]}>{attendanceStats.rate}%</Text>
                  </View>
                </View>
                <Text style={[styles.bottomPillSub, { color: themeColors.textSecondary }]}>
                  {attendanceStats.present} / {attendanceStats.total} {t('staffPresent')}
                </Text>
              </View>
            </View>
            <Ionicons name="chevron-forward" size={16} color="#94A3B8" />
          </Pressable>

          {/* Pending Tasks */}
          <Pressable
            style={[styles.bottomPillCard, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}
            onPress={() => (navigation as any).navigate('MyTasks')}
          >
            <View style={styles.bottomPillLeft}>
              <View style={[styles.bottomPillIconBox, { backgroundColor: isDark ? '#1E3A8A' : '#EFF6FF' }]}>
                <Ionicons name="checkbox" size={18} color="#2563EB" />
              </View>
              <View>
                <Text style={[styles.bottomPillTitle, { color: themeColors.text }]}>{t('pendingTasks')}</Text>
                <Text style={[styles.bottomPillSub, { color: themeColors.textSecondary }]}>
                  <Text style={{ fontWeight: '800', color: themeColors.text }}>
                    {pendingTasksCount}
                  </Text>{' '}
                  {t('itemsToHandle')}
                </Text>
              </View>
            </View>
            <Ionicons name="chevron-forward" size={16} color="#94A3B8" />
          </Pressable>
        </View>
      </View>

      {/* Machine Output Details Modal */}
      <Modal
        visible={showMachineModal}
        animationType="slide"
        transparent
        onRequestClose={() => setShowMachineModal(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}>
            {/* Modal Header */}
            <View style={styles.modalHeader}>
              <View style={{ flex: 1 }}>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                  <Ionicons name="hardware-chip" size={18} color={isDark ? '#38BDF8' : '#0A1E38'} />
                  <Text style={[typography.h2, { color: themeColors.text }]}>Machine Output Details</Text>
                </View>
                <Text style={[styles.modalSubtitle, { color: themeColors.textSecondary }]}>
                  Items created on each machine in {selectedMonth?.monthFull ?? ''}
                </Text>
              </View>
              <Pressable
                onPress={() => setShowMachineModal(false)}
                style={[styles.modalCloseBtn, { backgroundColor: isDark ? '#1E293B' : '#F1F5F9' }]}
                hitSlop={8}
              >
                <Ionicons name="close" size={22} color={themeColors.text} />
              </Pressable>
            </View>

            {/* Month Switcher Tabs in Modal */}
            <View style={styles.modalMonthSwitcher}>
              <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={{ gap: 6 }}
              >
                {monthlyData.map((m, idx) => {
                  const active = idx === selectedMonthIndex;
                  return (
                    <Pressable
                      key={m.monthKey}
                      style={[
                        styles.modalMonthChip,
                        { backgroundColor: isDark ? '#1E293B' : '#F1F5F9' },
                        active && styles.modalMonthChipActive,
                      ]}
                      onPress={() => setSelectedMonthIndex(idx)}
                    >
                      <Text
                        style={[
                          styles.modalMonthChipText,
                          { color: isDark ? '#CBD5E1' : '#475569' },
                          active && styles.modalMonthChipTextActive,
                        ]}
                      >
                        {m.monthLabel}
                      </Text>
                    </Pressable>
                  );
                })}
              </ScrollView>
            </View>

            {/* Total items banner in modal */}
            {selectedMonth && (
              <View style={[styles.modalSummaryBox, { backgroundColor: isDark ? '#1E3A8A' : '#EFF6FF', borderColor: isDark ? '#3B82F6' : '#BFDBFE' }]}>
                <View>
                  <Text style={[styles.modalSummaryLabel, { color: isDark ? '#93C5FD' : '#2563EB' }]}>
                    Total Items Created in {selectedMonth.monthFull}
                  </Text>
                  <Text style={[styles.modalSummaryValue, { color: isDark ? '#EFF6FF' : '#1D4ED8' }]}>
                    {formatNumber(selectedMonth.produced)} pcs
                  </Text>
                </View>
                <View style={styles.modalSummaryBadge}>
                  <Text style={styles.modalSummaryBadgeText}>
                    {selectedMonth.machinesBreakdown.filter((m) => m.itemsProduced > 0).length}{' '}
                    Active Machines
                  </Text>
                </View>
              </View>
            )}

            {/* Machines List in Modal */}
            <ScrollView style={{ maxHeight: 380 }} showsVerticalScrollIndicator={true}>
              {selectedMonth?.machinesBreakdown && selectedMonth.machinesBreakdown.length > 0 ? (
                selectedMonth.machinesBreakdown.map((mach) => {
                  const isProduced = mach.itemsProduced > 0;
                  return (
                    <View key={mach.machineId} style={[styles.modalMachineCard, { backgroundColor: isDark ? '#0F172A' : '#F8FAFC', borderColor: themeColors.border }]}>
                      <View style={styles.modalMachineCardHeader}>
                        <View style={{ flex: 1 }}>
                          <Text style={[styles.modalMachineName, { color: themeColors.text }]}>{mach.machineName}</Text>
                          <Text style={[styles.modalMachineCode, { color: themeColors.textSecondary }]}>
                            {mach.machineCode} • {mach.machineType.replace('_', ' ')}
                          </Text>
                        </View>
                        <View style={{ alignItems: 'flex-end' }}>
                          <Text
                            style={[
                              styles.modalMachineProducedValue,
                              { color: themeColors.text },
                              !isProduced && { color: colors.textMuted },
                            ]}
                          >
                            {formatNumber(mach.itemsProduced)} pcs
                          </Text>
                          {isProduced && (
                            <Text style={styles.modalMachinePctText}>
                              {Math.round(mach.pctOfTotal)}% of month
                            </Text>
                          )}
                        </View>
                      </View>

                      {isProduced ? (
                        <View style={styles.modalMachineProgressBarBg}>
                          <View
                            style={[
                              styles.modalMachineProgressBarFill,
                              { width: `${Math.min(100, Math.max(5, Math.round(mach.pctOfTotal)))}%` },
                            ]}
                          />
                        </View>
                      ) : (
                        <Text style={[styles.modalIdleMachineText, { color: themeColors.textSecondary }]}>
                          No production entries this month
                        </Text>
                      )}

                      {mach.rejectedCount > 0 && (
                        <View style={styles.modalRejectRow}>
                          <Ionicons name="alert-circle-outline" size={12} color={colors.danger} />
                          <Text style={styles.modalRejectText}>
                            {formatNumber(mach.rejectedCount)} rejected in inspection
                          </Text>
                        </View>
                      )}
                    </View>
                  );
                })
              ) : (
                <View style={styles.noMachineOutputBox}>
                  <Text style={[styles.noMachineOutputText, { color: themeColors.textSecondary }]}>No machines found.</Text>
                </View>
              )}
            </ScrollView>

            <Pressable
              style={styles.modalDismissBtn}
              onPress={() => setShowMachineModal(false)}
            >
              <Text style={styles.modalDismissBtnText}>{t('closeModal')}</Text>
            </Pressable>
          </View>
        </View>
      </Modal>
    </Screen>
  );
}

const styles = StyleSheet.create({
  contentBody: {
    paddingHorizontal: 16,
    paddingTop: 14,
    paddingBottom: 32,
    backgroundColor: '#F8FAFC',
  },
  greetingContainer: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    overflow: 'hidden',
    position: 'relative',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  factoryWatermark: {
    position: 'absolute',
    right: 0,
    bottom: -5,
  },
  greetingTopRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  greetingSub: {
    fontSize: 13,
    color: '#64748B',
    fontWeight: '500',
  },
  greetingTitle: {
    fontSize: 24,
    fontWeight: '800',
    color: '#0F172A',
    marginTop: 2,
    marginBottom: 4,
    letterSpacing: -0.3,
  },
  greetingHint: {
    fontSize: 12.5,
    color: '#64748B',
    fontWeight: '400',
  },
  dateBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    paddingHorizontal: 9,
    paddingVertical: 5,
    borderRadius: 8,
  },
  dateBadgeText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#475569',
  },

  /* Top 4 KPI Row */
  kpiRow: {
    gap: 10,
    paddingBottom: 4,
    marginBottom: 18,
  },
  kpiCard: {
    width: 130,
    borderRadius: 14,
    borderWidth: 1,
    padding: 12,
    justifyContent: 'space-between',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.03,
    shadowRadius: 4,
    elevation: 1,
  },
  kpiIconBox: {
    width: 32,
    height: 32,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 8,
  },
  kpiLabel: {
    fontSize: 11,
    color: '#64748B',
    fontWeight: '600',
    marginBottom: 2,
  },
  kpiValue: {
    fontSize: 18,
    fontWeight: '800',
    color: '#0F172A',
    letterSpacing: -0.2,
  },
  kpiValueSub: {
    fontSize: 13,
    fontWeight: '600',
    color: '#64748B',
  },
  kpiFootText: {
    fontSize: 10.5,
    fontWeight: '700',
    marginTop: 3,
    marginBottom: 6,
  },
  kpiProgressBarBg: {
    height: 4,
    borderRadius: 2,
    backgroundColor: 'rgba(0, 0, 0, 0.06)',
    overflow: 'hidden',
  },
  kpiProgressBarFill: {
    height: '100%',
    borderRadius: 2,
  },

  /* Sections */
  sectionBlock: {
    marginBottom: 16,
  },
  sectionHeaderLine: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 10,
  },
  sectionMainTitle: {
    fontSize: 15,
    fontWeight: '800',
    color: '#0F172A',
    letterSpacing: -0.1,
  },
  viewAllRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  viewAllText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#2563EB',
  },

  /* Production Progress Card */
  productionProgressCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 14,
  },
  progressCardBody: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  progressTargetTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0F172A',
  },
  progressTargetMeta: {
    fontSize: 11.5,
    color: '#64748B',
    marginTop: 2,
    fontWeight: '500',
  },
  progressQualityMeta: {
    fontSize: 11.5,
    color: '#64748B',
    marginTop: 2,
    fontWeight: '500',
  },
  progressDeltaContainer: {
    alignItems: 'flex-end',
    marginLeft: 8,
  },
  deltaPill: {
    backgroundColor: '#ECFDF5',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 12,
  },
  deltaPillText: {
    fontSize: 11,
    fontWeight: '800',
    color: '#10B981',
  },
  deltaFootText: {
    fontSize: 9.5,
    color: '#94A3B8',
    marginTop: 3,
  },

  /* Full Width Row-Wise Cards */
  fullWidthCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 12,
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 3,
    elevation: 1,
  },
  machineStatusRow: {
    flexDirection: 'row',
    gap: 8,
  },
  machineRowCell: {
    flex: 1,
    borderRadius: 10,
    borderWidth: 1,
    paddingVertical: 10,
    paddingHorizontal: 6,
    alignItems: 'center',
    justifyContent: 'center',
  },
  machineCellCount: {
    fontSize: 16,
    fontWeight: '800',
    marginTop: 4,
    marginBottom: 2,
  },
  machineCellLabel: {
    fontSize: 10.5,
    color: '#64748B',
    fontWeight: '600',
  },

  /* Activity List Container */
  activityListContainer: {
    gap: 0,
  },
  activityItemFullRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 10,
    paddingHorizontal: 2,
    gap: 10,
  },
  activityDot: {
    width: 7,
    height: 7,
    borderRadius: 3.5,
  },
  activityTextFull: {
    flex: 1,
    fontSize: 12,
    color: '#334155',
    fontWeight: '600',
  },
  activityTimeText: {
    fontSize: 10.5,
    color: '#94A3B8',
  },

  /* Monthly Production Trend */
  chartCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    paddingVertical: 14,
    paddingHorizontal: 10,
  },
  chartContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    height: 120,
    paddingTop: 10,
  },
  chartColumn: {
    flex: 1,
    alignItems: 'center',
    height: '100%',
    justifyContent: 'flex-end',
  },
  barValueText: {
    fontSize: 10,
    color: '#64748B',
    fontWeight: '600',
    marginBottom: 4,
  },
  barValueTextActive: {
    fontSize: 11,
    fontWeight: '800',
    color: '#0F172A',
  },
  barSlot: {
    width: 28,
    height: 70,
    justifyContent: 'flex-end',
    alignItems: 'center',
  },
  barFill: {
    width: '100%',
    borderRadius: 4,
  },
  barFillInactive: {
    backgroundColor: '#BAE6FD',
  },
  barFillActive: {
    backgroundColor: '#2563EB',
  },
  chartMonthLabel: {
    fontSize: 10.5,
    color: '#64748B',
    fontWeight: '600',
    marginTop: 6,
  },
  chartMonthLabelActive: {
    fontWeight: '800',
    color: '#2563EB',
  },

  /* Bottom Pill Row */
  bottomPillRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 4,
  },
  bottomPillCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 4,
    elevation: 1,
  },
  bottomPillLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 9,
    flex: 1,
  },
  bottomPillIconBox: {
    width: 32,
    height: 32,
    borderRadius: 8,
    justifyContent: 'center',
    alignItems: 'center',
  },
  bottomPillTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: '#0F172A',
  },
  turnoutPill: {
    backgroundColor: '#DCFCE7',
    paddingHorizontal: 5,
    paddingVertical: 1.5,
    borderRadius: 6,
  },
  turnoutPillText: {
    fontSize: 9,
    fontWeight: '800',
    color: '#16A34A',
  },
  bottomPillSub: {
    fontSize: 10.5,
    color: '#64748B',
    marginTop: 1,
  },

  /* Modal */
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.6)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    paddingHorizontal: 20,
    paddingTop: 20,
    paddingBottom: 36,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 14,
  },
  modalSubtitle: {
    fontSize: 12,
    color: '#64748B',
    marginTop: 2,
  },
  modalCloseBtn: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#F1F5F9',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalMonthSwitcher: {
    marginBottom: 12,
  },
  modalMonthChip: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    backgroundColor: '#F1F5F9',
  },
  modalMonthChipActive: {
    backgroundColor: '#2563EB',
  },
  modalMonthChipText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#475569',
  },
  modalMonthChipTextActive: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
  modalSummaryBox: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: '#F0F9FF',
    borderRadius: 10,
    padding: 12,
    marginBottom: 12,
  },
  modalSummaryLabel: {
    fontSize: 11,
    color: '#0369A1',
  },
  modalSummaryValue: {
    fontSize: 17,
    fontWeight: '800',
    color: '#0C4A6E',
    marginTop: 2,
  },
  modalSummaryBadge: {
    backgroundColor: '#BAE6FD',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  modalSummaryBadgeText: {
    fontSize: 10.5,
    fontWeight: '700',
    color: '#0369A1',
  },
  modalMachineCard: {
    backgroundColor: '#F8FAFC',
    borderRadius: 10,
    padding: 12,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  modalMachineCardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  modalMachineName: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0F172A',
  },
  modalMachineCode: {
    fontSize: 10.5,
    color: '#64748B',
    marginTop: 1,
  },
  modalMachineProducedValue: {
    fontSize: 13,
    fontWeight: '800',
    color: '#0F172A',
  },
  modalMachinePctText: {
    fontSize: 10,
    color: '#0284C7',
    fontWeight: '600',
    marginTop: 1,
  },
  modalMachineProgressBarBg: {
    height: 4,
    borderRadius: 2,
    backgroundColor: '#E2E8F0',
    overflow: 'hidden',
  },
  modalMachineProgressBarFill: {
    height: '100%',
    backgroundColor: '#2563EB',
    borderRadius: 2,
  },
  modalIdleMachineText: {
    fontSize: 10.5,
    color: '#94A3B8',
    fontStyle: 'italic',
  },
  modalRejectRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginTop: 4,
  },
  modalRejectText: {
    fontSize: 10,
    color: '#DC2626',
    fontWeight: '600',
  },
  noMachineOutputBox: {
    padding: 24,
    alignItems: 'center',
  },
  noMachineOutputText: {
    fontSize: 12,
    color: '#94A3B8',
  },
  modalDismissBtn: {
    backgroundColor: '#2563EB',
    borderRadius: 10,
    paddingVertical: 12,
    alignItems: 'center',
    marginTop: 14,
  },
  modalDismissBtnText: {
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 13,
  },
});
