import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { useCallback, useState } from 'react';
import { Text } from 'react-native';
import { ListRow } from '../../components/common/ListRow';
import { Screen } from '../../components/common/Screen';
import { SectionHeader } from '../../components/common/SectionHeader';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { listProductionOrders } from '../../api/repositories/productionOrderRepository';
import type { ProductionOrderRow } from '../../types/database';
import type { ProductionStackParamList } from '../../navigation/types';
import { typography } from '../../theme';
import { progressPct } from '../../utils/calculations';
import { formatPct } from '../../utils/format';

type Props = NativeStackScreenProps<ProductionStackParamList, 'ProductionHub'>;

export function ProductionHubScreen({ navigation }: Props) {
  const [inProgress, setInProgress] = useState<ProductionOrderRow[]>([]);

  const load = useCallback(async () => {
    setInProgress(await listProductionOrders({ status: 'IN_PROGRESS' }));
  }, []);

  useLiveQuery(load);

  return (
    <Screen scroll>
      <Text style={typography.h2}>Production</Text>

      {inProgress.length > 0 ? (
        <>
          <SectionHeader title="Production in progress" />
          {inProgress.map((o) => (
            <ListRow
              key={o.id}
              title={o.order_number}
              subtitle={`${o.product_code} · ${o.line_code}${o.machine_code ? ` · ${o.machine_code}` : ''}`}
              status="IN_PROGRESS"
              rightMeta={formatPct(progressPct(o.produced_quantity, o.target_quantity))}
              onPress={() => navigation.navigate('ProductionOrderDetail', { orderId: o.id })}
            />
          ))}
        </>
      ) : (
        <Text style={typography.caption}>No active production — start an order from Production orders.</Text>
      )}

      <SectionHeader title="Modules" />
      <ListRow
        title="Production plans"
        subtitle="Schedule & targets"
        onPress={() => navigation.navigate('ProductionPlans')}
      />
      <ListRow
        title="Production orders"
        subtitle="Orders & material check"
        onPress={() => navigation.navigate('ProductionOrders')}
      />
      <ListRow
        title="Production floor"
        subtitle="Lines & machine status"
        onPress={() => navigation.navigate('ProductionFloor')}
      />
    </Screen>
  );
}
