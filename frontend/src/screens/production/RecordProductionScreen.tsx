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
} from '../../database/repositories/productionOrderRepository';
import { recordProduction } from '../../services/productionService';
import type { MaterialConsumptionLine, ProductionOrderRow } from '../../types/database';
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
  const [orderDropdownOpen, setOrderDropdownOpen] = useState(false);
  const [productId, setProductId] = useState<string | null>(null);
  const [usage, setUsage] = useState<MaterialConsumptionLine[]>([]);

  const currentShiftDef = SHIFT_OPTIONS.find((s) => s.id === shift) || SHIFT_OPTIONS[0];

  useEffect(() => {
    (async () => {
      const orders = await listProductionOrders({ status: 'IN_PROGRESS' });
      setActiveOrders(orders);

      let targetId = route.params?.orderId;
      if (!targetId && route.params?.machineId) {
        const matching = orders.find((o) => o.machine_id === route.params.machineId);
        if (matching) targetId = matching.id;
      }
      if (!targetId && orders.length > 0) {
        targetId = orders[0].id;
      }

      if (targetId) {
        setSelectedOrderId(targetId);
        const o = await getProductionOrderById(targetId);
        if (o) {
          setCurrentOrder(o);
          setProductId(o.product_id);
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
      let targetMachineId = order?.machine_id || route.params?.machineId;
      if (!targetMachineId) {
        Alert.alert(
          'Machine & Worker Required',
          `Order ${order?.order_number || selectedOrderId} has not started production yet. Please open Order Details to assign machine(s) and worker(s) before recording output.`,
          [
            { text: 'Cancel', style: 'cancel' },
            {
              text: 'Open Order Details',
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

      <Text style={typography.label}>Production Shift *</Text>
      <View style={styles.dropdownContainer}>
        <Pressable
          style={[styles.dropdownHeader, shiftDropdownOpen && styles.dropdownHeaderActive]}
          onPress={() => setShiftDropdownOpen((v) => !v)}
        >
          <View style={[styles.shiftIconBox, { backgroundColor: currentShiftDef.bg }]}>
            <Ionicons
              name={currentShiftDef.icon}
              size={18}
              color={currentShiftDef.color}
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
      </View>

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
  dropdownContainer: {
    marginBottom: spacing.xs,
  },
  dropdownHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    borderWidth: 1,
    borderColor: '#CBD5E1',
    borderRadius: 8,
    padding: spacing.md,
    backgroundColor: colors.surface,
  },
  dropdownHeaderActive: {
    borderColor: '#0A1E38',
    borderBottomLeftRadius: 0,
    borderBottomRightRadius: 0,
  },
  shiftIconBox: {
    width: 34,
    height: 34,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  dropdownSelectedText: {
    fontSize: 14,
    fontWeight: '700',
    color: '#0A1E38',
  },
  dropdownHoursText: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 2,
  },
  dropdownMenu: {
    borderWidth: 1,
    borderTopWidth: 0,
    borderColor: '#0A1E38',
    borderBottomLeftRadius: 8,
    borderBottomRightRadius: 8,
    backgroundColor: '#FFFFFF',
    overflow: 'hidden',
  },
  dropdownItem: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  dropdownItemSelected: {
    backgroundColor: '#F8FAFC',
  },
  dropdownItemTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: colors.text,
  },
  dropdownItemTitleSelected: {
    fontWeight: '800',
    color: '#0A1E38',
  },
  dropdownItemHours: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 1,
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
});
