import { createNativeStackNavigator } from '@react-navigation/native-stack';
import type { NativeStackScreenProps } from '@react-navigation/native-stack';
import { Ionicons } from '@expo/vector-icons';
import { Text } from 'react-native';
import { ListRow } from '../components/common/ListRow';
import { Screen } from '../components/common/Screen';
import { ActivityHistoryScreen } from '../screens/activity/ActivityHistoryScreen';
import { DispatchScreen } from '../screens/dispatch/DispatchScreen';
import { FinishedGoodsScreen } from '../screens/finishedGoods/FinishedGoodsScreen';
import { MaintenanceDetailScreen } from '../screens/maintenance/MaintenanceDetailScreen';
import { MaintenanceScreen } from '../screens/maintenance/MaintenanceScreen';
import { MaterialDetailScreen } from '../screens/materials/MaterialDetailScreen';
import { MaterialsScreen } from '../screens/materials/MaterialsScreen';
import { ProductBomScreen } from '../screens/materials/ProductBomScreen';
import { ProductCreateScreen } from '../screens/materials/ProductCreateScreen';
import { ProductEditScreen } from '../screens/materials/ProductEditScreen';
import { ProductListScreen } from '../screens/products/ProductListScreen';
import { NotificationsScreen } from '../screens/notifications/NotificationsScreen';
import { ReportsScreen } from '../screens/reports/ReportsScreen';

import { DispatchCreateScreen } from '../screens/dispatch/DispatchCreateScreen';
const OeeScreen = ReportsScreen as any;
import { GlobalSearchScreen } from '../screens/search/GlobalSearchScreen';
import { SettingsScreen } from '../screens/settings/SettingsScreen';
import { PlatformWorkflowScreen } from '../screens/settings/PlatformWorkflowScreen';
import { typography } from '../theme';
import type { MoreStackParamList } from './types';

const Stack = createNativeStackNavigator<MoreStackParamList>();

const MENU: {
  label: string;
  subtitle: string;
  icon: keyof typeof Ionicons.glyphMap;
  nav: (n: NativeStackScreenProps<MoreStackParamList, 'MoreMenu'>['navigation']) => void;
}[] = [
  {
    label: 'Maintenance',
    subtitle: 'Work orders & PM',
    icon: 'build-outline',
    nav: (n) => n.navigate('Maintenance'),
  },
  {
    label: 'Products',
    subtitle: 'Catalog & BOM',
    icon: 'pricetags-outline',
    nav: (n) => n.navigate('Products'),
  },
  {
    label: 'Materials',
    subtitle: 'Stock & receive/issue',
    icon: 'cube-outline',
    nav: (n) => n.navigate('Materials'),
  },
  {
    label: 'Finished goods',
    subtitle: 'Available inventory',
    icon: 'archive-outline',
    nav: (n) => n.navigate('FinishedGoods'),
  },
  {
    label: 'Dispatch',
    subtitle: 'Shipments',
    icon: 'car-outline',
    nav: (n) => n.navigate('Dispatch'),
  },
  {
    label: 'Reports',
    subtitle: 'Export & OEE',
    icon: 'bar-chart-outline',
    nav: (n) => n.navigate('Reports'),
  },
  {
    label: 'Activity & tasks',
    subtitle: 'Handle open work',
    icon: 'list-outline',
    nav: (n) => n.navigate('ActivityHistory'),
  },
  {
    label: 'Settings',
    subtitle: 'Search & reset',
    icon: 'settings-outline',
    nav: (n) => n.navigate('Settings'),
  },
];

function MoreMenuScreen({ navigation }: NativeStackScreenProps<MoreStackParamList, 'MoreMenu'>) {
  return (
    <Screen scroll>
      <Text style={typography.h2}>More modules</Text>
      {MENU.map((item) => (
        <ListRow
          key={item.label}
          title={item.label}
          subtitle={item.subtitle}
          onPress={() => item.nav(navigation)}
        />
      ))}
    </Screen>
  );
}

const stackScreenOptions = {
  headerShadowVisible: false,
};

export function MoreStackNavigator() {
  return (
    <Stack.Navigator screenOptions={stackScreenOptions}>
      <Stack.Screen name="MoreMenu" component={MoreMenuScreen} options={{ title: 'More' }} />
      <Stack.Screen name="Maintenance" component={MaintenanceScreen} />
      <Stack.Screen name="MaintenanceDetail" component={MaintenanceDetailScreen} />
      <Stack.Screen name="Products" component={ProductListScreen} options={{ title: 'Products' }} />
      <Stack.Screen name="Materials" component={MaterialsScreen} />
      <Stack.Screen name="MaterialDetail" component={MaterialDetailScreen} options={{ title: 'Material' }} />
      <Stack.Screen
        name="ProductBom"
        component={ProductBomScreen}
        options={{ title: 'Material per product' }}
      />
      <Stack.Screen
        name="ProductCreate"
        component={ProductCreateScreen}
        options={{ title: 'New product' }}
      />
      <Stack.Screen
        name="ProductEdit"
        component={ProductEditScreen}
        options={{ title: 'Edit product' }}
      />
      <Stack.Screen name="FinishedGoods" component={FinishedGoodsScreen} options={{ title: 'Finished goods' }} />
      <Stack.Screen name="Dispatch" component={DispatchScreen} />
      <Stack.Screen name="DispatchCreate" component={DispatchCreateScreen} options={{ title: 'New dispatch' }} />
      <Stack.Screen name="Reports" component={ReportsScreen} />
      <Stack.Screen name="Oee" component={OeeScreen} options={{ title: 'OEE' }} />
      <Stack.Screen name="Settings" component={SettingsScreen} />
      <Stack.Screen name="GlobalSearch" component={GlobalSearchScreen} options={{ title: 'Search' }} />
      <Stack.Screen name="Notifications" component={NotificationsScreen} />
      <Stack.Screen name="ActivityHistory" component={ActivityHistoryScreen} options={{ title: 'Activity' }} />
      <Stack.Screen name="PlatformWorkflow" component={PlatformWorkflowScreen} options={{ headerShown: false }} />
    </Stack.Navigator>
  );
}
