import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/common.dart';
import '../../models/dashboard.dart';
import '../../models/machine.dart';
import '../../models/production.dart';
import '../../widgets/shimmers/index.dart';

class ManagementScreen extends ConsumerStatefulWidget {
  const ManagementScreen({super.key});

  @override
  ConsumerState<ManagementScreen> createState() => _ManagementScreenState();
}

class _ManagementScreenState extends ConsumerState<ManagementScreen> {
  // Live KPI counters for dynamic badge indicators
  int _activeOrdersCount = 0;
  int _machineAlertsCount = 0;
  int _lowStockCount = 0;
  int _staffCount = 0;
  int _pendingPurchasesCount = 0;
  int _readyDispatchesCount = 0;
  int _contactsCount = 0;
  int _unreadAlertsCount = 0;
  int _productsCount = 0;
  int _bomsCount = 0;
  int _finishedGoodsCount = 0;
  int _finishedGoodsReadyQty = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadModuleKpis();
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(dashboardProvider);
    await _loadModuleKpis();
  }

  Future<void> _loadModuleKpis() async {
    try {
      final api = ref.read(apiServiceProvider);

      final results = await Future.wait([
        api.listProductionOrders(limit: 100).catchError((_) => const PaginatedResponse<ProductionOrder>(
          data: [],
          pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false),
        )),
        api.listMachines(limit: 100).catchError((_) => const PaginatedResponse<Machine>(
          data: [],
          pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false),
        )),
        api.getCollection('materials', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(
          data: [],
          pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false),
        )),
        api.getCollection('staff', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(
          data: [],
          pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false),
        )),
        api.getCollection('purchase_orders', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(
          data: [],
          pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false),
        )),
        api.getCollection('dispatch_orders', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(
          data: [],
          pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false),
        )),
        api.getCollection('notifications', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(
          data: [],
          pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false),
        )),
        api.getCollection('products', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(
          data: [],
          pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false),
        )),
        api.getCollection('customers', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(
          data: [],
          pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false),
        )),
        api.getCollection('finished_goods', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(
          data: [],
          pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false),
        )),
        api.getCollection('bom_items', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(
          data: [],
          pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false),
        )),
      ]);

      final orders = (results[0] as PaginatedResponse<ProductionOrder>).data;
      final machines = (results[1] as PaginatedResponse<Machine>).data;
      final materials = (results[2] as PaginatedResponse<Map<String, dynamic>>).data;
      final staff = (results[3] as PaginatedResponse<Map<String, dynamic>>).data;
      final purchases = (results[4] as PaginatedResponse<Map<String, dynamic>>).data;
      final dispatches = (results[5] as PaginatedResponse<Map<String, dynamic>>).data;
      final notifs = (results[6] as PaginatedResponse<Map<String, dynamic>>).data;
      final products = (results[7] as PaginatedResponse<Map<String, dynamic>>).data;
      final customers = (results[8] as PaginatedResponse<Map<String, dynamic>>).data;
      final finishedGoods = (results[9] as PaginatedResponse<Map<String, dynamic>>).data;
      final bomItems = (results[10] as PaginatedResponse<Map<String, dynamic>>).data;

      if (mounted) {
        setState(() {
          _activeOrdersCount = orders.where((o) {
            final st = o.status.toUpperCase();
            return st == 'PENDING' || st == 'IN_PROGRESS' || st == 'RUNNING';
          }).length;
          _machineAlertsCount = machines.where((m) {
            final st = m.status.toUpperCase();
            return st == 'BREAKDOWN' || st == 'MAINTENANCE';
          }).length;
          _lowStockCount = materials.where((m) {
            final cur = ((m['current_stock'] ?? m['currentStock'] ?? 0) as num).toDouble();
            final min = ((m['minimum_stock'] ?? m['minimumStock'] ?? 0) as num).toDouble();
            return min > 0 && cur <= min;
          }).length;
          _staffCount = staff.length;
          _pendingPurchasesCount = purchases.where((p) => (p['status'] ?? '').toString().toUpperCase() == 'PENDING').length;
          _readyDispatchesCount = dispatches.where((d) => (d['status'] ?? '').toString().toUpperCase() == 'READY').length;
          _unreadAlertsCount = notifs.where((n) => (n['is_read'] ?? 0) == 0).length;
          _productsCount = products.length;
          _bomsCount = bomItems.length;
          _contactsCount = customers.length;
          _finishedGoodsCount = finishedGoods.length;
          _finishedGoodsReadyQty = finishedGoods.fold<num>(0, (sum, fg) => sum + ((fg['available_quantity'] ?? fg['availableQuantity'] ?? 0) as num)).toInt();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.headerNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: 'Back',
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text(
          'Management Hub',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // KPI Summary Row (4 metric columns)
            if (dashboardAsync.isLoading && !dashboardAsync.hasValue)
              const ShimmerKpiRow(padding: EdgeInsets.zero)
            else
              _buildKpiSummaryBar(context, dashboardAsync.valueOrNull, isDark),
            const SizedBox(height: 18),

            // Section 1: Operations & Floor
            _buildSectionHeader(
              context,
              title: 'Operations & Floor',
              subtitle: 'Shop floor execution, tracking & quality',
              icon: Icons.factory_outlined,
              badgeText: '12 Modules',
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildModuleGrid(context, [
              _ModuleItem(
                id: 'orders',
                title: 'Production Orders',
                subtitle: 'Customer & work orders tracking',
                icon: Icons.assignment_outlined,
                color: AppColors.moduleOrders,
                bgColor: AppColors.moduleOrdersBg,
                route: '/production/orders',
                badge: _activeOrdersCount > 0 ? '$_activeOrdersCount Active' : 'Active',
                badgeColor: AppColors.moduleOrders,
                permissionKey: 'home_orders',
              ),
              const _ModuleItem(
                id: 'floor',
                title: 'Production Floor',
                subtitle: 'Live line status & logging',
                icon: Icons.precision_manufacturing_outlined,
                color: AppColors.moduleFloor,
                bgColor: AppColors.moduleFloorBg,
                route: '/production/floor',
                badge: 'Live',
                badgeColor: AppColors.moduleFloor,
                permissionKey: 'home_production',
              ),
              const _ModuleItem(
                id: 'plans',
                title: 'Production Plans',
                subtitle: 'Monthly targets & line scheduling',
                icon: Icons.calendar_month_outlined,
                color: AppColors.modulePlans,
                bgColor: AppColors.modulePlansBg,
                route: '/production/plans',
                badge: 'Plans',
                badgeColor: AppColors.modulePlans,
                permissionKey: 'home_production',
              ),
              _ModuleItem(
                id: 'stock',
                title: 'Stock Inventory',
                subtitle: 'Raw materials & warehouse stock',
                icon: Icons.inventory_2_outlined,
                color: AppColors.moduleInventory,
                bgColor: AppColors.moduleInventoryBg,
                route: '/inventory/stock',
                badge: _lowStockCount > 0 ? '$_lowStockCount Low' : null,
                badgeColor: AppColors.statusDanger,
                permissionKey: 'home_stock',
              ),
              _ModuleItem(
                id: 'finished_goods',
                title: 'Finished Goods',
                subtitle: 'Warehouse ready stock & QA output',
                icon: Icons.warehouse_outlined,
                color: AppColors.moduleFinishedGoods,
                bgColor: AppColors.moduleFinishedGoodsBg,
                route: '/inventory/finished-goods',
                badge: _finishedGoodsReadyQty > 0
                    ? '$_finishedGoodsReadyQty Ready'
                    : (_finishedGoodsCount > 0 ? '$_finishedGoodsCount Items' : 'Ready'),
                badgeColor: AppColors.moduleFinishedGoods,
                permissionKey: 'home_stock',
              ),
              _ModuleItem(
                id: 'products',
                title: 'Products Catalog',
                subtitle: 'Master catalog, models & finished specs',
                icon: Icons.category_outlined,
                color: AppColors.moduleProducts,
                bgColor: AppColors.moduleProductsBg,
                route: '/inventory/products',
                badge: _productsCount > 0 ? '$_productsCount Items' : null,
                badgeColor: AppColors.moduleProducts,
                permissionKey: 'home_products',
              ),
              _ModuleItem(
                id: 'bom',
                title: 'Bill of Materials',
                subtitle: 'Recipe matrix, raw ratios & unit formulas',
                icon: Icons.hub_outlined,
                color: AppColors.moduleBOM,
                bgColor: AppColors.moduleBOMBg,
                route: '/inventory/bom',
                badge: _bomsCount > 0 ? '$_bomsCount Items' : 'BOM Matrix',
                badgeColor: AppColors.moduleBOM,
                permissionKey: 'home_products',
              ),
              const _ModuleItem(
                id: 'quality',
                title: 'Quality Control',
                subtitle: 'Inspections, QA checklists & audits',
                icon: Icons.verified_outlined,
                color: AppColors.moduleQuality,
                bgColor: AppColors.moduleQualityBg,
                route: '/quality/inspections',
                badge: 'Audits',
                badgeColor: AppColors.moduleQuality,
                permissionKey: 'home_quality',
              ),
              _ModuleItem(
                id: 'machines',
                title: 'Machines Telemetry',
                subtitle: 'IoT telemetry & machine health',
                icon: Icons.settings_suggest_outlined,
                color: AppColors.moduleMachines,
                bgColor: AppColors.moduleMachinesBg,
                route: '/machines',
                badge: _machineAlertsCount > 0 ? '$_machineAlertsCount Alerts' : 'Online',
                badgeColor: _machineAlertsCount > 0 ? AppColors.statusDanger : AppColors.statusSuccess,
                permissionKey: 'home_machines',
              ),
              const _ModuleItem(
                id: 'maintenance',
                title: 'Machine Maintenance',
                subtitle: 'Breakdown reports & service schedules',
                icon: Icons.build_outlined,
                color: AppColors.moduleMaintenance,
                bgColor: AppColors.moduleMaintenanceBg,
                route: '/maintenance',
                permissionKey: 'home_maintenance',
              ),
              const _ModuleItem(
                id: 'rework',
                title: 'Rework & Defects',
                subtitle: 'Corrective actions & defect tracking',
                icon: Icons.refresh_outlined,
                color: AppColors.moduleRework,
                bgColor: AppColors.moduleReworkBg,
                route: '/rework',
                permissionKey: 'home_quality',
              ),
              const _ModuleItem(
                id: 'reports',
                title: 'Reports & Analytics',
                subtitle: 'OEE, efficiency & monthly trends',
                icon: Icons.analytics_outlined,
                color: AppColors.moduleReports,
                bgColor: AppColors.moduleReportsBg,
                route: '/reports/production',
                badge: 'OEE',
                badgeColor: AppColors.moduleReports,
                permissionKey: 'mgmt_reports',
              ),
            ]),
            const SizedBox(height: 22),

            // Section 2: Administration & Management
            _buildSectionHeader(
              context,
              title: 'Administration & Management',
              subtitle: 'Workforce, suppliers & logistics',
              icon: Icons.admin_panel_settings_outlined,
              badgeText: '7 Modules',
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _buildModuleGrid(context, [
              _ModuleItem(
                id: 'staff',
                title: 'Staff & Shifts',
                subtitle: 'Operators, rosters & attendance',
                icon: Icons.people_outline,
                color: AppColors.moduleStaff,
                bgColor: AppColors.moduleStaffBg,
                route: '/staff/attendance',
                badge: _staffCount > 0 ? '$_staffCount Staff' : null,
                badgeColor: AppColors.moduleStaff,
                permissionKey: 'mgmt_staff',
              ),
              _ModuleItem(
                id: 'purchase',
                title: 'Purchase & Suppliers',
                subtitle: 'Vendor POs, RFQs & GRN receiving',
                icon: Icons.shopping_cart_outlined,
                color: AppColors.modulePurchase,
                bgColor: AppColors.modulePurchaseBg,
                route: '/purchase/orders',
                badge: _pendingPurchasesCount > 0 ? '$_pendingPurchasesCount Pending' : null,
                badgeColor: AppColors.statusWarning,
                permissionKey: 'mgmt_purchase',
              ),
              const _ModuleItem(
                id: 'costing',
                title: 'Costing & Accounts',
                subtitle: 'Production costing & ledger',
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.moduleCosting,
                bgColor: AppColors.moduleCostingBg,
                route: '/costing',
                permissionKey: 'mgmt_reports',
              ),
              _ModuleItem(
                id: 'contacts',
                title: 'Customers & Contacts',
                subtitle: 'Directory of clients & suppliers',
                icon: Icons.business_outlined,
                color: AppColors.moduleContacts,
                bgColor: AppColors.moduleContactsBg,
                route: '/contacts',
                badge: _contactsCount > 0 ? '$_contactsCount Contacts' : null,
                badgeColor: AppColors.moduleContacts,
                permissionKey: 'mgmt_contacts',
              ),
              _ModuleItem(
                id: 'dispatch',
                title: 'Dispatch & Logistics',
                subtitle: 'Shipments, vehicles & delivery notes',
                icon: Icons.local_shipping_outlined,
                color: AppColors.moduleDispatch,
                bgColor: AppColors.moduleDispatchBg,
                route: '/dispatch/orders',
                badge: _readyDispatchesCount > 0 ? '$_readyDispatchesCount Ready' : null,
                badgeColor: AppColors.statusSuccess,
                permissionKey: 'mgmt_dispatch',
              ),
              const _ModuleItem(
                id: 'roles',
                title: 'Roles & Access',
                subtitle: 'Permissions, company & security',
                icon: Icons.shield_outlined,
                color: AppColors.moduleRoles,
                bgColor: AppColors.moduleRolesBg,
                route: '/roles',
                badge: 'Security',
                badgeColor: AppColors.moduleRoles,
                permissionKey: 'mgmt_roles',
              ),
              _ModuleItem(
                id: 'alerts',
                title: 'Alerts & Notifications',
                subtitle: 'System warnings & audit events',
                icon: Icons.notifications_outlined,
                color: AppColors.moduleAlerts,
                bgColor: AppColors.moduleAlertsBg,
                route: '/settings/notifications',
                badge: _unreadAlertsCount > 0 ? '$_unreadAlertsCount New' : null,
                badgeColor: AppColors.statusDanger,
                permissionKey: 'mgmt_alerts',
              ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP 4 KPI SUMMARY BAR
  // ===========================================================================
  Widget _buildKpiSummaryBar(BuildContext context, DashboardResponse? dashboard, bool isDark) {
    final activeOrdersText = _activeOrdersCount > 0 ? '$_activeOrdersCount' : 'Active';
    final machineBreakdowns = _machineAlertsCount > 0 ? _machineAlertsCount : (dashboard?.machines.breakdown ?? 0);
    final staffPresent = _staffCount > 0 ? _staffCount : (dashboard?.attendance.present ?? 0);
    final pendingTasks = _readyDispatchesCount + _lowStockCount + (dashboard?.pendingTasksCount ?? 0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildKpiItem(
            context,
            icon: Icons.assignment,
            iconColor: const Color(0xFF0284C7),
            bgColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
            label: 'Orders',
            value: activeOrdersText,
            onTap: () => context.push('/production/orders'),
            isDark: isDark,
          ),
          _buildKpiDivider(isDark),
          _buildKpiItem(
            context,
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFDC2626),
            bgColor: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2),
            label: 'Alerts',
            value: '$machineBreakdowns',
            onTap: () => context.push('/machines'),
            isDark: isDark,
          ),
          _buildKpiDivider(isDark),
          _buildKpiItem(
            context,
            icon: Icons.people,
            iconColor: const Color(0xFF16A34A),
            bgColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
            label: 'Present',
            value: '$staffPresent',
            onTap: () => context.push('/staff/attendance'),
            isDark: isDark,
          ),
          _buildKpiDivider(isDark),
          _buildKpiItem(
            context,
            icon: Icons.task_alt,
            iconColor: const Color(0xFF7C3AED),
            bgColor: isDark ? const Color(0xFF4C1D95) : const Color(0xFFF5F3FF),
            label: 'Tasks',
            value: '$pendingTasks',
            onTap: () => context.go('/tasks'),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required String badgeText,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0284C7).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF0284C7)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2-COLUMN KPI-TYPE MODULE GRID (TWO CARDS PER ROW)
  // ===========================================================================
  Widget _buildModuleGrid(BuildContext context, List<_ModuleItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Exactly 2 cards per row on mobile, 3 on tablet, 4 on desktop
        final int crossAxisCount = constraints.maxWidth > 800
            ? 4
            : (constraints.maxWidth > 580 ? 3 : 2);

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisExtent: 112,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildKpiModuleCard(context, item);
          },
        );
      },
    );
  }

  // ===========================================================================
  // KPI-TYPE CARD DESIGN (WITH RBAC PERMISSION ENFORCEMENT)
  // ===========================================================================
  Widget _buildKpiModuleCard(BuildContext context, _ModuleItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveUser = ref.watch(effectiveUserProvider);
    final isAllowed = item.permissionKey == null || effectiveUser.hasPermission(item.permissionKey!);

    return Opacity(
      opacity: isAllowed ? 1.0 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: !isAllowed
                ? (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))
                : (item.badgeColor != null && item.badge != null
                    ? item.badgeColor!.withValues(alpha: 0.3)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!isAllowed) {
                _showPermissionDeniedDialog(context, item, effectiveUser);
              } else {
                context.push(item.route);
              }
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Rounded Icon Box + KPI Badge / Lock / Chevron
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? item.color.withValues(alpha: 0.2) : item.bgColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon, size: 20, color: item.color),
                      ),
                      if (!isAllowed)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_outline, size: 10, color: Color(0xFF64748B)),
                              SizedBox(width: 3),
                              Text('Locked', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                            ],
                          ),
                        )
                      else if (item.badge != null)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: (item.badgeColor ?? item.color).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.badge!,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: item.badgeColor ?? item.color,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 11,
                          color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Title + Subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPermissionDeniedDialog(BuildContext context, _ModuleItem item, EffectiveUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Access Restricted',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your active role (${user.role}) does not have permission to access "${item.title}".',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• Required permission: ${item.permissionKey ?? "Manager"}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                  const SizedBox(height: 4),
                  const Text('• Contact your plant manager or administrator to update access permissions.', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                  if (user.isImpersonating) ...[
                    const SizedBox(height: 8),
                    const Text('• You are currently viewing as this staff member. Tap below to exit view and regain admin access.', style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFFD97706))),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          if (user.isImpersonating)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(impersonationProvider.notifier).exitImpersonation();
                ref.read(rolePreviewProvider.notifier).exitPreview();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exited staff view. Admin permissions restored.')),
                );
              },
              icon: const Icon(Icons.logout_rounded, size: 16),
              label: const Text('Exit Staff View'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB45309)),
            ),
        ],
      ),
    );
  }
}

class _ModuleItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String route;
  final String? badge;
  final Color? badgeColor;
  final String? permissionKey;

  const _ModuleItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.route,
    this.badge,
    this.badgeColor,
    this.permissionKey,
  });
}
