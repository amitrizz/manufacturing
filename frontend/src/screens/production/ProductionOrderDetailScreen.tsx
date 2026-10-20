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
import { ProgressBar } from '../../components/common/ProgressBar';
import { Screen } from '../../components/common/Screen';
import { SectionHeader } from '../../components/common/SectionHeader';
import { StatusBadge } from '../../components/common/StatusBadge';
import { listMachines } from '../../database/repositories/machineRepository';
import { listStaff } from '../../database/repositories/staffRepository';
import {
  deleteProductionOrder,
  getMaterialAvailabilityForOrder,
  getProductionOrderById,
  updateProductionOrder,
} from '../../database/repositories/productionOrderRepository';
import type { RootStackParamList } from '../../navigation/types';
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

type Props = NativeStackScreenProps<RootStackParamList, 'ProductionOrderDetail'>;

const statusColor = (s: MaterialAvailabilityRow['status']) => {
  if (s === 'AVAILABLE') return colors.materialAvailable;
  if (s === 'SHORTAGE') return colors.materialShortage;
  return colors.materialNearMinimum;
};

export function ProductionOrderDetailScreen({ navigation, route }: Props) {
  const isViewOnly = Boolean(route.params?.viewOnly);
  const [order, setOrder] = useState<ProductionOrderRow | null>(null);
  const [materials, setMaterials] = useState<MaterialAvailabilityRow[]>([]);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editTargetQty, setEditTargetQty] = useState('');
  const [editPriority, setEditPriority] = useState<Priority>('MEDIUM');

  // Resource Assignment Modal State (Machine + Worker required for production)
  const [showStartModal, setShowStartModal] = useState(false);
  const [availableMachines, setAvailableMachines] = useState<MachineRow[]>([]);
  const [availableStaff, setAvailableStaff] = useState<StaffRow[]>([]);
  const [selectedMachineIds, setSelectedMachineIds] = useState<string[]>([]);
  const [selectedStaffIds, setSelectedStaffIds] = useState<string[]>([]);
  const [startingProduction, setStartingProduction] = useState(false);

  const load = useCallback(async () => {
    const o = await getProductionOrderById(route.params.orderId);
    setOrder(o);
    setMaterials(await getMaterialAvailabilityForOrder(route.params.orderId));
  }, [route.params.orderId]);

  useLiveQuery(load);

  const handleOpenEdit = () => {
    if (!order) return;
    setEditTargetQty(order.target_quantity.toString());
    setEditPriority(order.priority);
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

  const onStart = async () => {
    if (!isQcApproved) {
      Alert.alert(
        'Quality Check Required',
        `Pre-production quality check has not been approved yet.\n\nCurrent status: ${order?.qc_status || 'PENDING'}.\n\nQuality approval must be completed in Quality Assurance before starting production.`,
        [{ text: 'OK' }],
      );
      return;
    }

    try {
      const [machines, staff] = await Promise.all([
        listMachines().catch(() => []),
        listStaff({ activeOnly: true }).catch(() => []),
      ]);
      setAvailableMachines(machines);
      setAvailableStaff(staff);

      // Pre-select order's machine or first idle machine
      const defaultMId =
        order?.machine_id ||
        machines.find((m) => m.status === 'IDLE')?.id ||
        machines[0]?.id;
      setSelectedMachineIds(defaultMId ? [defaultMId] : []);

      // Pre-select first operator if available
      const defaultWorker =
        staff.find((s) => s.role === 'OPERATOR') ||
        staff[0];
      setSelectedStaffIds(defaultWorker ? [defaultWorker.id] : []);

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

  const handleConfirmStartProduction = async () => {
    if (selectedMachineIds.length === 0) {
      Alert.alert('Machine Required', 'Please assign at least one machine for this production.');
      return;
    }
    if (selectedStaffIds.length === 0) {
      Alert.alert('Worker Required', 'Please assign at least one worker to the machine(s).');
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
  const progress = progressPct(order.produced_quantity, order.target_quantity);
  const inProgress = order.status === 'IN_PROGRESS';
  const hasMachine = Boolean(order.machine_id);
  const canStart =
    order.status === 'PENDING' ||
    (order.status as string) === 'PLANNED' ||
    order.status === 'DELAYED' ||
    (inProgress && !hasMachine);
  const isQcApproved = order.qc_status === 'PASSED' || order.qc_status === 'WAIVED';

  return (
    <Screen scroll>
      {isViewOnly && (
        <ViewModeBanner
          message="Order viewing mode. Starting production and recording output are disabled."
        />
      )}
      <View style={styles.headerRow}>
        <View style={{ flex: 1 }}>
          <Text style={typography.h2}>{order.order_number}</Text>
          <Text style={styles.headerSubtitle}>
            {order.product_code} • {order.product_name}
          </Text>
        </View>
        <StatusBadge status={order.status} />
      </View>
      {inProgress ? (
        <View style={styles.inProgressBanner}>
          <Text style={styles.inProgressTitle}>Production in progress</Text>
          <Text style={typography.caption}>
            {order.machine_code ? `Machine ${order.machine_code}` : 'Machine assigned'} · Record output
            below as units are made.
          </Text>
        </View>
      ) : null}
      <Card>
        <Text style={typography.body}>{order.product_name}</Text>
        <Text style={typography.bodySmall}>Line {order.line_code}</Text>
        <Text style={typography.label}>
          {formatNumber(order.produced_quantity)} / {formatNumber(order.target_quantity)} (
          {formatPct(progress)})
        </Text>
        <ProgressBar progress={progress} />
      </Card>

      {/* Assigned Resources Card */}
      {(order.assigned_machines?.length || order.assigned_workers?.length || order.machine_id) ? (
        <Card style={styles.resourceCard}>
          <View style={styles.resourceHeader}>
            <Ionicons name="hardware-chip-outline" size={17} color={colors.primary} />
            <Text style={styles.resourceTitle}>Assigned Production Resources</Text>
          </View>
          <View style={styles.resourceSection}>
            <Text style={styles.resourceLabel}>Assigned Machine(s):</Text>
            <View style={styles.tagWrap}>
              {(order.assigned_machines && order.assigned_machines.length > 0
                ? order.assigned_machines
                : order.machine_code
                ? [order.machine_code]
                : ['Assigned']
              ).map((mCode, idx) => (
                <View key={idx} style={styles.machineTag}>
                  <Ionicons name="cube" size={12} color="#1E40AF" />
                  <Text style={styles.machineTagText}>{mCode}</Text>
                </View>
              ))}
            </View>
          </View>
          <View style={[styles.resourceSection, { marginTop: 8 }]}>
            <Text style={styles.resourceLabel}>Assigned Operator(s) / Worker(s):</Text>
            <View style={styles.tagWrap}>
              {(order.assigned_workers && order.assigned_workers.length > 0
                ? order.assigned_workers
                : ['Not assigned yet']
              ).map((wName, idx) => (
                <View key={idx} style={styles.workerTag}>
                  <Ionicons name="person" size={12} color="#065F46" />
                  <Text style={styles.workerTagText}>{wName}</Text>
                </View>
              ))}
            </View>
          </View>
        </Card>
      ) : null}

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
            <View style={{ gap: 8 }}>
              {!isQcApproved && (
                <View style={styles.lockNoticeRow}>
                  <Ionicons name="lock-closed" size={14} color={colors.warning} />
                  <Text style={styles.lockNoticeText}>
                    Production is locked until QC is approved in Quality Assurance.
                  </Text>
                </View>
              )}
              <Button
                label={
                  isQcApproved
                    ? 'Start Production (Assign Machine & Worker)'
                    : 'Start Production (QC Pending)'
                }
                variant={isQcApproved ? 'primary' : 'secondary'}
                onPress={onStart}
              />
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

            <View style={styles.modalActions}>
              <Button label="Cancel" variant="secondary" onPress={() => setShowEditModal(false)} />
              <Button label="Save Changes" onPress={handleSaveEdit} />
            </View>
          </View>
        </View>
      </Modal>

      {/* Start Production & Resource Assignment Modal */}
      <Modal visible={showStartModal} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={[styles.modalContent, { maxHeight: '88%' }]}>
            <View style={styles.modalHeader}>
              <View style={{ flex: 1 }}>
                <Text style={typography.h2}>Start Production</Text>
                <Text style={styles.modalSub}>
                  {order.order_number} · {order.product_name}
                </Text>
              </View>
              <Pressable onPress={() => setShowStartModal(false)}>
                <Ionicons name="close" size={24} color={colors.text} />
              </Pressable>
            </View>

            <ScrollView showsVerticalScrollIndicator={false}>
              {/* Step 1: Machine Assignment */}
              <View style={styles.stepBox}>
                <View style={styles.stepHeaderRow}>
                  <View style={styles.stepNumberBadge}>
                    <Text style={styles.stepNumberText}>1</Text>
                  </View>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.stepTitle}>Assign Machine(s) *</Text>
                    <Text style={styles.stepSubtitle}>
                      Select 1 or more machines for this production run:
                    </Text>
                  </View>
                  <View style={styles.selectedCountBadge}>
                    <Text style={styles.selectedCountText}>
                      {selectedMachineIds.length} selected
                    </Text>
                  </View>
                </View>

                {availableMachines.length === 0 ? (
                  <Text style={styles.emptyNotice}>No machines registered in the factory.</Text>
                ) : (
                  <View style={{ gap: 8, marginTop: 10 }}>
                    {availableMachines.map((m) => {
                      const isSelected = selectedMachineIds.includes(m.id);
                      const isIdle = m.status === 'IDLE';
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
                            size={20}
                            color={isSelected ? colors.primary : '#94A3B8'}
                          />
                          <View style={{ flex: 1 }}>
                            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                              <Text style={styles.resourceCardName}>{m.code}</Text>
                              <Text style={styles.resourceCardSub}>- {m.name}</Text>
                            </View>
                            {m.machine_type ? (
                              <Text style={styles.resourceCardType}>{m.machine_type}</Text>
                            ) : null}
                          </View>
                          <View
                            style={[
                              styles.miniStatusBadge,
                              { backgroundColor: isIdle ? '#DCFCE7' : '#E0F2FE' },
                            ]}
                          >
                            <Text
                              style={[
                                styles.miniStatusText,
                                { color: isIdle ? '#166534' : '#075985' },
                              ]}
                            >
                              {m.status}
                            </Text>
                          </View>
                        </Pressable>
                      );
                    })}
                  </View>
                )}
              </View>

              {/* Step 2: Worker Assignment */}
              <View style={[styles.stepBox, { marginTop: 14 }]}>
                <View style={styles.stepHeaderRow}>
                  <View style={[styles.stepNumberBadge, { backgroundColor: '#0284C7' }]}>
                    <Text style={styles.stepNumberText}>2</Text>
                  </View>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.stepTitle}>Assign Worker(s) to Machine(s) *</Text>
                    <Text style={styles.stepSubtitle}>
                      Assign 1 or more staff members to operate the machine(s):
                    </Text>
                  </View>
                  <View style={[styles.selectedCountBadge, { backgroundColor: '#E0F2FE' }]}>
                    <Text style={[styles.selectedCountText, { color: '#0369A1' }]}>
                      {selectedStaffIds.length} assigned
                    </Text>
                  </View>
                </View>

                {availableStaff.length === 0 ? (
                  <Text style={styles.emptyNotice}>No active staff members found.</Text>
                ) : (
                  <View style={{ gap: 8, marginTop: 10 }}>
                    {availableStaff.map((s) => {
                      const isSelected = selectedStaffIds.includes(s.id);
                      return (
                        <Pressable
                          key={s.id}
                          style={[
                            styles.resourcePickCard,
                            isSelected && styles.resourcePickCardSelected,
                          ]}
                          onPress={() => toggleStaffSelection(s.id)}
                        >
                          <Ionicons
                            name={isSelected ? 'checkbox' : 'square-outline'}
                            size={20}
                            color={isSelected ? colors.primary : '#94A3B8'}
                          />
                          <View style={{ flex: 1 }}>
                            <Text style={styles.resourceCardName}>{s.name}</Text>
                            <Text style={styles.resourceCardSub}>
                              ID: {s.employee_id} · Shift: {s.shift || 'General'}
                            </Text>
                          </View>
                          <View style={styles.roleTag}>
                            <Text style={styles.roleTagText}>{s.role}</Text>
                          </View>
                        </Pressable>
                      );
                    })}
                  </View>
                )}
              </View>

              <View style={styles.summaryBox}>
                <Ionicons name="information-circle" size={16} color="#0284C7" />
                <Text style={styles.summaryText}>
                  Rule: At least 1 machine and 1 worker must be assigned. Selected machines will transition to RUNNING with worker info assigned.
                </Text>
              </View>
            </ScrollView>

            <View style={styles.modalActions}>
              <Button
                label="Cancel"
                variant="secondary"
                onPress={() => setShowStartModal(false)}
                disabled={startingProduction}
              />
              <Button
                label={startingProduction ? 'Starting...' : 'Confirm & Start Production'}
                onPress={handleConfirmStartProduction}
                disabled={startingProduction}
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
  headerSubtitle: {
    fontSize: 13,
    color: colors.textSecondary,
    marginTop: 2,
  },
  inProgressBanner: {
    marginTop: spacing.sm,
    padding: spacing.md,
    borderRadius: 12,
    backgroundColor: colors.infoBg,
    borderWidth: 1,
    borderColor: '#BAE6FD',
    gap: spacing.xs,
  },
  inProgressTitle: {
    ...typography.body,
    fontWeight: '700',
    color: colors.info,
  },
  qcCard: {
    marginTop: spacing.xs,
    padding: spacing.md,
    borderRadius: 16,
    borderWidth: 1,
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
    backgroundColor: '#FFFBEB',
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
    borderRadius: 10,
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
    paddingVertical: 3,
    borderRadius: 20,
    borderWidth: 1,
  },
  qcBadgeText: {
    fontSize: 10,
    fontWeight: '800',
  },
  qcNotesBox: {
    marginTop: 10,
    padding: 8,
    borderRadius: 8,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  qcNotesText: {
    fontSize: 12,
    color: colors.text,
  },
  qcDateText: {
    fontSize: 10,
    color: colors.textMuted,
    marginTop: 4,
  },
  qcActionRow: {
    marginTop: 10,
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  qcVerifiedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    backgroundColor: '#DCFCE7',
    paddingVertical: 6,
    paddingHorizontal: 10,
    borderRadius: 8,
  },
  qcVerifiedText: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.success,
  },
  lockNoticeRow: {
    flexDirection: 'row',
    alignItems: 'center',
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
});

