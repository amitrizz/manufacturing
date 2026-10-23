import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useMemo, useState } from 'react';
import {
  Alert,
  FlatList,
  Pressable,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { dispatchOrder, listDispatchOrders } from '../../api/repositories/dispatchRepository';
import type { DispatchOrderRow } from '../../types/database';
import type { MoreStackParamList } from '../../navigation/types';
import { colors, spacing, typography } from '../../theme';
import { formatDateTime, formatNumber } from '../../utils/format';

type Props = NativeStackScreenProps<MoreStackParamList, 'Dispatch'>;

export function DispatchScreen({ navigation }: Props) {
  const [orders, setOrders] = useState<DispatchOrderRow[]>([]);
  const [search, setSearch] = useState('');
  const [refreshing, setRefreshing] = useState(false);

  const load = useCallback(async () => {
    try {
      setRefreshing(true);
      setOrders(await listDispatchOrders());
    } finally {
      setRefreshing(false);
    }
  }, []);

  useLiveQuery(load);

  const filteredOrders = useMemo(() => {
    if (!search.trim()) return orders;
    const q = search.trim().toLowerCase();
    return orders.filter(
      (o) =>
        (o.dispatch_number || '').toLowerCase().includes(q) ||
        (o.customer_name || '').toLowerCase().includes(q) ||
        (o.product_name || '').toLowerCase().includes(q) ||
        (o.product_code || '').toLowerCase().includes(q),
    );
  }, [orders, search]);

  const readyCount = useMemo(
    () => orders.filter((o) => o.status === 'READY' || o.status === 'PENDING').length,
    [orders],
  );
  const dispatchedCount = useMemo(
    () => orders.filter((o) => o.status === 'DISPATCHED' || o.status === 'DELIVERED').length,
    [orders],
  );
  const totalUnitsShipped = useMemo(
    () =>
      orders
        .filter((o) => o.status === 'DISPATCHED' || o.status === 'DELIVERED')
        .reduce((sum, o) => sum + (o.quantity || 0), 0),
    [orders],
  );

  const handleDispatchNow = (item: DispatchOrderRow) => {
    Alert.alert(
      'Confirm Dispatch',
      `Ship order ${item.dispatch_number} (${item.quantity} units to ${item.customer_name})?\n\nThis will deduct ${item.quantity} units from Finished Goods warehouse.`,
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Confirm & Ship',
          style: 'default',
          onPress: async () => {
            try {
              await dispatchOrder(item.id);
              Alert.alert('Dispatched', `Order ${item.dispatch_number} has been dispatched.`);
              load();
            } catch (e: unknown) {
              Alert.alert('Error', e instanceof Error ? e.message : 'Dispatch failed');
            }
          },
        },
      ],
    );
  };

  return (
    <View style={styles.container}>
      {/* Top Action & KPIs */}
      <View style={styles.kpiRow}>
        <View style={styles.kpiBox}>
          <Text style={styles.kpiNumberAmber}>{readyCount}</Text>
          <Text style={styles.kpiLabel}>Ready to Ship</Text>
        </View>
        <View style={styles.kpiBox}>
          <Text style={styles.kpiNumberGreen}>{dispatchedCount}</Text>
          <Text style={styles.kpiLabel}>Dispatched</Text>
        </View>
        <View style={styles.kpiBox}>
          <Text style={styles.kpiNumberBlue}>{formatNumber(totalUnitsShipped)}</Text>
          <Text style={styles.kpiLabel}>Units Fulfilled</Text>
        </View>
      </View>

      {/* Action Button & Search */}
      <View style={styles.actionHeader}>
        <View style={styles.searchBox}>
          <Ionicons name="search" size={15} color={colors.textSecondary} />
          <TextInput
            style={styles.searchInput}
            placeholder="Search challan, customer, product..."
            value={search}
            onChangeText={setSearch}
            placeholderTextColor={colors.textMuted}
          />
          {search ? (
            <Pressable onPress={() => setSearch('')}>
              <Ionicons name="close-circle" size={15} color={colors.textSecondary} />
            </Pressable>
          ) : null}
        </View>

        <Pressable
          style={styles.createBtn}
          onPress={() => navigation.navigate('DispatchCreate')}
        >
          <Ionicons name="add" size={18} color="#FFFFFF" />
          <Text style={styles.createBtnText}>New Challan</Text>
        </Pressable>
      </View>

      {/* Orders List */}
      <FlatList
        style={styles.list}
        contentContainerStyle={styles.content}
        data={filteredOrders}
        keyExtractor={(o) => o.id}
        onRefresh={load}
        refreshing={refreshing}
        ListEmptyComponent={
          <View style={styles.emptyCard}>
            <Ionicons name="paper-plane-outline" size={44} color={colors.textMuted} />
            <Text style={styles.emptyTitle}>No Dispatch Orders Yet</Text>
            <Text style={styles.emptyDesc}>
              Create delivery challans to ship inspected finished goods from the warehouse to your
              customers.
            </Text>
            <Pressable
              style={styles.emptyActionBtn}
              onPress={() => navigation.navigate('DispatchCreate')}
            >
              <Text style={styles.emptyActionBtnText}>+ Create Delivery Challan</Text>
            </Pressable>
          </View>
        }
        renderItem={({ item }) => {
          const isDispatched = item.status === 'DISPATCHED' || item.status === 'DELIVERED';
          return (
            <View style={styles.card}>
              <View style={styles.cardHeader}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.dispatchNum}>{item.dispatch_number}</Text>
                  <Text style={styles.customerName}>{item.customer_name}</Text>
                </View>
                <View
                  style={[
                    styles.statusBadge,
                    isDispatched ? styles.statusBadgeGreen : styles.statusBadgeAmber,
                  ]}
                >
                  <Text
                    style={[
                      styles.statusBadgeText,
                      isDispatched ? styles.statusBadgeTextGreen : styles.statusBadgeTextAmber,
                    ]}
                  >
                    {item.status}
                  </Text>
                </View>
              </View>

              <View style={styles.cardBody}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.productText}>
                    {item.product_code ? `${item.product_code} • ` : ''}
                    {item.product_name || 'Finished Product'}
                  </Text>
                  <Text style={styles.qtyText}>
                    Quantity: <Text style={{ fontWeight: '800' }}>{formatNumber(item.quantity)}</Text> pcs
                  </Text>
                  {item.delivery_address ? (
                    <Text style={styles.detailAddressText} numberOfLines={1}>
                      📍 {item.delivery_address}
                    </Text>
                  ) : null}
                  {item.vehicle_number || item.driver_name ? (
                    <Text style={styles.detailTransportText}>
                      🚚 {[item.vehicle_number, item.driver_name].filter(Boolean).join(' • ')}
                    </Text>
                  ) : null}
                </View>
                {item.created_at ? (
                  <Text style={styles.dateText}>{formatDateTime(item.created_at)}</Text>
                ) : null}
              </View>

              {!isDispatched ? (
                <View style={styles.cardFooter}>
                  <Pressable
                    style={styles.dispatchNowBtn}
                    onPress={() => handleDispatchNow(item)}
                  >
                    <Ionicons name="checkmark-circle-outline" size={15} color="#059669" />
                    <Text style={styles.dispatchNowText}>Dispatch & Ship Now</Text>
                  </Pressable>
                </View>
              ) : null}
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
  kpiRow: {
    flexDirection: 'row',
    gap: spacing.sm,
    paddingHorizontal: spacing.md,
    paddingTop: spacing.md,
    paddingBottom: spacing.xs,
  },
  kpiBox: {
    flex: 1,
    backgroundColor: colors.surface,
    padding: spacing.sm,
    borderRadius: 10,
    alignItems: 'center',
    borderWidth: 1,
    borderColor: colors.border,
  },
  kpiNumberAmber: {
    fontSize: 18,
    fontWeight: '800',
    color: '#D97706',
  },
  kpiNumberGreen: {
    fontSize: 18,
    fontWeight: '800',
    color: '#059669',
  },
  kpiNumberBlue: {
    fontSize: 18,
    fontWeight: '800',
    color: '#0284C7',
  },
  kpiLabel: {
    fontSize: 10,
    fontWeight: '600',
    color: colors.textSecondary,
    marginTop: 2,
  },
  actionHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: spacing.md,
    marginVertical: spacing.sm,
  },
  searchBox: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 7,
  },
  searchInput: {
    flex: 1,
    fontSize: 12.5,
    color: colors.text,
    padding: 0,
  },
  createBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: colors.primary,
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 8,
  },
  createBtnText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '700',
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
    marginBottom: 8,
  },
  dispatchNum: {
    fontSize: 15,
    fontWeight: '800',
    color: colors.text,
  },
  customerName: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 1,
  },
  statusBadge: {
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  statusBadgeGreen: {
    backgroundColor: '#DCFCE7',
  },
  statusBadgeAmber: {
    backgroundColor: '#FEF3C7',
  },
  statusBadgeText: {
    fontSize: 10,
    fontWeight: '800',
  },
  statusBadgeTextGreen: {
    color: '#15803D',
  },
  statusBadgeTextAmber: {
    color: '#B45309',
  },
  cardBody: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    backgroundColor: '#F8FAFC',
    padding: 10,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  productText: {
    fontSize: 13,
    fontWeight: '700',
    color: colors.text,
  },
  qtyText: {
    fontSize: 12,
    color: colors.textSecondary,
    marginTop: 2,
  },
  detailAddressText: {
    fontSize: 11,
    color: '#0369A1',
    marginTop: 4,
    fontWeight: '500',
  },
  detailTransportText: {
    fontSize: 11,
    color: '#475569',
    marginTop: 2,
    fontWeight: '500',
  },
  dateText: {
    fontSize: 10.5,
    color: colors.textMuted,
  },
  cardFooter: {
    marginTop: 10,
    paddingTop: 8,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
    flexDirection: 'row',
    justifyContent: 'flex-end',
  },
  dispatchNowBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: '#ECFDF5',
    paddingHorizontal: 10,
    paddingVertical: 5,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: '#A7F3D0',
  },
  dispatchNowText: {
    color: '#059669',
    fontSize: 11.5,
    fontWeight: '700',
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
    maxWidth: 280,
  },
  emptyActionBtn: {
    marginTop: 8,
    backgroundColor: colors.primary,
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 8,
  },
  emptyActionBtnText: {
    color: '#FFFFFF',
    fontSize: 12.5,
    fontWeight: '700',
  },
});