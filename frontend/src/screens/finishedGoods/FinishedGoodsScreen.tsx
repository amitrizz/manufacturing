import { useCallback, useMemo, useState } from 'react';
import { useNavigation } from '@react-navigation/native';
import type { NavigationProp, ParamListBase } from '@react-navigation/native';
import {
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { listFinishedGoods } from '../../api/repositories/finishedGoodsRepository';
import type { FinishedGoodsRow } from '../../types/database';
import { colors, spacing, typography } from '../../theme';
import { formatNumber } from '../../utils/format';

export function FinishedGoodsScreen() {
  const navigation = useNavigation<NavigationProp<ParamListBase>>();
  const [items, setItems] = useState<FinishedGoodsRow[]>([]);
  const [search, setSearch] = useState('');
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async () => {
    try {
      setRefreshing(true);
      const data = await listFinishedGoods();
      setItems(data);
    } finally {
      setRefreshing(false);
    }
  }, []);

  useLiveQuery(load);

  const filteredItems = useMemo(() => {
    if (!search.trim()) return items;
    const q = search.trim().toLowerCase();
    return items.filter(
      (i) =>
        (i.product_code || '').toLowerCase().includes(q) ||
        (i.product_name || '').toLowerCase().includes(q),
    );
  }, [items, search]);

  const totalAvailable = useMemo(
    () => items.reduce((sum, i) => sum + (i.available_quantity || 0), 0),
    [items],
  );
  const totalProduced = useMemo(
    () => items.reduce((sum, i) => sum + (i.produced_quantity || 0), 0),
    [items],
  );
  const totalPassed = useMemo(
    () => items.reduce((sum, i) => sum + (i.quality_passed_quantity || 0), 0),
    [items],
  );

  return (
    <View style={styles.container}>
      {/* Warehouse KPI Overview */}
      <View style={styles.kpiContainer}>
        <View style={styles.kpiCard}>
          <Text style={styles.kpiValueGreen}>{formatNumber(totalAvailable)}</Text>
          <Text style={styles.kpiLabel}>Available (Ready)</Text>
        </View>
        <View style={styles.kpiCard}>
          <Text style={styles.kpiValueBlue}>{formatNumber(totalProduced)}</Text>
          <Text style={styles.kpiLabel}>Total Produced</Text>
        </View>
        <View style={styles.kpiCard}>
          <Text style={styles.kpiValuePurple}>{formatNumber(totalPassed)}</Text>
          <Text style={styles.kpiLabel}>QA Passed</Text>
        </View>
      </View>

      {/* Search Bar */}
      <View style={styles.searchBar}>
        <Ionicons name="search" size={16} color={colors.textSecondary} />
        <TextInput
          style={styles.searchInput}
          placeholder="Search finished products..."
          value={search}
          onChangeText={setSearch}
          placeholderTextColor={colors.textMuted}
        />
        {search ? (
          <Pressable onPress={() => setSearch('')}>
            <Ionicons name="close-circle" size={16} color={colors.textSecondary} />
          </Pressable>
        ) : null}
      </View>

      {/* List */}
      <FlatList
        style={styles.list}
        contentContainerStyle={styles.content}
        data={filteredItems}
        keyExtractor={(i) => i.id}
        onRefresh={load}
        refreshing={refreshing}
        ListEmptyComponent={
          <View style={styles.emptyCard}>
            <Ionicons name="cube-outline" size={40} color={colors.textMuted} />
            <Text style={styles.emptyTitle}>No Finished Goods Found</Text>
            <Text style={styles.emptyDesc}>
              Products appear here automatically as output is produced and verified in Quality
              Assurance.
            </Text>
          </View>
        }
        renderItem={({ item }) => {
          const hasStock = (item.available_quantity || 0) > 0;
          return (
            <View style={styles.card}>
              <View style={styles.cardHeader}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.productCode}>{item.product_code || 'Product'}</Text>
                  <Text style={styles.productName}>{item.product_name || 'Standard Item'}</Text>
                </View>
                <View style={[styles.badge, hasStock ? styles.badgeInStock : styles.badgeZero]}>
                  <Text style={[styles.badgeText, hasStock ? styles.badgeTextInStock : styles.badgeTextZero]}>
                    {hasStock ? 'IN STOCK' : 'ZERO STOCK'}
                  </Text>
                </View>
              </View>

              {/* Metrics Grid */}
              <View style={styles.metricsGrid}>
                <View style={styles.metricCol}>
                  <Text style={styles.metricLabel}>AVAILABLE (READY)</Text>
                  <Text style={styles.metricValHighlight}>{formatNumber(item.available_quantity || 0)}</Text>
                </View>
                <View style={styles.metricCol}>
                  <Text style={styles.metricLabel}>TOTAL PRODUCED</Text>
                  <Text style={styles.metricVal}>{formatNumber(item.produced_quantity || 0)}</Text>
                </View>
                <View style={styles.metricCol}>
                  <Text style={styles.metricLabel}>QA PASSED</Text>
                  <Text style={styles.metricVal}>{formatNumber(item.quality_passed_quantity || 0)}</Text>
                </View>
              </View>

              {/* Action Button */}
              {hasStock && (
                <View style={styles.actionRow}>
                  <Pressable
                    style={styles.dispatchBtn}
                    onPress={() => {
                      try {
                        navigation.navigate('DispatchCreate');
                      } catch {
                        navigation.navigate('Dispatch');
                      }
                    }}
                  >
                    <Ionicons name="paper-plane-outline" size={14} color="#0A1E38" />
                    <Text style={styles.dispatchBtnText}>Create Dispatch Order</Text>
                  </Pressable>
                </View>
              )}
            </View>
          );
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  kpiContainer: {
    flexDirection: 'row',
    gap: spacing.sm,
    paddingHorizontal: spacing.md,
    paddingTop: spacing.md,
    paddingBottom: spacing.xs,
  },
  kpiCard: {
    flex: 1,
    backgroundColor: colors.surface,
    padding: spacing.sm,
    borderRadius: 10,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.border,
  },
  kpiValueGreen: {
    fontSize: 18,
    fontWeight: '800',
    color: '#059669',
  },
  kpiValueBlue: {
    fontSize: 18,
    fontWeight: '800',
    color: '#0284C7',
  },
  kpiValuePurple: {
    fontSize: 18,
    fontWeight: '800',
    color: '#7C3AED',
  },
  kpiLabel: {
    fontSize: 10,
    fontWeight: '600',
    color: colors.textSecondary,
    marginTop: 2,
  },
  searchBar: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    marginHorizontal: spacing.md,
    marginVertical: spacing.sm,
  },
  searchInput: {
    flex: 1,
    fontSize: 13,
    color: colors.text,
    padding: 0,
  },
  list: { flex: 1 },
  content: { padding: spacing.md, paddingTop: 4 },
  card: {
    backgroundColor: colors.surface,
    padding: spacing.md,
    borderRadius: 12,
    marginBottom: spacing.sm,
    borderWidth: 1,
    borderColor: colors.border,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    marginBottom: 12,
  },
  productCode: {
    fontSize: 15,
    fontWeight: '800',
    color: colors.text,
  },
  productName: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  badgeInStock: {
    backgroundColor: '#DCFCE7',
  },
  badgeZero: {
    backgroundColor: '#F1F5F9',
  },
  badgeText: {
    fontSize: 10,
    fontWeight: '800',
  },
  badgeTextInStock: {
    color: '#15803D',
  },
  badgeTextZero: {
    color: '#64748B',
  },
  metricsGrid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: '#F8FAFC',
    borderRadius: 8,
    padding: 10,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  metricCol: {
    alignItems: 'center',
    flex: 1,
  },
  metricLabel: {
    fontSize: 9,
    fontWeight: '700',
    color: colors.textSecondary,
    marginBottom: 2,
  },
  metricVal: {
    fontSize: 14,
    fontWeight: '700',
    color: colors.text,
  },
  metricValHighlight: {
    fontSize: 15,
    fontWeight: '800',
    color: '#059669',
  },
  actionRow: {
    marginTop: 10,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  dispatchBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
    backgroundColor: '#E0F2FE',
  },
  dispatchBtnText: {
    fontSize: 11.5,
    fontWeight: '700',
    color: '#0284C7',
  },
  emptyCard: {
    alignItems: 'center',
    justifyContent: 'center',
    padding: 32,
    marginTop: 40,
    gap: 8,
  },
  emptyTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: colors.text,
  },
  emptyDesc: {
    fontSize: 12,
    color: colors.textSecondary,
    textAlign: 'center',
    maxWidth: 260,
  },
});
