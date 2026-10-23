import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { FlatList, View } from 'react-native';
import { Button } from '../../components/common/Button';
import { ListRow } from '../../components/common/ListRow';
import { SearchField } from '../../components/common/SearchField';
import { listProductionOrders } from '../../api/repositories/productionOrderRepository';
import type { ProductionOrderRow } from '../../types/database';
import type { ProductionStackParamList } from '../../navigation/types';
import { colors, spacing } from '../../theme';
import { progressPct } from '../../utils/calculations';
import { formatPct } from '../../utils/format';

import { ViewModeBanner } from '../../components/common/ViewModeBanner';

type Props = NativeStackScreenProps<ProductionStackParamList, 'ProductionOrders'>;

export function ProductionOrdersScreen({ navigation, route }: Props) {
  const isViewOnly = Boolean(route.params?.viewOnly);
  const [orders, setOrders] = useState<ProductionOrderRow[]>([]);
  const [search, setSearch] = useState('');

  const load = useCallback(async () => {
    const all = await listProductionOrders({ search: search || undefined });
    const rank = (s: ProductionOrderRow['status']) => (s === 'IN_PROGRESS' ? 0 : s === 'PENDING' ? 1 : 2);
    all.sort((a, b) => rank(a.status) - rank(b.status) || b.created_at - a.created_at);
    setOrders(all);
  }, [search]);

  useLiveQuery(load);

  return (
    <View style={{ flex: 1, backgroundColor: colors.background, padding: spacing.lg, gap: spacing.sm }}>
      {isViewOnly && (
        <ViewModeBanner
          message="Orders viewing mode. Creating or modifying orders is disabled. Use the Management tab to create orders."
        />
      )}
      {!isViewOnly && (
        <Button
          label="+ New order"
          variant="secondary"
          onPress={() => navigation.navigate('ProductionOrderCreate')}
        />
      )}
      <SearchField value={search} onChangeText={setSearch} placeholder="Search orders…" />
      <FlatList
        data={orders}
        keyExtractor={(o) => o.id}
        onRefresh={load}
        refreshing={false}
        contentContainerStyle={{ paddingTop: spacing.sm }}
        renderItem={({ item }) => (
          <ListRow
            title={item.order_number}
            subtitle={`${item.product_code} · ${item.line_code}${item.status === 'PENDING' ? (item.qc_status === 'PASSED' ? ' · QC PASSED' : ' · QC PENDING') : ''}`}
            status={item.status}
            rightMeta={formatPct(progressPct(item.produced_quantity, item.target_quantity))}
            onPress={() =>
              navigation.navigate('ProductionOrderDetail', {
                orderId: item.id,
                viewOnly: isViewOnly,
              })
            }
          />
        )}
      />
    </View>
  );
}
