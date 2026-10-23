import { Ionicons } from '@expo/vector-icons';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
import {
  Alert,
  Modal,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Button } from '../../components/common/Button';
import { Card } from '../../components/common/Card';
import { Screen } from '../../components/common/Screen';
import { SectionHeader } from '../../components/common/SectionHeader';
import { StatusBadge } from '../../components/common/StatusBadge';
import {
  assignOperatorToMachine,
  deleteMachine,
  getActiveOperatorAssignments,
  getMachineById,
  getMachineOperatorEntries,
  getMachineProductionTotals,
  listLines,
  updateMachine,
  type MachineProductionTotals,
} from '../../api/repositories/machineRepository';
import { listStaff } from '../../api/repositories/staffRepository';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import type { MachinesStackParamList } from '../../navigation/types';
import { machineStatusOptions, setMachineStatus } from '../../services/machineService';
import { colors, spacing, typography } from '../../theme';
import type {
  ActiveOperatorAssignment,
  MachineOperatorEntry,
  MachineRow,
  MachineStatus,
  StaffRow,
} from '../../types/database';
import { getRangeForPreset, type DatePreset } from '../../utils/dateRange';
import { formatDateTime, formatNumber } from '../../utils/format';

import { ViewModeBanner } from '../../components/common/ViewModeBanner';

type Props = NativeStackScreenProps<MachinesStackParamList, 'MachineDetail'>;

const PERIOD_TABS: { label: string; preset: DatePreset }[] = [
  { label: '1 Day', preset: 'today' },
  { label: '1 Week', preset: 'week' },
  { label: '1 Month', preset: 'month' },
];

const SHIFT_OPTIONS = ['Morning', 'Evening', 'Night'];

