import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useEffect, useMemo, useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen } from '../../components/common/Screen';
import { listLines, listMachines } from '../../api/repositories/machineRepository';
import { createProductionOrder } from '../../api/repositories/productionOrderRepository';
import { listProductionPlans } from '../../api/repositories/productionPlanRepository';
import { listProducts } from '../../api/repositories/productRepository';
import type { MachineRow, Priority, ProductionPlanRow } from '../../types/database';
import type { ProductionStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';
import { formatNumber } from '../../utils/format';

type Props = NativeStackScreenProps<ProductionStackParamList, 'ProductionOrderCreate'>;

const PRIORITIES: Priority[] = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
const PLANS_PER_PAGE = 4;

export function ProductionOrderCreateScreen({ navigation }: Props) {
  const [products, setProducts] = useState<{ id: string; code: string }[]>([]);
  const [lines, setLines] = useState<{ id: string; code: string }[]>([]);
  const [machines, setMachines] = useState<MachineRow[]>([]);
  const [plans, setPlans] = useState<ProductionPlanRow[]>([]);
  const [productId, setProductId] = useState('');
  const [lineId, setLineId] = useState('');
  const [selectedMachineIds, setSelectedMachineIds] = useState<string[]>([]);
  const [planId, setPlanId] = useState<string | null>(null);
  const [priority, setPriority] = useState<Priority>('MEDIUM');
  const [target, setTarget] = useState('100');
  const [orderNumber, setOrderNumber] = useState(() => `ORD-${Date.now().toString().slice(-6)}`);

  // Plan pagination and search state
  const [planSearch, setPlanSearch] = useState('');
  const [planPage, setPlanPage] = useState(1);

  useEffect(() => {
    listProducts().then((p) => {
      setProducts(p);
      if (p[0]) setProductId(p[0].id);
    });
    listLines().then((l) => {
      setLines(l);
      if (l[0]) setLineId(l[0].id);
    });
    listMachines().then((m) => {
      setMachines(m);
    }).catch(() => {});
    listProductionPlans().then((pl) => {
      setPlans(pl);
    });
  }, []);

  const filteredPlans = useMemo(() => {
    if (!planSearch.trim()) return plans;
    const q = planSearch.trim().toLowerCase();
    return plans.filter(
      (p) =>
        p.plan_number.toLowerCase().includes(q) ||
        p.product_code?.toLowerCase().includes(q) ||
        p.product_name?.toLowerCase().includes(q) ||
        p.line_code?.toLowerCase().includes(q)
    );
  }, [plans, planSearch]);

  const totalPlanPages = Math.max(1, Math.ceil(filteredPlans.length / PLANS_PER_PAGE));
  const currentPage = Math.min(planPage, totalPlanPages);

  const paginatedPlans = useMemo(() => {
    const start = (currentPage - 1) * PLANS_PER_PAGE;
    return filteredPlans.slice(start, start + PLANS_PER_PAGE);
  }, [filteredPlans, currentPage]);

  const selectedPlan = useMemo(
    () => plans.find((p) => p.id === planId) ?? null,
    [plans, planId]
  );

  const handleSelectPlan = (pl: ProductionPlanRow | null) => {
    if (!pl) {
      setPlanId(null);
      return;
    }
    if (planId === pl.id) {
      setPlanId(null);
      return;
    }
    setPlanId(pl.id);
    // Auto-fill product, line, target, and priority from selected plan
    if (pl.product_id) setProductId(pl.product_id);
    if (pl.line_id) setLineId(pl.line_id);
    if (pl.target_quantity) setTarget(String(pl.target_quantity));
    if (pl.priority) setPriority(pl.priority);
  };

  const submit = async () => {
    try {
      const qty = Number(target);
      if (!Number.isFinite(qty) || qty <= 0) {
        Alert.alert('Error', 'Enter a valid target quantity');
        return;
      }
      if (!productId || !lineId) {
        Alert.alert('Error', 'Select product and line');
        return;
      }
      const id = await createProductionOrder({
        order_number: orderNumber.trim(),
        product_id: productId,
        line_id: lineId,
        machine_id: selectedMachineIds[0] || null,
        assigned_machines: selectedMachineIds,
        target_quantity: qty,
        priority,
        plan_id: planId,
      });
      navigation.replace('ProductionOrderDetail', { orderId: id });
    } catch (e: unknown) {
      Alert.alert('Error', e instanceof Error ? e.message : 'Failed');
    }
  };

  return (
    <Screen contentContainerStyle={styles.container}>
      <Text style={typography.label}>Order number</Text>
      <TextInput style={styles.input} value={orderNumber} onChangeText={setOrderNumber} />

      <Text style={typography.label}>Product</Text>
      <View style={styles.chips}>
        {products.map((p) => (
          <Pressable
            key={p.id}
            style={[styles.chip, productId === p.id && styles.chipActive]}
            onPress={() => setProductId(p.id)}
          >
            <Text style={productId === p.id ? styles.chipTextActive : undefined}>{p.code}</Text>
          </Pressable>
        ))}
      </View>

      <Text style={typography.label}>Line</Text>
      <View style={styles.chips}>
        {lines.map((l) => (
          <Pressable
            key={l.id}
            style={[styles.chip, lineId === l.id && styles.chipActive]}
            onPress={() => setLineId(l.id)}
          >
            <Text style={lineId === l.id ? styles.chipTextActive : undefined}>{l.code}</Text>
          </Pressable>
        ))}
      </View>

      <Text style={typography.label}>
        Assigned Machines ({selectedMachineIds.length} selected - Optional)
      </Text>
      <View style={styles.chips}>
        {machines
          .filter((m) => !lineId || m.line_id === lineId)
          .map((m) => {
            const active = selectedMachineIds.includes(m.id);
            return (
              <Pressable
                key={m.id}
                style={[styles.chip, active && styles.chipActive]}
                onPress={() => {
                  setSelectedMachineIds((prev) =>
                    prev.includes(m.id) ? prev.filter((id) => id !== m.id) : [...prev, m.id],
                  );
                }}
              >
                <Text style={active ? styles.chipTextActive : undefined}>
                  {active ? '✓ ' : ''}{m.code} ({m.name})
                </Text>
              </Pressable>
            );
          })}
        {machines.filter((m) => !lineId || m.line_id === lineId).length === 0 && (
          <Text style={{ fontSize: 12, color: colors.textMuted, fontStyle: 'italic', marginVertical: 4 }}>
            No machines registered for this line. You can assign machines later.
          </Text>
        )}
      </View>

      <Text style={typography.label}>Target quantity</Text>
      <TextInput
        style={styles.input}
        value={target}
        onChangeText={setTarget}
        keyboardType="numeric"
      />

      <Text style={typography.label}>Priority</Text>
      <View style={styles.chips}>
        {PRIORITIES.map((p) => (
          <Pressable
            key={p}
            style={[styles.chip, priority === p && styles.chipActive]}
            onPress={() => setPriority(p)}
          >
            <Text style={priority === p ? styles.chipTextActive : undefined}>{p}</Text>
          </Pressable>
        ))}
      </View>

      <Text style={typography.label}>Production Plan (Optional)</Text>
      {plans.length > 0 && (
        <TextInput
          style={styles.input}
          placeholder="Search plan number, product, or line..."
          value={planSearch}
          onChangeText={(t) => {
            setPlanSearch(t);
            setPlanPage(1);
          }}
        />
      )}
      <View style={styles.chips}>
        <Pressable
          style={[styles.chip, !planId && styles.chipActive]}
          onPress={() => handleSelectPlan(null)}
        >
          <Text style={!planId ? styles.chipTextActive : undefined}>None</Text>
        </Pressable>
        {paginatedPlans.map((pl) => (
          <Pressable
            key={pl.id}
            style={[styles.chip, planId === pl.id && styles.chipActive]}
            onPress={() => handleSelectPlan(pl)}
          >
            <Text style={planId === pl.id ? styles.chipTextActive : undefined}>
              {pl.plan_number}
            </Text>
          </Pressable>
        ))}
      </View>
      {totalPlanPages > 1 && (
        <View style={styles.paginationRow}>
          <Pressable
            disabled={currentPage <= 1}
            onPress={() => setPlanPage((p) => Math.max(1, p - 1))}
            style={[styles.pageBtn, currentPage <= 1 && styles.pageBtnDisabled]}
          >
            <Ionicons name="chevron-back" size={16} color={currentPage <= 1 ? colors.textMuted : colors.primary} />
          </Pressable>
          <Text style={typography.caption}>
            Page {currentPage} of {totalPlanPages}
          </Text>
          <Pressable
            disabled={currentPage >= totalPlanPages}
            onPress={() => setPlanPage((p) => Math.min(totalPlanPages, p + 1))}
            style={[styles.pageBtn, currentPage >= totalPlanPages && styles.pageBtnDisabled]}
          >
            <Ionicons name="chevron-forward" size={16} color={currentPage >= totalPlanPages ? colors.textMuted : colors.primary} />
          </Pressable>
        </View>
      )}

      {selectedPlan && (
        <View style={styles.selectedPlanBox}>
          <Text style={styles.selectedPlanTitle}>Plan: {selectedPlan.plan_number}</Text>
          <Text style={styles.selectedPlanMeta}>
            Product: {selectedPlan.product_code ?? selectedPlan.product_name ?? '—'}
          </Text>
          <Text style={styles.selectedPlanMeta}>
            Line: {selectedPlan.line_code ?? '—'} | Qty: {formatNumber(selectedPlan.target_quantity)}
          </Text>
        </View>
      )}

      <Pressable style={styles.btn} onPress={submit}>
        <Text style={styles.btnText}>Create Order</Text>
      </Pressable>
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: { gap: spacing.sm, paddingBottom: spacing.xxl },
  input: {
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    padding: spacing.md,
    backgroundColor: colors.surface,
  },
  chips: { flexDirection: 'row', flexWrap: 'wrap', gap: spacing.xs },
  chip: {
    paddingHorizontal: spacing.sm,
    paddingVertical: 6,
    borderRadius: 8,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
  },
  chipActive: { backgroundColor: colors.primary, borderColor: colors.primary },
  chipTextActive: { color: '#fff', fontWeight: '600' },
  paginationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing.md,
    marginVertical: spacing.xs,
  },
  pageBtn: {
    padding: 6,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surface,
  },
  pageBtnDisabled: {
    opacity: 0.4,
  },
  selectedPlanBox: {
    padding: spacing.md,
    borderRadius: 8,
    backgroundColor: '#EFF6FF',
    borderWidth: 1,
    borderColor: colors.primary,
    gap: 4,
    marginTop: spacing.xs,
  },
  selectedPlanTitle: {
    fontWeight: '700',
    color: colors.primary,
    fontSize: 14,
  },
  selectedPlanMeta: {
    fontSize: 12,
    color: colors.textSecondary,
  },
  btn: {
    backgroundColor: colors.primary,
    padding: spacing.md,
    borderRadius: 8,
    marginTop: spacing.md,
  },
  btnText: { color: '#fff', textAlign: 'center', fontWeight: '600' },
});
