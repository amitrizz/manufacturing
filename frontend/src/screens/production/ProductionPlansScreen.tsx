import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { FlatList, View } from 'react-native';
import { Button } from '../../components/common/Button';
import { ListRow } from '../../components/common/ListRow';
import { SearchField } from '../../components/common/SearchField';
import { listProductionPlans } from '../../database/repositories/productionPlanRepository';
import type { ProductionPlanRow } from '../../types/database';
import type { ProductionStackParamList } from '../../navigation/types';
import { colors, spacing } from '../../theme';
import { formatDate } from '../../utils/format';

type Props = NativeStackScreenProps<ProductionStackParamList, 'ProductionPlans'>;

export function ProductionPlansScreen({ navigation }: Props) {
  const [plans, setPlans] = useState<ProductionPlanRow[]>([]);
  const [search, setSearch] = useState('');

  const load = useCallback(async () => {
    setPlans(await listProductionPlans({ search: search || undefined }));
  }, [search]);

  useLiveQuery(load);

  return (
    <View style={{ flex: 1, backgroundColor: colors.background, padding: spacing.lg, gap: spacing.sm }}>
      <Button label="+ New plan" variant="secondary" onPress={() => navigation.navigate('ProductionPlanCreate')} />
      <SearchField value={search} onChangeText={setSearch} placeholder="Search plans…" />
      <FlatList
        data={plans}
        keyExtractor={(p) => p.id}
        onRefresh={load}
        refreshing={false}
        renderItem={({ item }) => (
          <ListRow
            title={item.plan_number}
            subtitle={`${item.product_code} · ${formatDate(item.start_date)}`}
            status={item.status}
            onPress={() => navigation.navigate('ProductionPlanDetail', { planId: item.id })}
          />
        )}
      />
    </View>
  );
}
