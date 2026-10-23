import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { ActivityHistoryScreen } from '../screens/activity/ActivityHistoryScreen';
import { ContactsScreen } from '../screens/contacts/ContactsScreen';
import { DashboardScreen } from '../screens/dashboard/DashboardScreen';
import { DispatchScreen } from '../screens/dispatch/DispatchScreen';
import { MachineDetailScreen } from '../screens/machines/MachineDetailScreen';
import { MachineListScreen } from '../screens/machines/MachineListScreen';
import { MaterialDetailScreen } from '../screens/materials/MaterialDetailScreen';
import { MaterialsScreen } from '../screens/materials/MaterialsScreen';
import { NotificationsScreen } from '../screens/notifications/NotificationsScreen';
import { ProductionFloorScreen } from '../screens/production/ProductionFloorScreen';
import { ProductionOrderCreateScreen } from '../screens/production/ProductionOrderCreateScreen';
import { ProductionOrderDetailScreen } from '../screens/production/ProductionOrderDetailScreen';
import { ProductionOrdersScreen } from '../screens/production/ProductionOrdersScreen';
import { RecordProductionScreen } from '../screens/production/RecordProductionScreen';
import { PurchaseHomeScreen } from '../screens/purchase/PurchaseHomeScreen';
import { InspectionCreateScreen } from '../screens/quality/InspectionCreateScreen';
import { QualityDashboardScreen } from '../screens/quality/QualityDashboardScreen';
import { ReportsScreen } from '../screens/reports/ReportsScreen';

import { DispatchCreateScreen } from '../screens/dispatch/DispatchCreateScreen';
const ReportBreakdownScreen = MachineDetailScreen as any;
const ReworkListScreen = QualityDashboardScreen as any;
const OeeScreen = ReportsScreen as any;
import { GlobalSearchScreen } from '../screens/search/GlobalSearchScreen';
import { PlatformWorkflowScreen } from '../screens/settings/PlatformWorkflowScreen';
import { SettingsScreen } from '../screens/settings/SettingsScreen';
import { StaffScreen } from '../screens/staff/StaffScreen';
import { StockHomeScreen } from '../screens/stock/StockHomeScreen';
import type { HomeStackParamList } from './types';

const Stack = createNativeStackNavigator<HomeStackParamList>();

export function HomeStackNavigator() {
  return (
    <Stack.Navigator
      screenOptions={{
        headerShadowVisible: false,
      }}
    >
      <Stack.Screen
        name="Dashboard"
        component={DashboardScreen}
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="ProductionOrders"
        component={ProductionOrdersScreen}
        options={{ title: 'Customer & Production Orders' }}
      />
      <Stack.Screen
        name="ProductionOrderCreate"
        component={ProductionOrderCreateScreen}
        options={{ title: 'New Order' }}
      />
      <Stack.Screen
        name="ProductionOrderDetail"
        component={ProductionOrderDetailScreen}
        options={{ title: 'Order Details' }}
      />
      <Stack.Screen
        name="ProductionFloor"
        component={ProductionFloorScreen}
        options={{ title: 'Production Output & Floor' }}
      />
      <Stack.Screen
        name="RecordProduction"
        component={RecordProductionScreen}
        options={{ title: 'Daily Output Entry' }}
      />
      <Stack.Screen
        name="StockHome"
        component={StockHomeScreen}
        options={{ title: 'Stock & Inventory' }}
      />
      <Stack.Screen
        name="Materials"
        component={MaterialsScreen}
        options={{ title: 'Materials Stock' }}
      />
      <Stack.Screen
        name="MaterialDetail"
        component={MaterialDetailScreen}
        options={{ title: 'Material Detail' }}
      />
      <Stack.Screen
        name="PurchaseHome"
        component={PurchaseHomeScreen}
        options={{ title: 'Purchase & GRN' }}
      />
      <Stack.Screen
        name="MachineList"
        component={MachineListScreen}
        options={{ title: 'Machines Fleet' }}
      />
      <Stack.Screen
        name="MachineDetail"
        component={MachineDetailScreen}
        options={{ title: 'Machine Status' }}
      />
      <Stack.Screen
        name="ReportBreakdown"
        component={ReportBreakdownScreen}
        options={{ title: 'Report Breakdown' }}
      />
      <Stack.Screen
        name="Staff"
        component={StaffScreen}
        options={{ title: 'Workers & Staff' }}
      />
      <Stack.Screen
        name="QualityDashboard"
        component={QualityDashboardScreen}
        options={{ title: 'Quality Assurance' }}
      />
      <Stack.Screen
        name="InspectionCreate"
        component={InspectionCreateScreen}
        options={{ title: 'New Quality Inspection' }}
      />
      <Stack.Screen
        name="ReworkList"
        component={ReworkListScreen}
        options={{ title: 'Rework Queue' }}
      />
      <Stack.Screen
        name="Dispatch"
        component={DispatchScreen}
        options={{ title: 'Dispatch & Delivery' }}
      />
      <Stack.Screen
        name="DispatchCreate"
        component={DispatchCreateScreen}
        options={{ title: 'Create Dispatch' }}
      />
      <Stack.Screen
        name="Reports"
        component={ReportsScreen}
        options={{ title: 'Reports & Costing' }}
      />
      <Stack.Screen
        name="Oee"
        component={OeeScreen}
        options={{ title: 'OEE Analytics' }}
      />
      <Stack.Screen
        name="Contacts"
        component={ContactsScreen}
        options={{ title: 'Customers & Suppliers' }}
      />
      <Stack.Screen
        name="Notifications"
        component={NotificationsScreen}
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="Settings"
        component={SettingsScreen}
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="PlatformWorkflow"
        component={PlatformWorkflowScreen}
        options={{ headerShown: false }}
      />
      <Stack.Screen
        name="GlobalSearch"
        component={GlobalSearchScreen}
        options={{ title: 'Global Search' }}
      />
      <Stack.Screen
        name="ActivityHistory"
        component={ActivityHistoryScreen}
        options={{ headerShown: false }}
      />
    </Stack.Navigator>
  );
}
