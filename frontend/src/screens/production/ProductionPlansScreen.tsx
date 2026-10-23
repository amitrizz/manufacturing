import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
import { FlatList, View } from 'react-native';
import { Button } from '../../components/common/Button';
import { ListRow } from '../../components/common/ListRow';
import { SearchField } from '../../components/common/SearchField';
import { ViewModeBanner } from '../../components/common/ViewModeBanner';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { listProductionPlans } from '../../api/repositories/productionPlanRepository';
import type { ProductionPlanRow } from '../../types/database';
import type { ProductionStackParamList } from '../../navigation/types';
import { colors, spacing } from '../../theme';
import { formatNumber } from '../../utils/format';

type Props = NativeStackScreenProps<ProductionStackParamList, 'ProductionPlans'>;

export function ProductionPlansScreen({ navigation, route }: Props) {
  const isViewOnly = Boolean(route.params?.viewOnly);
  const [plans, setPlans] = useState<ProductionPlanRow[]>([]);
  const [search, setSearch] = useState('');

  const load = useCallback(async () => {
    const all = await listProductionPlans();
    if (!search.trim()) {
      setPlans(all);
    } else {
      const q = search.trim().toLowerCase();
      setPlans(
        all.filter(
          (p) =>
            p.plan_number.toLowerCase().includes(q) ||
            p.product_code?.toLowerCase().includes(q) ||
            p.product_name?.toLowerCase().includes(q) ||
            p.line_code?.toLowerCase().includes(q)
        )
      );
    }
  }, [search]);

  useLiveQuery(load);

  return (
    <View style={{ flex: 1, backgroundColor: colors.background, padding: spacing.lg, gap: spacing.sm }}>
      {isViewOnly && (
        <ViewModeBanner message="Plans viewing mode. Creating or modifying plans is disabled." />
      )}
      {!isViewOnly && (
        <Button
          label="+ New production plan"
          variant="secondary"
          onPress={() => navigation.navigate('ProductionPlanCreate')}
        />
      )}
      <SearchField value={search} onChangeText={setSearch} placeholder="Search plans, products, lines…" />
      <FlatList
        data={plans}
        keyExtractor={(p) => p.id}
        onRefresh={load}
        refreshing={false}
        contentContainerStyle={{ paddingTop: spacing.sm }}
        renderItem={({ item }) => (
          <ListRow
            title={item.plan_number}
            subtitle={`${item.product_code || item.product_name || 'Product'} · Line ${item.line_code || 'Line'}`}
            status={item.status}
            rightMeta={`Target: ${formatNumber(item.target_quantity)}`}
            onPress={() =>
              navigation.navigate('ProductionPlanDetail', {
                planId: item.id,
                viewOnly: isViewOnly,
              })
            }
          />
        )}
      />
    </View>
  );
}
