import { Ionicons } from '@expo/vector-icons';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useEffect, useRef, useState } from 'react';
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
import { ProgressBar } from '../../components/common/ProgressBar';
import { Screen } from '../../components/common/Screen';
import { SectionHeader } from '../../components/common/SectionHeader';
import { StatusBadge } from '../../components/common/StatusBadge';
import { listMachines } from '../../api/repositories/machineRepository';
import { listStaff } from '../../api/repositories/staffRepository';
import {
  deleteProductionOrder,
  getMaterialAvailabilityForOrder,
  getProductionOrderById,
  updateProductionOrder,
} from '../../api/repositories/productionOrderRepository';
import type { HomeStackParamList } from '../../navigation/types';
import {
  ProductionBlockedError,
  startProduction,
} from '../../services/productionService';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { colors, spacing, typography } from '../../theme';
import type {
  MachineRow,
  MaterialAvailabilityRow,
  Priority,
  ProductionOrderRow,
  StaffRow,
} from '../../types/database';
import { progressPct } from '../../utils/calculations';
import { formatDateTime, formatNumber, formatPct } from '../../utils/format';

import { ViewModeBanner } from '../../components/common/ViewModeBanner';

const statusColor = (s: 'AVAILABLE' | 'NEAR_MINIMUM' | 'SHORTAGE' | string) => {
  if (s === 'AVAILABLE') return colors.materialAvailable || colors.success;
  if (s === 'SHORTAGE') return colors.materialShortage || colors.danger;
  return colors.materialNearMinimum || colors.warning;
};

type Props = NativeStackScreenProps<HomeStackParamList, 'ProductionOrderDetail'>;

