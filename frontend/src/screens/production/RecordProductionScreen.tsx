import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Card } from '../../components/common/Card';
import { Screen } from '../../components/common/Screen';
import { SectionHeader } from '../../components/common/SectionHeader';
import {
  getMaterialConsumptionPreview,
  getProductionOrderById,
  listProductionOrders,
} from '../../api/repositories/productionOrderRepository';
import { listMachines } from '../../api/repositories/machineRepository';
import { recordProduction } from '../../services/productionService';
import type { MachineRow, MaterialConsumptionLine, ProductionOrderRow } from '../../types/database';
import type { ProductionStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';
import { formatNumber } from '../../utils/format';
import { useAuthStore } from '../../store/authStore';

import { ViewModeBanner } from '../../components/common/ViewModeBanner';

type Props = NativeStackScreenProps<ProductionStackParamList, 'RecordProduction'>;

const SHIFT_OPTIONS = [
  { id: 'Morning', label: 'Morning', icon: 'sunny-outline' as const, color: '#D97706', bg: '#FEF3C7' },
  { id: 'Evening', label: 'Evening', icon: 'partly-sunny-outline' as const, color: '#0284C7', bg: '#E0F2FE' },
  { id: 'Night', label: 'Night', icon: 'moon-outline' as const, color: '#7C3AED', bg: '#F3E8FF' },
];

export function RecordProductionScreen({ navigation, route }: Props) {
  const isViewOnly = Boolean(route.params?.viewOnly);
  const user = useAuthStore((s) => s.user);
  const company = useAuthStore((s) => s.company);
  const previewRole = useAuthStore((s) => s.previewRole);
  const previewStaff = useAuthStore((s) => s.previewStaff);

  const recordedBy = useMemo(() => {
    if (previewStaff) {
      return `${previewStaff.name} (${previewStaff.role})`;
    }

    if (previewRole) {
      return `${user?.name || 'Staff'} (${previewRole.name})`;
    }

    if (!user) return 'Staff (OPERATOR)';

    if (user.type === 'COMPANY_ADMIN') {
      const companyName = company?.name || 'Company';
      return `Admin (${companyName})`;
    }

    // Regular staff user: username with role
    return `${user.name} (${user.role})`;
  }, [user, company, previewRole, previewStaff]);

  const activeShift = previewStaff?.shift || user?.shift || 'Morning';

  const [good, setGood] = useState('10');
  const [reject, setReject] = useState('0');
  const [shift, setShift] = useState(
    ['Morning', 'Evening', 'Night'].includes(activeShift) ? activeShift : 'Morning',
  );
  const [shiftDropdownOpen, setShiftDropdownOpen] = useState(false);
  const [selectedOrderId, setSelectedOrderId] = useState<string | null>(route.params?.orderId || null);
  const [currentOrder, setCurrentOrder] = useState<ProductionOrderRow | null>(null);
  const [activeOrders, setActiveOrders] = useState<ProductionOrderRow[]>([]);
  const [machines, setMachines] = useState<MachineRow[]>([]);
  const [selectedMachineId, setSelectedMachineId] = useState<string | null>(route.params?.machineId || null);
  const [orderDropdownOpen, setOrderDropdownOpen] = useState(false);
  const [productId, setProductId] = useState<string | null>(null);
  const [usage, setUsage] = useState<MaterialConsumptionLine[]>([]);

  const currentShiftDef = SHIFT_OPTIONS.find((s) => s.id === shift) || SHIFT_OPTIONS[0];

  useEffect(() => {
    listMachines().then(setMachines).catch(() => []);
  }, []);

  useEffect(() => {
    (async () => {
      const allOrders = await listProductionOrders();
      const inProgress = allOrders.filter((o) => o.status === 'IN_PROGRESS');
      const qcPassed = allOrders.filter((o) => o.status === 'PENDING' && o.qc_status === 'PASSED');
      const selectable = [...inProgress, ...qcPassed];
      setActiveOrders(selectable.length > 0 ? selectable : allOrders);

      let targetId = route.params?.orderId;
      if (!targetId && route.params?.machineId) {
        const matching = selectable.find(
          (o) =>
            o.machine_id === route.params.machineId ||
            (Array.isArray((o as any).assigned_machines) && (o as any).assigned_machines.includes(route.params.machineId!)),
        );
        if (matching) targetId = matching.id;
      }
      if (!targetId && selectable.length > 0) {
        targetId = selectable[0].id;
      }

      if (targetId) {
        setSelectedOrderId(targetId);
        const o = await getProductionOrderById(targetId);
        if (o) {
          setCurrentOrder(o);
          setProductId(o.product_id);
          const orderMachines = Array.isArray(o.assigned_machines) && o.assigned_machines.length > 0
            ? o.assigned_machines.map(String)
            : o.machine_id
            ? [o.machine_id]
            : [];
          if (orderMachines.length > 0 && !selectedMachineId) {
            setSelectedMachineId(orderMachines[0]);
          }
        }
      }
    })();
  }, [route.params?.orderId, route.params?.machineId]);

  const handleSelectOrder = async (orderId: string) => {
    setSelectedOrderId(orderId);
    setOrderDropdownOpen(false);
    const o = await getProductionOrderById(orderId);
    if (o) {
      setCurrentOrder(o);
      setProductId(o.product_id);
      const orderMachines = Array.isArray(o.assigned_machines) && o.assigned_machines.length > 0
        ? o.assigned_machines.map(String)
        : o.machine_id
        ? [o.machine_id]
        : [];
      if (orderMachines.length > 0) {
        setSelectedMachineId(orderMachines[0]);
      }
    }
  };

  const refreshUsage = useCallback(async () => {
    if (!productId) return;
    const units = Number(good) + Number(reject);
    if (!Number.isFinite(units) || units <= 0) {
      setUsage([]);
      return;
    }
    setUsage(await getMaterialConsumptionPreview(productId, units));
  }, [productId, good, reject]);

  useEffect(() => {
    refreshUsage();
  }, [refreshUsage]);

  const submit = async () => {
    if (isViewOnly) {
      Alert.alert('View Only', 'Cannot submit production entry in view-only mode.');
      return;
    }
    if (!selectedOrderId) {
      Alert.alert('Required', 'Please select a production order.');
      return;
    }
    try {
      const order = currentOrder || (await getProductionOrderById(selectedOrderId));
      let targetMachineId =
        selectedMachineId ||
        order?.machine_id ||
        (Array.isArray((order as any)?.assigned_machines) && (order as any)?.assigned_machines.length > 0
          ? (order as any)?.assigned_machines[0]
          : null) ||
        route.params?.machineId;

      if (!targetMachineId) {
        Alert.alert(
          'Machine & Worker Assignment Required',
          `Order ${order?.order_number || selectedOrderId} requires assigned machine(s) and worker(s) before logging output.\n\nPlease open Order Details to assign production resources.`,
          [
            { text: 'Cancel', style: 'cancel' },
            {
              text: 'Assign Resources Now',
              onPress: () => {
                navigation.replace('ProductionOrderDetail', { orderId: selectedOrderId });
              },
            },
          ],
        );
        return;
      }
      await recordProduction({
        orderId: selectedOrderId,
        machineId: targetMachineId,
        shift,
        goodQuantity: Number(good),
        rejectedQuantity: Number(reject),
        operator: recordedBy,
      });
      navigation.goBack();
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Failed');
    }
  };

  const outputUnits = Number(good) + Number(reject);

  return (
    <Screen contentContainerStyle={styles.content}>
      {isViewOnly && (
        <ViewModeBanner
          message="Production recording viewing mode. Submissions are disabled. Use the Management tab to record production."
        />
      )}
      {/* Active Production Order Info Card */}
      {currentOrder ? (
        <Card style={styles.orderBannerCard}>
          <View style={styles.orderBannerHeader}>
            <View style={{ flex: 1 }}>
              <Text style={styles.orderBannerTitle}>{currentOrder.order_number}</Text>
              <Text style={styles.orderBannerSubtitle}>
                Product: <Text style={{ fontWeight: '700' }}>{currentOrder.product_code}</Text>
              </Text>
            </View>
            {activeOrders.length > 1 && (
              <Pressable
                style={styles.switchOrderBtn}
                onPress={() => setOrderDropdownOpen((v) => !v)}
              >
                <Text style={styles.switchOrderBtnText}>Switch Order</Text>
                <Ionicons name="chevron-down" size={14} color="#0284C7" />
              </Pressable>
            )}
          </View>

          {orderDropdownOpen && (
            <View style={styles.orderDropdownList}>
              {activeOrders.map((o) => (
                <Pressable
                  key={o.id}
                  style={[
                    styles.orderDropdownItem,
                    o.id === selectedOrderId && styles.orderDropdownItemActive,
                  ]}
                  onPress={() => handleSelectOrder(o.id)}
                >
                  <Text
                    style={[
                      styles.orderDropdownItemText,
                      o.id === selectedOrderId && styles.orderDropdownItemTextActive,
                    ]}
                  >
                    {o.order_number} · {o.product_code} ({formatNumber(o.produced_quantity)} / {formatNumber(o.target_quantity)})
                  </Text>
                </Pressable>
              ))}
            </View>
          )}

          <View style={styles.orderBannerStats}>
            <Text style={styles.orderBannerStat}>
              Target: <Text style={styles.bold}>{formatNumber(currentOrder.target_quantity)}</Text>
            </Text>
            <Text style={styles.orderBannerStat}>
              Produced: <Text style={styles.bold}>{formatNumber(currentOrder.produced_quantity)}</Text>
            </Text>
          </View>
        </Card>
      ) : (
        <Card style={styles.orderBannerCard}>
          <Text style={styles.orderBannerTitle}>No In-Progress Order</Text>
          <Text style={styles.orderBannerSubtitle}>
            Please select or start a production order to log output.
          </Text>
        </Card>
      )}

      {currentOrder && (Array.isArray(currentOrder.assigned_machines) ? currentOrder.assigned_machines.length > 1 : false) && (
        <View style={{ marginBottom: 12 }}>
          <Text style={typography.label}>Operating Machine</Text>
          <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 6, marginTop: 4 }}>
            {(currentOrder.assigned_machines as string[]).map((mId) => {
              const mObj = machines.find((m) => String(m.id) === String(mId));
              const active = selectedMachineId === mId;
              return (
                <Pressable
                  key={mId}
                  style={[
                    styles.chip,
                    active && styles.chipActive,
                  ]}
                  onPress={() => setSelectedMachineId(mId)}
                >
                  <Text style={[styles.chipText, active && styles.chipTextActive]}>
                    {active ? '✓ ' : ''}{mObj ? `${mObj.code} (${mObj.name})` : `Machine #${mId}`}
                  </Text>
                </Pressable>
              );
            })}
          </View>
        </View>
      )}

      <Text style={typography.label}>Good quantity</Text>
      <TextInput style={styles.input} value={good} onChangeText={setGood} keyboardType="numeric" />
      <Text style={typography.label}>Rejected</Text>
      <TextInput style={styles.input} value={reject} onChangeText={setReject} keyboardType="numeric" />

      <SectionHeader title="Materials for this entry" />
      <Text style={typography.caption}>
        Formula: BOM per unit × output ({Number.isFinite(outputUnits) ? outputUnits : 0} units =
        good + reject). Stock reduces when you submit.
      </Text>
      {usage.length === 0 ? (
        <Card>
          <Text style={typography.bodySmall}>Enter quantities above to see material usage.</Text>
        </Card>
      ) : (
        usage.map((line) => (
          <Card key={line.material_id}>
            <Text style={typography.body}>{line.code}</Text>
            <Text style={typography.caption}>
              {formatNumber(line.per_unit, 3)} {line.unit}/unit → uses{' '}
              <Text style={styles.strong}>
                {formatNumber(line.quantity, 2)} {line.unit}
              </Text>
            </Text>
          </Card>
        ))
      )}

      <Text style={typography.label}>Shift</Text>
      <Pressable style={styles.dropdownTrigger} onPress={() => setShiftDropdownOpen(!shiftDropdownOpen)}>
        <View style={styles.dropdownLeading}>
          <Ionicons
            name={currentShiftDef.icon as any}
            size={18}
            color={currentShiftDef.color}
            style={{ marginRight: 6 }}
          />
        </View>
        <Text style={[styles.dropdownSelectedText, { flex: 1 }]}>{currentShiftDef.label}</Text>
          <Ionicons
            name={shiftDropdownOpen ? 'chevron-up' : 'chevron-down'}
            size={18}
            color="#64748B"
          />
        </Pressable>

        {shiftDropdownOpen && (
          <View style={styles.dropdownMenu}>
            {SHIFT_OPTIONS.map((opt) => {
              const selected = shift === opt.id;
              return (
                <Pressable
                  key={opt.id}
                  style={[styles.dropdownItem, selected && styles.dropdownItemSelected]}
                  onPress={() => {
                    setShift(opt.id);
                    setShiftDropdownOpen(false);
                  }}
                >
                  <View style={[styles.shiftIconBox, { backgroundColor: opt.bg }]}>
                    <Ionicons name={opt.icon} size={16} color={opt.color} />
                  </View>
                  <Text style={[styles.dropdownItemTitle, { flex: 1 }, selected && styles.dropdownItemTitleSelected]}>
                    {opt.label}
                  </Text>
                  {selected && (
                    <Ionicons name="checkmark-circle" size={18} color="#0A1E38" />
                  )}
                </Pressable>
              );
            })}
          </View>
        )}

      <Text style={typography.label}>Recorded By (User & Role)</Text>
      <View style={styles.recorderCard}>
        <View
          style={[
            styles.recorderIconBox,
            user?.type === 'COMPANY_ADMIN' && styles.adminIconBox,
          ]}
        >
          <Ionicons
            name={user?.type === 'COMPANY_ADMIN' ? 'shield-checkmark' : 'person'}
            size={18}
            color={user?.type === 'COMPANY_ADMIN' ? '#0369A1' : '#15803D'}
          />
        </View>
        <View style={{ flex: 1 }}>
          <Text style={styles.recorderTitle}>{recordedBy}</Text>
          <Text style={styles.recorderSubtitle}>
            {user?.type === 'COMPANY_ADMIN'
              ? `Company Administrator · ${company?.name || 'Company'}`
              : `Logged in staff · ID: ${user?.employee_id || 'Active User'}`}
          </Text>
        </View>
        <View style={styles.lockBadge}>
          <Ionicons name="lock-closed" size={12} color="#64748B" />
          <Text style={styles.lockBadgeText}>LOCKED</Text>
        </View>
      </View>

      {!isViewOnly && (
        <Pressable style={styles.btn} onPress={submit}>
          <Text style={styles.btnText}>Submit Production Entry</Text>
        </Pressable>
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  content: { gap: spacing.sm, paddingBottom: spacing.xxl },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.md,
    backgroundColor: colors.surface,
  },
  strong: { fontWeight: '700', color: colors.primary },
  dropdownBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.md,
    backgroundColor: colors.surface,
  },
  dropdownBtnText: {
    fontSize: 14,
    color: colors.text,
  },
  dropdownTrigger: {
    flexDirection: 'row',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.md,
    backgroundColor: colors.surface,
  },
  dropdownLeading: {
    marginRight: 4,
  },
  dropdownSelectedText: {
    fontSize: 14,
    color: colors.text,
  },
  dropdownMenu: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    overflow: 'hidden',
    marginTop: 4,
  },
  dropdownList: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    overflow: 'hidden',
    marginTop: 4,
  },
  dropdownItem: {
    padding: spacing.md,
    flexDirection: 'row',
    alignItems: 'center',
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  dropdownItemActive: {
    backgroundColor: colors.primary + '15',
  },
  dropdownItemSelected: {
    backgroundColor: colors.primary + '15',
  },
  dropdownItemTitle: {
    fontSize: 14,
    color: colors.text,
  },
  dropdownItemTitleSelected: {
    color: colors.primary,
    fontWeight: '700',
  },
  shiftIconBox: {
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 8,
  },
  dropdownItemText: {
    fontSize: 14,
    color: colors.text,
  },
  dropdownItemTextActive: {
    color: colors.primary,
    fontWeight: '700',
  },
  recorderCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#E2E8F0',
    borderRadius: 10,
    padding: spacing.md,
  },
  recorderIconBox: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#DCFCE7',
    alignItems: 'center',
    justifyContent: 'center',
  },
  adminIconBox: {
    backgroundColor: '#E0F2FE',
  },
  recorderTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#0A1E38',
  },
  recorderSubtitle: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 2,
  },
  lockBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#EEF2F6',
    paddingHorizontal: 8,
    paddingVertical: 4,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#CBD5E1',
  },
  lockBadgeText: {
    fontSize: 10,
    fontWeight: '800',
    color: '#64748B',
    letterSpacing: 0.5,
  },
  btn: {
    backgroundColor: colors.primary,
    padding: spacing.md,
    borderRadius: 8,
    marginTop: spacing.md,
  },
  btnText: {
    color: '#fff',
    textAlign: 'center',
    fontWeight: '700',
    fontSize: 15,
  },
  orderBannerCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#BAE6FD',
    padding: 14,
    marginBottom: spacing.md,
    gap: 8,
  },
  orderBannerHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  orderBannerTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: '#0A1E38',
  },
  orderBannerSubtitle: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  switchOrderBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 8,
    backgroundColor: '#E0F2FE',
  },
  switchOrderBtnText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#0284C7',
  },
  orderDropdownList: {
    backgroundColor: '#F8FAFC',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    overflow: 'hidden',
    marginTop: 4,
  },
  orderDropdownItem: {
    paddingVertical: 10,
    paddingHorizontal: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
  },
  orderDropdownItemActive: {
    backgroundColor: '#E0F2FE',
  },
  orderDropdownItemText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#334155',
  },
  orderDropdownItemTextActive: {
    color: '#0284C7',
    fontWeight: '700',
  },
  orderBannerStats: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  orderBannerStat: {
    fontSize: 12,
    color: colors.textSecondary,
  },
  bold: {
    fontWeight: '700',
    color: '#0A1E38',
  },
  chip: {
    paddingHorizontal: 10,
    paddingVertical: 5,
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
