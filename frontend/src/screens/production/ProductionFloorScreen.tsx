import { useNavigation, useRoute } from '@react-navigation/native';
import type { NavigationProp, ParamListBase } from '@react-navigation/native';
import { useCallback, useMemo, useState } from 'react';
import {
  Alert,
  FlatList,
  Modal,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { StatusBadge } from '../../components/common/StatusBadge';
import { ViewModeBanner } from '../../components/common/ViewModeBanner';
import { SearchField } from '../../components/common/SearchField';
import { Button } from '../../components/common/Button';
import { Card } from '../../components/common/Card';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import {
  assignOperatorToMachine,
  createLine,
  listLines,
  listMachineOperatorSummaries,
} from '../../database/repositories/machineRepository';
import { listProductionOrders } from '../../database/repositories/productionOrderRepository';
import { listStaff } from '../../database/repositories/staffRepository';
import type {
  MachineOperatorSummary,
  ProductionOrderRow,
  StaffRow,
} from '../../types/database';
import { getRangeForPreset, type DatePreset } from '../../utils/dateRange';
import { formatNumber } from '../../utils/format';
import { colors, spacing } from '../../theme';

type PeriodFilter = DatePreset | 'all';

const PERIOD_TABS: { label: string; value: PeriodFilter }[] = [
  { label: 'Today', value: 'today' },
  { label: 'This Week', value: 'week' },
  { label: 'This Month', value: 'month' },
  { label: 'All Time', value: 'all' },
];

const SHIFT_OPTIONS: ('Morning' | 'Evening' | 'Night')[] = ['Morning', 'Evening', 'Night'];

export function ProductionFloorScreen() {
  const navigation = useNavigation<NavigationProp<ParamListBase>>();
  const route = useRoute<any>();
  const isViewOnly = Boolean(route.params?.viewOnly);

  const [period, setPeriod] = useState<PeriodFilter>('today');
  const [search, setSearch] = useState('');
  const [refreshing, setRefreshing] = useState(false);

  const [lines, setLines] = useState<{ id: string; code: string; name: string }[]>([]);
  const [machineSummaries, setMachineSummaries] = useState<MachineOperatorSummary[]>([]);
  const [activeOrders, setActiveOrders] = useState<ProductionOrderRow[]>([]);
  const [staffList, setStaffList] = useState<StaffRow[]>([]);

  // Add Line Modal State
  const [addLineModalVisible, setAddLineModalVisible] = useState(false);
  const [newLineCode, setNewLineCode] = useState('');
  const [newLineName, setNewLineName] = useState('');
  const [isSubmittingLine, setIsSubmittingLine] = useState(false);

  // Assign Worker Modal State
  const [assignModalVisible, setAssignModalVisible] = useState(false);
  const [assignMachineId, setAssignMachineId] = useState('');
  const [assignMachineCode, setAssignMachineCode] = useState('');
  const [assignShift, setAssignShift] = useState<'Morning' | 'Evening' | 'Night'>('Morning');
  const [assignOperatorName, setAssignOperatorName] = useState('');
  const [assignNotes, setAssignNotes] = useState('');
  const [isSubmittingAssign, setIsSubmittingAssign] = useState(false);

  const loadData = useCallback(async () => {
    setRefreshing(true);
    try {
      let startDate: number | undefined;
      let endDate: number | undefined;

      if (period !== 'all') {
        const range = getRangeForPreset(period);
        startDate = range.start;
        endDate = range.end;
      }

      const [l, mSummaries, orders, staff] = await Promise.all([
        listLines(),
        listMachineOperatorSummaries({ startDate, endDate }),
        listProductionOrders({ status: 'IN_PROGRESS' }),
        listStaff({ activeOnly: true }).catch(() => []),
      ]);

      setLines(l);
      setMachineSummaries(mSummaries);
      setActiveOrders(orders);
      setStaffList(staff);
    } catch (e: unknown) {
      console.error('Error loading production floor data:', e);
    } finally {
      setRefreshing(false);
    }
  }, [period]);

  useLiveQuery(loadData);

  // Active production orders mapped by machine id
  const orderByMachine = useMemo(() => {
    const map = new Map<string, ProductionOrderRow>();
    for (const o of activeOrders) {
      if (o.machine_id) {
        map.set(o.machine_id, o);
      }
    }
    return map;
  }, [activeOrders]);

  // Filtered machines based on search
  const filteredMachines = useMemo(() => {
    if (!search.trim()) return machineSummaries;
    const q = search.trim().toLowerCase();
    return machineSummaries.filter(
      (m) =>
        m.machine_code.toLowerCase().includes(q) ||
        m.machine_name.toLowerCase().includes(q) ||
        (m.line_code || '').toLowerCase().includes(q) ||
        (m.line_name || '').toLowerCase().includes(q) ||
        (m.current_operator || '').toLowerCase().includes(q) ||
        (m.current_product || '').toLowerCase().includes(q) ||
        m.operators.some((op) => op.name.toLowerCase().includes(q)),
    );
  }, [machineSummaries, search]);

  // Group machines by Line
  const groupedLines = useMemo(() => {
    return lines.map((line) => {
      const lineMachines = filteredMachines.filter(
        (m) => m.line_id === line.id || m.line_code === line.code,
      );
      const lineProduced = lineMachines.reduce((acc, m) => acc + (m.total_produced || 0), 0);
      const runningMachines = lineMachines.filter((m) => m.machine_status === 'RUNNING').length;
      return {
        line,
        machines: lineMachines,
        lineProduced,
        runningMachines,
      };
    });
  }, [lines, filteredMachines]);

  // Aggregate floor metrics
  const totalFloorProduced = useMemo(() => {
    return machineSummaries.reduce((sum, m) => sum + (m.total_produced || 0), 0);
  }, [machineSummaries]);

  const totalRunningCount = useMemo(() => {
    return machineSummaries.filter((m) => m.machine_status === 'RUNNING').length;
  }, [machineSummaries]);

  const totalActiveWorkers = useMemo(() => {
    const workerSet = new Set<string>();
    for (const m of machineSummaries) {
      for (const sa of m.shift_assignments || []) {
        if (sa.operator) workerSet.add(sa.operator.trim().toLowerCase());
      }
    }
    return workerSet.size;
  }, [machineSummaries]);

  // Handlers for Line Creation
  const handleOpenAddLine = () => {
    setNewLineCode('');
    setNewLineName('');
    setAddLineModalVisible(true);
  };

  const handleCreateLineSubmit = async () => {
    if (!newLineCode.trim() || !newLineName.trim()) {
      Alert.alert('Required Fields', 'Please enter both line code (e.g. LINE-E) and line name.');
      return;
    }
    try {
      setIsSubmittingLine(true);
      await createLine({
        code: newLineCode.trim().toUpperCase(),
        name: newLineName.trim(),
      });
      setAddLineModalVisible(false);
      Alert.alert('Success', `Production Line ${newLineCode.trim().toUpperCase()} created!`);
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not create line');
    } finally {
      setIsSubmittingLine(false);
    }
  };

  // Handlers for Worker Assignment
  const handleOpenAssignModal = (
    machineId: string,
    machineCode: string,
    shift: 'Morning' | 'Evening' | 'Night',
    currentOp?: string | null,
  ) => {
    if (isViewOnly) return;
    setAssignMachineId(machineId);
    setAssignMachineCode(machineCode);
    setAssignShift(shift);
    setAssignOperatorName(currentOp || '');
    setAssignNotes('');
    setAssignModalVisible(true);
  };

  const handleAssignSubmit = async () => {
    if (!assignOperatorName.trim()) {
      Alert.alert('Missing Name', 'Please select or enter the worker name for this shift.');
      return;
    }
    try {
      setIsSubmittingAssign(true);
      await assignOperatorToMachine(
        assignMachineId,
        assignOperatorName.trim(),
        assignShift,
        assignNotes.trim() || undefined,
      );
      setAssignModalVisible(false);
      Alert.alert(
        'Staff Assigned',
        `${assignOperatorName} assigned to ${assignMachineCode} for ${assignShift} shift.`,
      );
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Assignment Error', e instanceof Error ? e.message : 'Could not assign worker');
    } finally {
      setIsSubmittingAssign(false);
    }
  };

  const handleOpenRecordProduction = (machine: MachineOperatorSummary) => {
    if (isViewOnly) return;
    const active = orderByMachine.get(machine.machine_id);
    if (active) {
      navigation.navigate('RecordProduction', { orderId: active.id, machineId: machine.machine_id });
    } else if (activeOrders.length === 1) {
      navigation.navigate('RecordProduction', {
        orderId: activeOrders[0].id,
        machineId: machine.machine_id,
      });
    } else if (activeOrders.length > 1) {
      navigation.navigate('RecordProduction', { machineId: machine.machine_id });
    } else {
      Alert.alert(
        'No Active Order',
        `To record production on ${machine.machine_code}, there should be an active order.`,
        [
          { text: 'Cancel', style: 'cancel' },
          {
            text: 'View / Start Orders',
            onPress: () => navigation.navigate('ProductionOrders'),
          },
        ],
      );
    }
  };

  return (
    <View style={styles.container}>
      {isViewOnly && (
        <ViewModeBanner message="Live Production Floor Overview. Showing machine outputs, workers and shift details. Modification actions are disabled in view mode." />
      )}

      {/* Header Bar: Title & Add Line Button */}
      <View style={styles.headerRow}>
        <View style={{ flex: 1 }}>
          <Text style={styles.headerTitle}>Floor & Shift Output</Text>
          <Text style={styles.headerSubtitle}>
            Live output by line, machine, workers & shifts
          </Text>
        </View>

        {!isViewOnly && (
          <Pressable style={styles.addLineBtn} onPress={handleOpenAddLine}>
            <Ionicons name="add" size={17} color="#FFFFFF" />
            <Text style={styles.addLineBtnText}>+ Add Line</Text>
          </Pressable>
        )}
      </View>

      {/* KPI Summary Cards Strip */}
      <View style={styles.kpiGrid}>
        <View style={[styles.kpiCard, { borderColor: '#BBF7D0', backgroundColor: '#F0FDF4' }]}>
          <View style={styles.kpiCardHeader}>
            <Ionicons name="flash" size={15} color="#16A34A" />
            <Text style={[styles.kpiLabel, { color: '#166534' }]}>Total Output</Text>
          </View>
          <Text style={[styles.kpiValue, { color: '#14532D' }]}>
            {formatNumber(totalFloorProduced)}{' '}
            <Text style={styles.kpiUnit}>pcs</Text>
          </Text>
        </View>

        <View style={[styles.kpiCard, { borderColor: '#BAE6FD', backgroundColor: '#F0F9FF' }]}>
          <View style={styles.kpiCardHeader}>
            <Ionicons name="hardware-chip-outline" size={15} color="#0284C7" />
            <Text style={[styles.kpiLabel, { color: '#075985' }]}>Running</Text>
          </View>
          <Text style={[styles.kpiValue, { color: '#0C4A6E' }]}>
            {totalRunningCount} / {machineSummaries.length}
          </Text>
        </View>

        <View style={[styles.kpiCard, { borderColor: '#DDD6FE', backgroundColor: '#F5F3FF' }]}>
          <View style={styles.kpiCardHeader}>
            <Ionicons name="people-outline" size={15} color="#7C3AED" />
            <Text style={[styles.kpiLabel, { color: '#5B21B6' }]}>Workers</Text>
          </View>
          <Text style={[styles.kpiValue, { color: '#4C1D95' }]}>
            {totalActiveWorkers} on shift
          </Text>
        </View>
      </View>

      {/* Period Filter Tabs (Today, Week, Month, All Time) */}
      <View style={styles.periodTabsRow}>
        {PERIOD_TABS.map((tab) => {
          const isActive = period === tab.value;
          return (
            <Pressable
              key={tab.value}
              style={[styles.periodTab, isActive && styles.periodTabActive]}
              onPress={() => setPeriod(tab.value)}
            >
              <Text style={[styles.periodTabText, isActive && styles.periodTabTextActive]}>
                {tab.label}
              </Text>
            </Pressable>
          );
        })}
      </View>

      {/* Search Bar */}
      <View style={styles.searchWrapper}>
        <SearchField
          value={search}
          onChangeText={setSearch}
          placeholder="Search machine, line, worker or product…"
        />
      </View>

      {/* Direct Record Action Bar (if not viewOnly) */}
      {!isViewOnly && (
        <Pressable
          style={styles.quickRecordCard}
          onPress={() => {
            if (activeOrders.length > 0) {
              navigation.navigate('RecordProduction', { orderId: activeOrders[0].id });
            } else {
              navigation.navigate('RecordProduction', {});
            }
          }}
        >
          <View style={styles.quickRecordIcon}>
            <Ionicons name="create-outline" size={18} color="#FFFFFF" />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={styles.quickRecordTitle}>Log Production Output</Text>
            <Text style={styles.quickRecordSubtitle}>
              {activeOrders.length > 0
                ? `${activeOrders.length} order${activeOrders.length > 1 ? 's' : ''} running • Tap to record pieces & shift`
                : 'Select an order and log output pieces per worker'}
            </Text>
          </View>
          <Ionicons name="chevron-forward" size={16} color="#0A1E38" />
        </Pressable>
      )}

      {/* Lines and Machines List */}
      <FlatList
        data={groupedLines}
        keyExtractor={(item) => item.line.id}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={loadData} tintColor={colors.primary} />
        }
        contentContainerStyle={{ paddingBottom: 40 }}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Ionicons name="git-branch-outline" size={48} color={colors.textMuted} />
            <Text style={styles.emptyTitle}>No Production Lines</Text>
            <Text style={styles.emptySubtitle}>
              Create a production line to start assigning machines and logging shift output.
            </Text>
            {!isViewOnly && (
              <Button
                label="+ Add Production Line"
                variant="primary"
                onPress={handleOpenAddLine}
                style={{ marginTop: 12 }}
              />
            )}
          </View>
        }
        renderItem={({ item }) => (
          <View style={styles.lineContainer}>
            {/* Line Header */}
            <View style={styles.lineHeaderCard}>
              <View style={styles.lineHeaderLeft}>
                <View style={styles.lineBadge}>
                  <Ionicons name="git-network-outline" size={14} color="#0284C7" />
                  <Text style={styles.lineBadgeText}>{item.line.code}</Text>
                </View>
                <Text style={styles.lineNameText} numberOfLines={1}>
                  {item.line.name}
                </Text>
              </View>

              <View style={styles.lineHeaderRight}>
                <View style={styles.lineOutputPill}>
                  <Ionicons name="layers-outline" size={12} color="#15803D" />
                  <Text style={styles.lineOutputText}>
                    {formatNumber(item.lineProduced)} pcs
                  </Text>
                </View>
                <Text style={styles.lineMachineCount}>
                  {item.machines.length} machine{item.machines.length === 1 ? '' : 's'}
                </Text>
              </View>
            </View>

            {/* Machines in Line */}
            {item.machines.length === 0 ? (
              <View style={styles.lineEmptyState}>
                <Text style={styles.lineEmptyText}>No machines assigned to {item.line.code} yet.</Text>
                {!isViewOnly && (
                  <Pressable
                    style={styles.addMachineToLineBtn}
                    onPress={() => navigation.navigate('MachineList')}
                  >
                    <Ionicons name="add-circle-outline" size={14} color={colors.primary} />
                    <Text style={styles.addMachineToLineText}>Assign / Add Machine</Text>
                  </Pressable>
                )}
              </View>
            ) : (
              item.machines.map((m) => {
                const active = orderByMachine.get(m.machine_id);

                return (
                  <Card key={m.machine_id} style={styles.machineCard}>
                    {/* Top Row: Machine Code, Name, Type, and Status */}
                    <View style={styles.machineHeader}>
                      <View style={{ flex: 1 }}>
                        <View style={styles.machineTitleRow}>
                          <Text style={styles.machineCode}>{m.machine_code}</Text>
                          <View style={styles.machineTypeBadge}>
                            <Text style={styles.machineTypeText}>{m.machine_type || 'General'}</Text>
                          </View>
                        </View>
                        <Text style={styles.machineName} numberOfLines={2}>
                          {m.machine_name}
                        </Text>
                      </View>
                      <StatusBadge status={m.machine_status} />
                    </View>

                    {/* Active Production Order Info (if running) */}
                    {active && (
                      <View style={styles.activeOrderBox}>
                        <View style={styles.activeOrderRow}>
                          <Ionicons name="play-circle" size={14} color="#0284C7" />
                          <Text style={styles.activeOrderNumber}>{active.order_number}</Text>
                          <Text style={styles.activeOrderProduct} numberOfLines={1}>
                            · {active.product_code || 'Product'} ({active.produced_quantity || 0} / {active.target_quantity} pcs)
                          </Text>
                        </View>
                        <View style={styles.progressBarBg}>
                          <View
                            style={[
                              styles.progressBarFill,
                              {
                                width: `${Math.min(
                                  100,
                                  Math.round(
                                    ((active.produced_quantity || 0) / (active.target_quantity || 1)) *
                                      100,
                                  ),
                                )}%`,
                              },
                            ]}
                          />
                        </View>
                      </View>
                    )}

                    {/* SHIFT & WORKER BREAKDOWN TABLE */}
                    <View style={styles.shiftsContainer}>
                      <View style={styles.shiftsTitleRow}>
                        <Ionicons name="time-outline" size={13} color="#0A1E38" />
                        <Text style={styles.shiftsTitle}>Shift Output & Assigned Staff</Text>
                        <Text style={styles.shiftsSubtitleNote}>
                          Units completed in {period === 'all' ? 'All Time' : period === 'today' ? 'Today' : period === 'week' ? 'Past 7 Days' : 'This Month'}
                        </Text>
                      </View>

                      {/* 3 Shifts: Morning, Evening, Night */}
                      <View style={styles.shiftCardsList}>
                        {SHIFT_OPTIONS.map((sh) => {
                          const assignment = (m.shift_assignments || []).find((s) => s.shift === sh);
                          const isMorning = sh === 'Morning';
                          const isEvening = sh === 'Evening';
                          const shiftColor = isMorning ? '#EA580C' : isEvening ? '#D97706' : '#6366F1';
                          const shiftBg = isMorning ? '#FFF7ED' : isEvening ? '#FEF3C7' : '#EEF2FF';
                          const shiftIcon = isMorning
                            ? 'sunny-outline'
                            : isEvening
                              ? 'partly-sunny-outline'
                              : 'moon-outline';
                          const shiftTime = isMorning
                            ? '06:00 - 14:00'
                            : isEvening
                              ? '14:00 - 22:00'
                              : '22:00 - 06:00';

                          const workerName = assignment?.operator;
                          const unitsProduced = assignment?.total_produced || 0;

                          return (
                            <View
                              key={sh}
                              style={[
                                styles.shiftItemRow,
                                workerName ? styles.shiftItemRowActive : styles.shiftItemRowEmpty,
                              ]}
                            >
                              {/* Left: Shift Badge & Time */}
                              <View style={styles.shiftItemLeft}>
                                <View style={[styles.shiftIconBox, { backgroundColor: shiftBg }]}>
                                  <Ionicons name={shiftIcon} size={14} color={shiftColor} />
                                </View>
                                <View>
                                  <Text style={[styles.shiftLabelText, { color: shiftColor }]}>
                                    {sh}
                                  </Text>
                                  <Text style={styles.shiftTimeText}>{shiftTime}</Text>
                                </View>
                              </View>

                              {/* Center: Person / Worker Name */}
                              <View style={styles.shiftItemCenter}>
                                {workerName ? (
                                  <View style={styles.workerBadge}>
                                    <Ionicons name="person" size={12} color={colors.primary} />
                                    <Text style={styles.workerNameText} numberOfLines={1}>
                                      {workerName}
                                    </Text>
                                  </View>
                                ) : (
                                  <Text style={styles.unassignedWorkerText}>
                                    No worker assigned
                                  </Text>
                                )}
                              </View>

                              {/* Right: Units Completed Count & Assign button */}
                              <View style={styles.shiftItemRight}>
                                <View
                                  style={[
                                    styles.unitsBadge,
                                    unitsProduced > 0 && styles.unitsBadgeActive,
                                  ]}
                                >
                                  <Text
                                    style={[
                                      styles.unitsValueText,
                                      unitsProduced > 0 && styles.unitsValueTextActive,
                                    ]}
                                  >
                                    {formatNumber(unitsProduced)}{' '}
                                    <Text style={styles.unitsSuffix}>pcs</Text>
                                  </Text>
                                </View>

                                {!isViewOnly && (
                                  <Pressable
                                    hitSlop={8}
                                    style={styles.shiftAssignBtn}
                                    onPress={() =>
                                      handleOpenAssignModal(
                                        m.machine_id,
                                        m.machine_code,
                                        sh,
                                        workerName,
                                      )
                                    }
                                  >
                                    <Ionicons
                                      name={workerName ? 'create-outline' : 'person-add-outline'}
                                      size={14}
                                      color="#0284C7"
                                    />
                                  </Pressable>
                                )}
                              </View>
                            </View>
                          );
                        })}
                      </View>
                    </View>

                    {/* Machine Total Output Footer & Actions */}
                    <View style={styles.machineFooterRow}>
                      <View style={styles.machineTotalStat}>
                        <Text style={styles.machineTotalLabel}>Machine Total:</Text>
                        <Text style={styles.machineTotalValue}>
                          {formatNumber(m.total_produced)} pcs
                        </Text>
                        {m.total_rejected > 0 && (
                          <Text style={styles.machineRejectValue}>
                            ({formatNumber(m.total_rejected)} reject)
                          </Text>
                        )}
                      </View>

                      <View style={styles.machineActionBtns}>
                        {!isViewOnly && (
                          <Pressable
                            style={styles.recordMachineBtn}
                            onPress={() => handleOpenRecordProduction(m)}
                          >
                            <Ionicons name="create-outline" size={13} color="#0284C7" />
                            <Text style={styles.recordMachineBtnText}>Record Output</Text>
                          </Pressable>
                        )}
                        <Pressable
                          style={styles.machineDetailBtn}
                          onPress={() =>
                            navigation.navigate('MachineDetail', { machineId: m.machine_id })
                          }
                        >
                          <Ionicons name="chevron-forward" size={16} color={colors.textMuted} />
                        </Pressable>
                      </View>
                    </View>
                  </Card>
                );
              })
            )}
          </View>
        )}
      />

      {/* MODAL 1: ADD PRODUCTION LINE */}
      <Modal
        visible={addLineModalVisible}
        transparent
        animationType="slide"
        onRequestClose={() => setAddLineModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                <View style={[styles.modalIconBox, { backgroundColor: '#E0F2FE' }]}>
                  <Ionicons name="git-branch-outline" size={18} color="#0284C7" />
                </View>
                <Text style={styles.modalTitle}>Add Production Line</Text>
              </View>
              <Pressable onPress={() => setAddLineModalVisible(false)}>
                <Ionicons name="close" size={22} color={colors.textSecondary} />
              </Pressable>
            </View>

            <ScrollView showsVerticalScrollIndicator={false}>
              <Text style={styles.inputLabel}>Line Code *</Text>
              <TextInput
                style={styles.textInput}
                placeholder="e.g. LINE-E or PACK-01"
                value={newLineCode}
                onChangeText={setNewLineCode}
                autoCapitalize="characters"
              />

              <Text style={styles.inputLabel}>Line Name / Description *</Text>
              <TextInput
                style={styles.textInput}
                placeholder="e.g. Final Packaging & Dispatch Line"
                value={newLineName}
                onChangeText={setNewLineName}
              />

              <View style={styles.modalHelperBox}>
                <Ionicons name="information-circle-outline" size={16} color="#0284C7" />
                <Text style={styles.modalHelperText}>
                  Machines, production orders, and shift records can be linked to this line once created.
                </Text>
              </View>
            </ScrollView>

            <View style={styles.modalActions}>
              <Button
                label="Cancel"
                variant="secondary"
                style={{ flex: 1 }}
                onPress={() => setAddLineModalVisible(false)}
              />
              <Button
                label={isSubmittingLine ? 'Creating…' : 'Create Line'}
                variant="primary"
                style={{ flex: 1 }}
                onPress={handleCreateLineSubmit}
                disabled={isSubmittingLine}
              />
            </View>
          </View>
        </View>
      </Modal>

      {/* MODAL 2: ASSIGN WORKER TO MACHINE SHIFT */}
      <Modal
        visible={assignModalVisible}
        transparent
        animationType="slide"
        onRequestClose={() => setAssignModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                <View style={[styles.modalIconBox, { backgroundColor: '#FEF3C7' }]}>
                  <Ionicons name="person-add-outline" size={18} color="#D97706" />
                </View>
                <View>
                  <Text style={styles.modalTitle}>Assign Shift Worker</Text>
                  <Text style={styles.modalSubtitle}>
                    {assignMachineCode} · {assignShift} Shift
                  </Text>
                </View>
              </View>
              <Pressable onPress={() => setAssignModalVisible(false)}>
                <Ionicons name="close" size={22} color={colors.textSecondary} />
              </Pressable>
            </View>

            <ScrollView showsVerticalScrollIndicator={false}>
              <Text style={styles.inputLabel}>Shift</Text>
              <View style={styles.shiftSelectRow}>
                {SHIFT_OPTIONS.map((sh) => {
                  const isSel = assignShift === sh;
                  return (
                    <Pressable
                      key={sh}
                      style={[styles.shiftSelectChip, isSel && styles.shiftSelectChipActive]}
                      onPress={() => setAssignShift(sh)}
                    >
                      <Text style={[styles.shiftSelectText, isSel && styles.shiftSelectTextActive]}>
                        {sh}
                      </Text>
                    </Pressable>
                  );
                })}
              </View>

              <Text style={styles.inputLabel}>Select Staff Member</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginVertical: 6 }}>
                {staffList.map((s) => {
                  const active = assignOperatorName === s.name;
                  return (
                    <Pressable
                      key={s.id}
                      style={[styles.staffChip, active && styles.staffChipActive]}
                      onPress={() => setAssignOperatorName(s.name)}
                    >
                      <Ionicons
                        name="person"
                        size={12}
                        color={active ? '#FFFFFF' : colors.primary}
                      />
                      <Text style={[styles.staffChipText, active && styles.staffChipTextActive]}>
                        {s.name} ({s.role || 'Staff'})
                      </Text>
                    </Pressable>
                  );
                })}
              </ScrollView>

              <Text style={styles.inputLabel}>Or Enter Worker Name</Text>
              <TextInput
                style={styles.textInput}
                placeholder="Worker Name"
                value={assignOperatorName}
                onChangeText={setAssignOperatorName}
              />

              <Text style={styles.inputLabel}>Notes (Optional)</Text>
              <TextInput
                style={[styles.textInput, { height: 64, textAlignVertical: 'top' }]}
                placeholder="Shift instructions or allocation notes"
                value={assignNotes}
                onChangeText={setAssignNotes}
                multiline
              />
            </ScrollView>

            <View style={styles.modalActions}>
              <Button
                label="Cancel"
                variant="secondary"
                style={{ flex: 1 }}
                onPress={() => setAssignModalVisible(false)}
              />
              <Button
                label={isSubmittingAssign ? 'Assigning…' : 'Assign Worker'}
                variant="primary"
                style={{ flex: 1 }}
                onPress={handleAssignSubmit}
                disabled={isSubmittingAssign}
              />
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
    paddingHorizontal: spacing.md,
    paddingTop: spacing.sm,
  },
  headerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: spacing.xs,
  },
  headerTitle: {
    fontSize: 20,
    fontWeight: '800',
    color: '#0A1E38',
  },
  headerSubtitle: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  addLineBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#0284C7',
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.1,
    shadowRadius: 2,
    elevation: 2,
  },
  addLineBtnText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  kpiGrid: {
    flexDirection: 'row',
    gap: 8,
    marginVertical: spacing.xs,
  },
  kpiCard: {
    flex: 1,
    padding: 10,
    borderRadius: 10,
    borderWidth: 1,
  },
  kpiCardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    marginBottom: 4,
  },
  kpiLabel: {
    fontSize: 11,
    fontWeight: '700',
  },
  kpiValue: {
    fontSize: 15,
    fontWeight: '800',
  },
  kpiUnit: {
    fontSize: 10,
    fontWeight: '600',
  },
  periodTabsRow: {
    flexDirection: 'row',
    backgroundColor: '#E2E8F0',
    borderRadius: 8,
    padding: 2,
    marginVertical: spacing.xs,
  },
  periodTab: {
    flex: 1,
    paddingVertical: 6,
    alignItems: 'center',
    borderRadius: 6,
  },
  periodTabActive: {
    backgroundColor: '#FFFFFF',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.08,
    shadowRadius: 1,
    elevation: 1,
  },
  periodTabText: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  periodTabTextActive: {
    color: '#0A1E38',
    fontWeight: '800',
  },
  searchWrapper: {
    marginBottom: spacing.xs,
  },
  quickRecordCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: '#FFFFFF',
    padding: 11,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: '#BAE6FD',
    marginBottom: spacing.xs,
  },
  quickRecordIcon: {
    width: 32,
    height: 32,
    borderRadius: 8,
    backgroundColor: '#0284C7',
    alignItems: 'center',
    justifyContent: 'center',
  },
  quickRecordTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: '#0A1E38',
  },
  quickRecordSubtitle: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 1,
  },
  emptyContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 48,
    paddingHorizontal: 24,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: '#0A1E38',
    marginTop: 12,
  },
  emptySubtitle: {
    fontSize: 12,
    color: colors.textSecondary,
    textAlign: 'center',
    marginTop: 4,
  },
  lineContainer: {
    marginBottom: spacing.md,
  },
  lineHeaderCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#F1F5F9',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#CBD5E1',
    marginBottom: 6,
  },
  lineHeaderLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flex: 1,
  },
  lineBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#E0F2FE',
    paddingHorizontal: 7,
    paddingVertical: 3,
    borderRadius: 5,
  },
  lineBadgeText: {
    fontSize: 11,
    fontWeight: '800',
    color: '#0284C7',
  },
  lineNameText: {
    fontSize: 13,
    fontWeight: '700',
    color: '#1E293B',
    flex: 1,
  },
  lineHeaderRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  lineOutputPill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    backgroundColor: '#DCFCE7',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  lineOutputText: {
    fontSize: 11,
    fontWeight: '800',
    color: '#15803D',
  },
  lineMachineCount: {
    fontSize: 11,
    color: colors.textSecondary,
    fontWeight: '600',
  },
  lineEmptyState: {
    padding: 14,
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.border,
    alignItems: 'center',
    gap: 6,
  },
  lineEmptyText: {
    fontSize: 12,
    color: colors.textSecondary,
  },
  addMachineToLineBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  addMachineToLineText: {
    fontSize: 12,
    color: colors.primary,
    fontWeight: '700',
  },
  machineCard: {
    backgroundColor: '#FFFFFF',
    padding: 12,
    borderRadius: 10,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  machineHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    gap: 8,
  },
  machineTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  machineCode: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0A1E38',
  },
  machineTypeBadge: {
    backgroundColor: '#F1F5F9',
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 4,
  },
  machineTypeText: {
    fontSize: 10,
    fontWeight: '700',
    color: colors.textSecondary,
  },
  machineName: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  activeOrderBox: {
    backgroundColor: '#F0F9FF',
    padding: 8,
    borderRadius: 6,
    marginTop: 8,
    borderWidth: 1,
    borderColor: '#BAE6FD',
  },
  activeOrderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
  },
  activeOrderNumber: {
    fontSize: 11,
    fontWeight: '800',
    color: '#0284C7',
  },
  activeOrderProduct: {
    fontSize: 11,
    color: '#0A1E38',
    fontWeight: '600',
    flex: 1,
  },
  progressBarBg: {
    height: 4,
    backgroundColor: '#E0F2FE',
    borderRadius: 2,
    marginTop: 5,
    overflow: 'hidden',
  },
  progressBarFill: {
    height: '100%',
    backgroundColor: '#0284C7',
    borderRadius: 2,
  },
  shiftsContainer: {
    marginTop: 10,
    backgroundColor: '#F8FAFC',
    borderRadius: 8,
    padding: 8,
    borderWidth: 1,
    borderColor: '#EEF2F6',
  },
  shiftsTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    marginBottom: 6,
  },
  shiftsTitle: {
    fontSize: 11,
    fontWeight: '800',
    color: '#0A1E38',
  },
  shiftsSubtitleNote: {
    fontSize: 9,
    color: colors.textMuted,
    marginLeft: 'auto',
  },
  shiftCardsList: {
    gap: 5,
  },
  shiftItemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 5,
    paddingHorizontal: 8,
    borderRadius: 6,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  shiftItemRowActive: {
    borderColor: '#CBD5E1',
  },
  shiftItemRowEmpty: {
    backgroundColor: '#FAFAFA',
  },
  shiftItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    width: 95,
  },
  shiftIconBox: {
    width: 24,
    height: 24,
    borderRadius: 5,
    alignItems: 'center',
    justifyContent: 'center',
  },
  shiftLabelText: {
    fontSize: 11,
    fontWeight: '800',
  },
  shiftTimeText: {
    fontSize: 8,
    color: colors.textMuted,
  },
  shiftItemCenter: {
    flex: 1,
    paddingHorizontal: 6,
  },
  workerBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#EFF6FF',
    paddingHorizontal: 7,
    paddingVertical: 2,
    borderRadius: 4,
    alignSelf: 'flex-start',
  },
  workerNameText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#1D4ED8',
  },
  unassignedWorkerText: {
    fontSize: 11,
    fontStyle: 'italic',
    color: colors.textMuted,
  },
  shiftItemRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  unitsBadge: {
    backgroundColor: '#F1F5F9',
    paddingHorizontal: 7,
    paddingVertical: 2,
    borderRadius: 4,
    minWidth: 54,
    alignItems: 'flex-end',
  },
  unitsBadgeActive: {
    backgroundColor: '#DCFCE7',
  },
  unitsValueText: {
    fontSize: 11,
    fontWeight: '700',
    color: colors.textSecondary,
  },
  unitsValueTextActive: {
    color: '#15803D',
    fontWeight: '800',
  },
  unitsSuffix: {
    fontSize: 9,
    fontWeight: '600',
  },
  shiftAssignBtn: {
    padding: 3,
  },
  machineFooterRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginTop: 8,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  machineTotalStat: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  machineTotalLabel: {
    fontSize: 11,
    color: colors.textSecondary,
    fontWeight: '600',
  },
  machineTotalValue: {
    fontSize: 12,
    fontWeight: '800',
    color: '#0A1E38',
  },
  machineRejectValue: {
    fontSize: 10,
    color: colors.danger,
    fontWeight: '700',
  },
  machineActionBtns: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  recordMachineBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    backgroundColor: '#E0F2FE',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  recordMachineBtnText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#0284C7',
  },
  machineDetailBtn: {
    padding: 2,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0, 0, 0, 0.45)',
    justifyContent: 'center',
    alignItems: 'center',
    padding: spacing.md,
  },
  modalContent: {
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    padding: 18,
    width: '100%',
    maxWidth: 420,
    maxHeight: '85%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 14,
  },
  modalIconBox: {
    width: 32,
    height: 32,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  modalTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: '#0A1E38',
  },
  modalSubtitle: {
    fontSize: 11,
    color: colors.textSecondary,
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: '#1E293B',
    marginTop: 10,
    marginBottom: 4,
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#CBD5E1',
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 8,
    fontSize: 13,
    color: '#0A1E38',
    backgroundColor: '#FAFAFA',
  },
  modalHelperBox: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 6,
    backgroundColor: '#F0F9FF',
    padding: 10,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#BAE6FD',
    marginTop: 12,
  },
  modalHelperText: {
    fontSize: 11,
    color: '#0369A1',
    flex: 1,
    lineHeight: 16,
  },
  modalActions: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 16,
  },
  shiftSelectRow: {
    flexDirection: 'row',
    gap: 8,
    marginVertical: 4,
  },
  shiftSelectChip: {
    flex: 1,
    paddingVertical: 7,
    alignItems: 'center',
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#CBD5E1',
    backgroundColor: '#F8FAFC',
  },
  shiftSelectChipActive: {
    borderColor: colors.primary,
    backgroundColor: '#EFF6FF',
  },
  shiftSelectText: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  shiftSelectTextActive: {
    color: colors.primary,
    fontWeight: '800',
  },
  staffChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 16,
    backgroundColor: '#F1F5F9',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    marginRight: 6,
  },
  staffChipActive: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
  },
  staffChipText: {
    fontSize: 11,
    fontWeight: '600',
    color: '#334155',
  },
  staffChipTextActive: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
});
