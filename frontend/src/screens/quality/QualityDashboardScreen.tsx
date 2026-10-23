import { Ionicons } from '@expo/vector-icons';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useMemo, useState } from 'react';
import {
  FlatList,
  Pressable,
  RefreshControl,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { Button } from '../../components/common/Button';
import { Card } from '../../components/common/Card';
import { Screen } from '../../components/common/Screen';
import { SearchField } from '../../components/common/SearchField';
import { ViewModeBanner } from '../../components/common/ViewModeBanner';
import {
  listOrdersWaitingForQc,
  listQualityInspections,
  listReworkOrders,
} from '../../api/repositories/qualityRepository';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import type { QualityStackParamList } from '../../navigation/types';
import { colors, spacing } from '../../theme';
import type { ProductionOrderRow, QualityInspectionRow, ReworkOrderRow } from '../../types/database';
import { formatDateTime, formatNumber } from '../../utils/format';

type Props = NativeStackScreenProps<QualityStackParamList, 'QualityDashboard'>;
type TabType = 'waiting' | 'history' | 'rework';

export function QualityDashboardScreen({ navigation, route }: Props) {
  const isViewOnly = Boolean(route.params?.viewOnly);

  const [tab, setTab] = useState<TabType>('waiting');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(false);

  const [waitingOrders, setWaitingOrders] = useState<ProductionOrderRow[]>([]);
  const [inspections, setInspections] = useState<QualityInspectionRow[]>([]);
  const [reworkOrders, setReworkOrders] = useState<ReworkOrderRow[]>([]);

  const loadData = useCallback(async () => {
    try {
      setLoading(true);
      const [waiting, insp, rework] = await Promise.all([
        listOrdersWaitingForQc(),
        listQualityInspections(),
        listReworkOrders(),
      ]);
      setWaitingOrders(waiting);
      setInspections(insp);
      setReworkOrders(rework);
    } finally {
      setLoading(false);
    }
  }, []);

  useLiveQuery(loadData);

  // Stats
  const passCount = useMemo(
    () => inspections.filter((i) => i.overall_result === 'PASS').length,
    [inspections],
  );
  const passRate = useMemo(
    () => (inspections.length > 0 ? Math.round((passCount / inspections.length) * 100) : 100),
    [inspections, passCount],
  );

  // Filtered lists based on search
  const filteredWaiting = useMemo(() => {
    if (!search.trim()) return waitingOrders;
    const q = search.toLowerCase();
    return waitingOrders.filter(
      (o) =>
        o.order_number.toLowerCase().includes(q) ||
        (o.product_name && o.product_name.toLowerCase().includes(q)) ||
        (o.product_code && o.product_code.toLowerCase().includes(q)),
    );
  }, [waitingOrders, search]);

  const filteredHistory = useMemo(() => {
    if (!search.trim()) return inspections;
    const q = search.toLowerCase();
    return inspections.filter(
      (i) =>
        i.batch_number.toLowerCase().includes(q) ||
        (i.inspector && i.inspector.toLowerCase().includes(q)) ||
        ((i as any).order_number && (i as any).order_number.toLowerCase().includes(q)) ||
        ((i as any).product_name && (i as any).product_name.toLowerCase().includes(q)),
    );
  }, [inspections, search]);

  return (
    <Screen scroll={false} style={styles.container}>
      {isViewOnly && (
        <ViewModeBanner message="Quality Assurance view mode. Inspecting and approving orders is disabled here. Use Management tab to record quality inspections." />
      )}

      {/* Header Banner */}
      <View style={styles.headerBanner}>
        <View style={{ flex: 1 }}>
          <Text style={styles.headerTitle}>Quality Assurance & Control</Text>
          <Text style={styles.headerSubtitle}>
            Pre-production clearance, inspection checks & production approvals
          </Text>
        </View>
        {!isViewOnly && (
          <Button
            label="+ New Inspection"
            onPress={() => navigation.navigate('InspectionCreate')}
            style={{ paddingHorizontal: 12 }}
          />
        )}
      </View>

      {/* KPI Overview Grid (3 Metric Cards) */}
      <View style={styles.kpiRow}>
        <Pressable
          style={[styles.kpiCard, tab === 'waiting' && styles.kpiCardActive]}
          onPress={() => setTab('waiting')}
        >
          <View style={styles.kpiHeader}>
            <Text style={styles.kpiLabel}>Waiting for QC</Text>
            <Ionicons
              name="alert-circle"
              size={15}
              color={waitingOrders.length > 0 ? colors.warning : colors.textMuted}
            />
          </View>
          <Text
            style={[
              styles.kpiValue,
              waitingOrders.length > 0 && { color: colors.warning },
            ]}
          >
            {waitingOrders.length}
          </Text>
          <Text style={styles.kpiSub}>Orders waiting for start</Text>
        </Pressable>

        <Pressable
          style={[styles.kpiCard, tab === 'history' && styles.kpiCardActive]}
          onPress={() => setTab('history')}
        >
          <View style={styles.kpiHeader}>
            <Text style={styles.kpiLabel}>Pass Rate</Text>
            <Ionicons name="shield-checkmark" size={15} color={colors.success} />
          </View>
          <Text style={[styles.kpiValue, { color: colors.success }]}>{passRate}%</Text>
          <Text style={styles.kpiSub}>{inspections.length} recorded tests</Text>
        </Pressable>

        <Pressable
          style={[styles.kpiCard, tab === 'rework' && styles.kpiCardActive]}
          onPress={() => setTab('rework')}
        >
          <View style={styles.kpiHeader}>
            <Text style={styles.kpiLabel}>Rework Queue</Text>
            <Ionicons name="refresh-outline" size={15} color={colors.danger} />
          </View>
          <Text
            style={[
              styles.kpiValue,
              reworkOrders.length > 0 && { color: colors.danger },
            ]}
          >
            {reworkOrders.length}
          </Text>
          <Text style={styles.kpiSub}>Defect items in rework</Text>
        </Pressable>
      </View>

      {/* Segment Switcher */}
      <View style={styles.segmentContainer}>
        <Pressable
          style={[styles.segmentBtn, tab === 'waiting' && styles.segmentBtnActive]}
          onPress={() => setTab('waiting')}
        >
          <Text style={[styles.segmentText, tab === 'waiting' && styles.segmentTextActive]}>
            Waiting for QC ({waitingOrders.length})
          </Text>
        </Pressable>

        <Pressable
          style={[styles.segmentBtn, tab === 'history' && styles.segmentBtnActive]}
          onPress={() => setTab('history')}
        >
          <Text style={[styles.segmentText, tab === 'history' && styles.segmentTextActive]}>
            Inspection History ({inspections.length})
          </Text>
        </Pressable>

        <Pressable
          style={[styles.segmentBtn, tab === 'rework' && styles.segmentBtnActive]}
          onPress={() => setTab('rework')}
        >
          <Text style={[styles.segmentText, tab === 'rework' && styles.segmentTextActive]}>
            Rework ({reworkOrders.length})
          </Text>
        </Pressable>
      </View>

      {/* Search Input */}
      <View style={{ marginBottom: spacing.md }}>
        <SearchField
          value={search}
          onChangeText={setSearch}
          placeholder={
            tab === 'waiting'
              ? 'Search pending orders by number/product...'
              : 'Search inspections by batch/inspector...'
          }
        />
      </View>

      {/* Content Section */}
      {tab === 'waiting' ? (
        <FlatList
          data={filteredWaiting}
          keyExtractor={(item) => item.id}
          refreshControl={<RefreshControl refreshing={loading} onRefresh={loadData} />}
          contentContainerStyle={{ paddingBottom: 32 }}
          ListEmptyComponent={
            <View style={styles.emptyBox}>
              <Ionicons name="checkmark-done-circle-outline" size={44} color={colors.success} />
              <Text style={styles.emptyTitle}>All Orders Cleared</Text>
              <Text style={styles.emptySub}>
                There are currently no orders pending pre-production quality inspection. All work
                orders are approved and can run.
              </Text>
              <Button
                label="View Production Orders →"
                variant="secondary"
                onPress={() => (navigation as any).navigate('Production', { screen: 'ProductionOrders' })}
                style={{ marginTop: 12 }}
              />
            </View>
          }
          renderItem={({ item }) => (
            <Card style={styles.orderCard}>
              <View style={styles.orderCardHeader}>
                <View style={{ flex: 1 }}>
                  <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                    <Text style={styles.orderNumber}>{item.order_number}</Text>
                    <View style={styles.waitingBadge}>
                      <Ionicons name="alert-circle" size={11} color={colors.warning} />
                      <Text style={styles.waitingBadgeText}>AWAITING PRE-PRODUCTION QC</Text>
                    </View>
                  </View>
                  <Text style={styles.productName}>
                    {item.product_name ?? item.product_code}
                  </Text>
                  <Text style={styles.orderMeta}>
                    Line: <Text style={{ fontWeight: '700' }}>{item.line_code || 'Line A'}</Text> •
                    Machine:{' '}
                    <Text style={{ fontWeight: '700' }}>{item.machine_code || 'Auto-assign'}</Text>
                  </Text>
                </View>

                <View
                  style={[
                    styles.priorityBadge,
                    {
                      backgroundColor:
                        item.priority === 'CRITICAL' || item.priority === 'HIGH'
                          ? colors.dangerBg
                          : '#F1F5F9',
                    },
                  ]}
                >
                  <Text
                    style={[
                      styles.priorityBadgeText,
                      {
                        color:
                          item.priority === 'CRITICAL' || item.priority === 'HIGH'
                            ? colors.danger
                            : colors.textSecondary,
                      },
                    ]}
                  >
                    {item.priority}
                  </Text>
                </View>
              </View>

              <View style={styles.orderStatsRow}>
                <View>
                  <Text style={styles.statLabel}>Target Output</Text>
                  <Text style={styles.statValue}>{formatNumber(item.target_quantity)} pcs</Text>
                </View>
                <View>
                  <Text style={styles.statLabel}>Production State</Text>
                  <Text style={[styles.statValue, { color: colors.warning }]}>
                    Locked (QC Required)
                  </Text>
                </View>
              </View>

              {/* Action Button: Inspect & Approve */}
              {!isViewOnly && (
                <View style={styles.cardActionRow}>
                  <Pressable
                    style={styles.inspectBtn}
                    onPress={() =>
                      navigation.navigate('InspectionCreate', { orderId: item.id })
                    }
                  >
                    <Ionicons name="shield-checkmark" size={14} color="#FFFFFF" />
                    <Text style={styles.inspectBtnText}>Inspect & Approve for Production →</Text>
                  </Pressable>
                </View>
              )}
            </Card>
          )}
        />
      ) : tab === 'history' ? (
        <FlatList
          data={filteredHistory}
          keyExtractor={(item) => item.id}
          refreshControl={<RefreshControl refreshing={loading} onRefresh={loadData} />}
          contentContainerStyle={{ paddingBottom: 32 }}
          ListEmptyComponent={
            <View style={styles.emptyBox}>
              <Ionicons name="document-text-outline" size={40} color={colors.textMuted} />
              <Text style={styles.emptyTitle}>No Inspection Records</Text>
              <Text style={styles.emptySub}>No quality inspection tests have been completed yet.</Text>
            </View>
          }
          renderItem={({ item }) => {
            const isPass = item.overall_result === 'PASS';
            return (
              <Card style={styles.historyCard}>
                <View style={styles.historyHeader}>
                  <View style={{ flex: 1 }}>
                    <Text style={styles.historyBatch}>{item.batch_number}</Text>
                    {(item as any).order_number ? (
                      <Text style={{ fontSize: 12, fontWeight: '700', color: colors.text, marginTop: 2 }}>
                        Order: {(item as any).order_number}
                        {(item as any).product_name ? ` • ${(item as any).product_name}` : ''}
                      </Text>
                    ) : null}
                    <Text style={styles.historyMeta}>
                      Inspector: {item.inspector} • {formatDateTime(item.inspected_at)}
                    </Text>
                  </View>
                  <View
                    style={[
                      styles.resultBadge,
                      { backgroundColor: isPass ? colors.successBg : colors.dangerBg },
                    ]}
                  >
                    <Text
                      style={[
                        styles.resultBadgeText,
                        { color: isPass ? colors.success : colors.danger },
                      ]}
                    >
                      {item.overall_result}
                    </Text>
                  </View>
                </View>

                {item.rejection_reason && (
                  <View style={styles.rejectionBox}>
                    <Ionicons name="warning-outline" size={13} color={colors.danger} />
                    <Text style={styles.rejectionText}>
                      Reason: {item.rejection_reason} ({item.rejection_action || 'HOLD'})
                    </Text>
                  </View>
                )}
              </Card>
            );
          }}
        />
      ) : (
        <FlatList
          data={reworkOrders}
          keyExtractor={(item) => item.id}
          refreshControl={<RefreshControl refreshing={loading} onRefresh={loadData} />}
          contentContainerStyle={{ paddingBottom: 32 }}
          ListEmptyComponent={
            <View style={styles.emptyBox}>
              <Ionicons name="refresh-circle-outline" size={40} color={colors.textMuted} />
              <Text style={styles.emptyTitle}>Rework Queue Empty</Text>
              <Text style={styles.emptySub}>No defective batches require rework at this time.</Text>
            </View>
          }
          renderItem={({ item }) => (
            <Card style={styles.historyCard}>
              <View style={styles.historyHeader}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.historyBatch}>{item.rework_number}</Text>
                  <Text style={styles.historyMeta}>
                    Reason: {item.reason} • Created: {formatDateTime(item.created_at)}
                  </Text>
                </View>
                <View
                  style={[
                    styles.resultBadge,
                    {
                      backgroundColor:
                        item.status === 'COMPLETED' ? colors.successBg : colors.warningBg,
                    },
                  ]}
                >
                  <Text
                    style={[
                      styles.resultBadgeText,
                      {
                        color:
                          item.status === 'COMPLETED' ? colors.success : colors.warning,
                      },
                    ]}
                  >
                    {item.status}
                  </Text>
                </View>
              </View>
              <Text style={[styles.orderMeta, { marginTop: 4 }]}>
                Quantity: <Text style={{ fontWeight: '700' }}>{formatNumber(item.quantity)} pcs</Text>
              </Text>
            </Card>
          )}
        />
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  container: {
    paddingHorizontal: 16,
    paddingTop: 12,
  },
  headerBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    padding: 14,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 3,
    elevation: 2,
  },
  headerTitle: {
    fontSize: 16,
    fontWeight: '800',
    color: colors.text,
  },
  headerSubtitle: {
    fontSize: 11.5,
    color: colors.textSecondary,
    marginTop: 2,
  },
  kpiRow: {
    flexDirection: 'row',
    gap: 8,
    marginBottom: spacing.md,
  },
  kpiCard: {
    flex: 1,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 12,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 3,
    elevation: 1,
  },
  kpiCardActive: {
    borderColor: colors.primary,
    backgroundColor: '#F8FAFC',
  },
  kpiHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  kpiLabel: {
    fontSize: 10,
    fontWeight: '700',
    color: colors.textSecondary,
    textTransform: 'uppercase',
  },
  kpiValue: {
    fontSize: 19,
    fontWeight: '800',
    color: colors.text,
  },
  kpiSub: {
    fontSize: 9.5,
    color: colors.textMuted,
    marginTop: 2,
  },
  segmentContainer: {
    flexDirection: 'row',
    backgroundColor: '#E2E8F0',
    borderRadius: 10,
    padding: 3,
    marginBottom: spacing.md,
  },
  segmentBtn: {
    flex: 1,
    paddingVertical: 7,
    alignItems: 'center',
    borderRadius: 8,
  },
  segmentBtnActive: {
    backgroundColor: '#FFFFFF',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.08,
    shadowRadius: 3,
    elevation: 2,
  },
  segmentText: {
    fontSize: 11.5,
    fontWeight: '600',
    color: '#64748B',
  },
  segmentTextActive: {
    color: colors.primary,
    fontWeight: '700',
  },
  orderCard: {
    borderRadius: 14,
    padding: 14,
    marginBottom: spacing.sm,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  orderCardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 8,
  },
  orderNumber: {
    fontSize: 14,
    fontWeight: '800',
    color: colors.text,
  },
  waitingBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
    backgroundColor: '#FFFBEB',
    paddingHorizontal: 5,
    paddingVertical: 1.5,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: '#FDE68A',
  },
  waitingBadgeText: {
    fontSize: 8.5,
    fontWeight: '800',
    color: colors.warning,
  },
  productName: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.text,
    marginTop: 2,
  },
  orderMeta: {
    fontSize: 11.5,
    color: colors.textSecondary,
    marginTop: 3,
  },
  priorityBadge: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  priorityBadgeText: {
    fontSize: 9.5,
    fontWeight: '800',
  },
  orderStatsRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: '#F8FAFC',
    borderRadius: 8,
    padding: 8,
    marginTop: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  statLabel: {
    fontSize: 10,
    color: colors.textMuted,
    fontWeight: '600',
  },
  statValue: {
    fontSize: 12,
    fontWeight: '800',
    color: colors.text,
    marginTop: 1,
  },
  cardActionRow: {
    marginTop: 10,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  inspectBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 6,
    backgroundColor: colors.primary,
    borderRadius: 8,
    paddingVertical: 8,
  },
  inspectBtnText: {
    fontSize: 12,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  historyCard: {
    borderRadius: 12,
    padding: 12,
    marginBottom: spacing.sm,
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  historyHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
  },
  historyBatch: {
    fontSize: 13.5,
    fontWeight: '700',
    color: colors.text,
  },
  historyMeta: {
    fontSize: 11,
    color: colors.textSecondary,
    marginTop: 2,
  },
  resultBadge: {
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  resultBadgeText: {
    fontSize: 10,
    fontWeight: '800',
  },
  rejectionBox: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#FEF2F2',
    padding: 6,
    borderRadius: 6,
    marginTop: 6,
  },
  rejectionText: {
    fontSize: 11,
    color: colors.danger,
  },
  emptyBox: {
    alignItems: 'center',
    padding: 32,
    backgroundColor: '#F8FAFC',
    borderRadius: 14,
    marginTop: 12,
  },
  emptyTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: colors.text,
    marginTop: 8,
  },
  emptySub: {
    fontSize: 12,
    color: colors.textSecondary,
    textAlign: 'center',
    marginTop: 4,
    lineHeight: 16,
  },
});
