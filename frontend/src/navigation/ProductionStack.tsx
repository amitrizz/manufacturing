import { createNativeStackNavigator } from '@react-navigation/native-stack';
import type { ProductionStackParamList } from './types';
import { ProductionHubScreen } from '../screens/production/ProductionHubScreen';
import { ProductionPlansScreen } from '../screens/production/ProductionPlansScreen';
import { ProductionPlanCreateScreen } from '../screens/production/ProductionPlanCreateScreen';
import { ProductionPlanDetailScreen } from '../screens/production/ProductionPlanDetailScreen';
import { ProductionOrdersScreen } from '../screens/production/ProductionOrdersScreen';
import { ProductionOrderCreateScreen } from '../screens/production/ProductionOrderCreateScreen';
import { ProductionOrderDetailScreen } from '../screens/production/ProductionOrderDetailScreen';
import { ProductionFloorScreen } from '../screens/production/ProductionFloorScreen';
import { RecordProductionScreen } from '../screens/production/RecordProductionScreen';

const Stack = createNativeStackNavigator<ProductionStackParamList>();

export function ProductionStack() {
  return (
    <Stack.Navigator
      screenOptions={{
        headerBackTitle: 'Back',
      }}
    >
      <Stack.Screen name="ProductionHub" component={ProductionHubScreen} options={{ title: 'Production Hub' }} />
      <Stack.Screen name="ProductionPlans" component={ProductionPlansScreen} options={{ title: 'Plans' }} />
      <Stack.Screen name="ProductionPlanCreate" component={ProductionPlanCreateScreen} options={{ title: 'New plan' }} />
      <Stack.Screen name="ProductionPlanDetail" component={ProductionPlanDetailScreen as any} options={{ title: 'Plan' }} />
      <Stack.Screen name="ProductionOrders" component={ProductionOrdersScreen as any} options={{ title: 'Orders' }} />
      <Stack.Screen
        name="ProductionOrderCreate"
        component={ProductionOrderCreateScreen}
        options={{ title: 'New order' }}
      />
      <Stack.Screen name="ProductionOrderDetail" component={ProductionOrderDetailScreen as any} options={{ title: 'Order' }} />
      <Stack.Screen name="ProductionFloor" component={ProductionFloorScreen as any} options={{ title: 'Floor & Shifts' }} />
      <Stack.Screen name="RecordProduction" component={RecordProductionScreen as any} options={{ title: 'Record' }} />
    </Stack.Navigator>
  );
}
