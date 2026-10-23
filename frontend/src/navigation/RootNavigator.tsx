import { NavigationContainer } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { ActivityHistoryScreen } from '../screens/activity/ActivityHistoryScreen';
import { ContactsScreen } from '../screens/contacts/ContactsScreen';
import { DispatchScreen } from '../screens/dispatch/DispatchScreen';
import { FinishedGoodsScreen } from '../screens/finishedGoods/FinishedGoodsScreen';
import { MachineDetailScreen } from '../screens/machines/MachineDetailScreen';
import { MachineListScreen } from '../screens/machines/MachineListScreen';
import { MaintenanceDetailScreen } from '../screens/maintenance/MaintenanceDetailScreen';
import { MaintenanceScreen } from '../screens/maintenance/MaintenanceScreen';
import { ManagementScreen } from '../screens/management/ManagementScreen';
import { MaterialDetailScreen } from '../screens/materials/MaterialDetailScreen';
import { MaterialsScreen } from '../screens/materials/MaterialsScreen';
import { ProductBomScreen } from '../screens/materials/ProductBomScreen';
import { ProductCreateScreen } from '../screens/materials/ProductCreateScreen';
import { ProductEditScreen } from '../screens/materials/ProductEditScreen';
import { NotificationsScreen } from '../screens/notifications/NotificationsScreen';
import { FirstLaunchScreen } from '../screens/onboarding/FirstLaunchScreen';
import { ProductionFloorScreen } from '../screens/production/ProductionFloorScreen';
import { ProductionHubScreen } from '../screens/production/ProductionHubScreen';
import { ProductionOrderCreateScreen } from '../screens/production/ProductionOrderCreateScreen';
import { ProductionOrderDetailScreen } from '../screens/production/ProductionOrderDetailScreen';
import { ProductionOrdersScreen } from '../screens/production/ProductionOrdersScreen';
import { ProductionPlanCreateScreen } from '../screens/production/ProductionPlanCreateScreen';
import { ProductionPlanDetailScreen } from '../screens/production/ProductionPlanDetailScreen';
import { ProductionPlansScreen } from '../screens/production/ProductionPlansScreen';
import { RecordProductionScreen } from '../screens/production/RecordProductionScreen';
import { ProductListScreen } from '../screens/products/ProductListScreen';
import { PurchaseHomeScreen } from '../screens/purchase/PurchaseHomeScreen';
import { InspectionCreateScreen } from '../screens/quality/InspectionCreateScreen';
import { QualityDashboardScreen } from '../screens/quality/QualityDashboardScreen';
import { ReportsScreen } from '../screens/reports/ReportsScreen';

import { DispatchCreateScreen } from '../screens/dispatch/DispatchCreateScreen';
const ReportBreakdownScreen = MachineDetailScreen as any;
const ReworkListScreen = QualityDashboardScreen as any;
const OeeScreen = ReportsScreen as any;
import { GlobalSearchScreen } from '../screens/search/GlobalSearchScreen';
import { SettingsScreen } from '../screens/settings/SettingsScreen';
import { PlatformWorkflowScreen } from '../screens/settings/PlatformWorkflowScreen';
import { RolesScreen } from '../screens/management/RolesScreen';
import { StaffScreen } from '../screens/staff/StaffScreen';
import { StockHomeScreen } from '../screens/stock/StockHomeScreen';
import { LoginScreen } from '../screens/auth/LoginScreen';
import { useAuthStore } from '../store/authStore';
import { useThemeStore } from '../store/themeStore';
import { Ionicons } from '@expo/vector-icons';
import { Pressable, Text } from 'react-native';
import { RootTabs } from './RootTabs';
import type { RootStackParamList } from './types';

const Stack = createNativeStackNavigator<RootStackParamList>();

