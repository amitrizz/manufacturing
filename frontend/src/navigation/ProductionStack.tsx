import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { ProductionFloorScreen } from '../screens/production/ProductionFloorScreen';
import { ProductionHubScreen } from '../screens/production/ProductionHubScreen';
import { ProductionOrderDetailScreen } from '../screens/production/ProductionOrderDetailScreen';
import { ProductionOrderCreateScreen } from '../screens/production/ProductionOrderCreateScreen';
import { ProductionOrdersScreen } from '../screens/production/ProductionOrdersScreen';
import { ProductionPlanCreateScreen } from '../screens/production/ProductionPlanCreateScreen';
import { ProductionPlanDetailScreen } from '../screens/production/ProductionPlanDetailScreen';
import { ProductionPlansScreen } from '../screens/production/ProductionPlansScreen';
import { RecordProductionScreen } from '../screens/production/RecordProductionScreen';
import type { ProductionStackParamList } from './types';

const Stack = createNativeStackNavigator<ProductionStackParamList>();

export function ProductionStackNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen name="ProductionHub" component={ProductionHubScreen} options={{ title: 'Production' }} />
      <Stack.Screen name="ProductionPlans" component={ProductionPlansScreen} options={{ title: 'Plans' }} />
      <Stack.Screen name="ProductionPlanCreate" component={ProductionPlanCreateScreen} options={{ title: 'New plan' }} />
      <Stack.Screen name="ProductionPlanDetail" component={ProductionPlanDetailScreen} options={{ title: 'Plan' }} />
      <Stack.Screen name="ProductionOrders" component={ProductionOrdersScreen} options={{ title: 'Orders' }} />
      <Stack.Screen
        name="ProductionOrderCreate"
        component={ProductionOrderCreateScreen}
        options={{ title: 'New order' }}
      />
      <Stack.Screen name="ProductionOrderDetail" component={ProductionOrderDetailScreen} options={{ title: 'Order' }} />
      <Stack.Screen name="ProductionFloor" component={ProductionFloorScreen} options={{ title: 'Floor & Shifts' }} />
      <Stack.Screen name="RecordProduction" component={RecordProductionScreen} options={{ title: 'Record' }} />
    </Stack.Navigator>
  );
}
