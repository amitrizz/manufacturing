import { Ionicons } from '@expo/vector-icons';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
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
import { Button } from '../../components/common/Button';
import { Card } from '../../components/common/Card';
import { SearchField } from '../../components/common/SearchField';
import { StatusBadge } from '../../components/common/StatusBadge';
import {
  assignOperatorToMachine,
  createLine,
  createMachine,
  getActiveOperatorAssignments,
  listLines,
  listMachineOperatorSummaries,
  listOperatorMachineSummaries,
} from '../../api/repositories/machineRepository';
import { listStaff } from '../../api/repositories/staffRepository';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import type { MachinesStackParamList } from '../../navigation/types';
import { colors } from '../../theme';
import type {
  ActiveOperatorAssignment,
  MachineOperatorSummary,
  MachineStatus,
  OperatorMachineSummary,
  StaffRow,
} from '../../types/database';
import { getRangeForPreset, type DatePreset } from '../../utils/dateRange';
import { formatDateTime, formatNumber } from '../../utils/format';

import { ViewModeBanner } from '../../components/common/ViewModeBanner';

type Props = NativeStackScreenProps<MachinesStackParamList, 'MachineList'>;
type ViewMode = 'machines' | 'operators';

const PERIOD_TABS: { label: string; preset: DatePreset }[] = [
  { label: '1 Day', preset: 'today' },
  { label: '1 Week', preset: 'week' },
  { label: '1 Month', preset: 'month' },
];

const STATUS_FILTERS: (MachineStatus | 'ALL')[] = [
  'ALL',
  'RUNNING',
  'IDLE',
  'BREAKDOWN',
  'MAINTENANCE',
];

const SHIFT_OPTIONS = ['Morning', 'Evening', 'Night'];

