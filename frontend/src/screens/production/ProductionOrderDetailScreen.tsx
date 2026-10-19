import { Ionicons } from '@expo/vector-icons';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
import {
  Alert,
  Modal,
  Pressable,
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
import type { MaterialAvailabilityRow, Priority, ProductionOrderRow } from '../../types/database';
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
      const idleMachines = await listMachines({ status: 'IDLE' });
      const runningMachines = await listMachines({ status: 'RUNNING' });
      const allMachines = await listMachines();
      const machineId =
        order?.machine_id ??
        idleMachines[0]?.id ??
        runningMachines[0]?.id ??
        allMachines[0]?.id;
      if (!machineId) {
        Alert.alert('No machine', 'No machines available. Please create a machine first.');
        return;
      }
      await startProduction(route.params.orderId, machineId);
      await load();
      Alert.alert('Started', 'Production started successfully.');
    } catch (e: unknown) {
      const msg =
        e instanceof ProductionBlockedError
          ? e.message
          : e instanceof Error
            ? e.message
            : 'Failed';
      Alert.alert('Cannot start', msg);
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
                    ? hasMachine
                      ? 'Start production'
                      : 'Assign Machine & Start Production'
                    : 'Start production (QC Pending)'
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
});

