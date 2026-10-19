import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useEffect, useMemo, useState } from 'react';
import { Alert, Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Screen } from '../../components/common/Screen';
import { listLines } from '../../database/repositories/machineRepository';
import { createProductionOrder } from '../../database/repositories/productionOrderRepository';
import { listProductionPlans } from '../../database/repositories/productionPlanRepository';
import { listProducts } from '../../database/repositories/productRepository';
import type { Priority, ProductionPlanRow } from '../../types/database';
import type { ProductionStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';
import { formatNumber } from '../../utils/format';

type Props = NativeStackScreenProps<ProductionStackParamList, 'ProductionOrderCreate'>;

const PRIORITIES: Priority[] = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
const PLANS_PER_PAGE = 4;

export function ProductionOrderCreateScreen({ navigation }: Props) {
  const [products, setProducts] = useState<{ id: string; code: string }[]>([]);
  const [lines, setLines] = useState<{ id: string; code: string }[]>([]);
  const [plans, setPlans] = useState<ProductionPlanRow[]>([]);
  const [productId, setProductId] = useState('');
  const [lineId, setLineId] = useState('');
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

      {/* Link to plan section with search, scroll, and pagination */}
      <View style={styles.planSectionContainer}>
        <View style={styles.sectionHeaderRow}>
          <View style={styles.sectionTitleWithBadge}>
            <Ionicons name="calendar-outline" size={16} color={colors.primary} />
            <Text style={typography.label}>Link to plan (optional)</Text>
          </View>
          <View style={styles.planBadgeContainer}>
            <Text style={styles.planBadgeText}>
              {filteredPlans.length} {filteredPlans.length === 1 ? 'plan' : 'plans'}
            </Text>
          </View>
        </View>

        {/* Selected Plan Banner */}
        {selectedPlan && (
          <View style={styles.selectedPlanBanner}>
            <View style={{ flex: 1 }}>
              <View style={styles.selectedPlanHeader}>
                <Ionicons name="checkmark-circle" size={16} color={colors.success} />
                <Text style={styles.selectedPlanTitle}>{selectedPlan.plan_number}</Text>
                <View style={styles.selectedPlanTag}>
                  <Text style={styles.selectedPlanTagText}>{selectedPlan.status}</Text>
                </View>
              </View>
              <Text style={styles.selectedPlanSubtitle}>
                {selectedPlan.product_code ?? 'Product'} • Target: {formatNumber(selectedPlan.target_quantity)} • Line: {selectedPlan.line_code ?? 'N/A'}
              </Text>
            </View>
            <Pressable style={styles.unlinkBtn} onPress={() => handleSelectPlan(null)}>
              <Ionicons name="close-circle-outline" size={16} color={colors.danger} />
              <Text style={styles.unlinkBtnText}>Unlink</Text>
            </Pressable>
          </View>
        )}

        {/* Plan search box */}
        <View style={styles.planSearchBox}>
          <Ionicons name="search-outline" size={16} color={colors.textSecondary} />
          <TextInput
            style={styles.planSearchInput}
            placeholder="Search plan by number, product, line..."
            placeholderTextColor={colors.textMuted}
            value={planSearch}
            onChangeText={(txt) => {
              setPlanSearch(txt);
              setPlanPage(1);
            }}
          />
          {planSearch.length > 0 && (
            <Pressable onPress={() => { setPlanSearch(''); setPlanPage(1); }}>
              <Ionicons name="close-circle" size={16} color={colors.textMuted} />
            </Pressable>
          )}
        </View>

        {/* Scrollable plan cards list */}
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.planCardsScroll}
        >
          {/* None Card */}
          <Pressable
            style={[
              styles.planCard,
              styles.planCardNone,
              planId === null && styles.planCardActive,
            ]}
            onPress={() => handleSelectPlan(null)}
          >
            <View style={styles.planCardNoneIcon}>
              <Ionicons
                name={planId === null ? 'checkmark-circle' : 'remove-circle-outline'}
                size={22}
                color={planId === null ? colors.primary : colors.textMuted}
              />
            </View>
            <Text style={[styles.planCardTitle, planId === null && styles.planCardTitleActive]}>
              None
            </Text>
            <Text style={styles.planCardSubtitle}>No linked plan</Text>
          </Pressable>

          {/* Paginated Plan Cards */}
          {paginatedPlans.map((pl) => {
            const isSelected = planId === pl.id;
            return (
              <Pressable
                key={pl.id}
                style={[styles.planCard, isSelected && styles.planCardActive]}
                onPress={() => handleSelectPlan(pl)}
              >
                <View style={styles.planCardHeader}>
                  <Text
                    style={[styles.planCardTitle, isSelected && styles.planCardTitleActive]}
                    numberOfLines={1}
                  >
                    {pl.plan_number}
                  </Text>
                  {isSelected ? (
                    <Ionicons name="checkmark-circle" size={16} color={colors.primary} />
                  ) : null}
                </View>

                <Text style={styles.planCardProduct} numberOfLines={1}>
                  {pl.product_code ?? 'Product'}
                </Text>

                <View style={styles.planCardMetaRow}>
                  <Text style={styles.planCardMeta}>
                    Target: {formatNumber(pl.target_quantity)}
                  </Text>
                  {pl.line_code ? (
                    <Text style={styles.planCardLineBadge}>{pl.line_code}</Text>
                  ) : null}
                </View>
              </Pressable>
            );
          })}

          {paginatedPlans.length === 0 && (
            <View style={styles.noPlansFound}>
              <Text style={styles.noPlansText}>No plans matching &quot;{planSearch}&quot;</Text>
            </View>
          )}
        </ScrollView>

        {/* Pagination Controls */}
        <View style={styles.paginationRow}>
          <Pressable
            style={[styles.pageBtn, currentPage <= 1 && styles.pageBtnDisabled]}
            disabled={currentPage <= 1}
            onPress={() => setPlanPage((p) => Math.max(1, p - 1))}
          >
            <Ionicons
              name="chevron-back"
              size={15}
              color={currentPage <= 1 ? colors.textMuted : colors.text}
            />
            <Text style={[styles.pageBtnText, currentPage <= 1 && styles.pageBtnTextDisabled]}>
              Prev
            </Text>
          </Pressable>

          <Text style={styles.pageInfoText}>
            Page <Text style={styles.pageInfoBold}>{currentPage}</Text> of{' '}
            <Text style={styles.pageInfoBold}>{totalPlanPages}</Text>
          </Text>

          <Pressable
            style={[styles.pageBtn, currentPage >= totalPlanPages && styles.pageBtnDisabled]}
            disabled={currentPage >= totalPlanPages}
            onPress={() => setPlanPage((p) => Math.min(totalPlanPages, p + 1))}
          >
            <Text style={[styles.pageBtnText, currentPage >= totalPlanPages && styles.pageBtnTextDisabled]}>
              Next
            </Text>
            <Ionicons
              name="chevron-forward"
              size={15}
              color={currentPage >= totalPlanPages ? colors.textMuted : colors.text}
            />
          </Pressable>
        </View>
      </View>

      <Text style={typography.label}>Priority</Text>
      <View style={styles.chips}>
        {PRIORITIES.map((pr) => (
          <Pressable
            key={pr}
            style={[styles.chip, priority === pr && styles.chipActive]}
            onPress={() => setPriority(pr)}
          >
            <Text style={priority === pr ? styles.chipTextActive : undefined}>{pr}</Text>
          </Pressable>
        ))}
      </View>

      <Text style={typography.label}>Target quantity</Text>
      <TextInput style={styles.input} value={target} onChangeText={setTarget} keyboardType="numeric" />

      <Pressable style={styles.btn} onPress={submit}>
        <Text style={styles.btnText}>Create order</Text>
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

  // Plan section styling
  planSectionContainer: {
    backgroundColor: colors.surface,
    borderRadius: 10,
    borderWidth: 1,
    borderColor: colors.border,
    padding: spacing.sm,
    gap: spacing.xs,
  },
  sectionHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 2,
  },
  sectionTitleWithBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  planBadgeContainer: {
    backgroundColor: '#E2E8F0',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 12,
  },
  planBadgeText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.textSecondary,
  },
  selectedPlanBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#F0F9FF',
    borderWidth: 1,
    borderColor: '#BAE6FD',
    borderRadius: 8,
    padding: spacing.sm,
    marginBottom: 4,
  },
  selectedPlanHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  selectedPlanTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: '#0369A1',
  },
  selectedPlanTag: {
    backgroundColor: '#E0F2FE',
    paddingHorizontal: 6,
    paddingVertical: 1,
    borderRadius: 4,
  },
  selectedPlanTagText: {
    fontSize: 10,
    fontWeight: '600',
    color: '#0284C7',
  },
  selectedPlanSubtitle: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 2,
  },
  unlinkBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingVertical: 4,
    paddingHorizontal: 8,
    borderRadius: 6,
    backgroundColor: '#FEE2E2',
  },
  unlinkBtnText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.danger,
  },
  planSearchBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.background,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    paddingHorizontal: spacing.sm,
    paddingVertical: 6,
    gap: 6,
  },
  planSearchInput: {
    flex: 1,
    fontSize: 12,
    color: colors.text,
    paddingVertical: 0,
  },
  planCardsScroll: {
    flexDirection: 'row',
    gap: 8,
    paddingVertical: 4,
  },
  planCard: {
    width: 150,
    backgroundColor: colors.background,
    borderWidth: 1.5,
    borderColor: colors.border,
    borderRadius: 8,
    padding: 10,
    justifyContent: 'space-between',
  },
  planCardNone: {
    width: 105,
    alignItems: 'center',
    justifyContent: 'center',
  },
  planCardNoneIcon: {
    marginBottom: 4,
  },
  planCardActive: {
    borderColor: colors.primary,
    backgroundColor: '#F0F7FF',
  },
  planCardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 2,
  },
  planCardTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.text,
  },
  planCardTitleActive: {
    color: colors.primary,
  },
  planCardSubtitle: {
    fontSize: 11,
    color: colors.textMuted,
  },
  planCardProduct: {
    fontSize: 11,
    color: colors.textSecondary,
    fontWeight: '500',
    marginBottom: 6,
  },
  planCardMetaRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  planCardMeta: {
    fontSize: 10,
    color: colors.textMuted,
    fontWeight: '500',
  },
  planCardLineBadge: {
    fontSize: 9,
    fontWeight: '700',
    color: colors.primaryDark,
    backgroundColor: '#DBEAFE',
    paddingHorizontal: 4,
    paddingVertical: 1,
    borderRadius: 3,
  },
  noPlansFound: {
    paddingVertical: 16,
    paddingHorizontal: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  noPlansText: {
    fontSize: 12,
    color: colors.textMuted,
    fontStyle: 'italic',
  },
  paginationRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingTop: 4,
    borderTopWidth: 1,
    borderTopColor: colors.border,
  },
  pageBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingVertical: 4,
    paddingHorizontal: 10,
    borderRadius: 6,
    backgroundColor: colors.background,
    borderWidth: 1,
    borderColor: colors.border,
  },
  pageBtnDisabled: {
    opacity: 0.45,
  },
  pageBtnText: {
    fontSize: 11,
    fontWeight: '600',
    color: colors.text,
  },
  pageBtnTextDisabled: {
    color: colors.textMuted,
  },
  pageInfoText: {
    fontSize: 11,
    color: colors.textSecondary,
  },
  pageInfoBold: {
    fontWeight: '700',
    color: colors.text,
  },

  btn: { backgroundColor: colors.primary, padding: spacing.md, borderRadius: 8, marginTop: spacing.md },
  btnText: { color: '#fff', textAlign: 'center', fontWeight: '600' },
});

