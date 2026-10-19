import { Ionicons } from '@expo/vector-icons';
import { useNavigation } from '@react-navigation/native';
import { useCallback, useMemo, useState } from 'react';
import {
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { AppHeader } from '../../components/common/AppHeader';
import { listCustomers } from '../../database/repositories/customerRepository';
import { listDispatchOrders } from '../../database/repositories/dispatchRepository';
import { listMachines } from '../../database/repositories/machineRepository';
import { listMaterials } from '../../database/repositories/materialRepository';
import { countUnreadNotifications } from '../../database/repositories/notificationRepository';
import { listProducts } from '../../database/repositories/productRepository';
import { listProductionOrders } from '../../database/repositories/productionOrderRepository';
import { listPurchaseRequests } from '../../database/repositories/purchaseRepository';
import { listStaff } from '../../database/repositories/staffRepository';
import { listSuppliers } from '../../database/repositories/supplierRepository';
import { useLiveQuery } from '../../hooks/useLiveQuery';
import { useAuthStore } from '../../store/authStore';
import { useThemeStore } from '../../store/themeStore';
import { useTranslation } from '../../store/languageStore';
import { colors } from '../../theme';

type ManagementModule = {
  id: string;
  category: 'operations' | 'admin';
  title: string;
  subtitle: string;
  icon: keyof typeof Ionicons.glyphMap;
  color: string;
  bgColor: string;
  route: string;
  requiredPermission?: string;
  badge?: string;
  badgeColor?: string;
};

export function ManagementScreen() {
  const navigation = useNavigation<any>();
  const hasPermission = useAuthStore((s) => s.hasPermission);
  const isDark = useThemeStore((s) => s.isDark);
  const themeColors = useThemeStore((s) => s.colors);
  const { t } = useTranslation();
  const [refreshing, setRefreshing] = useState(false);

  // Live counters for badges & KPI bar
  const [pendingRequests, setPendingRequests] = useState(0);
  const [staffCount, setStaffCount] = useState(0);
  const [unreadAlerts, setUnreadAlerts] = useState(0);
  const [readyDispatches, setReadyDispatches] = useState(0);
  const [contactsCount, setContactsCount] = useState(0);
  const [activeOrdersCount, setActiveOrdersCount] = useState(0);
  const [lowStockCount, setLowStockCount] = useState(0);
  const [machineAlertsCount, setMachineAlertsCount] = useState(0);
  const [productsCount, setProductsCount] = useState(0);

  const loadData = useCallback(async () => {
    try {
      setRefreshing(true);
      const [
        requests,
        staff,
        unread,
        dispatches,
        customers,
        suppliers,
        orders,
        lowStock,
        machines,
        products,
      ] = await Promise.all([
        listPurchaseRequests('PENDING').catch(() => []),
        listStaff().catch(() => []),
        countUnreadNotifications().catch(() => 0),
        listDispatchOrders().catch(() => []),
        listCustomers().catch(() => []),
        listSuppliers().catch(() => []),
        listProductionOrders().catch(() => []),
        listMaterials({ lowStockOnly: true }).catch(() => []),
        listMachines().catch(() => []),
        listProducts().catch(() => []),
      ]);

      setPendingRequests(requests.length);
      setStaffCount(staff.length);
      setUnreadAlerts(unread);
      setReadyDispatches(
        dispatches.filter((d: any) => d.status === 'READY').length,
      );
      setContactsCount(customers.length + suppliers.length);

      const activeOrders = orders.filter(
        (o: any) =>
          o.status === 'PENDING' ||
          o.status === 'IN_PROGRESS' ||
          o.status === 'DELAYED',
      );
      setActiveOrdersCount(activeOrders.length);
      setLowStockCount(lowStock.length);

      const alertMachines = machines.filter(
        (m: any) => m.status === 'BREAKDOWN' || m.status === 'MAINTENANCE',
      );
      setMachineAlertsCount(alertMachines.length);
      setProductsCount(products.length);
    } finally {
      setRefreshing(false);
    }
  }, []);

  useLiveQuery(loadData);

  const allModules: ManagementModule[] = useMemo(() => [
    // ------------------------------------------------------------------
    // Operations & Floor Modules
    // ------------------------------------------------------------------
    {
      id: 'orders',
      category: 'operations',
      title: t('productionOrders'),
      subtitle: t('productionOrdersSub'),
      icon: 'document-text-outline',
      color: '#0284C7',
      bgColor: '#EFF6FF',
      route: 'ProductionOrders',
      requiredPermission: 'home_production_orders',
      badge: activeOrdersCount > 0 ? `${activeOrdersCount} active` : undefined,
      badgeColor: colors.primary,
    },
    {
      id: 'floor',
      category: 'operations',
      title: t('productionFloor'),
      subtitle: t('productionFloorSub'),
      icon: 'construct-outline',
      color: '#16A34A',
      bgColor: '#ECFDF5',
      route: 'ProductionFloor',
      requiredPermission: 'home_production_floor',
    },
    {
      id: 'stock',
      category: 'operations',
      title: t('stockInventory'),
      subtitle: t('stockInventorySub'),
      icon: 'cube-outline',
      color: '#EA580C',
      bgColor: '#FFFBEB',
      route: 'StockHome',
      requiredPermission: 'home_stock',
      badge: lowStockCount > 0 ? `${lowStockCount} low` : undefined,
      badgeColor: colors.danger,
    },
    {
      id: 'machines',
      category: 'operations',
      title: t('machinesTelemetry'),
      subtitle: t('machinesTelemetrySub'),
      icon: 'settings-outline',
      color: '#DB2777',
      bgColor: '#FDF2F8',
      route: 'MachineList',
      requiredPermission: 'home_machines',
      badge: machineAlertsCount > 0 ? `${machineAlertsCount} alerts` : undefined,
      badgeColor: colors.warning,
    },
    {
      id: 'quality',
      category: 'operations',
      title: t('qualityControl'),
      subtitle: t('qualityControlSub'),
      icon: 'clipboard-outline',
      color: '#0284C7',
      bgColor: '#EFF6FF',
      route: 'QualityDashboard',
      requiredPermission: 'home_quality',
    },
    {
      id: 'reports',
      category: 'operations',
      title: t('reports'),
      subtitle: t('reportsSub'),
      icon: 'bar-chart-outline',
      color: '#2563EB',
      bgColor: '#EFF6FF',
      route: 'Reports',
      requiredPermission: 'mgmt_reports',
    },
    {
      id: 'rework',
      category: 'operations',
      title: t('reworkDefects'),
      subtitle: t('reworkDefectsSub'),
      icon: 'refresh-outline',
      color: '#D84315',
      bgColor: '#FBE9E7',
      route: 'ReworkList',
      requiredPermission: 'home_quality',
    },
    {
      id: 'maintenance',
      category: 'operations',
      title: t('machineMaintenance'),
      subtitle: t('machineMaintenanceSub'),
      icon: 'build-outline',
      color: '#5D4037',
      bgColor: '#EFEBE9',
      route: 'Maintenance',
      requiredPermission: 'home_maintenance',
    },
    {
      id: 'products',
      category: 'operations',
      title: t('productsBom'),
      subtitle: t('productsBomSub'),
      icon: 'pricetags-outline',
      color: '#7B1FA2',
      bgColor: '#F3E5F5',
      route: 'Products',
      requiredPermission: 'home_products',
      badge: productsCount > 0 ? `${productsCount} products` : undefined,
      badgeColor: '#7B1FA2',
    },

    // ------------------------------------------------------------------
    // Administration & Management Modules
    // ------------------------------------------------------------------
    {
      id: 'staff',
      category: 'admin',
      title: t('staffShifts'),
      subtitle: t('staffShiftsSub'),
      icon: 'people-outline',
      color: '#7C3AED',
      bgColor: '#F5F3FF',
      route: 'Staff',
      requiredPermission: 'mgmt_staff',
      badge: staffCount > 0 ? `${staffCount} active` : undefined,
      badgeColor: colors.info,
    },
    {
      id: 'purchase',
      category: 'admin',
      title: t('purchaseSuppliers'),
      subtitle: t('purchaseSuppliersSub'),
      icon: 'cart-outline',
      color: '#0284C7',
      bgColor: '#EFF6FF',
      route: 'PurchaseHome',
      requiredPermission: 'mgmt_purchase',
      badge: pendingRequests > 0 ? `${pendingRequests} pending` : undefined,
      badgeColor: colors.warning,
    },
    {
      id: 'materials_store',
      category: 'admin',
      title: t('storesManagement'),
      subtitle: t('storesManagementSub'),
      icon: 'home-outline',
      color: '#DC2626',
      bgColor: '#FEF2F2',
      route: 'Materials',
      requiredPermission: 'home_stock',
    },
    {
      id: 'costing',
      category: 'admin',
      title: t('costingAccounts'),
      subtitle: t('costingAccountsSub'),
      icon: 'cash-outline',
      color: '#7C3AED',
      bgColor: '#F5F3FF',
      route: 'Reports',
      requiredPermission: 'mgmt_reports',
    },
    {
      id: 'contacts',
      category: 'admin',
      title: t('customersContacts'),
      subtitle: t('customersContactsSub'),
      icon: 'business-outline',
      color: '#00695C',
      bgColor: '#E0F2F1',
      route: 'Contacts',
      requiredPermission: 'mgmt_contacts',
      badge: `${contactsCount} contacts`,
      badgeColor: colors.textSecondary,
    },
    {
      id: 'dispatch',
      category: 'admin',
      title: t('dispatchLogistics'),
      subtitle: t('dispatchLogisticsSub'),
      icon: 'car-outline',
      color: '#1565C0',
      bgColor: '#E3F2FD',
      route: 'Dispatch',
      requiredPermission: 'mgmt_dispatch',
      badge: readyDispatches > 0 ? `${readyDispatches} ready` : undefined,
      badgeColor: colors.success,
    },
    {
      id: 'roles',
      category: 'admin',
      title: t('rolesAccess'),
      subtitle: t('rolesAccessSub'),
      icon: 'shield-checkmark-outline',
      color: '#1E40AF',
      bgColor: '#EFF6FF',
      route: 'RolesList',
      requiredPermission: 'mgmt_roles',
    },
    {
      id: 'alerts',
      category: 'admin',
      title: t('alertsNotifications'),
      subtitle: t('alertsNotificationsSub'),
      icon: 'notifications-outline',
      color: '#D32F2F',
      bgColor: '#FFEBEE',
      route: 'Notifications',
      requiredPermission: 'mgmt_alerts',
      badge: unreadAlerts > 0 ? `${unreadAlerts} unread` : undefined,
      badgeColor: colors.danger,
    },
  ], [
    activeOrdersCount,
    lowStockCount,
    machineAlertsCount,
    productsCount,
    staffCount,
    pendingRequests,
    readyDispatches,
    contactsCount,
    t,
    unreadAlerts,
  ]);

  // Permission filtering
  const authorizedModules = useMemo(
    () => allModules.filter((m) => !m.requiredPermission || hasPermission(m.requiredPermission)),
    [allModules, hasPermission],
  );

  const operationsModules = useMemo(
    () => authorizedModules.filter((m) => m.category === 'operations'),
    [authorizedModules],
  );
  const adminModules = useMemo(
    () => authorizedModules.filter((m) => m.category === 'admin'),
    [authorizedModules],
  );

  const renderModuleCard = (m: ManagementModule) => (
    <Pressable
      key={m.id}
      style={({ pressed }) => [
        styles.gridModuleCard,
        { backgroundColor: themeColors.surface, borderColor: themeColors.border },
        pressed && styles.moduleCardPressed,
      ]}
      onPress={() => navigation.navigate(m.route)}
    >
      <View style={styles.gridCardContent}>
        <View style={[styles.gridIconBox, { backgroundColor: isDark ? '#0F172A' : m.bgColor }]}>
          <Ionicons name={m.icon} size={20} color={m.color} />
        </View>

        <View style={{ flex: 1 }}>
          <Text style={[styles.gridModuleTitle, { color: themeColors.text }]} numberOfLines={1}>
            {m.title}
          </Text>
          <Text style={[styles.gridModuleSubtitle, { color: themeColors.textSecondary }]} numberOfLines={2}>
            {m.subtitle}
          </Text>
        </View>

        <Ionicons
          name="chevron-forward"
          size={14}
          color="#94A3B8"
          style={{ marginLeft: 2 }}
        />
      </View>
    </Pressable>
  );

  return (
    <View style={[styles.screen, { backgroundColor: themeColors.background }]}>
      <AppHeader />
      <ScrollView
        style={styles.container}
        contentContainerStyle={styles.content}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={loadData}
            tintColor={colors.primary}
          />
        }
      >
        {/* Quick KPI summary bar (4 columns) */}
        <View style={[styles.kpiBar, { backgroundColor: themeColors.surface, borderColor: themeColors.border }]}>
          <Pressable
            style={styles.kpiItem}
            onPress={() => navigation.navigate('ProductionOrders', { viewOnly: true })}
          >
            <View style={[styles.kpiIconRound, { backgroundColor: isDark ? '#1E3A8A' : '#EFF6FF' }]}>
              <Ionicons name="document-text" size={15} color="#0284C7" />
            </View>
            <Text style={[styles.kpiValue, { color: themeColors.text }]}>{activeOrdersCount}</Text>
            <Text style={[styles.kpiLabel, { color: themeColors.textSecondary }]}>{t('orders')}</Text>
          </Pressable>

          <View style={[styles.kpiDivider, { backgroundColor: themeColors.border }]} />

          <Pressable
            style={styles.kpiItem}
            onPress={() => navigation.navigate('PurchaseHome', { viewOnly: true })}
          >
            <View style={[styles.kpiIconRound, { backgroundColor: isDark ? '#78350F' : '#FFFBEB' }]}>
              <Ionicons name="time" size={15} color="#EA580C" />
            </View>
            <Text style={[styles.kpiValue, { color: themeColors.text }]}>{pendingRequests}</Text>
            <Text style={[styles.kpiLabel, { color: themeColors.textSecondary }]}>{t('pendingPos')}</Text>
          </Pressable>

          <View style={[styles.kpiDivider, { backgroundColor: themeColors.border }]} />

          <Pressable
            style={styles.kpiItem}
            onPress={() => navigation.navigate('Staff', { viewOnly: true })}
          >
            <View style={[styles.kpiIconRound, { backgroundColor: isDark ? '#064E3B' : '#ECFDF5' }]}>
              <Ionicons name="people" size={15} color="#16A34A" />
            </View>
            <Text style={[styles.kpiValue, { color: themeColors.text }]}>{staffCount}</Text>
            <Text style={[styles.kpiLabel, { color: themeColors.textSecondary }]}>{t('staff')}</Text>
          </Pressable>

          <View style={[styles.kpiDivider, { backgroundColor: themeColors.border }]} />

          <Pressable
            style={styles.kpiItem}
            onPress={() => navigation.navigate('MyTasks')}
          >
            <View style={[styles.kpiIconRound, { backgroundColor: isDark ? '#7F1D1D' : '#FEF2F2' }]}>
              <Ionicons name="notifications" size={15} color="#DC2626" />
            </View>
            <Text style={[styles.kpiValue, { color: '#DC2626' }]}>{unreadAlerts}</Text>
            <Text style={[styles.kpiLabel, { color: themeColors.textSecondary }]}>{t('alerts')}</Text>
          </Pressable>
        </View>

        {/* Modules List View */}
        <View style={{ gap: 16 }}>
          {/* Group 1: Operations & Floor */}
          {operationsModules.length > 0 && (
            <View style={styles.groupSection}>
              <View style={styles.groupHeaderRow}>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                  <Ionicons name="construct" size={15} color="#2563EB" />
                  <Text style={[styles.groupHeaderTitle, { color: themeColors.text }]}>{t('operationsFloor')}</Text>
                </View>
                <View style={styles.moduleCountRow}>
                  <Text style={[styles.groupHeaderBadge, { color: themeColors.textSecondary }]}>{operationsModules.length} {t('modulesCount')}</Text>
                  <Ionicons name="chevron-forward" size={13} color="#94A3B8" />
                </View>
              </View>
              <View style={styles.modulesGrid}>
                {operationsModules.map(renderModuleCard)}
              </View>
            </View>
          )}

          {/* Group 2: Administration */}
          {adminModules.length > 0 && (
            <View style={styles.groupSection}>
              <View style={styles.groupHeaderRow}>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6 }}>
                  <Ionicons name="people" size={15} color="#2563EB" />
                  <Text style={[styles.groupHeaderTitle, { color: themeColors.text }]}>{t('administration')}</Text>
                </View>
                <View style={styles.moduleCountRow}>
                  <Text style={[styles.groupHeaderBadge, { color: themeColors.textSecondary }]}>{adminModules.length} {t('modulesCount')}</Text>
                  <Ionicons name="chevron-forward" size={13} color="#94A3B8" />
                </View>
              </View>
              <View style={styles.modulesGrid}>
                {adminModules.map(renderModuleCard)}
              </View>
            </View>
          )}
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  container: {
    flex: 1,
  },
  content: {
    paddingHorizontal: 16,
    paddingTop: 14,
    paddingBottom: 40,
  },
  /* Top 4 KPI bar */
  kpiBar: {
    flexDirection: 'row',
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    paddingVertical: 12,
    paddingHorizontal: 8,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    alignItems: 'center',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.04,
    shadowRadius: 3,
    elevation: 1.5,
  },
  kpiItem: {
    flex: 1,
    alignItems: 'center',
  },
  kpiIconRound: {
    width: 26,
    height: 26,
    borderRadius: 13,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: 4,
  },
  kpiValue: {
    fontSize: 16,
    fontWeight: '800',
    color: '#0F172A',
  },
  kpiLabel: {
    fontSize: 10,
    fontWeight: '600',
    color: '#64748B',
    marginTop: 1,
  },
  kpiDivider: {
    width: 1,
    height: 28,
    backgroundColor: '#E2E8F0',
  },

  /* Groups & Grids */
  groupSection: {
    gap: 8,
  },
  groupHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 2,
    marginBottom: 2,
  },
  groupHeaderTitle: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0F172A',
  },
  moduleCountRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
  groupHeaderBadge: {
    fontSize: 11,
    fontWeight: '600',
    color: '#64748B',
  },
  modulesGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  gridModuleCard: {
    width: '48.7%',
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    padding: 10,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.03,
    shadowRadius: 3,
    elevation: 1,
  },
  gridCardContent: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  gridIconBox: {
    width: 36,
    height: 36,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  gridModuleTitle: {
    fontSize: 12.5,
    fontWeight: '800',
    color: '#0F172A',
    marginBottom: 2,
  },
  gridModuleSubtitle: {
    fontSize: 10,
    color: '#64748B',
    lineHeight: 13,
  },
  moduleCardPressed: {
    backgroundColor: '#F1F5F9',
    transform: [{ scale: 0.985 }],
  },
});
