import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { DashboardScreen } from '../screens/dashboard/DashboardScreen';
import { ActivityHistoryScreen } from '../screens/activity/ActivityHistoryScreen';
import { ManagementScreen } from '../screens/management/ManagementScreen';
import { SettingsScreen } from '../screens/settings/SettingsScreen';
import type { RootTabParamList } from './types';
import { useThemeStore } from '../store/themeStore';
import { useTranslation } from '../store/languageStore';

const Tab = createBottomTabNavigator<RootTabParamList>();

type IconName = keyof typeof Ionicons.glyphMap;

export function RootTabs() {
  const isDark = useThemeStore((s) => s.isDark);
  const themeColors = useThemeStore((s) => s.colors);
  const { language, t } = useTranslation();

  const tabIcon = (name: IconName, focused: boolean) => (
    <Ionicons
      name={name}
      size={22}
      color={focused ? themeColors.primary : themeColors.textMuted}
    />
  );

  return (
    <Tab.Navigator
      key={`tabs-${language}-${isDark ? 'dark' : 'light'}`}
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: themeColors.primary,
        tabBarInactiveTintColor: themeColors.textMuted,
        tabBarStyle: {
          backgroundColor: isDark ? '#0F172A' : '#FFFFFF',
          borderTopColor: isDark ? '#1E293B' : themeColors.border,
          borderTopWidth: 1,
          height: 64,
          paddingBottom: 10,
          paddingTop: 8,
          shadowColor: '#000000',
          shadowOffset: { width: 0, height: -2 },
          shadowOpacity: isDark ? 0.3 : 0.04,
          shadowRadius: 6,
          elevation: 6,
        },
        tabBarLabelStyle: {
          fontSize: 11,
          fontWeight: '700',
          letterSpacing: 0.2,
        },
      }}
    >
      <Tab.Screen
        name="Home"
        component={DashboardScreen}
        options={{
          title: t('tabHome'),
          tabBarLabel: t('tabHome'),
          tabBarIcon: ({ focused }) => tabIcon(focused ? 'home' : 'home-outline', focused),
        }}
      />
      <Tab.Screen
        name="MyTasks"
        component={ActivityHistoryScreen}
        options={{
          title: t('tabTasks'),
          tabBarLabel: t('tabTasks'),
          tabBarIcon: ({ focused }) =>
            tabIcon(focused ? 'checkbox' : 'checkbox-outline', focused),
        }}
      />
      <Tab.Screen
        name="Management"
        component={ManagementScreen}
        options={{
          title: t('tabManagement'),
          tabBarLabel: t('tabManagement'),
          tabBarIcon: ({ focused }) =>
            tabIcon(focused ? 'briefcase' : 'briefcase-outline', focused),
        }}
      />
      <Tab.Screen
        name="Profile"
        component={SettingsScreen}
        options={{
          title: t('tabProfile'),
          tabBarLabel: t('tabProfile'),
          tabBarIcon: ({ focused }) =>
            tabIcon(focused ? 'person' : 'person-outline', focused),
        }}
      />
    </Tab.Navigator>
  );
}
