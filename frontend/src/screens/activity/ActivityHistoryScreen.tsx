import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import type { NavigationProp, ParamListBase } from '@react-navigation/native';
import { useCallback, useMemo, useState } from 'react';
import {
  Alert,
  FlatList,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { AppHeader } from '../../components/common/AppHeader';
import { Card } from '../../components/common/Card';
import { listActivityFiltered } from '../../api/repositories/activityRepository';
import { dispatchOrder } from '../../api/repositories/dispatchRepository';
import { completeReworkOrder } from '../../api/repositories/qualityRepository';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { navigateToActivityReference } from '../../navigation/navigateToReference';
import { listActionableTasks } from '../../services/actionableTasksService';
import { useAuthStore } from '../../store/authStore';
import { useFilterStore } from '../../store/filterStore';
import { colors, typography } from '../../theme';
import type { ActivityRow } from '../../types/database';
import type { ActionableTask } from '../../types/tasks';
import { getRangeForPreset } from '../../utils/dateRange';
import { formatDateTime } from '../../utils/format';
import { useThemeStore } from '../../store/themeStore';
import { useTranslation } from '../../store/languageStore';

type Mode = 'tasks' | 'history';

const HISTORY_FILTER_DEFS: { labelKey: 'filterAll' | 'filterProduction' | 'filterRecorded' | 'filterBreakdown' | 'filterMachines' | 'filterMaintenance' | 'filterQuality' | 'filterDispatch' | 'filterMaterials'; type: string | null }[] = [
  { labelKey: 'filterAll', type: null },
  { labelKey: 'filterProduction', type: 'PRODUCTION_STARTED' },
  { labelKey: 'filterRecorded', type: 'PRODUCTION_RECORDED' },
  { labelKey: 'filterBreakdown', type: 'BREAKDOWN_REPORTED' },
  { labelKey: 'filterMachines', type: '__MACHINE__' },
  { labelKey: 'filterMaintenance', type: 'MAINTENANCE_COMPLETED' },
  { labelKey: 'filterQuality', type: 'QUALITY_INSPECTION' },
  { labelKey: 'filterDispatch', type: 'DISPATCH_DISPATCHED' },
  { labelKey: 'filterMaterials', type: '__MATERIAL__' },
];

function openTask(navigation: NavigationProp<ParamListBase>, task: ActionableTask) {
  try {
    navigation.navigate(task.route.screen, task.route.params);
  } catch {
    navigation.navigate(task.route.tab, {
      screen: task.route.screen,
      params: task.route.params,
    });
  }
}

export function ActivityHistoryScreen() {
  const navigation = useNavigation<NavigationProp<ParamListBase>>();
  const hasPermission = useAuthStore((s) => s.hasPermission);
  const preset = useFilterStore((s) => s.dashboardDatePreset);
  const customStart = useFilterStore((s) => s.customRangeStart);
  const customEnd = useFilterStore((s) => s.customRangeEnd);

  const isDark = useThemeStore((s) => s.isDark);
  const themeColors = useThemeStore((s) => s.colors);
  const { t } = useTranslation();

  const [mode, setMode] = useState<Mode>('tasks');
  const [tasks, setTasks] = useState<ActionableTask[]>([]);
  const [history, setHistory] = useState<ActivityRow[]>([]);
  const [historyFilter, setHistoryFilter] = useState<string | null>(null);
  const [refreshing, setRefreshing] = useState(false);

  // Icon ticker filter state
  const [selectedCategory, setSelectedCategory] = useState<string>('All');

  const load = useCallback(async () => {
    setRefreshing(true);
    try {
      const { start, end } = getRangeForPreset(
        preset,
        customStart ?? undefined,
        customEnd ?? undefined,
      );
      const t = await listActionableTasks();
      let h = await listActivityFiltered(
        historyFilter === '__MATERIAL__' || historyFilter === '__MACHINE__'
          ? null
          : historyFilter,
        start,
        end,
      );
      if (historyFilter === '__MATERIAL__') {
        h = h.filter((row) => row.event_type.startsWith('MATERIAL_'));
      }
      if (historyFilter === '__MACHINE__') {
        h = h.filter(
          (row) =>
            row.event_type === 'MACHINE_STATUS_CHANGED' ||
            row.event_type === 'BREAKDOWN_REPORTED',
        );
      }
      setTasks(t);
      setHistory(h);
    } finally {
      setRefreshing(false);
    }
  }, [preset, customStart, customEnd, historyFilter]);

  useLiveQuery(load);

  const visibleTasks = useMemo(() => {
    const categoryPermissionMap: Record<ActionableTask['category'], string> = {
      Production: 'tasks_production',
      Maintenance: 'tasks_maintenance',
      Quality: 'tasks_quality',
      Dispatch: 'tasks_dispatch',
      Machines: 'tasks_machines',
      Materials: 'tasks_materials',
    };
    return tasks.filter((t) => hasPermission(categoryPermissionMap[t.category]));
  }, [tasks, hasPermission]);

  // Counts for top cards & category pills
  const prodCount = useMemo(
    () => visibleTasks.filter((t) => t.category === 'Production').length,
    [visibleTasks],
  );
  const machCount = useMemo(
    () => visibleTasks.filter((t) => t.category === 'Machines').length,
    [visibleTasks],
  );
  const matsCount = useMemo(
    () => visibleTasks.filter((t) => t.category === 'Materials').length,
    [visibleTasks],
  );
  const maintCount = useMemo(
    () => visibleTasks.filter((t) => t.category === 'Maintenance').length,
    [visibleTasks],
  );
  const reworkCount = useMemo(
    () => visibleTasks.filter((t) => t.category === 'Quality').length,
    [visibleTasks],
  );
  const dispCount = useMemo(
    () => visibleTasks.filter((t) => t.category === 'Dispatch').length,
    [visibleTasks],
  );

  // Filtered task list by icon ticker filter
  const filteredTasks = useMemo(() => {
    let list = visibleTasks;

    if (selectedCategory !== 'All') {
      list = list.filter((t) => t.category.toLowerCase() === selectedCategory.toLowerCase());
    }

    const statusWeights: Record<string, number> = {
      BREAKDOWN: 4,
      SHORTAGE: 3,
      PENDING_QC: 2,
    };
    return [...list].sort(
      (a, b) =>
        (statusWeights[b.status] || 1) - (statusWeights[a.status] || 1),
    );
  }, [visibleTasks, selectedCategory]);

  const runQuickAction = async (task: ActionableTask) => {
    if (!hasPermission('tasks_quick_actions')) {
      Alert.alert(
        'Access Denied',
        'Your role does not have permission to execute 1-tap quick actions.',
      );
      return;
    }
    try {
      if (task.quickAction === 'dispatch') {
        await dispatchOrder(task.referenceId);
        Alert.alert('Dispatched', `${task.title} marked as dispatched`);
      } else if (task.quickAction === 'complete_rework') {
        await completeReworkOrder(task.referenceId);
        Alert.alert('Done', 'Rework marked complete');
      }
      await load();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Action failed');
    }
  };

  const getTaskVisuals = (task: ActionableTask) => {
    switch (task.category) {
      case 'Machines':
        return {
          icon: 'construct' as keyof typeof Ionicons.glyphMap,
          iconColor: '#DC2626',
          iconBg: isDark ? '#450A0A' : '#FEE2E2',
          badgeText: t('breakdownBadge'),
          badgeColor: '#DC2626',
          badgeBg: isDark ? '#450A0A' : '#FEE2E2',
          timeColor: '#DC2626',
          defaultRef: `WO-${task.referenceId ? task.referenceId.slice(0, 8) : '2026-0012'}`,
          location: 'Painting Section',
        };
      case 'Materials':
        return {
          icon: 'cube' as keyof typeof Ionicons.glyphMap,
          iconColor: '#D97706',
          iconBg: isDark ? '#78350F' : '#FEF3C7',
          badgeText: t('shortageBadge'),
          badgeColor: '#D97706',
          badgeBg: isDark ? '#78350F' : '#FEF3C7',
          timeColor: '#D97706',
          defaultRef: 'Stock: 180 kg (Min: 250 kg)',
          location: 'Main Store',
        };
      case 'Quality':
        return {
          icon: 'clipboard' as keyof typeof Ionicons.glyphMap,
          iconColor: '#7C3AED',
          iconBg: isDark ? '#4C1D95' : '#EDE9FE',
          badgeText: t('rework'),
          badgeColor: '#7C3AED',
          badgeBg: isDark ? '#4C1D95' : '#EDE9FE',
          timeColor: '#64748B',
          defaultRef: 'Batch Rework Plan',
          location: 'QC Lab',
        };
      case 'Maintenance':
        return {
          icon: 'build' as keyof typeof Ionicons.glyphMap,
          iconColor: '#16A34A',
          iconBg: isDark ? '#064E3B' : '#DCFCE7',
          badgeText: t('attentionBadge'),
          badgeColor: '#D97706',
          badgeBg: isDark ? '#78350F' : '#FEF3C7',
          timeColor: '#D97706',
          defaultRef: `MT-${task.referenceId ? task.referenceId.slice(0, 8) : '2026-0081'}`,
          location: 'CNC Section',
        };
      case 'Dispatch':
        return {
          icon: 'car' as keyof typeof Ionicons.glyphMap,
          iconColor: '#0284C7',
          iconBg: isDark ? '#075985' : '#E0F2FE',
          badgeText: t('readyBadge'),
          badgeColor: '#0284C7',
          badgeBg: isDark ? '#075985' : '#E0F2FE',
          timeColor: '#64748B',
          defaultRef: 'Packing Slip Ready',
          location: 'Dispatch Dock',
        };
      default:
        return {
          icon: 'document-text' as keyof typeof Ionicons.glyphMap,
          iconColor: '#2563EB',
          iconBg: isDark ? '#1E3A8A' : '#DBEAFE',
          badgeText: t('pendingQcBadge'),
          badgeColor: '#2563EB',
          badgeBg: isDark ? '#1E3A8A' : '#DBEAFE',
          timeColor: '#2563EB',
          defaultRef: 'Target: 500 pcs | Completed: 420 pcs',
          location: 'Line 2',
        };
    }
  };

  const renderHeader = () => (
    <View style={styles.headerBlock}>
      {/* Top Controls: Mode Switcher (Tasks / History) */}
      <View style={styles.topControlRow}>
        <View style={{ flex: 1 }} />
        <Pressable
          style={[
            styles.historyPill,
            { backgroundColor: isDark ? '#1E293B' : '#FFFFFF', borderColor: themeColors.border },
            mode === 'history' && styles.historyPillActive,
          ]}
          onPress={() => setMode(mode === 'tasks' ? 'history' : 'tasks')}
        >
          <Ionicons
            name="time-outline"
            size={14}
            color={mode === 'history' ? '#FFFFFF' : '#2563EB'}
          />
          <Text
            style={[
              styles.historyPillText,
              mode === 'history' && styles.historyPillTextActive,
            ]}
          >
            {mode === 'history' ? t('tasksView') : t('historyLog')}
          </Text>
        </Pressable>
      </View>

      {/* 7 Status Summary Cards: Only Icon Ticker Filter */}
      {mode === 'tasks' ? (
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.summaryCardsRow}
        >
          <Pressable
            style={[
              styles.summaryCard,
              { backgroundColor: isDark ? '#1E3A8A' : '#EFF6FF', borderColor: isDark ? '#3B82F6' : '#BFDBFE' },
              selectedCategory === 'All' && styles.summaryCardActiveBorder,
            ]}
            onPress={() => setSelectedCategory('All')}
          >
            <Text style={[styles.summaryValuePrimary, { color: isDark ? '#93C5FD' : '#2563EB' }]}>
              {visibleTasks.length}
            </Text>
            <Text style={[styles.summaryLabelPrimary, { color: isDark ? '#93C5FD' : '#2563EB' }]}>{t('total')}</Text>
          </Pressable>

          <Pressable
            style={[
              styles.summaryCard,
              { backgroundColor: themeColors.surface, borderColor: themeColors.border },
              selectedCategory === 'Production' && styles.summaryCardActiveBorder,
            ]}
            onPress={() => setSelectedCategory('Production')}
          >
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
              <Ionicons name="business" size={15} color="#0284C7" />
              <Text style={[styles.summaryValue, { color: themeColors.text }]}>
                {prodCount}
              </Text>
            </View>
            <Text style={[styles.summaryLabel, { color: themeColors.textSecondary }]}>{t('filterProduction')}</Text>
          </Pressable>

          <Pressable
            style={[
              styles.summaryCard,
              { backgroundColor: themeColors.surface, borderColor: themeColors.border },
              selectedCategory === 'Machines' && styles.summaryCardActiveBorder,
            ]}
            onPress={() => setSelectedCategory('Machines')}
          >
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
              <Ionicons name="warning" size={15} color="#DC2626" />
              <Text style={[styles.summaryValue, { color: '#DC2626' }]}>
                {machCount}
              </Text>
            </View>
            <Text style={[styles.summaryLabel, { color: themeColors.textSecondary }]}>{t('breakdown')}</Text>
          </Pressable>

          <Pressable
            style={[
              styles.summaryCard,
              { backgroundColor: themeColors.surface, borderColor: themeColors.border },
              selectedCategory === 'Materials' && styles.summaryCardActiveBorder,
            ]}
            onPress={() => setSelectedCategory('Materials')}
          >
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
              <Ionicons name="cube" size={15} color="#D97706" />
              <Text style={[styles.summaryValue, { color: themeColors.text }]}>
                {matsCount}
              </Text>
            </View>
            <Text style={[styles.summaryLabel, { color: themeColors.textSecondary }]}>{t('lowStock')}</Text>
          </Pressable>

          <Pressable
            style={[
              styles.summaryCard,
              { backgroundColor: themeColors.surface, borderColor: themeColors.border },
              selectedCategory === 'Maintenance' && styles.summaryCardActiveBorder,
            ]}
            onPress={() => setSelectedCategory('Maintenance')}
          >
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
              <Ionicons name="construct" size={15} color="#16A34A" />
              <Text style={[styles.summaryValue, { color: themeColors.text }]}>
                {maintCount}
              </Text>
            </View>
            <Text style={[styles.summaryLabel, { color: themeColors.textSecondary }]}>{t('maintenance')}</Text>
          </Pressable>

          <Pressable
            style={[
              styles.summaryCard,
              { backgroundColor: themeColors.surface, borderColor: themeColors.border },
              selectedCategory === 'Quality' && styles.summaryCardActiveBorder,
            ]}
            onPress={() => setSelectedCategory('Quality')}
          >
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
              <Ionicons name="refresh" size={15} color="#7C3AED" />
              <Text style={[styles.summaryValue, { color: themeColors.text }]}>
                {reworkCount}
              </Text>
            </View>
            <Text style={[styles.summaryLabel, { color: themeColors.textSecondary }]}>{t('rework')}</Text>
          </Pressable>

          <Pressable
            style={[
              styles.summaryCard,
              { backgroundColor: themeColors.surface, borderColor: themeColors.border },
              selectedCategory === 'Dispatch' && styles.summaryCardActiveBorder,
            ]}
            onPress={() => setSelectedCategory('Dispatch')}
          >
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
              <Ionicons name="car" size={15} color="#64748B" />
              <Text style={[styles.summaryValue, { color: themeColors.text }]}>
                {dispCount}
              </Text>
            </View>
            <Text style={[styles.summaryLabel, { color: themeColors.textSecondary }]}>{t('dispatch')}</Text>
          </Pressable>
        </ScrollView>
      ) : (
        /* History filters */
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.categoryPillsRow}
        >
          {HISTORY_FILTER_DEFS.map((f) => (
            <Pressable
              key={f.labelKey}
              style={[
                styles.filterPill,
                { backgroundColor: isDark ? '#1E293B' : '#FFFFFF', borderColor: themeColors.border },
                historyFilter === f.type && styles.filterPillActive,
              ]}
              onPress={() => setHistoryFilter(f.type)}
            >
              <Text
                style={[
                  styles.filterPillText,
                  { color: isDark ? '#E2E8F0' : '#475569' },
                  historyFilter === f.type && styles.filterPillTextActive,
                ]}
              >
                {t(f.labelKey)}
              </Text>
            </Pressable>
          ))}
        </ScrollView>
      )}
    </View>
  );

  return (
    <View style={[styles.screen, { backgroundColor: themeColors.background }]}>
      <AppHeader />
      {mode === 'tasks' ? (
        <FlatList
          style={styles.list}
          contentContainerStyle={styles.content}
          data={filteredTasks}
          keyExtractor={(t) => t.id}
          ListHeaderComponent={renderHeader}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={load}
              tintColor={colors.primary}
            />
          }
          ListEmptyComponent={
            <Card style={{ padding: 24, alignItems: 'center', backgroundColor: themeColors.surface, borderColor: themeColors.border }}>
              <Ionicons name="checkmark-done-circle" size={40} color="#10B981" />
              <Text style={{ fontSize: 15, fontWeight: '700', color: themeColors.text, marginTop: 8 }}>
                {t('allClear')}
              </Text>
              <Text style={{ fontSize: 12, color: themeColors.textSecondary, marginTop: 3, textAlign: 'center' }}>
                {t('noOpenIssues')}
              </Text>
            </Card>
          }
          renderItem={({ item }) => {
            const v = getTaskVisuals(item);

            return (
              <View style={[styles.taskCard, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}>
                <View style={styles.taskCardInner}>
                  {/* Left Pastel Icon */}
                  <View style={[styles.taskIconBox, { backgroundColor: v.iconBg }]}>
                    <Ionicons name={v.icon} size={22} color={v.iconColor} />
                  </View>

                  {/* Task Content */}
                  <View style={{ flex: 1 }}>
                    {/* Category + Status badge + Waiting time */}
                    <View style={styles.taskTopMetaRow}>
                      <Text style={styles.taskCategoryLabel}>
                        {item.category.toUpperCase()}
                      </Text>

                      <View style={[styles.taskStatusPill, { backgroundColor: v.badgeBg }]}>
                        <Text style={[styles.taskStatusPillText, { color: v.badgeColor }]}>
                          {v.badgeText}
                        </Text>
                      </View>

                      <View style={styles.taskWaitingTimeRow}>
                        <Ionicons name="time-outline" size={11} color={v.timeColor} />
                        <Text style={[styles.taskWaitingTimeText, { color: v.timeColor }]}>
                          {t('waitingSince')}
                        </Text>
                      </View>
                    </View>

                    {/* Title & Subtitle */}
                    <Text style={[styles.taskCardTitle, { color: themeColors.text }]}>{item.title}</Text>
                    <Text style={[styles.taskCardSubtitle, { color: themeColors.textSecondary }]} numberOfLines={1}>
                      {item.subtitle}
                    </Text>

                    {/* Footer tags */}
                    <View style={styles.taskFooterRow}>
                      <View style={[styles.taskFooterTag, { backgroundColor: isDark ? '#0F172A' : '#F8FAFC' }]}>
                        <Ionicons name="document-text-outline" size={11} color={themeColors.textSecondary} />
                        <Text style={[styles.taskFooterTagText, { color: themeColors.textSecondary }]}>{v.defaultRef}</Text>
                      </View>

                      <View style={[styles.taskFooterTag, { backgroundColor: isDark ? '#0F172A' : '#F8FAFC' }]}>
                        <Ionicons name="location-outline" size={11} color={themeColors.textSecondary} />
                        <Text style={[styles.taskFooterTagText, { color: themeColors.textSecondary }]}>{v.location}</Text>
                      </View>
                    </View>
                  </View>

                  {/* Right Action: Chevron + Handle Button */}
                  <View style={styles.taskRightActionContainer}>
                    <Ionicons
                      name="chevron-forward"
                      size={14}
                      color="#94A3B8"
                      style={{ alignSelf: 'flex-end', marginBottom: 12 }}
                    />
                    <Pressable
                      style={styles.handleButton}
                      onPress={() => {
                        if (item.quickAction) {
                          runQuickAction(item);
                        } else {
                          openTask(navigation, item);
                        }
                      }}
                    >
                      <Text style={styles.handleButtonText}>{t('handle')}</Text>
                    </Pressable>
                  </View>
                </View>
              </View>
            );
          }}
        />
      ) : (
        /* History Event List */
        <FlatList
          style={styles.list}
          contentContainerStyle={styles.content}
          data={history}
          keyExtractor={(a) => a.id}
          ListHeaderComponent={renderHeader}
          refreshControl={
            <RefreshControl
              refreshing={refreshing}
              onRefresh={load}
              tintColor={colors.primary}
            />
          }
          ListEmptyComponent={
            <Card style={{ padding: 24, alignItems: 'center', backgroundColor: themeColors.surface, borderColor: themeColors.border }}>
              <Text style={[typography.bodySmall, { color: themeColors.textSecondary }]}>{t('noActivityDateRange')}</Text>
            </Card>
          }
          renderItem={({ item }) => (
            <Pressable
              onPress={() => {
                const ok = navigateToActivityReference(
                  navigation,
                  item.reference_type,
                  item.reference_id,
                );
                if (!ok) {
                  Alert.alert(item.title, item.description ?? item.event_type);
                }
              }}
            >
              <Card style={[styles.historyCard, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}>
                <View style={{ flexDirection: 'row', justifyContent: 'space-between' }}>
                  <Text style={styles.historyEventLabel}>
                    {item.event_type.replace(/_/g, ' ')}
                  </Text>
                  <Text style={[styles.historyTime, { color: themeColors.textSecondary }]}>{formatDateTime(item.timestamp)}</Text>
                </View>
                <Text style={[styles.historyTitle, { color: themeColors.text }]}>{item.title}</Text>
                {item.description ? (
                  <Text style={[styles.historyDesc, { color: themeColors.textSecondary }]}>{item.description}</Text>
                ) : null}
                {item.reference_type ? (
                  <Text style={styles.openHint}>{t('tapToViewRecord')}</Text>
                ) : null}
              </Card>
            </Pressable>
          )}
        />
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, backgroundColor: '#F8FAFC' },
  list: { flex: 1 },
  content: { paddingHorizontal: 16, paddingTop: 14, paddingBottom: 40 },

  headerBlock: {
    marginBottom: 14,
  },
  topControlRow: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'center',
    marginBottom: 10,
    marginTop: 2,
  },
  historyPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 20,
    paddingHorizontal: 10,
    paddingVertical: 6,
  },
  historyPillActive: {
    backgroundColor: '#2563EB',
    borderColor: '#2563EB',
  },
  historyPillText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#2563EB',
  },
  historyPillTextActive: {
    color: '#FFFFFF',
  },

  /* 7 Summary Cards */
  summaryCardsRow: {
    gap: 8,
    paddingBottom: 4,
    marginBottom: 14,
  },
  summaryCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    paddingVertical: 10,
    paddingHorizontal: 14,
    minWidth: 84,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 3,
    elevation: 1,
  },
  summaryCardPrimary: {
    backgroundColor: '#EFF6FF',
    borderColor: '#BFDBFE',
  },
  summaryCardActiveBorder: {
    borderColor: '#2563EB',
    borderWidth: 1.5,
  },
  summaryValuePrimary: {
    fontSize: 18,
    fontWeight: '800',
    color: '#2563EB',
  },
  summaryLabelPrimary: {
    fontSize: 10.5,
    fontWeight: '700',
    color: '#2563EB',
    marginTop: 2,
  },
  summaryValue: {
    fontSize: 16,
    fontWeight: '800',
    color: '#0F172A',
  },
  summaryLabel: {
    fontSize: 10.5,
    fontWeight: '600',
    color: '#64748B',
    marginTop: 2,
  },


  /* Category Filter Pills */
  categoryPillsRow: {
    gap: 7,
    paddingBottom: 4,
    marginBottom: 12,
  },
  filterPill: {
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 18,
    paddingHorizontal: 13,
    paddingVertical: 6,
  },
  filterPillActive: {
    backgroundColor: '#2563EB',
    borderColor: '#2563EB',
  },
  filterPillText: {
    fontSize: 11,
    fontWeight: '600',
    color: '#475569',
  },
  filterPillTextActive: {
    color: '#FFFFFF',
    fontWeight: '700',
  },


  /* Task Card */
  taskCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 12,
    marginBottom: 10,
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 3,
    elevation: 1,
  },
  taskCardInner: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 12,
  },
  taskIconBox: {
    width: 44,
    height: 44,
    borderRadius: 12,
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: 2,
  },
  taskTopMetaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: 6,
    marginBottom: 3,
  },
  taskCategoryLabel: {
    fontSize: 9.5,
    fontWeight: '800',
    color: '#94A3B8',
    letterSpacing: 0.4,
  },
  taskStatusPill: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 6,
  },
  taskStatusPillText: {
    fontSize: 9,
    fontWeight: '800',
  },
  taskWaitingTimeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
  },
  taskWaitingTimeText: {
    fontSize: 9.5,
    fontWeight: '600',
  },
  taskCardTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 2,
  },
  taskCardSubtitle: {
    fontSize: 11.5,
    color: '#64748B',
    marginBottom: 6,
  },
  taskFooterRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  taskFooterTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
  },
  taskFooterTagText: {
    fontSize: 10,
    color: '#64748B',
    fontWeight: '500',
  },
  taskRightActionContainer: {
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    paddingTop: 2,
  },
  handleButton: {
    backgroundColor: '#2563EB',
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderRadius: 8,
  },
  handleButtonText: {
    color: '#FFFFFF',
    fontSize: 11.5,
    fontWeight: '700',
  },

  /* History Card */
  historyCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 12,
    marginBottom: 8,
  },
  historyEventLabel: {
    fontSize: 10.5,
    fontWeight: '700',
    color: '#2563EB',
    textTransform: 'uppercase',
  },
  historyTime: {
    fontSize: 10,
    color: '#94A3B8',
  },
  historyTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0F172A',
    marginTop: 3,
  },
  historyDesc: {
    fontSize: 11,
    color: '#64748B',
    marginTop: 2,
  },
  openHint: {
    fontSize: 10.5,
    color: '#2563EB',
    fontWeight: '600',
    marginTop: 6,
  },
});
