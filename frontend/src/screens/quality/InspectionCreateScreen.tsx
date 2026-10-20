import { Ionicons } from '@expo/vector-icons';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  Alert,
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
import { ViewModeBanner } from '../../components/common/ViewModeBanner';
import {
  getProductionOrderById,
  listProductionOrders,
} from '../../database/repositories/productionOrderRepository';
import { listOrdersWaitingForQc } from '../../database/repositories/qualityRepository';
import { updatePreProductionQc } from '../../services/productionService';
import { useAuthStore } from '../../store/authStore';
import { colors, spacing } from '../../theme';
import type { ProductionOrderRow } from '../../types/database';
import { formatNumber } from '../../utils/format';

type Props = NativeStackScreenProps<any, 'InspectionCreate'>;

export function InspectionCreateScreen({ navigation, route }: Props) {
  const isViewOnly = Boolean(route.params?.viewOnly);
  const user = useAuthStore((s) => s.user);
  const previewStaff = useAuthStore((s) => s.previewStaff);
  const previewRole = useAuthStore((s) => s.previewRole);

  const defaultInspector = useMemo(() => {
    if (previewStaff) return `${previewStaff.name} (QA Inspector)`;
    if (previewRole) return `${user?.name || 'QA Lead'} (${previewRole.name})`;
    if (user?.name) return `${user.name} (QA Inspector)`;
    return 'Quality Inspector';
  }, [user, previewStaff, previewRole]);

  const [submitting, setSubmitting] = useState(false);
  const [pendingOrders, setPendingOrders] = useState<ProductionOrderRow[]>([]);
  const [allOrders, setAllOrders] = useState<ProductionOrderRow[]>([]);
  const [filterMode, setFilterMode] = useState<'waiting' | 'all'>('waiting');
  const [searchOrderQuery, setSearchOrderQuery] = useState('');
  const [selectedOrderId, setSelectedOrderId] = useState<string>(route.params?.orderId ?? '');
  const [selectedOrder, setSelectedOrder] = useState<ProductionOrderRow | null>(null);

  // Inspector and checklist
  const [inspector, setInspector] = useState(defaultInspector);
  const [notes, setNotes] = useState('');

  // Verification Checklist Items
  const [rawMaterialVerified, setRawMaterialVerified] = useState(true);
  const [toolingChecked, setToolingChecked] = useState(true);
  const [firstPieceApproved, setFirstPieceApproved] = useState(true);
  const [machineParametersSet, setMachineParametersSet] = useState(true);
  const [safetyGuardsActive, setSafetyGuardsActive] = useState(true);

  const paramOrderId = route.params?.orderId;

  const loadOrders = useCallback(async () => {
    try {
      const [waiting, all] = await Promise.all([
        listOrdersWaitingForQc().catch(() => []),
        listProductionOrders().catch(() => []),
      ]);
      setAllOrders(all);
      setPendingOrders(waiting);

      // Determine initial selection:
      // 1. If paramOrderId is passed, use it
      // 2. Otherwise pick first waiting order
      // 3. If no waiting orders, fallback to first active order
      const activeAll = all.filter((o) => o.status !== 'CANCELLED');
      const targetId =
        paramOrderId ||
        waiting[0]?.id ||
        (waiting[0] as any)?._id ||
        activeAll[0]?.id ||
        (activeAll[0] as any)?._id ||
        '';

      setSelectedOrderId(targetId);

      if (targetId) {
        const order = await getProductionOrderById(targetId);
        setSelectedOrder(order);
      } else {
        setSelectedOrder(null);
      }
    } catch (e) {
      console.warn('loadOrders error:', e);
    }
  }, [paramOrderId]);

  useEffect(() => {
    loadOrders();
  }, [loadOrders]);

  const handleSelectOrder = async (orderId: string) => {
    setSelectedOrderId(orderId);
    const order = await getProductionOrderById(orderId);
    setSelectedOrder(order);
  };

  const displayedOrders = useMemo(() => {
    let source =
      filterMode === 'waiting'
        ? pendingOrders
        : allOrders.filter((o) => o.status !== 'CANCELLED');
    if (searchOrderQuery.trim()) {
      const q = searchOrderQuery.trim().toLowerCase();
      source = source.filter(
        (o) =>
          o.order_number?.toLowerCase().includes(q) ||
          o.product_name?.toLowerCase().includes(q) ||
          o.product_code?.toLowerCase().includes(q)
      );
    }
    return source;
  }, [filterMode, pendingOrders, allOrders, searchOrderQuery]);

  const handleApproveInspection = async () => {
    if (isViewOnly) {
      Alert.alert('View Only', 'Cannot approve quality inspections in view-only mode.');
      return;
    }
    if (!selectedOrder) {
      Alert.alert('Required', 'Please select an order waiting for quality check.');
      return;
    }

    try {
      setSubmitting(true);
      await updatePreProductionQc({
        orderId: selectedOrder.id,
        qcStatus: 'PASSED',
        inspector: inspector.trim() || 'Quality Inspector',
        notes,
        parameters: {
          rawMaterialVerified,
          toolingChecked,
          firstPieceApproved,
          machineParametersSet,
          safetyGuardsActive,
        },
      });

      Alert.alert(
        'Quality Check Approved',
        `Order ${selectedOrder.order_number} has passed Quality Check.\n\nProduction is now unlocked. You can assign machine(s) and worker(s) when starting production from the order screen.`,
        [
          {
            text: 'View Order',
            onPress: () => {
              navigation.replace('ProductionOrderDetail', { orderId: selectedOrder.id });
            },
          },
          {
            text: 'Done',
            onPress: () => navigation.goBack(),
            style: 'cancel',
          },
        ],
      );
    } catch (e: unknown) {
      Alert.alert('Approval Error', e instanceof Error ? e.message : 'Failed to approve QC');
    } finally {
      setSubmitting(false);
    }
  };

  const handleRejectInspection = async () => {
    if (isViewOnly) {
      Alert.alert('View Only', 'Cannot reject quality inspections in view-only mode.');
      return;
    }
    if (!selectedOrder) return;

    Alert.alert(
      'Hold Order (QC Failed)',
      `Are you sure you want to reject the quality check for order ${selectedOrder.order_number}? Production will remain locked.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Confirm Reject',
          style: 'destructive',
          onPress: async () => {
            try {
              setSubmitting(true);
              await updatePreProductionQc({
                orderId: selectedOrder.id,
                qcStatus: 'FAILED',
                inspector: inspector.trim() || 'Quality Inspector',
                notes: notes.trim() || 'Pre-production quality check rejected by QA',
                parameters: {
                  rawMaterialVerified,
                  toolingChecked,
                  firstPieceApproved,
                  machineParametersSet,
                  safetyGuardsActive,
                },
              });
              Alert.alert('Order On Hold', 'Pre-production check recorded as FAILED. Production is locked.');
              navigation.goBack();
            } catch (e: unknown) {
              Alert.alert('Error', e instanceof Error ? e.message : 'Failed to update QC');
            } finally {
              setSubmitting(false);
            }
          },
        },
      ],
    );
  };

  return (
    <Screen scroll>
      {isViewOnly && (
        <ViewModeBanner message="Quality Assurance view mode. Inspecting and approving orders is disabled here. Use Management tab to record quality inspections." />
      )}

      {/* Header Banner */}
      <View style={styles.headerBox}>
        <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
          <View style={styles.headerIconBox}>
            <Ionicons name="shield-checkmark" size={20} color={colors.primary} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={styles.headerTitle}>Pre-Production Quality Check</Text>
            <Text style={styles.headerSubtitle}>
              Inspect and approve pending work orders before production starts
            </Text>
          </View>
        </View>
      </View>

      {/* 1. Order Selector Carousel */}
      <View style={styles.sectionHeader}>
        <View style={{ flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 4 }}>
          <Text style={styles.sectionTitle}>
            {filterMode === 'waiting'
              ? `Orders Waiting QC (${pendingOrders.length})`
              : `All Orders (${allOrders.length})`}
          </Text>
          <View style={{ flexDirection: 'row', gap: 6 }}>
            <Pressable
              onPress={() => setFilterMode('waiting')}
              style={[styles.modePill, filterMode === 'waiting' && styles.modePillActive]}
            >
              <Text style={[styles.modePillText, filterMode === 'waiting' && styles.modePillTextActive]}>
                Waiting QC
              </Text>
            </Pressable>
            <Pressable
              onPress={() => setFilterMode('all')}
              style={[styles.modePill, filterMode === 'all' && styles.modePillActive]}
            >
              <Text style={[styles.modePillText, filterMode === 'all' && styles.modePillTextActive]}>
                All Orders
              </Text>
            </Pressable>
          </View>
        </View>
        <Text style={styles.sectionHint}>Select an order to inspect</Text>
      </View>

      {/* Search Input */}
      {(allOrders.length > 2 || pendingOrders.length > 2) && (
        <View style={styles.searchBox}>
          <Ionicons name="search" size={15} color={colors.textMuted} />
          <TextInput
            placeholder="Search order number or product..."
            value={searchOrderQuery}
            onChangeText={setSearchOrderQuery}
            style={styles.searchInput}
            placeholderTextColor={colors.textMuted}
          />
          {searchOrderQuery ? (
            <Pressable onPress={() => setSearchOrderQuery('')}>
              <Ionicons name="close-circle" size={15} color={colors.textMuted} />
            </Pressable>
          ) : null}
        </View>
      )}

      {displayedOrders.length === 0 ? (
        <Card style={styles.emptyCard}>
          <Ionicons name="checkmark-done-circle-outline" size={36} color={colors.success} />
          <Text style={styles.emptyCardTitle}>No Orders Found</Text>
          <Text style={styles.emptyCardSubtitle}>
            {filterMode === 'waiting'
              ? 'No orders are currently waiting for pre-production quality check.'
              : 'No matching production orders found.'}
          </Text>
          {filterMode === 'waiting' && allOrders.length > 0 && (
            <Button
              label="Switch to All Orders"
              variant="secondary"
              onPress={() => setFilterMode('all')}
              style={{ marginTop: 10 }}
            />
          )}
        </Card>
      ) : (
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.orderCarousel}
        >
          {displayedOrders.map((o) => {
            const isSelected = (o.id || (o as any)._id) === selectedOrderId;
            const orderKey = o.id || (o as any)._id;
            return (
              <Pressable
                key={orderKey}
                style={[styles.orderChip, isSelected && styles.orderChipSelected]}
                onPress={() => handleSelectOrder(orderKey)}
              >
                <View style={styles.orderChipTop}>
                  <Text style={[styles.orderChipNum, isSelected && styles.orderChipNumSelected]}>
                    {o.order_number}
                  </Text>
                  <View
                    style={[
                      styles.priorityPill,
                      {
                        backgroundColor:
                          o.priority === 'CRITICAL' || o.priority === 'HIGH'
                            ? colors.dangerBg
                            : '#F1F5F9',
                      },
                    ]}
                  >
                    <Text
                      style={[
                        styles.priorityPillText,
                        {
                          color:
                            o.priority === 'CRITICAL' || o.priority === 'HIGH'
                              ? colors.danger
                              : colors.textSecondary,
                        },
                      ]}
                    >
                      {o.priority}
                    </Text>
                  </View>
                </View>
                <Text
                  style={[styles.orderChipProduct, isSelected && styles.orderChipProductSelected]}
                  numberOfLines={1}
                >
                  {o.product_name || o.product_code || 'Product'}
                </Text>
                <Text style={styles.orderChipMeta}>
                  Qty: {formatNumber(o.target_quantity)} pcs • {o.line_code || 'Line'}
                </Text>
              </Pressable>
            );
          })}
        </ScrollView>
      )}

      {/* 2. Selected Order Detail Card */}
      {selectedOrder && (
        <Card style={styles.orderDetailCard}>
          <View style={styles.orderDetailHeader}>
            <View style={{ flex: 1 }}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                <Text style={styles.orderDetailTitle}>{selectedOrder.order_number}</Text>
                <View style={styles.lockBadge}>
                  <Ionicons name="lock-closed" size={11} color={colors.warning} />
                  <Text style={styles.lockBadgeText}>PRODUCTION LOCKED</Text>
                </View>
              </View>
              <Text style={styles.orderDetailProduct}>
                {selectedOrder.product_name ?? selectedOrder.product_code}
              </Text>
              <Text style={styles.orderDetailSub}>
                Code: {selectedOrder.product_code} • Priority: {selectedOrder.priority}
              </Text>
            </View>
          </View>

          <View style={styles.orderMetricsRow}>
            <View style={styles.metricItem}>
              <Text style={styles.metricLabel}>Target Qty</Text>
              <Text style={styles.metricValue}>{formatNumber(selectedOrder.target_quantity)} pcs</Text>
            </View>
            <View style={styles.metricDivider} />
            <View style={styles.metricItem}>
              <Text style={styles.metricLabel}>Production Line</Text>
              <Text style={styles.metricValue}>{selectedOrder.line_code || 'Assigned'}</Text>
            </View>
            <View style={styles.metricDivider} />
            <View style={styles.metricItem}>
              <Text style={styles.metricLabel}>Machine</Text>
              <Text style={styles.metricValue}>{selectedOrder.machine_code || 'Auto-assign'}</Text>
            </View>
          </View>
        </Card>
      )}

      {/* 3. Pre-Production Quality Checklist */}
      {selectedOrder && (
        <Card style={styles.formCard}>
          <View style={styles.formSectionHeader}>
            <Ionicons name="checkbox-outline" size={18} color="#0A1E38" />
            <Text style={styles.formSectionTitle}>Pre-Production Inspection Checklist</Text>
          </View>
          <Text style={styles.checklistDesc}>
            Verify all offline parameters before approving production clearance.
          </Text>

          {/* Checklist items */}
          <Pressable
            style={styles.checkItem}
            onPress={() => setRawMaterialVerified((v) => !v)}
          >
            <Ionicons
              name={rawMaterialVerified ? 'checkbox' : 'square-outline'}
              size={22}
              color={rawMaterialVerified ? colors.primary : '#94A3B8'}
            />
            <View style={{ flex: 1 }}>
              <Text style={styles.checkItemTitle}>Raw Material Batch Verified</Text>
              <Text style={styles.checkItemSub}>
                Specifications, lot certificates, and raw inputs are within tolerance.
              </Text>
            </View>
          </Pressable>

          <Pressable
            style={styles.checkItem}
            onPress={() => setToolingChecked((v) => !v)}
          >
            <Ionicons
              name={toolingChecked ? 'checkbox' : 'square-outline'}
              size={22}
              color={toolingChecked ? colors.primary : '#94A3B8'}
            />
            <View style={{ flex: 1 }}>
              <Text style={styles.checkItemTitle}>Tooling & Machine Calibration Checked</Text>
              <Text style={styles.checkItemSub}>
                Dies, molds, cutter alignment, and speeds verified on machine.
              </Text>
            </View>
          </Pressable>

          <Pressable
            style={styles.checkItem}
            onPress={() => setFirstPieceApproved((v) => !v)}
          >
            <Ionicons
              name={firstPieceApproved ? 'checkbox' : 'square-outline'}
              size={22}
              color={firstPieceApproved ? colors.primary : '#94A3B8'}
            />
            <View style={{ flex: 1 }}>
              <Text style={styles.checkItemTitle}>First-Piece Sample Approved</Text>
              <Text style={styles.checkItemSub}>
                Initial trial unit inspected and verified against technical drawing.
              </Text>
            </View>
          </Pressable>

          <Pressable
            style={styles.checkItem}
            onPress={() => setMachineParametersSet((v) => !v)}
          >
            <Ionicons
              name={machineParametersSet ? 'checkbox' : 'square-outline'}
              size={22}
              color={machineParametersSet ? colors.primary : '#94A3B8'}
            />
            <View style={{ flex: 1 }}>
              <Text style={styles.checkItemTitle}>Process Temperatures & Tolerances Set</Text>
              <Text style={styles.checkItemSub}>
                Temperature, feed rate, and pressure settings meet SOP.
              </Text>
            </View>
          </Pressable>

          <Pressable
            style={styles.checkItem}
            onPress={() => setSafetyGuardsActive((v) => !v)}
          >
            <Ionicons
              name={safetyGuardsActive ? 'checkbox' : 'square-outline'}
              size={22}
              color={safetyGuardsActive ? colors.primary : '#94A3B8'}
            />
            <View style={{ flex: 1 }}>
              <Text style={styles.checkItemTitle}>Safety Guards & Environment Clear</Text>
              <Text style={styles.checkItemSub}>
                Operator safety interlocks and workplace hygiene checked.
              </Text>
            </View>
          </Pressable>

          {/* Inspector Input */}
          <View style={styles.inputGroup}>
            <Text style={styles.inputLabel}>Quality Inspector *</Text>
            <TextInput
              style={styles.input}
              value={inspector}
              onChangeText={setInspector}
              placeholder="e.g. Ramesh Verma (QA Inspector)"
              placeholderTextColor="#94A3B8"
            />
          </View>

          {/* Notes */}
          <View style={styles.inputGroup}>
            <Text style={styles.inputLabel}>Inspection Remarks / Notes (Optional)</Text>
            <TextInput
              style={[styles.input, { height: 68, textAlignVertical: 'top' }]}
              value={notes}
              onChangeText={setNotes}
              placeholder="e.g. Offline gauge measurements in spec. Ready for shift run."
              placeholderTextColor="#94A3B8"
              multiline
            />
          </View>

          {/* Action Buttons: QC Approval or Rejection Only */}
          {!isViewOnly && (
            <View style={styles.actionsBox}>
              <Pressable
                style={[styles.approveBtn, submitting && { opacity: 0.7 }]}
                onPress={handleApproveInspection}
                disabled={submitting}
              >
                <Ionicons name="checkmark-circle" size={18} color="#FFFFFF" />
                <Text style={styles.approveBtnText}>
                  {submitting ? 'Approving...' : 'Approve Quality Check'}
                </Text>
              </Pressable>

              <Pressable
                style={[styles.rejectBtn, submitting && { opacity: 0.7 }]}
                onPress={handleRejectInspection}
                disabled={submitting}
              >
                <Ionicons name="close-circle-outline" size={16} color={colors.danger} />
                <Text style={styles.rejectBtnText}>Reject (Hold Order)</Text>
              </Pressable>
            </View>
          )}
        </Card>
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  headerBox: {
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    padding: 14,
    marginBottom: spacing.md,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 3,
    elevation: 2,
  },
  headerIconBox: {
    width: 38,
    height: 38,
    borderRadius: 10,
    backgroundColor: '#EFF6FF',
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: '#BFDBFE',
  },
  headerTitle: {
    fontSize: 15,
    fontWeight: '800',
    color: colors.text,
  },
  headerSubtitle: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  sectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  sectionTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: colors.text,
  },
  sectionHint: {
    fontSize: 11.5,
    color: colors.textMuted,
  },
  modePill: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
    backgroundColor: '#F1F5F9',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  modePillActive: {
    backgroundColor: colors.primary,
    borderColor: colors.primary,
  },
  modePillText: {
    fontSize: 11,
    fontWeight: '700',
    color: colors.textSecondary,
  },
  modePillTextActive: {
    color: '#FFFFFF',
  },
  searchBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#CBD5E1',
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 6,
    gap: 8,
    marginBottom: spacing.sm,
  },
  searchInput: {
    flex: 1,
    fontSize: 12.5,
    color: colors.text,
    padding: 0,
  },
  orderCarousel: {
    gap: 10,
    paddingBottom: 4,
    marginBottom: spacing.md,
  },
  orderChip: {
    width: 200,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 12,
    borderWidth: 1.5,
    borderColor: '#E2E8F0',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 3,
    elevation: 2,
  },
  orderChipSelected: {
    borderColor: colors.primary,
    backgroundColor: '#F0F9FF',
  },
  orderChipTop: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  orderChipNum: {
    fontSize: 13,
    fontWeight: '800',
    color: colors.text,
  },
  orderChipNumSelected: {
    color: colors.primary,
  },
  priorityPill: {
    paddingHorizontal: 5,
    paddingVertical: 1.5,
    borderRadius: 4,
  },
  priorityPillText: {
    fontSize: 9.5,
    fontWeight: '800',
  },
  orderChipProduct: {
    fontSize: 12,
    fontWeight: '600',
    color: colors.text,
    marginBottom: 4,
  },
  orderChipProductSelected: {
    color: '#0A1E38',
  },
  orderChipMeta: {
    fontSize: 10.5,
    color: colors.textSecondary,
  },
  emptyCard: {
    alignItems: 'center',
    padding: 24,
    borderRadius: 14,
    marginBottom: spacing.md,
    backgroundColor: '#F8FAFC',
  },
  emptyCardTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: colors.text,
    marginTop: 8,
  },
  emptyCardSubtitle: {
    fontSize: 12,
    color: colors.textSecondary,
    textAlign: 'center',
    marginTop: 4,
  },
  orderDetailCard: {
    borderRadius: 14,
    padding: 14,
    marginBottom: spacing.md,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  orderDetailHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  orderDetailTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: colors.text,
  },
  lockBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#FFFBEB',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#FDE68A',
  },
  lockBadgeText: {
    fontSize: 9.5,
    fontWeight: '800',
    color: colors.warning,
    letterSpacing: 0.3,
  },
  orderDetailProduct: {
    fontSize: 13.5,
    fontWeight: '700',
    color: colors.text,
    marginTop: 3,
  },
  orderDetailSub: {
    fontSize: 11.5,
    color: colors.textSecondary,
    marginTop: 2,
  },
  orderMetricsRow: {
    flexDirection: 'row',
    backgroundColor: '#F8FAFC',
    borderRadius: 10,
    padding: 10,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  metricItem: {
    flex: 1,
    alignItems: 'center',
  },
  metricLabel: {
    fontSize: 10,
    color: colors.textMuted,
    fontWeight: '600',
  },
  metricValue: {
    fontSize: 12.5,
    fontWeight: '800',
    color: colors.text,
    marginTop: 2,
  },
  metricDivider: {
    width: 1,
    height: '100%',
    backgroundColor: '#E2E8F0',
  },
  formCard: {
    borderRadius: 14,
    padding: 16,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    marginBottom: spacing.xl,
  },
  formSectionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    marginBottom: 4,
  },
  formSectionTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: colors.text,
  },
  checklistDesc: {
    fontSize: 11.5,
    color: colors.textSecondary,
    marginBottom: 14,
  },
  checkItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 10,
    backgroundColor: '#F8FAFC',
    borderRadius: 10,
    padding: 10,
    marginBottom: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  checkItemTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.text,
  },
  checkItemSub: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 2,
    lineHeight: 15,
  },
  inputGroup: {
    marginTop: 12,
  },
  inputLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: colors.text,
    marginBottom: 6,
  },
  input: {
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#CBD5E1',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 13,
    color: colors.text,
  },
  switchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: '#EFF6FF',
    padding: 12,
    borderRadius: 10,
    marginTop: 16,
    borderWidth: 1,
    borderColor: '#BFDBFE',
  },
  switchTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.primary,
  },
  switchSub: {
    fontSize: 11,
    color: '#1E40AF',
    marginTop: 2,
  },
  actionsBox: {
    marginTop: 18,
    gap: 10,
  },
  approveBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    backgroundColor: '#16A34A',
    borderRadius: 10,
    paddingVertical: 13,
    shadowColor: '#16A34A',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 3,
  },
  approveBtnText: {
    fontSize: 14,
    fontWeight: '800',
    color: '#FFFFFF',
  },
  rejectBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    backgroundColor: '#FEF2F2',
    borderRadius: 10,
    paddingVertical: 11,
    borderWidth: 1,
    borderColor: '#FECACA',
  },
  rejectBtnText: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.danger,
  },
});