export function RootNavigator() {
  const onboardingComplete = useThemeStore((s) => s.onboardingComplete);
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const previewRole = useAuthStore((s) => s.previewRole);
  const previewStaff = useAuthStore((s) => s.previewStaff);
  const exitPreview = useAuthStore((s) => s.exitPreview);
  const isPreviewing = Boolean(previewRole || previewStaff);

  if (!onboardingComplete) {
    return (
      <NavigationContainer>
        <Stack.Navigator screenOptions={{ headerShadowVisible: false }}>
          <Stack.Screen name="FirstLaunch" options={{ headerShown: false }}>
            {() => (
              <FirstLaunchScreen
                onExplore={() => {
                  useThemeStore.getState().completeOnboarding();
                }}
              />
            )}
          </Stack.Screen>
        </Stack.Navigator>
      </NavigationContainer>
    );
  }

  if (!isAuthenticated) {
    return (
      <NavigationContainer>
        <Stack.Navigator screenOptions={{ headerShadowVisible: false }}>
          <Stack.Screen
            name="Login"
            component={LoginScreen}
            options={{ headerShown: false }}
          />
        </Stack.Navigator>
      </NavigationContainer>
    );
  }

  return (
    <NavigationContainer>
      <Stack.Navigator
        screenOptions={{
          headerShadowVisible: false,
          headerRight: isPreviewing
            ? () => (
                <Pressable
                  style={{
                    flexDirection: 'row',
                    alignItems: 'center',
                    gap: 4,
                    backgroundColor: '#DC2626',
                    paddingHorizontal: 8,
                    paddingVertical: 5,
                    borderRadius: 6,
                  }}
                  onPress={exitPreview}
                >
                  <Ionicons name="close-circle" size={13} color="#FFFFFF" />
                  <Text style={{ color: '#FFFFFF', fontSize: 11, fontWeight: '800' }}>
                    Exit Preview
                  </Text>
                </Pressable>
              )
            : undefined,
        }}
      >
        <Stack.Screen
          name="Main"
          component={RootTabs}
          options={{ headerShown: false }}
        />

        {/* Feature & Detail screens accessible from any Tab */}
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
          options={{ title: 'Production Floor' }}
        />
        <Stack.Screen
          name="RecordProduction"
          component={RecordProductionScreen}
          options={{ title: 'Daily Output Entry' }}
        />
        <Stack.Screen
          name="ProductionHub"
          component={ProductionHubScreen}
          options={{ title: 'Production Hub' }}
        />
        <Stack.Screen
          name="ProductionPlans"
          component={ProductionPlansScreen}
          options={{ title: 'Production Plans' }}
        />
        <Stack.Screen
          name="ProductionPlanCreate"
          component={ProductionPlanCreateScreen}
          options={{ title: 'New Plan' }}
        />
        <Stack.Screen
          name="ProductionPlanDetail"
          component={ProductionPlanDetailScreen}
          options={{ title: 'Plan Details' }}
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
          name="Products"
          component={ProductListScreen}
          options={{ title: 'Products Catalog' }}
        />
        <Stack.Screen
          name="ProductBom"
          component={ProductBomScreen}
          options={{ title: 'Bill of Materials' }}
        />
        <Stack.Screen
          name="ProductCreate"
          component={ProductCreateScreen}
          options={{ title: 'New Product' }}
        />
        <Stack.Screen
          name="ProductEdit"
          component={ProductEditScreen}
          options={{ title: 'Edit Product' }}
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
          name="Maintenance"
          component={MaintenanceScreen}
          options={{ title: 'Maintenance Orders' }}
        />
        <Stack.Screen
          name="MaintenanceDetail"
          component={MaintenanceDetailScreen}
          options={{ title: 'Maintenance Detail' }}
        />
        <Stack.Screen
          name="FinishedGoods"
          component={FinishedGoodsScreen}
          options={{ title: 'Finished Goods Inventory' }}
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
          name="GlobalSearch"
          component={GlobalSearchScreen}
          options={{ title: 'Global Search' }}
        />
        <Stack.Screen
          name="Management"
          component={ManagementScreen}
          options={{ headerShown: false }}
        />
        <Stack.Screen
          name="ActivityHistory"
          component={ActivityHistoryScreen}
          options={{ headerShown: false }}
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
          name="RolesList"
          component={RolesScreen}
          options={{ title: 'Roles & Access Permissions' }}
        />
        <Stack.Screen
          name="PlatformWorkflow"
          component={PlatformWorkflowScreen}
          options={{ headerShown: false }}
        />
      </Stack.Navigator>
    </NavigationContainer>
  );
}