export function MachineDetailScreen({ navigation, route }: Props) {
  const isViewOnly = Boolean(route.params?.viewOnly);
  const [machine, setMachine] = useState<MachineRow | null>(null);
  const [prodTotals, setProdTotals] = useState<MachineProductionTotals | null>(null);
  const [statusNote, setStatusNote] = useState('');
  const [period, setPeriod] = useState<DatePreset>('today');
  const [operatorEntries, setOperatorEntries] = useState<MachineOperatorEntry[]>([]);
  const [staffList, setStaffList] = useState<StaffRow[]>([]);
  const [activeAssignments, setActiveAssignments] = useState<Record<string, ActiveOperatorAssignment>>({});

  // Edit Machine Modal State
  const [editModalVisible, setEditModalVisible] = useState(false);
  const [editCode, setEditCode] = useState('');
  const [editName, setEditName] = useState('');
  const [editType, setEditType] = useState('General');
  const [editLineId, setEditLineId] = useState('');
  const [lines, setLines] = useState<{ id: string; code: string; name: string }[]>([]);

  // Assign Operator Modal State
  const [assignModalVisible, setAssignModalVisible] = useState(false);
  const [selectedOperator, setSelectedOperator] = useState('');
  const [selectedShift, setSelectedShift] = useState('Morning');
  const [assignNotes, setAssignNotes] = useState('');

  const load = useCallback(async () => {
    const { start, end } = getRangeForPreset(period);
    const [m, totals, entries, staff, assignments, prodLines] = await Promise.all([
      getMachineById(route.params.machineId),
      getMachineProductionTotals(route.params.machineId),
      getMachineOperatorEntries(route.params.machineId, start, end),
      listStaff({ activeOnly: true }).catch(() => []),
      getActiveOperatorAssignments().catch(() => ({})),
      listLines().catch(() => []),
    ]);
    setMachine(m);
    setProdTotals(totals);
    setOperatorEntries(entries);
    setStaffList(staff);
    setActiveAssignments(assignments);
    setLines(prodLines);
  }, [route.params.machineId, period]);

  useLiveQuery(load);

  const handleOpenEditModal = () => {
    if (!machine) return;
    setEditCode(machine.code || '');
    setEditName(machine.name || '');
    setEditType(machine.machine_type || 'General');
    setEditLineId(machine.line_id || '');
    setEditModalVisible(true);
  };

  const handleSaveEditMachine = async () => {
    if (!machine || !editCode.trim() || !editName.trim() || !editLineId) {
      Alert.alert('Required Fields', 'Please fill in machine code, name and line.');
      return;
    }
    try {
      await updateMachine(machine.id, {
        code: editCode,
        name: editName,
        machine_type: editType,
        line_id: editLineId,
      });
      setEditModalVisible(false);
      Alert.alert('Success', 'Machine updated successfully.');
      await load();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not update machine');
    }
  };

  const handleDeleteMachine = () => {
    if (!machine) return;
    Alert.alert(
      'Delete Machine',
      `Are you sure you want to delete machine ${machine.code} (${machine.name})? This cannot be undone.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete Machine',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteMachine(machine.id);
              Alert.alert('Deleted', `Machine ${machine.code} has been deleted.`);
              navigation.goBack();
            } catch (e: unknown) {
              Alert.alert('Cannot Delete', e instanceof Error ? e.message : 'Could not delete machine');
            }
          },
        },
      ],
    );
  };

  const applyStatus = (next: MachineStatus) => {
    if (!machine || machine.status === next) return;
    Alert.alert(
      'Change status',
      `Set ${machine.code} to ${next.replace(/_/g, ' ')}?`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Confirm',
          onPress: async () => {
            try {
              await setMachineStatus(machine.id, next, statusNote);
              setStatusNote('');
            } catch (e: unknown) {
              Alert.alert('Error', e instanceof Error ? e.message : 'Failed');
            }
          },
        },
      ],
    );
  };

  const handleOpenAssign = (shift = 'Morning', currentOp?: string | null) => {
    const availableStaff = staffList.find((s) => !activeAssignments[s.name]);
    setSelectedOperator(currentOp || availableStaff?.name || staffList[0]?.name || 'Arun Kumar');
    setSelectedShift(shift);
    setAssignNotes('');
    setAssignModalVisible(true);
  };

  const handleConfirmAssign = async () => {
    if (!machine || !selectedOperator.trim()) {
      Alert.alert('Required', 'Please select an operator.');
      return;
    }
    try {
      await assignOperatorToMachine(
        machine.id,
        selectedOperator.trim(),
        selectedShift,
        assignNotes.trim() || undefined,
      );
      setAssignModalVisible(false);
      Alert.alert('Success', `Assigned ${selectedOperator} to ${machine.code} on ${selectedShift} shift.`);
      await load();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not assign operator');
    }
  };

  if (!machine) return null;

  // Active / latest operator in current period
  const activeEntry = operatorEntries[0];
  const totalProducedInPeriod = operatorEntries.reduce((sum, e) => sum + (e.good_quantity || 0), 0);

  const shiftAssignments = (['Morning', 'Evening', 'Night'] as const).map((sh) => {
    const entry = operatorEntries.find(
      (e) => (e.shift || '').toLowerCase() === sh.toLowerCase() && !!e.operator,
    );
    const shiftTotal = operatorEntries
      .filter((e) => (e.shift || '').toLowerCase() === sh.toLowerCase())
      .reduce((sum, e) => sum + (e.good_quantity || 0), 0);

    return {
      shift: sh,
      operator: entry?.operator || null,
      total_produced: shiftTotal,
      last_active_at: entry?.entry_timestamp || null,
    };
  });

  return (
    <Screen scroll>
      {isViewOnly && (
        <ViewModeBanner
          message="Machine status & telemetry viewing mode. Operator assignment and status changes are disabled. Use the Management tab to make changes."
        />
      )}
      <View style={styles.headerRow}>
        <View style={{ flex: 1, marginRight: 8 }}>
          <Text style={typography.h2}>{machine.code}</Text>
          <Text style={[typography.bodySmall, { flexShrink: 1 }]} numberOfLines={2} ellipsizeMode="tail">
            Line {machine.line_code} · {machine.name}
          </Text>
        </View>
        <StatusBadge status={machine.status} />
      </View>

      {/* Quick Overview Card */}
      <Card style={styles.mainCard}>
        <View style={styles.metricRow}>
          <View style={styles.metricCol}>
            <Text style={styles.metricLabel}>Product</Text>
            <Text style={styles.metricVal}>
              {prodTotals?.activeProductCode || machine.product_code || 'General'}
            </Text>
            <Text style={styles.metricSub} numberOfLines={1}>
              {prodTotals?.activeProductName || 'Running Order'}
            </Text>
          </View>
          <View style={styles.metricCol}>
            <Text style={styles.metricLabel}>Items Created</Text>
            <Text style={styles.metricVal}>
              {formatNumber(totalProducedInPeriod)} pcs
            </Text>
            <Text style={styles.metricSub}>
              {prodTotals?.activeTargetQuantity
                ? `Order: ${formatNumber(prodTotals.activeProducedQuantity || 0)} / ${formatNumber(prodTotals.activeTargetQuantity)}`
                : `Total: ${formatNumber(prodTotals?.allTimeProduced || totalProducedInPeriod)} pcs`}
            </Text>
          </View>
          <View style={styles.metricCol}>
            <Text style={styles.metricLabel}>Total Output</Text>
            <Text style={styles.metricVal}>
              {formatNumber(prodTotals?.allTimeProduced || totalProducedInPeriod)} pcs
            </Text>
            <Text style={styles.metricSub}>
              {Math.round(machine.runtime_seconds / 3600)}h runtime
            </Text>
          </View>
        </View>
      </Card>

      {/* Operator Allocation Section with 1 Day, 1 Week, 1 Month Filter */}
      <View style={styles.sectionTitleRow}>
        <SectionHeader title="Person Working on Machine" />
        {!isViewOnly && (
          <Pressable style={styles.assignBtn} onPress={() => handleOpenAssign('Morning')}>
            <Ionicons name="person-add" size={14} color="#FFFFFF" />
            <Text style={styles.assignBtnText}>Assign Staff</Text>
          </Pressable>
        )}
      </View>

      {/* Period Tabs */}
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

      {/* 3 Shifts: Morning, Evening, Night */}
      <Card style={styles.operatorActiveCard}>
        <View style={styles.shiftsDetailHeader}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
            <Ionicons name="time-outline" size={16} color="#0A1E38" />
            <Text style={styles.shiftsDetailTitle}>3-Shift Staff Allocation</Text>
          </View>
          <Text style={styles.shiftsDetailBadge}>
            {shiftAssignments.filter((s) => s.operator !== null).length} / 3 Assigned
          </Text>
        </View>

        <View style={{ gap: 8, marginTop: 4 }}>
          {shiftAssignments.map((sa) => {
            const isMorning = sa.shift === 'Morning';
            const isEvening = sa.shift === 'Evening';
            const shiftIcon = isMorning ? 'sunny-outline' : isEvening ? 'partly-sunny-outline' : 'moon-outline';
            const shiftColor = isMorning ? '#EA580C' : isEvening ? '#D97706' : '#6366F1';
            const shiftBg = isMorning ? '#FFF7ED' : isEvening ? '#FEF3C7' : '#EEF2FF';
            const shiftTime = isMorning ? '06:00 - 14:00' : isEvening ? '14:00 - 22:00' : '22:00 - 06:00';

            return (
              <View
                key={sa.shift}
                style={[
                  styles.shiftDetailRow,
                  sa.operator ? styles.shiftDetailRowActive : styles.shiftDetailRowEmpty,
                ]}
              >
                <View style={styles.shiftDetailLeft}>
                  <View style={[styles.shiftDetailIconBox, { backgroundColor: shiftBg }]}>
                    <Ionicons name={shiftIcon} size={15} color={shiftColor} />
                  </View>
                  <View>
                    <Text style={[styles.shiftDetailLabel, { color: shiftColor }]}>
                      {sa.shift} Shift
                    </Text>
                    <Text style={styles.shiftDetailTime}>{shiftTime}</Text>
                  </View>
                </View>

                <View style={styles.shiftDetailRight}>
                  {sa.operator ? (
                    <View style={styles.shiftDetailAssignedBox}>
                      <View style={{ alignItems: 'flex-end' }}>
                        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                          <Ionicons name="person" size={12} color={colors.primary} />
                          <Text style={styles.shiftDetailOperatorName}>{sa.operator}</Text>
                        </View>
                        {sa.total_produced > 0 && (
                          <Text style={styles.shiftDetailProducedText}>
                            {formatNumber(sa.total_produced)} pcs
                          </Text>
                        )}
                      </View>
                      {!isViewOnly && (
                        <Pressable
                          style={styles.shiftDetailChangeBtn}
                          onPress={() => handleOpenAssign(sa.shift, sa.operator)}
                          hitSlop={6}
                        >
                          <Ionicons name="pencil" size={12} color="#0284C7" />
                        </Pressable>
                      )}
                    </View>
                  ) : !isViewOnly ? (
                    <Pressable
                      style={styles.shiftDetailAssignBtn}
                      onPress={() => handleOpenAssign(sa.shift)}
                    >
                      <Ionicons name="person-add-outline" size={13} color="#0284C7" />
                      <Text style={styles.shiftDetailAssignBtnText}>Assign</Text>
                    </Pressable>
                  ) : (
                    <Text style={{ fontSize: 11, color: colors.textMuted, paddingHorizontal: 6 }}>
                      Unassigned
                    </Text>
                  )}
                </View>
              </View>
            );
          })}
        </View>

        {activeEntry && (
          <View style={styles.activeStatsFooter}>
            <Text style={styles.statLine}>
              Total output this {period}: <Text style={styles.statBold}>{formatNumber(totalProducedInPeriod)} pcs</Text>
            </Text>
            <Text style={styles.statLine}>
              Active: {formatDateTime(activeEntry.entry_timestamp)}
            </Text>
          </View>
        )}
      </Card>

      {/* Detailed Operator History Timeline for Selected Period */}
      <SectionHeader title={`Work History (${PERIOD_TABS.find((t) => t.preset === period)?.label})`} />
      {operatorEntries.length === 0 ? (
        <Card style={styles.emptyCard}>
          <Text style={styles.emptyText}>No operator production logged in this period.</Text>
        </Card>
      ) : (
        operatorEntries.map((e) => (
          <Card key={e.id} style={styles.historyCard}>
            <View style={styles.historyTop}>
              <View style={styles.historyOperatorRow}>
                <Ionicons name="person-circle-outline" size={18} color={colors.primary} />
                <Text style={styles.historyOperatorName}>{e.operator || 'Operator'}</Text>
              </View>
              <View style={styles.historyShiftBadge}>
                <Text style={styles.historyShiftText}>{e.shift} Shift</Text>
              </View>
            </View>

            <View style={styles.historyDetails}>
              <Text style={styles.historyDetailText}>
                Order: <Text style={styles.statBold}>{e.order_number}</Text> ({e.product_code})
              </Text>
              <Text style={styles.historyDetailText}>
                Produced: <Text style={styles.statBold}>{formatNumber(e.good_quantity || 0)} pcs</Text>
                {(e.rejected_quantity || 0) > 0 && ` (${e.rejected_quantity} rejected)`}
              </Text>
            </View>

            <Text style={styles.historyTimestamp}>{formatDateTime(e.entry_timestamp)}</Text>
          </Card>
        ))
      )}

      {/* Machine Status Management (Hidden in viewOnly mode) */}
      {!isViewOnly && (
        <>
          <SectionHeader title="Update Machine Status" />
          <Text style={typography.caption}>Tap a status to update this machine.</Text>
          <View style={styles.statusGrid}>
            {machineStatusOptions().map((s) => {
              const active = machine.status === s;
              return (
                <Pressable
                  key={s}
                  style={[styles.statusChip, active && styles.statusChipActive]}
                  onPress={() => applyStatus(s)}
                >
                  <Text style={[styles.statusChipText, active && styles.statusChipTextActive]}>
                    {s.replace(/_/g, ' ')}
                  </Text>
                </Pressable>
              );
            })}
          </View>
          <TextInput
            style={styles.input}
            placeholder="Note (optional, e.g. reason for change)"
            value={statusNote}
            onChangeText={setStatusNote}
          />

          <Button
            label="Report breakdown (with details)"
            variant="danger"
            onPress={() => navigation.navigate('ReportBreakdown', { machineId: machine.id })}
          />

          <View style={{ flexDirection: 'row', gap: 10, marginTop: 10 }}>
            <View style={{ flex: 1 }}>
              <Button
                label="Edit Machine"
                variant="secondary"
                onPress={handleOpenEditModal}
              />
            </View>
            <View style={{ flex: 1 }}>
              <Button
                label="Delete Machine"
                variant="danger"
                onPress={handleDeleteMachine}
              />
            </View>
          </View>
        </>
      )}

      {/* Assign Operator Modal */}
      <Modal visible={assignModalVisible} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Assign Person</Text>
              <Pressable onPress={() => setAssignModalVisible(false)}>
                <Ionicons name="close" size={24} color={colors.textSecondary} />
              </Pressable>
            </View>

            <Text style={styles.modalSub}>
              Assign operator to machine <Text style={styles.modalSubBold}>{machine.code}</Text>
            </Text>

            {/* Select Staff */}
            <Text style={styles.inputLabel}>Select Staff / Worker (Each machine has 1 person)</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginVertical: 4 }}>
              {staffList.map((st) => {
                const active = selectedOperator === st.name;
                const assign = activeAssignments[st.name];
                const isOnThisMachine = assign?.machines?.some((m: any) => m.machineId === machine.id);
                const otherMachines = assign?.machines?.filter((m: any) => m.machineId !== machine.id) || [];
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
                            ? `On this (${machine.code})`
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
              const isOnThisMachine = currentAssign?.machines?.some((m: any) => m.machineId === machine.id);
              const otherMachines = currentAssign?.machines?.filter((m: any) => m.machineId !== machine.id) || [];
              const machineCurrentOp = activeEntry?.operator;

              return (
                <View style={{ gap: 6, marginVertical: 4 }}>
                  {/* Note about Machine: Each machine has 1 person */}
                  {machineCurrentOp && machineCurrentOp !== selectedOperator && (
                    <View style={styles.bannerInfo}>
                      <Ionicons name="swap-horizontal" size={17} color="#0284C7" />
                      <Text style={styles.bannerInfoText}>
                        {machine.code} is currently operated by <Text style={styles.bold}>{machineCurrentOp}</Text>. Assigning {selectedOperator} will set them as the single operator for this machine.
                      </Text>
                    </View>
                  )}

                  {/* Note about Operator: One person can have multiple machines */}
                  {isOnThisMachine ? (
                    <View style={styles.bannerSuccess}>
                      <Ionicons name="checkmark-circle" size={17} color="#16A34A" />
                      <Text style={styles.bannerSuccessText}>
                        {selectedOperator} is already operating {machine.code}. You can adjust shift or notes.
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
                          They will now manage both {otherMachines.map((m: any) => m.machineCode).join(', ')} and {machine.code}.
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
              placeholder="Or type worker name…"
              value={selectedOperator}
              onChangeText={setSelectedOperator}
            />

            {/* Shift */}
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
            <Text style={styles.inputLabel}>Notes (Optional)</Text>
            <TextInput
              style={styles.textInput}
              placeholder="e.g. Standard production assignment"
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
                  activeAssignments[selectedOperator]?.machines?.some((m: any) => m.machineId !== machine.id)
                    ? 'Assign (Multi-Machine)'
                    : `Assign to ${machine.code}`
                }
                variant="primary"
                style={{ flex: 1 }}
                onPress={handleConfirmAssign}
              />
            </View>
          </View>
        </View>
      </Modal>

      {/* Edit Machine Modal */}
      <Modal visible={editModalVisible} transparent animationType="fade">
        <View style={styles.modalOverlay}>
          <View style={styles.modalCard}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Edit Machine Details</Text>
              <Pressable onPress={() => setEditModalVisible(false)}>
                <Ionicons name="close" size={24} color={colors.textSecondary} />
              </Pressable>
            </View>

            <ScrollView showsVerticalScrollIndicator={false}>
              <Text style={styles.inputLabel}>Machine Code *</Text>
              <TextInput
                style={styles.textInput}
                value={editCode}
                onChangeText={setEditCode}
                autoCapitalize="characters"
              />

              <Text style={styles.inputLabel}>Machine Name *</Text>
              <TextInput
                style={styles.textInput}
                value={editName}
                onChangeText={setEditName}
              />

              <Text style={styles.inputLabel}>Machine Type</Text>
              <TextInput
                style={styles.textInput}
                value={editType}
                onChangeText={setEditType}
              />

              <Text style={styles.inputLabel}>Production Line *</Text>
              <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginVertical: 6 }}>
                {lines.map((l) => {
                  const active = editLineId === l.id;
                  return (
                    <Pressable
                      key={l.id}
                      style={[
                        {
                          paddingHorizontal: 12,
                          paddingVertical: 8,
                          borderRadius: 8,
                          backgroundColor: active ? '#0A1E38' : '#F1F5F9',
                          marginRight: 8,
                          borderWidth: 1,
                          borderColor: active ? '#0A1E38' : '#E2E8F0',
                        },
                      ]}
                      onPress={() => setEditLineId(l.id)}
                    >
                      <Text
                        style={{
                          fontSize: 12,
                          fontWeight: '600',
                          color: active ? '#FFFFFF' : '#475569',
                        }}
                      >
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
                onPress={() => setEditModalVisible(false)}
              />
              <Button
                label="Save Changes"
                variant="primary"
                style={{ flex: 1 }}
                onPress={handleSaveEditMachine}
              />
            </View>
          </View>
        </View>
      </Modal>
    </Screen>
  );
}

const styles = StyleSheet.create({
  headerRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.xs,
  },
  mainCard: {
    padding: 16,
    borderRadius: 14,
    marginVertical: spacing.xs,
  },
  metricRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  metricCol: {
    flex: 1,
  },
  metricLabel: {
    fontSize: 11,
    color: colors.textSecondary,
    fontWeight: '600',
    marginBottom: 4,
  },
  metricVal: {
    fontSize: 15,
    fontWeight: '800',
    color: colors.text,
  },
  metricSub: {
    fontSize: 10,
    color: colors.textMuted,
    marginTop: 2,
    fontWeight: '500',
  },
  sectionTitleRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: spacing.md,
  },
  assignBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: colors.primary,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
  },
  assignBtnText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '700',
  },
  periodTabs: {
    flexDirection: 'row',
    backgroundColor: '#EEF2F6',
    borderRadius: 10,
    padding: 3,
    marginVertical: spacing.sm,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  periodChip: {
    flex: 1,
    paddingVertical: 7,
    alignItems: 'center',
    borderRadius: 8,
  },
  periodChipActive: {
    backgroundColor: '#0A1E38',
  },
  periodChipText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#64748B',
  },
  periodChipTextActive: {
    color: '#FFFFFF',
    fontWeight: '700',
  },
  operatorActiveCard: {
    padding: 16,
    borderRadius: 14,
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    marginBottom: spacing.sm,
    gap: 10,
  },
  shiftsDetailHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  shiftsDetailTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: '#0A1E38',
  },
  shiftsDetailBadge: {
    fontSize: 11,
    fontWeight: '800',
    color: colors.primary,
    backgroundColor: '#E0F2FE',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
  },
  shiftDetailRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: 9,
    paddingHorizontal: 12,
    borderRadius: 10,
    borderWidth: 1,
  },
  shiftDetailRowActive: {
    backgroundColor: '#FFFFFF',
    borderColor: '#CBD5E1',
  },
  shiftDetailRowEmpty: {
    backgroundColor: '#F1F5F9',
    borderColor: '#E2E8F0',
    borderStyle: 'dashed',
  },
  shiftDetailLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    flex: 1,
  },
  shiftDetailIconBox: {
    width: 28,
    height: 28,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  shiftDetailLabel: {
    fontSize: 13,
    fontWeight: '700',
  },
  shiftDetailTime: {
    fontSize: 11,
    color: colors.textMuted,
  },
  shiftDetailRight: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  shiftDetailAssignedBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  shiftDetailOperatorName: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0A1E38',
  },
  shiftDetailProducedText: {
    fontSize: 11,
    color: colors.textSecondary,
    fontWeight: '500',
  },
  shiftDetailChangeBtn: {
    padding: 6,
    borderRadius: 6,
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
  },
  shiftDetailAssignBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingVertical: 6,
    paddingHorizontal: 10,
    borderRadius: 8,
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
  },
  shiftDetailAssignBtnText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#0284C7',
  },
  operatorCardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
  },
  operatorAvatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#DCFCE7',
    alignItems: 'center',
    justifyContent: 'center',
  },
  operatorLabel: {
    fontSize: 11,
    fontWeight: '600',
    color: '#166534',
  },
  operatorNameBig: {
    fontSize: 16,
    fontWeight: '800',
    color: colors.text,
    marginTop: 2,
  },
  shiftBadge: {
    backgroundColor: '#DCFCE7',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 8,
  },
  shiftBadgeText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#15803D',
  },
  activeStatsFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#DCFCE7',
  },
  statLine: {
    fontSize: 12,
    color: colors.textSecondary,
  },
  statBold: {
    fontWeight: '700',
    color: colors.text,
  },
  emptyCard: {
    padding: 16,
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  emptyText: {
    color: colors.textSecondary,
    fontSize: 13,
  },
  historyCard: {
    padding: 14,
    borderRadius: 12,
    marginBottom: spacing.sm,
    gap: 6,
  },
  historyTop: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  historyOperatorRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  historyOperatorName: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.text,
  },
  historyShiftBadge: {
    backgroundColor: '#F1F5F9',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
  },
  historyShiftText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  historyDetails: {
    flexDirection: 'row',
    justifyContent: 'space-between',
  },
  historyDetailText: {
    fontSize: 12,
    color: colors.textSecondary,
  },
  historyTimestamp: {
    fontSize: 11,
    color: colors.textMuted,
  },
  statusGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: spacing.sm,
    marginVertical: spacing.sm,
  },
  statusChip: {
    paddingHorizontal: spacing.md,
    paddingVertical: spacing.sm,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surface,
  },
  statusChipActive: {
    borderColor: colors.primary,
    backgroundColor: colors.primary,
  },
  statusChipText: { ...typography.caption, fontWeight: '600' },
  statusChipTextActive: { color: '#fff' },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 10,
    padding: spacing.md,
    backgroundColor: colors.surface,
    marginBottom: spacing.md,
  },
  // Modal
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
  assignTagMulti: {
    backgroundColor: '#E0F2FE',
  },
  assignTagOnThis: {
    backgroundColor: '#E0F2FE',
  },
  assignTagFree: {
    backgroundColor: '#DCFCE7',
  },
  assignTagText: {
    fontSize: 10,
    fontWeight: '700',
  },
  multiMachineTagBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    borderRadius: 6,
    paddingHorizontal: 8,
    paddingVertical: 4,
    marginTop: 6,
    alignSelf: 'flex-start',
  },
  multiMachineTagText: {
    fontSize: 11,
    fontWeight: '700',
    color: '#0369A1',
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
    color: '#0284C7',
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
  bold: {
    fontWeight: '700',
    color: colors.text,
  },
  modalActions: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 8,
  },
});