export function ProductionOrderDetailScreen({ navigation, route }: Props) {
  const isViewOnly = Boolean(route.params?.viewOnly);
  const [order, setOrder] = useState<ProductionOrderRow | null>(null);
  const [materials, setMaterials] = useState<MaterialAvailabilityRow[]>([]);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editTargetQty, setEditTargetQty] = useState('');
  const [editPriority, setEditPriority] = useState<Priority>('MEDIUM');
  const [editMachineIds, setEditMachineIds] = useState<string[]>([]);

  // Resource Assignment Modal State (Machine + Worker required for production)
  const [showStartModal, setShowStartModal] = useState(false);
  const [availableMachines, setAvailableMachines] = useState<MachineRow[]>([]);
  const [availableStaff, setAvailableStaff] = useState<StaffRow[]>([]);
  const [selectedMachineIds, setSelectedMachineIds] = useState<string[]>([]);
  const [selectedStaffIds, setSelectedStaffIds] = useState<string[]>([]);
  const [startingProduction, setStartingProduction] = useState(false);

  const load = useCallback(async () => {
    const [o, mats, allM, allSt] = await Promise.all([
      getProductionOrderById(route.params.orderId),
      getMaterialAvailabilityForOrder(route.params.orderId),
      listMachines().catch(() => []),
      listStaff({ activeOnly: true }).catch(() => []),
    ]);
    setOrder(o);
    setMaterials(mats);
    setAvailableMachines(allM);
    setAvailableStaff(allSt);
  }, [route.params.orderId]);

  useLiveQuery(load);

  const handleOpenEdit = () => {
    if (!order) return;
    const qty = order.target_quantity ?? (order as any).planned_quantity ?? '';
    setEditTargetQty(String(qty));
    setEditPriority(order.priority || 'MEDIUM');
    const existingMachines: string[] =
      Array.isArray(order.assigned_machines) && order.assigned_machines.length > 0
        ? order.assigned_machines.map(String)
        : order.machine_id
        ? [order.machine_id]
        : [];
    setEditMachineIds(existingMachines);
    setShowEditModal(true);
  };

  const handleSaveEdit = async () => {
    const qty = parseFloat(editTargetQty);
    if (isNaN(qty) || qty <= 0) {
      Alert.alert('Invalid Quantity', 'Target quantity must be greater than 0.');
      return;
    }
    try {
      await updateProductionOrder(route.params.orderId, {
        target_quantity: qty,
        priority: editPriority,
        machine_id: editMachineIds[0] || null,
        assigned_machines: editMachineIds,
      });
      setShowEditModal(false);
      Alert.alert('Success', 'Production order updated.');
      await load();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not update order');
    }
  };

  const handleDeleteOrder = () => {
    if (!order) return;
    Alert.alert(
      'Delete Order',
      `Are you sure you want to delete order ${order.order_number}? This cannot be undone.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete Order',
          style: 'destructive',
          onPress: async () => {
            try {
              await deleteProductionOrder(order.id);
              Alert.alert('Deleted', `Order ${order.order_number} has been deleted.`);
              navigation.goBack();
            } catch (e: unknown) {
              Alert.alert('Cannot Delete', e instanceof Error ? e.message : 'Could not delete order');
            }
          },
        },
      ],
    );
  };

  const inProgress = order?.status === 'IN_PROGRESS';
  const hasMachine = Boolean(
    order?.machine_id ||
      (Array.isArray(order?.assigned_machines) && order.assigned_machines.length > 0),
  );
  const canStart =
    order &&
    (order.status === 'PENDING' ||
      (order.status as string) === 'PLANNED' ||
      order.status === 'DELAYED' ||
      (inProgress && !hasMachine));
  const isQcApproved = order?.qc_status === 'PASSED' || order?.qc_status === 'WAIVED';

  const autoTriggeredRef = useRef(false);
  useEffect(() => {
    if (
      route.params?.autoOpenStartModal &&
      !autoTriggeredRef.current &&
      order &&
      isQcApproved &&
      order.status === 'PENDING'
    ) {
      autoTriggeredRef.current = true;
      onStart();
    }
  }, [route.params?.autoOpenStartModal, order?.id, isQcApproved]);

  const onStart = async () => {
    try {
      const [machines, staff] = await Promise.all([
        listMachines().catch(() => []),
        listStaff({ activeOnly: true }).catch(() => []),
      ]);
      setAvailableMachines(machines);
      setAvailableStaff(staff);

      let preselectedMachines: string[] = [];
      if (Array.isArray(order?.assigned_machines) && order.assigned_machines.length > 0) {
        preselectedMachines = order.assigned_machines.map(String);
      } else if (order?.machine_id) {
        preselectedMachines = [order.machine_id];
      } else if (machines.length > 0) {
        const lineMachine = machines.find((m) => m.line_id === order?.line_id);
        if (lineMachine) preselectedMachines = [lineMachine.id];
      }
      setSelectedMachineIds(preselectedMachines);

      let preselectedStaff: string[] = [];
      if (Array.isArray(order?.assigned_workers) && order.assigned_workers.length > 0) {
        const matched = staff.filter(
          (s) =>
            order.assigned_workers!.includes(s.name) ||
            order.assigned_workers!.includes(s.id),
        );
        preselectedStaff = matched.map((s) => s.id);
      }
      if (preselectedStaff.length === 0) {
        const defaultWorker = staff.find((s) => s.role === 'OPERATOR') || staff[0];
        if (defaultWorker) preselectedStaff = [defaultWorker.id];
      }
      setSelectedStaffIds(preselectedStaff);

      setShowStartModal(true);
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Could not load machines and staff');
    }
  };

  const toggleMachineSelection = (id: string) => {
    setSelectedMachineIds((prev) =>
      prev.includes(id) ? prev.filter((mId) => mId !== id) : [...prev, id],
    );
  };

  const toggleStaffSelection = (id: string) => {
    setSelectedStaffIds((prev) =>
      prev.includes(id) ? prev.filter((sId) => sId !== id) : [...prev, id],
    );
  };

  const handleSaveAssignmentOnly = async () => {
    if (selectedMachineIds.length === 0) {
      Alert.alert('Machine Required', 'Please select at least one machine.');
      return;
    }
    try {
      setStartingProduction(true);
      const chosenWorkers = availableStaff.filter((s) => selectedStaffIds.includes(s.id));
      const workerNames = chosenWorkers.map((w) => w.name);
      const primaryMachineId = selectedMachineIds[0];

      await updateProductionOrder(route.params.orderId, {
        machine_id: primaryMachineId,
        assigned_machines: selectedMachineIds,
        assigned_workers: workerNames,
      });

      setShowStartModal(false);
      await load();
      Alert.alert(
        'Assignment Saved',
        `Machine(s) and staff assigned to order ${order?.order_number}.\n\nMachines: ${selectedMachineIds.length} assigned\nWorkers: ${workerNames.length > 0 ? workerNames.join(', ') : 'None'}`,
      );
    } catch (e: unknown) {
      Alert.alert('Save Failed', e instanceof Error ? e.message : 'Could not save assignment');
    } finally {
      setStartingProduction(false);
    }
  };

  const handleConfirmStartProduction = async () => {
    if (selectedMachineIds.length === 0) {
      Alert.alert('Machine Required', 'Please assign at least one machine for this production.');
      return;
    }
    if (selectedStaffIds.length === 0) {
      Alert.alert('Worker Required', 'Please assign at least one worker to the machine(s).');
      return;
    }
    if (!isQcApproved) {
      Alert.alert(
        'Quality Check Required',
        `Pre-production quality check has not been approved yet.\n\nCurrent status: ${order?.qc_status || 'PENDING'}.\n\nQuality approval must be completed in Quality Assurance before starting live production.\n\nWould you like to save the machine & worker assignment for this order now?`,
        [
          { text: 'Cancel', style: 'cancel' },
          { text: 'Save Assignment Only', onPress: handleSaveAssignmentOnly },
        ],
      );
      return;
    }

    try {
      setStartingProduction(true);
      const chosenWorkers = availableStaff.filter((s) => selectedStaffIds.includes(s.id));
      const workerNames = chosenWorkers.map((w) => w.name);

      await startProduction({
        orderId: route.params.orderId,
        machineIds: selectedMachineIds,
        workerIds: selectedStaffIds,
        workerNames,
      });

      setShowStartModal(false);
      await load();
      Alert.alert(
        'Production Started',
        `Production started successfully for order ${order?.order_number}.\n\nMachines: ${selectedMachineIds.length} assigned\nWorkers: ${workerNames.join(', ')} assigned`,
      );
    } catch (e: unknown) {
      const msg =
        e instanceof ProductionBlockedError
          ? e.message
          : e instanceof Error
            ? e.message
            : 'Failed to start production';
      Alert.alert('Cannot Start', msg);
    } finally {
      setStartingProduction(false);
    }
  };


  if (!order) return null;
  const progress = progressPct(order.produced_quantity || 0, order.target_quantity || 0);
  const showMachineLockNotice = inProgress && hasMachine;

  return (
    <Screen scroll>
      {showMachineLockNotice ? (
        <View style={styles.headerRow}>
          <Ionicons name="information-circle" size={16} color="#B45309" />
          <Text style={styles.lockNoticeText}>
            Machine assignments are locked while order is IN PROGRESS. Log output below as units are made.
          </Text>
        </View>
      ) : null}
      <Card>
        <Text style={typography.body}>{order.product_name}</Text>
        <Text style={typography.bodySmall}>Line {order.line_code}</Text>
        <Text style={typography.label}>
          {formatNumber(order.produced_quantity || 0)} / {formatNumber(order.target_quantity || 0)} (
          {formatPct(progress)})
        </Text>
        <ProgressBar progress={progress} />
      </Card>

      {/* 2. Pre-Production Quality Check (Offline) Card */}
      <Card
        style={[
          styles.qcCard,
          isQcApproved
            ? styles.qcCardPassed
            : order.qc_status === 'FAILED'
            ? styles.qcCardFailed
            : styles.qcCardPending,
        ]}
      >
        <View style={styles.qcHeaderRow}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10, flex: 1 }}>
            <View
              style={[
                styles.qcIconBox,
                {
                  backgroundColor: isQcApproved
                    ? '#ECFDF5'
                    : order.qc_status === 'FAILED'
                    ? '#FEF2F2'
                    : '#FFFBEB',
                },
              ]}
            >
              <Ionicons
                name={
                  isQcApproved
                    ? 'checkmark-done-circle'
                    : order.qc_status === 'FAILED'
                    ? 'close-circle'
                    : 'shield-outline'
                }
                size={22}
                color={
                  isQcApproved
                    ? colors.success
                    : order.qc_status === 'FAILED'
                    ? colors.danger
                    : colors.warning
                }
              />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.qcTitle}>Pre-Production Quality Check</Text>
              <Text style={styles.qcSub}>
                {isQcApproved
                  ? `Offline Check Passed • Verified by ${order.qc_inspector || 'Inspector'}`
                  : order.qc_status === 'FAILED'
                  ? `QC Failed • Inspected by ${order.qc_inspector || 'Inspector'}`
                  : 'Mandatory offline check before start'}
              </Text>
            </View>
          </View>

          <View
            style={[
              styles.qcBadge,
              {
                backgroundColor: isQcApproved
                  ? '#ECFDF5'
                  : order.qc_status === 'FAILED'
                  ? '#FEF2F2'
                  : '#FFFBEB',
                borderColor: isQcApproved
                  ? '#A7F3D0'
                  : order.qc_status === 'FAILED'
                  ? '#FECACA'
                  : '#FDE68A',
              },
            ]}
          >
            <Text
              style={[
                styles.qcBadgeText,
                {
                  color: isQcApproved
                    ? colors.success
                    : order.qc_status === 'FAILED'
                    ? colors.danger
                    : colors.warning,
                },
              ]}
            >
              {order.qc_status === 'PASSED'
                ? 'PASSED'
                : order.qc_status === 'FAILED'
                ? 'FAILED'
                : order.qc_status === 'WAIVED'
                ? 'WAIVED'
                : 'QC PENDING'}
            </Text>
          </View>
        </View>

        {order.qc_notes ? (
          <View style={styles.qcNotesBox}>
            <Text style={styles.qcNotesText} numberOfLines={2}>
              {order.qc_notes}
            </Text>
            {order.qc_inspected_at ? (
              <Text style={styles.qcDateText}>
                Recorded on {formatDateTime(order.qc_inspected_at)}
              </Text>
            ) : null}
          </View>
        ) : null}

        {/* QC status footer */}
        {isQcApproved && order.qc_inspector ? (
          <View style={styles.qcActionRow}>
            <View style={styles.qcVerifiedBadge}>
              <Ionicons name="checkmark-circle" size={15} color={colors.success} />
              <Text style={styles.qcVerifiedText}>
                Approved in QA by {order.qc_inspector}
              </Text>
            </View>
          </View>
        ) : null}
      </Card>

      {/* 3. Assigned Production Resources Card */}
      <Card style={styles.resourceCard}>
        <View style={styles.resourceHeader}>
          <Ionicons name="hardware-chip-outline" size={18} color={colors.primary} />
          <View style={{ flex: 1 }}>
            <Text style={styles.resourceTitle}>Assigned Machines & Operators</Text>
          </View>
          {!isViewOnly && order.status !== 'COMPLETED' && order.status !== 'CANCELLED' && (
            <Pressable
              onPress={onStart}
              style={{
                paddingHorizontal: 10,
                paddingVertical: 5,
                borderRadius: 6,
                backgroundColor: '#E2E8F0',
              }}
            >
              <Text style={{ fontSize: 11, fontWeight: '700', color: colors.primary }}>
                {hasMachine ? 'Change / Reassign' : '+ Assign Resources'}
              </Text>
            </Pressable>
          )}
        </View>

        {/* Assigned Machines */}
        <View style={styles.resourceSection}>
          <Text style={styles.resourceLabel}>MACHINES:</Text>
          {Array.isArray(order.assigned_machines) && order.assigned_machines.length > 0 ? (
            <View style={styles.tagWrap}>
              {order.assigned_machines.map((mId) => {
                const machineObj = availableMachines.find((m) => String(m.id) === String(mId));
                const label = machineObj ? `${machineObj.code} (${machineObj.name})` : `Machine #${mId}`;
                return (
                  <View key={String(mId)} style={styles.machineTag}>
                    <Ionicons name="construct-outline" size={13} color="#1E40AF" />
                    <Text style={styles.machineTagText}>{label}</Text>
                  </View>
                );
              })}
            </View>
          ) : order.machine_id ? (
            <View style={styles.tagWrap}>
              {(() => {
                const machineObj = availableMachines.find((m) => String(m.id) === String(order.machine_id));
                const label = machineObj ? `${machineObj.code} (${machineObj.name})` : `Machine #${order.machine_id}`;
                return (
                  <View style={styles.machineTag}>
                    <Ionicons name="construct-outline" size={13} color="#1E40AF" />
                    <Text style={styles.machineTagText}>{label}</Text>
                  </View>
                );
              })()}
            </View>
          ) : (
            <Text style={styles.emptyNotice}>No machine assigned yet. Tap "+ Assign Resources" above.</Text>
          )}
        </View>

        {/* Assigned Staff */}
        <View style={[styles.resourceSection, { marginTop: 10 }]}>
          <Text style={styles.resourceLabel}>OPERATORS / WORKERS:</Text>
          {Array.isArray(order.assigned_workers) && order.assigned_workers.length > 0 ? (
            <View style={styles.tagWrap}>
              {order.assigned_workers.map((wName, idx) => (
                <View key={idx} style={styles.workerTag}>
                  <Ionicons name="person-outline" size={13} color="#065F46" />
                  <Text style={styles.workerTagText}>{wName}</Text>
                </View>
              ))}
            </View>
          ) : (
            <Text style={styles.emptyNotice}>No operator assigned yet. Tap "+ Assign Resources" above.</Text>
          )}
        </View>
      </Card>

      <SectionHeader title="Material availability" />
      {materials.map((m) => (
        <Card key={m.material_id}>
          <Text style={typography.body}>{m.code}</Text>
          <Text style={typography.caption}>
            Per unit: {formatNumber(m.per_unit, 3)} {m.unit}
          </Text>
          <Text style={[typography.caption, { color: statusColor(m.status) }]}>
            Used on order: {formatNumber(m.used_total, 1)} · Still needed:{' '}
            {formatNumber(m.required, 1)} · In stock: {formatNumber(m.available, 1)} · {m.status}
          </Text>
        </Card>
      ))}

      {!isViewOnly && order.status !== 'COMPLETED' && order.status !== 'CANCELLED' ? (
        <>
          {canStart ? (
            <View style={{ gap: 8, marginTop: 4 }}>
              {!isQcApproved && (
                <View style={styles.lockNoticeRow}>
                  <Ionicons name="lock-closed" size={14} color={colors.warning} />
                  <Text style={styles.lockNoticeText}>
                    Live production requires QC approval. You can assign machines and workers below anytime.
                  </Text>
                </View>
              )}
              <View style={{ flexDirection: 'row', gap: 8 }}>
                <View style={{ flex: 1 }}>
                  <Button
                    label={hasMachine ? 'Reassign Resources' : 'Assign Machine'}
                    variant="secondary"
                    onPress={onStart}
                  />
                </View>
                <View style={{ flex: 1.2 }}>
                  <Button
                    label={isQcApproved ? 'Start Production' : 'Start (QC Pending)'}
                    variant={isQcApproved ? 'primary' : 'secondary'}
                    onPress={onStart}
                  />
                </View>
              </View>
            </View>
          ) : null}
          {inProgress && hasMachine ? (
            <Button
              label="Record production"
              onPress={() => navigation.navigate('RecordProduction', { orderId: order.id })}
            />
          ) : null}

          {order.status === 'PENDING' && (
            <View style={{ flexDirection: 'row', gap: 10, marginTop: 10 }}>
              <View style={{ flex: 1 }}>
                <Button label="Edit Order" variant="secondary" onPress={handleOpenEdit} />
              </View>
              <View style={{ flex: 1 }}>
                <Button label="Delete Order" variant="danger" onPress={handleDeleteOrder} />
              </View>
            </View>
          )}
        </>
      ) : null}

      {!isViewOnly && order.status === 'CANCELLED' && (
        <Button label="Delete Order" variant="danger" onPress={handleDeleteOrder} style={{ marginTop: 10 }} />
      )}

      {/* Edit Order Modal */}
      <Modal visible={showEditModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={typography.h2}>Edit Production Order</Text>
              <Pressable onPress={() => setShowEditModal(false)}>
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>

            <Text style={styles.modalSub}>{order.order_number} · {order.product_name}</Text>

            <Text style={styles.inputLabel}>Target Quantity *</Text>
            <TextInput
              style={styles.modalInput}
              keyboardType="numeric"
              placeholder="e.g. 500"
              value={editTargetQty}
              onChangeText={setEditTargetQty}
            />

            <Text style={styles.inputLabel}>Priority</Text>
            <View style={{ flexDirection: 'row', gap: 6, marginVertical: 6 }}>
              {(['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'] as Priority[]).map((p) => {
                const active = editPriority === p;
                return (
                  <Pressable
                    key={p}
                    style={[
                      {
                        paddingHorizontal: 12,
                        paddingVertical: 7,
                        borderRadius: 8,
                        backgroundColor: active ? '#0A1E38' : '#F1F5F9',
                        borderWidth: 1,
                        borderColor: active ? '#0A1E38' : '#E2E8F0',
                      },
                    ]}
                    onPress={() => setEditPriority(p)}
                  >
                    <Text
                      style={{
                        fontSize: 12,
                        fontWeight: '600',
                        color: active ? '#FFFFFF' : '#475569',
                      }}
                    >
                      {p}
                    </Text>
                  </Pressable>
                );
              })}
            </View>

            <Text style={styles.inputLabel}>
              Assigned Machines ({editMachineIds.length} selected)
            </Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ marginVertical: 6 }}>
              <View style={{ flexDirection: 'row', gap: 6 }}>
                <Pressable
                  style={[
                    styles.chip,
                    editMachineIds.length === 0 && styles.chipActive,
                  ]}
                  onPress={() => setEditMachineIds([])}
                >
                  <Text style={[styles.chipText, editMachineIds.length === 0 && styles.chipTextActive]}>
                    None
                  </Text>
                </Pressable>
                {availableMachines.map((m) => {
                  const active = editMachineIds.includes(m.id);
                  return (
                    <Pressable
                      key={m.id}
                      style={[styles.chip, active && styles.chipActive]}
                      onPress={() => {
                        setEditMachineIds((prev) =>
                          prev.includes(m.id) ? prev.filter((id) => id !== m.id) : [...prev, m.id],
                        );
                      }}
                    >
                      <Text style={[styles.chipText, active && styles.chipTextActive]}>
                        {active ? '✓ ' : ''}{m.code} - {m.name}
                      </Text>
                    </Pressable>
                  );
                })}
              </View>
            </ScrollView>

            <View style={styles.modalActions}>
              <Button label="Cancel" variant="secondary" onPress={() => setShowEditModal(false)} />
              <Button label="Save Changes" onPress={handleSaveEdit} />
            </View>
          </View>
        </View>
      </Modal>

      {/* Resource Assignment Modal (Machine & Staff) */}
      <Modal visible={showStartModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { maxHeight: '88%' }]}>
            <View style={styles.modalHeader}>
              <View style={{ flex: 1 }}>
                <Text style={typography.h2}>Assign Production Resources</Text>
                <Text style={styles.modalSub}>
                  {order.order_number} · Line {order.line_code || 'General'}
                </Text>
              </View>
              <Pressable
                onPress={() => setShowStartModal(false)}
                hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
              >
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>

            <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={{ paddingBottom: 16 }}>
              {/* Step 1: Machine Selection */}
              <View style={styles.stepBox}>
                <View style={styles.stepHeaderRow}>
                  <View style={styles.stepNumberBadge}>
                    <Text style={styles.stepNumberText}>1</Text>
                  </View>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.stepTitle}>Assign Machine(s)</Text>
                    <Text style={styles.stepSubtitle}>Select one or more machines for this run</Text>
                  </View>
                  <View style={styles.selectedCountBadge}>
                    <Text style={styles.selectedCountText}>
                      {selectedMachineIds.length} selected
                    </Text>
                  </View>
                </View>

                <View style={{ gap: 8, marginTop: 10 }}>
                  {availableMachines.length === 0 ? (
                    <View style={styles.emptyNoticeBox}>
                      <Ionicons name="alert-circle-outline" size={20} color={colors.textMuted} />
                      <Text style={styles.emptyNoticeText}>
                        No machines found in this company. Please add machines in Machine Management.
                      </Text>
                    </View>
                  ) : (
                    availableMachines.map((m) => {
                      const isSelected = selectedMachineIds.includes(m.id);
                      const isSameLine = m.line_id === order.line_id;
                      const mStatusColor =
                        m.status === 'RUNNING'
                          ? '#059669'
                          : m.status === 'MAINTENANCE'
                          ? '#DC2626'
                          : m.status === 'IDLE'
                          ? '#2563EB'
                          : '#64748B';

                      return (
                        <Pressable
                          key={m.id}
                          style={[
                            styles.resourcePickCard,
                            isSelected && styles.resourcePickCardSelected,
                          ]}
                          onPress={() => toggleMachineSelection(m.id)}
                        >
                          <Ionicons
                            name={isSelected ? 'checkbox' : 'square-outline'}
                            size={22}
                            color={isSelected ? colors.primary : colors.border}
                          />
                          <View style={{ flex: 1 }}>
                            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                              <Text style={styles.resourceCardName}>{m.code}</Text>
                              <Text style={styles.resourceCardSub} numberOfLines={1}>
                                {m.name}
                              </Text>
                              {isSameLine && (
                                <View style={styles.lineMatchBadge}>
                                  <Text style={styles.lineMatchText}>Assigned Line</Text>
                                </View>
                              )}
                            </View>
                            {m.machine_type ? (
                              <Text style={styles.resourceCardType}>{m.machine_type}</Text>
                            ) : null}
                          </View>
                          <View
                            style={[
                              styles.miniStatusBadge,
                              { backgroundColor: `${mStatusColor}18` },
                            ]}
                          >
                            <Text style={[styles.miniStatusText, { color: mStatusColor }]}>
                              {m.status || 'AVAILABLE'}
                            </Text>
                          </View>
                        </Pressable>
                      );
                    })
                  )}
                </View>
              </View>

              {/* Step 2: Staff Selection */}
              <View style={[styles.stepBox, { marginTop: 12 }]}>
                <View style={styles.stepHeaderRow}>
                  <View style={styles.stepNumberBadge}>
                    <Text style={styles.stepNumberText}>2</Text>
                  </View>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.stepTitle}>Assign Operator(s) / Staff</Text>
                    <Text style={styles.stepSubtitle}>Who will operate the machine(s)?</Text>
                  </View>
                  <View style={styles.selectedCountBadge}>
                    <Text style={styles.selectedCountText}>
                      {selectedStaffIds.length} selected
                    </Text>
                  </View>
                </View>

                <View style={{ gap: 8, marginTop: 10 }}>
                  {availableStaff.length === 0 ? (
                    <View style={styles.emptyNoticeBox}>
                      <Ionicons name="person-outline" size={20} color={colors.textMuted} />
                      <Text style={styles.emptyNoticeText}>
                        No active staff members found. Add staff in Staff Management.
                      </Text>
                    </View>
                  ) : (
                    availableStaff.map((st) => {
                      const isSelected = selectedStaffIds.includes(st.id);
                      return (
                        <Pressable
                          key={st.id}
                          style={[
                            styles.resourcePickCard,
                            isSelected && styles.resourcePickCardSelected,
                          ]}
                          onPress={() => toggleStaffSelection(st.id)}
                        >
                          <Ionicons
                            name={isSelected ? 'checkbox' : 'square-outline'}
                            size={22}
                            color={isSelected ? colors.primary : colors.border}
                          />
                          <View style={{ flex: 1 }}>
                            <Text style={styles.resourceCardName}>{st.name}</Text>
                            <Text style={styles.resourceCardSub}>
                              {st.employee_id || st.role || 'Staff'}
                            </Text>
                          </View>
                          {st.role && (
                            <View style={styles.roleTag}>
                              <Text style={styles.roleTagText}>{st.role}</Text>
                            </View>
                          )}
                        </Pressable>
                      );
                    })
                  )}
                </View>
              </View>

              {/* Notice / QC Alert */}
              <View
                style={[
                  styles.summaryBox,
                  !isQcApproved && {
                    backgroundColor: '#FFFBEB',
                    borderColor: '#FDE68A',
                  },
                ]}
              >
                <Ionicons
                  name={isQcApproved ? 'shield-checkmark-outline' : 'alert-circle-outline'}
                  size={18}
                  color={isQcApproved ? '#0369A1' : '#B45309'}
                />
                <Text
                  style={[
                    styles.summaryText,
                    !isQcApproved && { color: '#B45309' },
                  ]}
                >
                  {isQcApproved
                    ? 'QC Approved: Starting production will transition this order to IN_PROGRESS and mark assigned machines as RUNNING.'
                    : 'Pre-production QC is PENDING. You can tap "Save Assignment" to link the machine & workers now without starting live production.'}
                </Text>
              </View>
            </ScrollView>

            {/* Modal Actions */}
            <View style={{ gap: 8, marginTop: 8 }}>
              <View style={{ flexDirection: 'row', gap: 8 }}>
                <View style={{ flex: 1 }}>
                  <Button
                    label="Cancel"
                    variant="secondary"
                    onPress={() => setShowStartModal(false)}
                  />
                </View>
                <View style={{ flex: 1.2 }}>
                  <Button
                    label={startingProduction ? 'Saving...' : 'Save Assignment'}
                    variant="secondary"
                    disabled={startingProduction || selectedMachineIds.length === 0}
                    onPress={handleSaveAssignmentOnly}
                  />
                </View>
              </View>
              <Button
                label={
                  startingProduction
                    ? 'Starting...'
                    : isQcApproved
                    ? 'Start Production Now'
                    : 'Start Production (Requires QC)'
                }
                variant={isQcApproved ? 'primary' : 'secondary'}
                disabled={startingProduction || selectedMachineIds.length === 0}
                onPress={handleConfirmStartProduction}
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
    gap: 6,
    backgroundColor: '#FFFBEB',
    padding: 8,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#FDE68A',
  },
  lockNoticeText: {
    fontSize: 11.5,
    color: '#B45309',
    fontWeight: '600',
    flex: 1,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  modalContent: {
    backgroundColor: colors.surface,
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    padding: spacing.lg,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.xs,
  },
  modalSub: {
    fontSize: 13,
    color: colors.textSecondary,
    marginBottom: spacing.sm,
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.textSecondary,
    marginTop: 10,
    marginBottom: 4,
  },
  modalInput: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    fontSize: 14,
    color: colors.text,
    backgroundColor: colors.background,
  },
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    gap: spacing.sm,
    marginTop: spacing.lg,
  },
  resourceCard: {
    backgroundColor: '#F8FAFC',
    borderColor: '#CBD5E1',
    borderWidth: 1,
    borderRadius: 12,
    padding: 12,
    marginBottom: spacing.md,
  },
  resourceHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    marginBottom: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
    paddingBottom: 6,
  },
  resourceTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: colors.text,
  },
  resourceSection: {
    marginTop: 2,
  },
  resourceLabel: {
    fontSize: 11,
    fontWeight: '700',
    color: colors.textSecondary,
    marginBottom: 4,
  },
  tagWrap: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  machineTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#EFF6FF',
    borderColor: '#BFDBFE',
    borderWidth: 1,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  machineTagText: {
    fontSize: 11.5,
    fontWeight: '700',
    color: '#1E40AF',
  },
  workerTag: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#ECFDF5',
    borderColor: '#A7F3D0',
    borderWidth: 1,
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  workerTagText: {
    fontSize: 11.5,
    fontWeight: '700',
    color: '#065F46',
  },
  stepBox: {
    backgroundColor: '#F8FAFC',
    borderRadius: 12,
    padding: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  stepHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  stepNumberBadge: {
    width: 22,
    height: 22,
    borderRadius: 11,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepNumberText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '800',
  },
  stepTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: colors.text,
  },
  stepSubtitle: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 1,
  },
  selectedCountBadge: {
    backgroundColor: '#DCFCE7',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 12,
  },
  selectedCountText: {
    fontSize: 10.5,
    fontWeight: '700',
    color: '#166534',
  },
  emptyNotice: {
    fontSize: 12,
    color: colors.textMuted,
    marginTop: 8,
    fontStyle: 'italic',
  },
  resourcePickCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    padding: 10,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  resourcePickCardSelected: {
    borderColor: colors.primary,
    backgroundColor: '#EFF6FF',
  },
  resourceCardName: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.text,
  },
  resourceCardSub: {
    fontSize: 11.5,
    color: colors.textSecondary,
  },
  resourceCardType: {
    fontSize: 10,
    color: colors.textMuted,
    marginTop: 1,
  },
  miniStatusBadge: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  miniStatusText: {
    fontSize: 10,
    fontWeight: '800',
  },
  roleTag: {
    backgroundColor: '#F1F5F9',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  roleTagText: {
    fontSize: 10,
    fontWeight: '700',
    color: '#475569',
  },
  summaryBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    borderRadius: 8,
    padding: 8,
    marginTop: 12,
    marginBottom: 8,
  },
  summaryText: {
    fontSize: 11,
    color: '#0369A1',
    flex: 1,
    lineHeight: 15,
  },
  qcCard: {
    borderRadius: 12,
    borderWidth: 1,
    padding: 14,
    marginBottom: spacing.md,
    gap: 10,
  },
  qcCardPassed: {
    backgroundColor: '#F0FDF4',
    borderColor: '#BBF7D0',
  },
  qcCardFailed: {
    backgroundColor: '#FEF2F2',
    borderColor: '#FECACA',
  },
  qcCardPending: {
    backgroundColor: '#FFFDF0',
    borderColor: '#FDE68A',
  },
  qcHeaderRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  qcIconBox: {
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },
  qcTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.text,
  },
  qcSub: {
    fontSize: 11.5,
    color: colors.textSecondary,
    marginTop: 2,
  },
  qcBadge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    borderWidth: 1,
  },
  qcBadgeText: {
    fontSize: 11,
    fontWeight: '800',
  },
  qcNotesBox: {
    backgroundColor: colors.surface,
    padding: 8,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: colors.border,
  },
  qcNotesText: {
    fontSize: 12,
    color: colors.text,
  },
  qcDateText: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 4,
  },
  qcActionRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing.sm,
  },
  qcVerifiedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#DCFCE7',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 6,
  },
  qcVerifiedText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#15803D',
  },
  lockNoticeRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: '#FEF3C7',
    padding: 8,
    borderRadius: 6,
  },
  emptyNoticeBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: '#F8FAFC',
    padding: 12,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  emptyNoticeText: {
    fontSize: 12,
    color: colors.textSecondary,
    flex: 1,
  },
  lineMatchBadge: {
    backgroundColor: '#DCFCE7',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  lineMatchText: {
    fontSize: 10,
    fontWeight: '700',
    color: '#15803D',
  },
  chip: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 8,
    backgroundColor: '#F1F5F9',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  chipActive: {
    backgroundColor: '#0A1E38',
    borderColor: '#0A1E38',
  },
  chipText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#475569',
  },
  chipTextActive: {
    color: '#FFFFFF',
  },
});