export function MachineListScreen({ navigation, route }: Props) {
  const isViewOnly = Boolean(route.params?.viewOnly);
  const [period, setPeriod] = useState<DatePreset>('today');
  const [viewMode, setViewMode] = useState<ViewMode>('machines');
  const [statusFilter, setStatusFilter] = useState<MachineStatus | 'ALL'>('ALL');
  const [search, setSearch] = useState('');
  const [refreshing, setRefreshing] = useState(false);

  const [machineSummaries, setMachineSummaries] = useState<MachineOperatorSummary[]>([]);
  const [operatorSummaries, setOperatorSummaries] = useState<OperatorMachineSummary[]>([]);
  const [staffList, setStaffList] = useState<StaffRow[]>([]);
  const [activeAssignments, setActiveAssignments] = useState<Record<string, ActiveOperatorAssignment>>({});

  // Create Machine Modal State
  const [createModalVisible, setCreateModalVisible] = useState(false);
  const [lines, setLines] = useState<{ id: string; code: string; name: string }[]>([]);
  const [newCode, setNewCode] = useState('');
  const [newName, setNewName] = useState('');
  const [newLineId, setNewLineId] = useState('');
  const [newType, setNewType] = useState('General');

  // Create Line Modal State
  const [createLineModalVisible, setCreateLineModalVisible] = useState(false);
  const [newLineCode, setNewLineCode] = useState('');
  const [newLineName, setNewLineName] = useState('');

  // Assign Operator Modal State
  const [assignModalVisible, setAssignModalVisible] = useState(false);
  const [selectedMachineId, setSelectedMachineId] = useState('');
  const [selectedMachineCode, setSelectedMachineCode] = useState('');
  const [selectedOperator, setSelectedOperator] = useState('');
  const [selectedShift, setSelectedShift] = useState('Morning');
  const [assignNotes, setAssignNotes] = useState('');

  const loadData = useCallback(async () => {
    setRefreshing(true);
    try {
      const { start, end } = getRangeForPreset(period);
      const [mSummaries, oSummaries, staff, assignments, prodLines] = await Promise.all([
        listMachineOperatorSummaries({ startDate: start, endDate: end, search: search || undefined }),
        listOperatorMachineSummaries({ startDate: start, endDate: end, search: search || undefined }),
        listStaff({ activeOnly: true }).catch(() => []),
        getActiveOperatorAssignments().catch(() => ({})),
        listLines().catch(() => []),
      ]);
      setMachineSummaries(mSummaries);
      setOperatorSummaries(oSummaries);
      setStaffList(staff);
      setActiveAssignments(assignments);
      setLines(prodLines);
      if (prodLines.length > 0 && !newLineId) {
        setNewLineId(prodLines[0].id);
      }
    } finally {
      setRefreshing(false);
    }
  }, [period, search, newLineId]);

  const handleCreateMachine = async () => {
    if (!newCode.trim() || !newName.trim() || !newLineId) {
      Alert.alert('Required Fields', 'Please enter machine code, name, and select a production line.');
      return;
    }
    try {
      await createMachine({
        code: newCode,
        name: newName,
        line_id: newLineId,
        machine_type: newType,
      });
      setCreateModalVisible(false);
      setNewCode('');
      setNewName('');
      Alert.alert('Success', `Machine ${newCode.toUpperCase()} created successfully.`);
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not create machine');
    }
  };

  const handleCreateLine = async () => {
    if (!newLineCode.trim() || !newLineName.trim()) {
      Alert.alert('Required Fields', 'Please enter line code and line name.');
      return;
    }
    try {
      const createdId = await createLine({
        code: newLineCode.trim().toUpperCase(),
        name: newLineName.trim(),
      });
      setCreateLineModalVisible(false);
      setNewLineCode('');
      setNewLineName('');
      setNewLineId(createdId);
      Alert.alert('Success', `Production Line ${newLineCode.trim().toUpperCase()} created!`);
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not create line');
    }
  };

  useLiveQuery(loadData);

  const handleOpenAssignModal = (
    machineId: string,
    machineCode: string,
    shift: 'Morning' | 'Evening' | 'Night' = 'Morning',
    currentOperator?: string | null,
  ) => {
    setSelectedMachineId(machineId);
    setSelectedMachineCode(machineCode);
    const availableStaff = staffList.find((s) => !activeAssignments[s.name]);
    setSelectedOperator(currentOperator || availableStaff?.name || staffList[0]?.name || 'Arun Kumar');
    setSelectedShift(shift);
    setAssignNotes('');
    setAssignModalVisible(true);
  };

  const handleConfirmAssign = async () => {
    if (!selectedMachineId || !selectedOperator.trim()) {
      Alert.alert('Required', 'Please select an operator.');
      return;
    }
    try {
      await assignOperatorToMachine(
        selectedMachineId,
        selectedOperator.trim(),
        selectedShift,
        assignNotes.trim() || undefined,
      );
      setAssignModalVisible(false);
      Alert.alert('Success', `Assigned ${selectedOperator} to ${selectedMachineCode} on ${selectedShift} shift.`);
      await loadData();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not assign operator');
    }
  };

  // Top KPI calculations
  const totalMachines = machineSummaries.length;
  const activeMachines = machineSummaries.filter((m) =>
    m.shift_assignments ? m.shift_assignments.some((s: any) => s.operator !== null) : m.current_operator !== null,
  ).length;
  const totalProduced = machineSummaries.reduce((sum, m) => sum + m.total_produced, 0);
  const totalOperatorsCount = operatorSummaries.length;

  const filteredMachines =
    statusFilter === 'ALL'
      ? machineSummaries
      : machineSummaries.filter((m) => m.machine_status === statusFilter);

  return (
    <View style={styles.screen}>
      {/* 1. Header with Period Filters (1 Day, 1 Week, 1 Month) */}
      <View style={styles.topBar}>
        <View style={styles.periodTabs}>
          {PERIOD_TABS.map((tab) => {
            const active = period === tab.preset;
            return (
              <Pressable
                key={tab.preset}
                style={[styles.periodChip, active && styles.periodChipActive]}
                onPress={() => setPeriod(tab.preset)}
              >
                <Text style={[styles.periodChipText, active && styles.periodChipTextActive]}>
                  {tab.label}
                </Text>
              </Pressable>
            );
          })}
        </View>

        {/* View Mode Toggle (By Machine vs By Person) */}
        <View style={styles.viewModeRow}>
          <Pressable
            style={[styles.viewModeBtn, viewMode === 'machines' && styles.viewModeBtnActive]}
            onPress={() => setViewMode('machines')}
          >
            <Ionicons
              name="cog-outline"
              size={15}
              color={viewMode === 'machines' ? '#FFFFFF' : '#64748B'}
            />
            <Text
              style={[
                styles.viewModeText,
                viewMode === 'machines' && styles.viewModeTextActive,
              ]}
            >
              By Machine
            </Text>
          </Pressable>

          <Pressable
            style={[styles.viewModeBtn, viewMode === 'operators' && styles.viewModeBtnActive]}
            onPress={() => setViewMode('operators')}
          >
            <Ionicons
              name="people-outline"
              size={15}
              color={viewMode === 'operators' ? '#FFFFFF' : '#64748B'}
            />
            <Text
              style={[
                styles.viewModeText,
                viewMode === 'operators' && styles.viewModeTextActive,
              ]}
            >
              By Person
            </Text>
          </Pressable>
        </View>
      </View>

      {isViewOnly && (
        <View style={{ paddingHorizontal: 20, paddingTop: 10 }}>
          <ViewModeBanner
            message="Machines fleet monitoring mode. Staff allocation and machine status updates are disabled. Use the Management tab to make changes."
          />
        </View>
      )}

      {/* 2. KPI Metrics Bar */}
      <View style={styles.kpiContainer}>
        <View style={styles.kpiCard}>
          <Text style={styles.kpiLabel}>Assigned</Text>
          <Text style={styles.kpiValue}>
            {activeMachines} <Text style={styles.kpiSub}>/ {totalMachines}</Text>
          </Text>
        </View>
        <View style={styles.kpiCard}>
          <Text style={styles.kpiLabel}>Operators</Text>
          <Text style={styles.kpiValue}>{totalOperatorsCount}</Text>
        </View>
        <View style={styles.kpiCard}>
          <Text style={styles.kpiLabel}>Output</Text>
          <Text style={styles.kpiValue}>{formatNumber(totalProduced)}</Text>
        </View>
      </View>

      {/* 3. Search Field & Add Machine */}
      <View style={styles.searchBox}>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
          <View style={{ flex: 1 }}>
            <SearchField
              value={search}
              onChangeText={setSearch}
              placeholder={
                viewMode === 'machines'
                  ? 'Search machine or line…'
                  : 'Search person or machine…'
              }
            />
          </View>
          {!isViewOnly && (
            <View style={{ flexDirection: 'row', gap: 6 }}>
              <Pressable
                style={styles.addLineBtn}
                onPress={() => setCreateLineModalVisible(true)}
              >
                <Ionicons name="git-branch-outline" size={15} color="#0284C7" />
                <Text style={styles.addLineBtnText}>+ Line</Text>
              </Pressable>
              <Pressable
                style={styles.addMachineBtn}
                onPress={() => {
                  if (lines.length > 0 && !newLineId) setNewLineId(lines[0].id);
                  setCreateModalVisible(true);
                }}
              >
                <Ionicons name="add" size={17} color="#FFFFFF" />
                <Text style={styles.addMachineBtnText}>+ Machine</Text>
              </Pressable>
            </View>
          )}
        </View>
      </View>

      {/* 3b. Machine Status Filter Chips (All, Running, Idle, Breakdown, Maintenance) */}
      {viewMode === 'machines' && (
        <View style={styles.statusFiltersWrapper}>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.statusFiltersScroll}
          >
            {STATUS_FILTERS.map((s) => {
              const active = statusFilter === s;
              const count =
                s === 'ALL'
                  ? machineSummaries.length
                  : machineSummaries.filter((m) => m.machine_status === s).length;
              return (
                <Pressable
                  key={s}
                  style={[styles.statusChip, active && styles.statusChipActive]}
                  onPress={() => setStatusFilter(s)}
                >
                  <Text style={[styles.statusChipText, active && styles.statusChipTextActive]}>
                    {s}
                  </Text>
                  <View style={[styles.statusCountBadge, active && styles.statusCountBadgeActive]}>
                    <Text style={[styles.statusCountText, active && styles.statusCountTextActive]}>
                      {count}
                    </Text>
                  </View>
                </Pressable>
              );
            })}
          </ScrollView>
        </View>
      )}

      {/* 4. Main List */}
      {viewMode === 'machines' ? (
        <FlatList
          data={filteredMachines}
          keyExtractor={(item) => item.machine_id}
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={loadData} tintColor={colors.primary} />
          }
          contentContainerStyle={styles.listContent}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="hardware-chip-outline" size={48} color={colors.textMuted} />
              <Text style={styles.emptyTitle}>
                {statusFilter === 'ALL' ? 'No machines found' : `No ${statusFilter} machines`}
              </Text>
              <Text style={styles.emptySubtitle}>
                {statusFilter === 'ALL'
                  ? 'Try adjusting your search or period filter.'
                  : `There are currently no machines with status "${statusFilter}".`}
              </Text>
            </View>
          }
          renderItem={({ item }) => (
            <Card style={styles.card}>
              {/* Machine Header */}
              <View style={styles.cardHeader}>
                <View style={styles.machineTitleRow}>
                  <Text style={styles.machineCode} numberOfLines={1} ellipsizeMode="tail">
                    {item.machine_code}
                  </Text>
                  <View style={styles.lineBadge}>
                    <Text style={styles.lineBadgeText}>{item.line_code || 'Line A'}</Text>
                  </View>
                </View>
                <StatusBadge status={item.machine_status} />
              </View>

              <Text style={styles.machineName} numberOfLines={2} ellipsizeMode="tail">
                {item.machine_name}
              </Text>

              {/* Product and Total Items Created */}
              <View style={styles.productStatsRow}>
                <View style={styles.productBadge}>
                  <Ionicons name="cube-outline" size={13} color="#0369A1" />
                  <Text style={styles.productBadgeText} numberOfLines={1} ellipsizeMode="tail">
                    Product: <Text style={{ fontWeight: '700' }}>{item.current_product || 'General'}</Text>
                  </Text>
                </View>
                <View style={styles.itemsCreatedBadge}>
                  <Ionicons name="layers-outline" size={13} color="#15803D" />
                  <Text style={styles.itemsCreatedBadgeText}>
                    Created: <Text style={{ fontWeight: '800' }}>{formatNumber(item.total_produced)} pcs</Text>
                  </Text>
                </View>
              </View>

              {/* 3-Shift Staff Allocations (Morning, Evening, Night) */}
              <View style={styles.shiftsSection}>
                <View style={styles.shiftsHeaderRow}>
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                    <Ionicons name="time-outline" size={14} color="#0A1E38" />
                    <Text style={styles.shiftsHeaderTitle}>3-Shift Staff Allocation</Text>
                  </View>
                  <Text style={styles.shiftsCountBadge}>
                    {(item.shift_assignments || []).filter((s: any) => s.operator !== null).length} / 3 Assigned
                  </Text>
                </View>

                <View style={styles.shiftRowsList}>
                  {(item.shift_assignments || [
                    { shift: 'Morning', operator: item.current_operator, total_produced: item.total_produced, last_active_at: item.last_active_at },
                    { shift: 'Evening', operator: null, total_produced: 0, last_active_at: null },
                    { shift: 'Night', operator: null, total_produced: 0, last_active_at: null },
                  ]).map((sa: any) => {
                    const isMorning = sa.shift === 'Morning';
                    const isEvening = sa.shift === 'Evening';
                    const shiftIcon = isMorning ? 'sunny-outline' : isEvening ? 'partly-sunny-outline' : 'moon-outline';
                    const shiftColor = isMorning ? '#EA580C' : isEvening ? '#D97706' : '#6366F1';
                    const shiftBg = isMorning ? '#FFF7ED' : isEvening ? '#FEF3C7' : '#EEF2FF';
                    const shiftTime = isMorning ? '06:00 - 14:00' : isEvening ? '14:00 - 22:00' : '22:00 - 06:00';

                    return (
                      <View
                        key={sa.shift}
                        style={[styles.shiftRow, sa.operator ? styles.shiftRowActive : styles.shiftRowEmpty]}
                      >
                        <View style={styles.shiftRowLeft}>
                          <View style={[styles.shiftIconBox, { backgroundColor: shiftBg }]}>
                            <Ionicons name={shiftIcon} size={14} color={shiftColor} />
                          </View>
                          <View>
                            <Text style={[styles.shiftRowLabel, { color: shiftColor }]}>
                              {sa.shift} Shift
                            </Text>
                            <Text style={styles.shiftRowTime}>{shiftTime}</Text>
                          </View>
                        </View>

                        <View style={styles.shiftRowRight}>
                          {sa.operator ? (
                            <View style={styles.shiftAssignedBox}>
                              <View style={styles.shiftOperatorInfo}>
                                <View style={styles.shiftOperatorNameRow}>
                                  <Ionicons name="person" size={11} color={colors.primary} />
                                  <Text
                                    style={styles.shiftOperatorName}
                                    numberOfLines={1}
                                    ellipsizeMode="tail"
                                  >
                                    {sa.operator}
                                  </Text>
                                </View>
                                {sa.total_produced > 0 && (
                                  <Text style={styles.shiftProducedText} numberOfLines={1}>
                                    {formatNumber(sa.total_produced)} pcs
                                  </Text>
                                )}
                              </View>
                              {!isViewOnly && (
                                <Pressable
                                  style={styles.shiftChangeBtn}
                                  onPress={() => handleOpenAssignModal(item.machine_id, item.machine_code || '', sa.shift as any, sa.operator)}
                                  hitSlop={6}
                                >
                                  <Ionicons name="pencil" size={11} color="#0284C7" />
                                </Pressable>
                              )}
                            </View>
                          ) : (
                            !isViewOnly ? (
                              <Pressable
                                style={styles.shiftAssignBtn}
                                onPress={() => handleOpenAssignModal(item.machine_id, item.machine_code || '', sa.shift as any)}
                              >
                                <Ionicons name="person-add-outline" size={12} color="#0284C7" />
                                <Text style={styles.shiftAssignBtnText}>Assign</Text>
                              </Pressable>
                            ) : (
                              <View style={{ paddingVertical: 4, paddingHorizontal: 6 }}>
                                <Text style={{ fontSize: 11, color: colors.textMuted }}>Unassigned</Text>
                              </View>
                            )
                          )}
                        </View>
                      </View>
                    );
                  })}
                </View>
              </View>

              {/* Bottom Card Actions */}
              <View style={styles.cardActionsRow}>
                <Pressable
                  style={[styles.actionBtnOutline, isViewOnly && { flex: 1 }]}
                  onPress={() =>
                    navigation.navigate('MachineDetail', {
                      machineId: item.machine_id,
                      viewOnly: isViewOnly,
                    })
                  }
                >
                  <Ionicons name="time-outline" size={16} color={colors.primary} />
                  <Text style={styles.actionBtnOutlineText}>History & Details</Text>
                </Pressable>

                {!isViewOnly && (
                  <Pressable
                    style={styles.actionBtnPrimary}
                    onPress={() => handleOpenAssignModal(item.machine_id, item.machine_code || '', 'Morning')}
                  >
                    <Ionicons name="person-add-outline" size={15} color="#FFFFFF" />
                    <Text style={styles.actionBtnPrimaryText}>Assign Staff</Text>
                  </Pressable>
                )}
              </View>
            </Card>
          )}
        />
      ) : (
        /* By Person (Operator View) */
        <FlatList
          data={operatorSummaries}
          keyExtractor={(item) => item.operator_name}
          refreshControl={
            <RefreshControl refreshing={refreshing} onRefresh={loadData} tintColor={colors.primary} />
          }
          contentContainerStyle={styles.listContent}
          ListEmptyComponent={
            <View style={styles.emptyContainer}>
              <Ionicons name="people-outline" size={48} color={colors.textMuted} />
              <Text style={styles.emptyTitle}>No workers active</Text>
              <Text style={styles.emptySubtitle}>No operator production logged in this period.</Text>
            </View>
          }
          renderItem={({ item }) => (
            <Card style={styles.card}>
              <View style={styles.personHeaderRow}>
                <View style={styles.personAvatarBox}>
                  <Ionicons name="person" size={22} color={colors.primary} />
                </View>
                <View style={styles.personInfo}>
                  <Text style={styles.personName} numberOfLines={2} ellipsizeMode="tail">
                    {item.operator_name}
                  </Text>
                  <Text style={styles.personShifts} numberOfLines={1}>
                    {item.shifts.join(', ')} Shift{item.shifts.length > 1 ? 's' : ''}
                  </Text>
                </View>
                <View style={styles.personOutputBox}>
                  <Text style={styles.personOutputVal}>{formatNumber(item.total_produced)}</Text>
                  <Text style={styles.personOutputLbl}>pcs produced</Text>
                </View>
              </View>

              {/* Machines Worked On */}
              <View style={styles.personMachinesSection}>
                <Text style={styles.sectionSmallLabel}>Machines Operated:</Text>
                <View style={styles.machineBadgesRow}>
                  {item.machines.map((mCode: any) => (
                    <View key={mCode} style={styles.machineBadgePill}>
                      <Ionicons name="hardware-chip-outline" size={12} color="#0A1E38" />
                      <Text style={styles.machineBadgePillText}>{mCode}</Text>
                    </View>
                  ))}
                </View>
              </View>

              <View style={styles.personFooterRow}>
                <Text style={styles.personFooterText} numberOfLines={1} ellipsizeMode="tail">
                  Latest on: <Text style={styles.bold}>{item.latest_machine}</Text>
                </Text>
                <Text style={styles.personFooterText}>
                  {formatDateTime(item.last_active_at)}
                </Text>
              </View>
            </Card>
          )}
        />
      )}

      {/* 5. Assign Operator Modal */}
      <Modal visible={assignModalVisible} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Assign Person to Machine</Text>
              <Pressable onPress={() => setAssignModalVisible(false)}>
                <Ionicons name="close" size={24} color={colors.textSecondary} />
              </Pressable>
            </View>

            <Text style={styles.modalSub}>
              Machine: <Text style={styles.modalSubBold}>{selectedMachineCode}</Text>
            </Text>

            {/* Select Operator */}
            <Text style={styles.inputLabel}>Select Staff / Worker (Each machine has 1 person)</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.chipScroll}>
              {staffList.map((st) => {
                const active = selectedOperator === st.name;
                const assign = activeAssignments[st.name];
                const isOnThisMachine = assign?.machines?.some((m: any) => m.machineId === selectedMachineId);
                const otherMachines = assign?.machines?.filter((m: any) => m.machineId !== selectedMachineId) || [];
                return (
                  <Pressable
                    key={st.id}
                    style={[
                      styles.staffChip,
                      active && styles.staffChipActive,
                      !active && otherMachines.length > 0 && styles.staffChipMulti,
                    ]}
                    onPress={() => setSelectedOperator(st.name)}
                  >
                    <View style={styles.staffChipContent}>
                      <View style={{ flexDirection: 'row', alignItems: 'center', gap: 5 }}>
                        <Ionicons
                          name={
                            isOnThisMachine
                              ? 'checkmark-circle'
                              : otherMachines.length > 0
                              ? 'git-network-outline'
                              : 'person-outline'
                          }
                          size={13}
                          color={
                            active
                              ? '#FFFFFF'
                              : isOnThisMachine
                              ? '#0284C7'
                              : otherMachines.length > 0
                              ? '#0284C7'
                              : colors.textSecondary
                          }
                        />
                        <Text style={[styles.staffChipText, active && styles.staffChipTextActive]}>
                          {st.name}
                        </Text>
                      </View>
                      <View
                        style={[
                          styles.assignTag,
                          active
                            ? styles.assignTagActive
                            : isOnThisMachine
                            ? styles.assignTagOnThis
                            : otherMachines.length > 0
                            ? styles.assignTagMulti
                            : styles.assignTagFree,
                        ]}
                      >
                        <Text
                          style={[
                            styles.assignTagText,
                            active && { color: '#FFFFFF' },
                            !active && isOnThisMachine && { color: '#0369A1' },
                            !active && otherMachines.length > 0 && { color: '#0369A1' },
                            !active && (!assign || (assign.machines || []).length === 0) && { color: '#15803D' },
                          ]}
                        >
                          {isOnThisMachine
                            ? `On this (${selectedMachineCode})`
                            : otherMachines.length > 0
                            ? `Operates ${otherMachines.length} machine${otherMachines.length > 1 ? 's' : ''}`
                            : 'Available'}
                        </Text>
                      </View>
                    </View>
                  </Pressable>
                );
              })}
            </ScrollView>

            {/* Live Assignment Status Banners */}
            {(() => {
              const currentAssign = activeAssignments[selectedOperator];
              const isOnThisMachine = currentAssign?.machines?.some((m: any) => m.machineId === selectedMachineId);
              const otherMachines = currentAssign?.machines?.filter((m: any) => m.machineId !== selectedMachineId) || [];

              return (
                <View style={{ gap: 6, marginVertical: 4 }}>
                  {/* Note about Machine: Shift-based allocation */}
                  <View style={styles.bannerInfo}>
                    <Ionicons name="information-circle" size={17} color="#0284C7" />
                    <Text style={styles.bannerInfoText}>
                      Assigning {selectedOperator} for <Text style={styles.bold}>{selectedShift} Shift</Text> on {selectedMachineCode}. Each machine has 3 staff assigned across Morning, Evening, and Night.
                    </Text>
                  </View>

                  {/* Note about Operator: One person can have multiple machines */}
                  {isOnThisMachine ? (
                    <View style={styles.bannerSuccess}>
                      <Ionicons name="checkmark-circle" size={17} color="#16A34A" />
                      <Text style={styles.bannerSuccessText}>
                        {selectedOperator} is already operating {selectedMachineCode}. You can adjust shift or work order notes.
                      </Text>
                    </View>
                  ) : otherMachines.length > 0 ? (
                    <View style={styles.bannerMultiMachine}>
                      <Ionicons name="git-network-outline" size={18} color="#0284C7" style={{ marginTop: 2 }} />
                      <View style={{ flex: 1, gap: 2 }}>
                        <Text style={styles.bannerMultiTitle}>
                          Multi-Machine Operator ({otherMachines.length + 1} machines total)
                        </Text>
                        <Text style={styles.bannerMultiDesc}>
                          {selectedOperator} is already operating <Text style={styles.bold}>{otherMachines.map((m: any) => `${m.machineCode} (${m.shift})`).join(', ')}</Text>.
                        </Text>
                        <Text style={styles.bannerMultiNote}>
                          They will now manage both {otherMachines.map((m: any) => m.machineCode).join(', ')} and {selectedMachineCode}.
                        </Text>
                      </View>
                    </View>
                  ) : selectedOperator ? (
                    <View style={styles.bannerSuccess}>
                      <Ionicons name="checkmark-circle" size={17} color="#16A34A" />
                      <Text style={styles.bannerSuccessText}>
                        {selectedOperator} is free (no machines assigned today).
                      </Text>
                    </View>
                  ) : null}
                </View>
              );
            })()}

            <TextInput
              style={styles.textInput}
              placeholder="Or type person name…"
              value={selectedOperator}
              onChangeText={setSelectedOperator}
            />

            {/* Select Shift */}
            <Text style={styles.inputLabel}>Shift</Text>
            <View style={styles.shiftPickerRow}>
              {SHIFT_OPTIONS.map((sh) => {
                const active = selectedShift === sh;
                return (
                  <Pressable
                    key={sh}
                    style={[styles.shiftBtn, active && styles.shiftBtnActive]}
                    onPress={() => setSelectedShift(sh)}
                  >
                    <Text style={[styles.shiftBtnText, active && styles.shiftBtnTextActive]}>
                      {sh}
                    </Text>
                  </Pressable>
                );
              })}
            </View>

            {/* Notes */}
            <Text style={styles.inputLabel}>Notes / Work Order (Optional)</Text>
            <TextInput
              style={styles.textInput}
              placeholder="e.g. Morning batch run"
              value={assignNotes}
              onChangeText={setAssignNotes}
            />

            {/* Modal Actions */}
            <View style={styles.modalActions}>
              <Button
                label="Cancel"
                variant="secondary"
                style={{ flex: 1 }}
                onPress={() => setAssignModalVisible(false)}
              />
              <Button
                label={
                  activeAssignments[selectedOperator]?.machines?.some((m: any) => m.machineId !== selectedMachineId)
                    ? `Assign (Multi-Machine)`
                    : `Assign to ${selectedMachineCode}`
                }
                variant="primary"
                style={{ flex: 1 }}
                onPress={handleConfirmAssign}
              />
            </View>
          </View>
        </View>
      </Modal>

      {/* 6. Create Machine Modal */}
      <Modal visible={createModalVisible} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Add New Machine</Text>
              <Pressable onPress={() => setCreateModalVisible(false)}>
                <Ionicons name="close" size={24} color={colors.textSecondary} />
              </Pressable>
            </View>

            <ScrollView showsVerticalScrollIndicator={false}>
              <Text style={styles.inputLabel}>Machine Code *</Text>
              <TextInput
                style={styles.textInput}
                placeholder="e.g. M-07 or CNC-02"
                value={newCode}
                onChangeText={setNewCode}
                autoCapitalize="characters"
              />

              <Text style={styles.inputLabel}>Machine Name *</Text>
              <TextInput
                style={styles.textInput}
                placeholder="e.g. 5-Axis Milling Unit"
                value={newName}
                onChangeText={setNewName}
              />

              <Text style={styles.inputLabel}>Machine Type</Text>
              <TextInput
                style={styles.textInput}
                placeholder="e.g. CNC, Press, Lathe, Assembly"
                value={newType}
                onChangeText={setNewType}
              />

              <View style={{ flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 10, marginBottom: 4 }}>
                <Text style={[styles.inputLabel, { marginTop: 0, marginBottom: 0 }]}>Production Line *</Text>
                <Pressable onPress={() => setCreateLineModalVisible(true)}>
                  <Text style={{ fontSize: 12, fontWeight: '700', color: colors.primary }}>+ New Line</Text>
                </Pressable>
              </View>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginVertical: 6 }}>
                {lines.map((l) => {
                  const active = newLineId === l.id;
                  return (
                    <Pressable
                      key={l.id}
                      style={[styles.lineOptionChip, active && styles.lineOptionChipActive]}
                      onPress={() => setNewLineId(l.id)}
                    >
                      <Text style={[styles.lineOptionChipText, active && styles.lineOptionChipTextActive]}>
                        Line {l.code} ({l.name})
                      </Text>
                    </Pressable>
                  );
                })}
              </ScrollView>
            </ScrollView>

            <View style={[styles.modalActions, { marginTop: 16 }]}>
              <Button
                label="Cancel"
                variant="secondary"
                style={{ flex: 1 }}
                onPress={() => setCreateModalVisible(false)}
              />
              <Button
                label="Create Machine"
                variant="primary"
                style={{ flex: 1 }}
                onPress={handleCreateMachine}
              />
            </View>
          </View>
        </View>
      </Modal>

      {/* CREATE LINE MODAL */}
      <Modal
        visible={createLineModalVisible}
        transparent
        animationType="slide"
        onRequestClose={() => setCreateLineModalVisible(false)}
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Add Production Line</Text>
              <Pressable onPress={() => setCreateLineModalVisible(false)}>
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

              <Text style={styles.inputLabel}>Line Name *</Text>
              <TextInput
                style={styles.textInput}
                placeholder="e.g. Assembly Line E"
                value={newLineName}
                onChangeText={setNewLineName}
              />
            </ScrollView>

            <View style={[styles.modalActions, { marginTop: 16 }]}>
              <Button
                label="Cancel"
                variant="secondary"
                style={{ flex: 1 }}
                onPress={() => setCreateLineModalVisible(false)}
              />
              <Button
                label="Create Line"
                variant="primary"
                style={{ flex: 1 }}
                onPress={handleCreateLine}
              />
            </View>
          </View>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: colors.background,
  },
  topBar: {
    backgroundColor: '#0A1E38',
    paddingHorizontal: 20,
    paddingTop: 12,
    paddingBottom: 16,
    gap: 12,
  },
  periodTabs: {
    flexDirection: 'row',
    backgroundColor: '#162E4E',
    borderRadius: 10,
    padding: 3,
  },
  periodChip: {
    flex: 1,
    paddingVertical: 7,
    alignItems: 'center',
    borderRadius: 8,
  },
  periodChipActive: {
    backgroundColor: '#FFFFFF',
  },
  periodChipText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#94A3B8',
  },
  periodChipTextActive: {
    color: '#0A1E38',
    fontWeight: '800',
  },
  viewModeRow: {
    flexDirection: 'row',
    backgroundColor: '#162E4E',
    borderRadius: 10,
    padding: 3,
  },
  viewModeBtn: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    paddingVertical: 8,
    borderRadius: 8,
  },
  viewModeBtnActive: {
    backgroundColor: colors.primary,
  },
  viewModeText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#94A3B8',
  },
  viewModeTextActive: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
  kpiContainer: {
    flexDirection: 'row',
    gap: 10,
    paddingHorizontal: 20,
    paddingTop: 14,
    paddingBottom: 4,
  },
  kpiCard: {
    flex: 1,
    backgroundColor: colors.surface,
    borderRadius: 12,
    padding: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 2,
    elevation: 1,
  },
  kpiLabel: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.textSecondary,
    marginBottom: 4,
  },
  kpiValue: {
    fontSize: 17,
    fontWeight: '800',
    color: colors.text,
  },
  kpiSub: {
    fontSize: 12,
    fontWeight: '500',
    color: colors.textMuted,
  },
  searchBox: {
    paddingHorizontal: 20,
    paddingTop: 10,
    paddingBottom: 8,
  },
  statusFiltersWrapper: {
    paddingBottom: 10,
  },
  statusFiltersScroll: {
    paddingHorizontal: 20,
    gap: 8,
  },
  statusChip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 20,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  statusChipActive: {
    backgroundColor: '#0A1E38',
    borderColor: '#0A1E38',
  },
  statusChipText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#64748B',
  },
  statusChipTextActive: {
    color: '#FFFFFF',
  },
  statusCountBadge: {
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 10,
    backgroundColor: '#F1F5F9',
  },
  statusCountBadgeActive: {
    backgroundColor: '#1E3A5F',
  },
  statusCountText: {
    fontSize: 11,
    fontWeight: '800',
    color: '#64748B',
  },
  statusCountTextActive: {
    color: '#FFFFFF',
  },
  listContent: {
    paddingHorizontal: 20,
    paddingBottom: 32,
    gap: 12,
  },
  card: {
    padding: 16,
    borderRadius: 14,
    gap: 10,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 8,
  },
  machineTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flex: 1,
    flexShrink: 1,
  },
  machineCode: {
    fontSize: 18,
    fontWeight: '800',
    color: colors.text,
    flexShrink: 1,
  },
  lineBadge: {
    backgroundColor: '#F1F5F9',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    flexShrink: 0,
  },
  lineBadgeText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  machineName: {
    fontSize: 13.5,
    fontWeight: '600',
    color: colors.textSecondary,
    lineHeight: 18,
    flexShrink: 1,
    marginTop: -2,
  },
  productStatsRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flexWrap: 'wrap',
    marginTop: 2,
    marginBottom: 2,
  },
  productBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    backgroundColor: '#F0F9FF',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#BAE6FD',
    maxWidth: '100%',
    flexShrink: 1,
  },
  productBadgeText: {
    fontSize: 11,
    color: '#0369A1',
    flexShrink: 1,
  },
  itemsCreatedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    backgroundColor: '#F0FDF4',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#BBF7D0',
  },
  itemsCreatedBadgeText: {
    fontSize: 11,
    color: '#15803D',
  },
  shiftsSection: {
    backgroundColor: '#F8FAFC',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    padding: 12,
    gap: 8,
  },
  shiftsHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 2,
  },
  shiftsHeaderTitle: {
    fontSize: 12,
    fontWeight: '800',
    color: '#0A1E38',
    letterSpacing: 0.2,
  },
  shiftsCountBadge: {
    fontSize: 11,
    fontWeight: '800',
    color: colors.primary,
    backgroundColor: '#E0F2FE',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
  },
  shiftRowsList: {
    gap: 6,
  },
  shiftRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 8,
    paddingHorizontal: 10,
    borderRadius: 8,
    borderWidth: 1,
    gap: 8,
  },
  shiftRowActive: {
    backgroundColor: '#FFFFFF',
    borderColor: '#CBD5E1',
  },
  shiftRowEmpty: {
    backgroundColor: '#F1F5F9',
    borderColor: '#E2E8F0',
    borderStyle: 'dashed',
  },
  shiftRowLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    flexShrink: 0,
  },
  shiftIconBox: {
    width: 26,
    height: 26,
    borderRadius: 6,
    alignItems: 'center',
    justifyContent: 'center',
  },
  shiftRowLabel: {
    fontSize: 12,
    fontWeight: '700',
  },
  shiftRowTime: {
    fontSize: 10,
    color: colors.textMuted,
  },
  shiftRowRight: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    flex: 1,
    flexShrink: 1,
    gap: 6,
  },
  shiftAssignedBox: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    gap: 8,
    flex: 1,
    flexShrink: 1,
  },
  shiftOperatorInfo: {
    alignItems: 'flex-end',
    flex: 1,
    flexShrink: 1,
  },
  shiftOperatorNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    gap: 4,
    maxWidth: '100%',
  },
  shiftOperatorName: {
    fontSize: 12,
    fontWeight: '700',
    color: '#0A1E38',
    flexShrink: 1,
  },
  shiftProducedText: {
    fontSize: 10,
    color: colors.textSecondary,
    fontWeight: '500',
  },
  shiftChangeBtn: {
    padding: 6,
    borderRadius: 6,
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
  },
  shiftAssignBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingVertical: 5,
    paddingHorizontal: 8,
    borderRadius: 6,
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
  },
  shiftAssignBtnText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#0284C7',
  },
  operatorBox: {
    borderRadius: 10,
    padding: 12,
    borderWidth: 1,
    gap: 6,
  },
  operatorBoxActive: {
    backgroundColor: '#F0FDF4',
    borderColor: '#BBF7D0',
  },
  operatorBoxIdle: {
    backgroundColor: '#F8FAFC',
    borderColor: '#E2E8F0',
  },
  operatorHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  operatorNameRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    flex: 1,
  },
  operatorName: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.text,
  },
  shiftPill: {
    backgroundColor: '#DCFCE7',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
  },
  shiftPillText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#15803D',
  },
  operatorStatsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 2,
  },
  statDetail: {
    fontSize: 12,
    color: colors.textSecondary,
  },
  statBold: {
    fontWeight: '700',
    color: colors.text,
  },
  statTime: {
    fontSize: 11,
    color: colors.textMuted,
  },
  otherOperatorsSection: {
    marginTop: 6,
    paddingTop: 6,
    borderTopWidth: 1,
    borderTopColor: '#DCFCE7',
  },
  otherOperatorsTitle: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.textSecondary,
    marginBottom: 4,
  },
  operatorPillsRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  miniOperatorPill: {
    backgroundColor: '#E2E8F0',
    paddingHorizontal: 7,
    paddingVertical: 2,
    borderRadius: 6,
  },
  miniOperatorText: {
    fontSize: 10,
    fontWeight: '600',
    color: '#334155',
  },
  cardActionsRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 4,
  },
  actionBtnOutline: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    paddingVertical: 9,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: colors.primary,
    backgroundColor: '#FFFFFF',
  },
  actionBtnOutlineText: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.primary,
  },
  actionBtnPrimary: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    paddingVertical: 9,
    borderRadius: 8,
    backgroundColor: colors.primary,
  },
  actionBtnPrimaryText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  // By Person View Styles
  personHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  personAvatarBox: {
    width: 42,
    height: 42,
    borderRadius: 21,
    backgroundColor: '#E0F2FE',
    alignItems: 'center',
    justifyContent: 'center',
  },
  personInfo: {
    flex: 1,
    flexShrink: 1,
    marginRight: 8,
  },
  personName: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.text,
    flexShrink: 1,
  },
  personShifts: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  personOutputBox: {
    alignItems: 'flex-end',
  },
  personOutputVal: {
    fontSize: 18,
    fontWeight: '800',
    color: colors.primary,
  },
  personOutputLbl: {
    fontSize: 10,
    fontWeight: '600',
    color: colors.textMuted,
  },
  personMachinesSection: {
    backgroundColor: '#F8FAFC',
    borderRadius: 8,
    padding: 10,
    marginVertical: 4,
    gap: 6,
  },
  sectionSmallLabel: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  machineBadgesRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  machineBadgePill: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#CBD5E1',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
  },
  machineBadgePillText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#0A1E38',
  },
  personFooterRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingTop: 4,
  },
  personFooterText: {
    fontSize: 11,
    color: colors.textMuted,
  },
  bold: {
    fontWeight: '700',
    color: colors.text,
  },
  // Modal Styles
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    padding: 20,
  },
  modalCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 20,
    gap: 12,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: '800',
    color: colors.text,
  },
  modalSub: {
    fontSize: 13,
    color: colors.textSecondary,
  },
  modalSubBold: {
    fontWeight: '700',
    color: colors.primary,
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.text,
    marginTop: 4,
  },
  chipScroll: {
    marginVertical: 4,
  },
  staffChip: {
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 8,
    backgroundColor: '#F1F5F9',
    marginRight: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  staffChipActive: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
  },
  multiMachineTagBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    backgroundColor: '#E0F2FE',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    borderRadius: 6,
    paddingHorizontal: 8,
    paddingVertical: 3,
    marginTop: 2,
    alignSelf: 'flex-start',
  },
  multiMachineTagText: {
    fontSize: 11,
    color: '#0369A1',
    fontWeight: '600',
  },
  staffChipOccupied: {
    borderColor: '#FDBA74',
    backgroundColor: '#FFF7ED',
  },
  staffChipMulti: {
    borderColor: '#BAE6FD',
    backgroundColor: '#F0F9FF',
  },
  staffChipContent: {
    gap: 4,
  },
  staffChipText: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  staffChipTextActive: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
  assignTag: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    alignSelf: 'flex-start',
  },
  assignTagActive: {
    backgroundColor: 'rgba(255,255,255,0.25)',
  },
  assignTagOccupied: {
    backgroundColor: '#FFEDD5',
  },
  assignTagOnThis: {
    backgroundColor: '#E0F2FE',
  },
  assignTagMulti: {
    backgroundColor: '#E0F2FE',
  },
  assignTagFree: {
    backgroundColor: '#DCFCE7',
  },
  assignTagText: {
    fontSize: 10,
    fontWeight: '700',
  },
  bannerMultiMachine: {
    flexDirection: 'row',
    gap: 10,
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    borderRadius: 10,
    padding: 12,
    marginVertical: 4,
  },
  bannerMultiTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: '#0369A1',
  },
  bannerMultiDesc: {
    fontSize: 12,
    color: '#075985',
    marginTop: 2,
  },
  bannerMultiNote: {
    fontSize: 11,
    fontWeight: '700',
    color: '#0369A1',
    marginTop: 4,
  },
  bannerWarning: {
    flexDirection: 'row',
    gap: 10,
    backgroundColor: '#FFFBEB',
    borderWidth: 1,
    borderColor: '#FCD34D',
    borderRadius: 10,
    padding: 12,
    marginVertical: 4,
  },
  bannerWarningTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: '#B45309',
  },
  bannerWarningDesc: {
    fontSize: 12,
    color: '#92400E',
    marginTop: 2,
  },
  bannerWarningNote: {
    fontSize: 11,
    fontWeight: '700',
    color: '#B45309',
    marginTop: 4,
  },
  bannerInfo: {
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center',
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    borderRadius: 10,
    padding: 10,
    marginVertical: 4,
  },
  bannerInfoText: {
    fontSize: 12,
    color: '#0369A1',
    flex: 1,
  },
  bannerSuccess: {
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center',
    backgroundColor: '#F0FDF4',
    borderWidth: 1,
    borderColor: '#BBF7D0',
    borderRadius: 10,
    padding: 10,
    marginVertical: 4,
  },
  bannerSuccessText: {
    fontSize: 12,
    color: '#15803D',
    flex: 1,
  },
  textInput: {
    borderWidth: 1,
    borderColor: '#CBD5E1',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 9,
    fontSize: 14,
    color: colors.text,
  },
  shiftPickerRow: {
    flexDirection: 'row',
    gap: 8,
  },
  shiftBtn: {
    flex: 1,
    paddingVertical: 8,
    borderRadius: 8,
    backgroundColor: '#F1F5F9',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  shiftBtnActive: {
    backgroundColor: '#0A1E38',
    borderColor: '#0A1E38',
  },
  shiftBtnText: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  shiftBtnTextActive: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
  modalActions: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 8,
  },
  emptyContainer: {
    alignItems: 'center',
    paddingVertical: 40,
    gap: 8,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.text,
  },
  emptySubtitle: {
    fontSize: 13,
    color: colors.textSecondary,
    textAlign: 'center',
  },
  addLineBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#E0F2FE',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 10,
  },
  addLineBtnText: {
    color: '#0284C7',
    fontWeight: '700',
    fontSize: 13,
  },
  addMachineBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: colors.primary,
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderRadius: 10,
  },
  addMachineBtnText: {
    color: '#FFFFFF',
    fontWeight: '700',
    fontSize: 13,
  },
  lineOptionChip: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
    backgroundColor: '#F1F5F9',
    marginRight: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  lineOptionChipActive: {
    backgroundColor: '#0A1E38',
    borderColor: '#0A1E38',
  },
  lineOptionChipText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#475569',
  },
  lineOptionChipTextActive: {
    color: '#FFFFFF',
  },
});
