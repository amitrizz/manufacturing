import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../widgets/impersonation_banner.dart';
import '../widgets/cashfree_gateway_modal.dart';
import '../screens/auth/login_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/tasks/tasks_screen.dart';
import '../screens/management/management_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/production/production_orders_screen.dart';
import '../screens/production/production_plans_screen.dart';
import '../screens/production/production_floor_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/inventory/finished_goods_screen.dart';
import '../screens/machines/machines_screen.dart';
import '../screens/machines/machine_detail_screen.dart';
import '../screens/maintenance/maintenance_screen.dart';
import '../screens/maintenance/maintenance_detail_screen.dart';
import '../screens/quality/quality_screen.dart';
import '../screens/purchase/purchase_screen.dart';
import '../screens/dispatch/dispatch_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/staff/staff_screen.dart';
import '../screens/management/roles_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/materials/product_bom_screen.dart';

class AppRouter {
  final Ref ref;
  final Listenable refreshListenable;
  
  AppRouter({required this.ref, required this.refreshListenable});
  
  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: refreshListenable,
    redirect: _redirect,
    routes: _routes,
    errorBuilder: (context, state) => _ErrorScreen(error: state.error.toString()),
  );
  
  String? _redirect(BuildContext context, GoRouterState state) {
    final authState = ref.read(authStateProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isLoggingIn = state.matchedLocation == '/login';
    final isOnboarding = state.matchedLocation == '/onboarding';
    
    if (!isAuthenticated && !isLoggingIn && !isOnboarding) {
      return '/login';
    }
    
    if (isAuthenticated && (isLoggingIn || isOnboarding)) {
      return '/dashboard';
    }

    // RBAC Route Guard: prevent staff from accessing unauthorized modules
    if (isAuthenticated) {
      final effectiveUser = ref.read(effectiveUserProvider);
      final location = state.matchedLocation;
      if (!effectiveUser.canAccessRoute(location)) {
        return '/dashboard';
      }
    }

    // Subscription Paywall Guard: when plan is expired, lock everything to dashboard paywall
    if (isAuthenticated) {
      final subState = ref.read(subscriptionProvider);
      if (subState.status == SubscriptionStatus.expired) {
        final location = state.matchedLocation;
        if (location != '/dashboard' && location != '/settings') {
          return '/dashboard';
        }
      }
    }
    
    return null;
  }
  
  List<RouteBase> get _routes => [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const _SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // =========================================================================
    // Core 4-Tab Shell Navigation: Home, Tasks, Management, Profile
    // =========================================================================
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => _MainShell(navigationShell: navigationShell),
      branches: [
        // Tab 1: Home (Dashboard)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),

        // Tab 2: Tasks (Actionable Tasks & Activity Log)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tasks',
              builder: (context, state) => const TasksScreen(),
            ),
          ],
        ),

        // Tab 3: Management Hub (Operations & Administration Modules)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/management',
              builder: (context, state) => const ManagementScreen(),
            ),
          ],
        ),

        // Tab 4: Profile (Settings, Subscription & Company Config)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // =========================================================================
    // Feature & Module Routes (Pushed from Management or Home)
    // =========================================================================
    GoRoute(
      path: '/production',
      builder: (context, state) => const ProductionOrdersScreen(),
    ),
    GoRoute(
      path: '/production/orders',
      builder: (context, state) => const ProductionOrdersScreen(),
    ),
    GoRoute(
      path: '/production/plans',
      builder: (context, state) => const ProductionPlansScreen(),
    ),
    GoRoute(
      path: '/production/floor',
      builder: (context, state) => const ProductionFloorScreen(),
    ),
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const InventoryScreen(initialTabIndex: 0),
    ),
    GoRoute(
      path: '/inventory/stock',
      builder: (context, state) => const InventoryScreen(initialTabIndex: 0),
    ),
    GoRoute(
      path: '/inventory/materials',
      builder: (context, state) => const InventoryScreen(initialTabIndex: 1),
    ),
    GoRoute(
      path: '/inventory/products',
      builder: (context, state) => const ProductsScreen(),
    ),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductsScreen(),
    ),
    GoRoute(
      path: '/inventory/bom',
      builder: (context, state) => ProductBomScreen(initialProductId: state.uri.queryParameters['productId']),
    ),
    GoRoute(
      path: '/bom',
      builder: (context, state) => ProductBomScreen(initialProductId: state.uri.queryParameters['productId']),
    ),
    GoRoute(
      path: '/inventory/finished-goods',
      builder: (context, state) => const FinishedGoodsScreen(),
    ),
    GoRoute(
      path: '/finished-goods',
      builder: (context, state) => const FinishedGoodsScreen(),
    ),
    GoRoute(
      path: '/machines',
      builder: (context, state) => const MachinesScreen(),
    ),
    GoRoute(
      path: '/machines/:id',
      builder: (context, state) => MachineDetailScreen(machineId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/maintenance',
      builder: (context, state) => const MaintenanceScreen(initialTabIndex: 0),
    ),
    GoRoute(
      path: '/maintenance/:id',
      builder: (context, state) => MaintenanceDetailScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/quality',
      builder: (context, state) {
        final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
        final orderId = state.uri.queryParameters['orderId'];
        return QualityScreen(initialTabIndex: tab, initialOrderId: orderId);
      },
    ),
    GoRoute(
      path: '/quality/inspections',
      builder: (context, state) {
        final orderId = state.uri.queryParameters['orderId'];
        return QualityScreen(initialTabIndex: 1, initialOrderId: orderId);
      },
    ),
    GoRoute(
      path: '/quality/waiting',
      builder: (context, state) => const QualityScreen(initialTabIndex: 0),
    ),
    GoRoute(
      path: '/quality/rework',
      builder: (context, state) => const QualityScreen(initialTabIndex: 2),
    ),
    GoRoute(
      path: '/purchase',
      builder: (context, state) => const PurchaseScreen(initialTabIndex: 0),
    ),
    GoRoute(
      path: '/purchase/orders',
      builder: (context, state) => const PurchaseScreen(initialTabIndex: 0),
    ),
    GoRoute(
      path: '/purchase/requests',
      builder: (context, state) => const PurchaseScreen(initialTabIndex: 1),
    ),
    GoRoute(
      path: '/purchase/grn',
      builder: (context, state) => const PurchaseScreen(initialTabIndex: 2),
    ),
    GoRoute(
      path: '/purchase/suppliers',
      builder: (context, state) => const PurchaseScreen(initialTabIndex: 3),
    ),
    GoRoute(
      path: '/materials',
      builder: (context, state) => const InventoryScreen(initialTabIndex: 1),
    ),
    GoRoute(
      path: '/dispatch',
      builder: (context, state) => const DispatchScreen(initialTabIndex: 0),
    ),
    GoRoute(
      path: '/dispatch/orders',
      builder: (context, state) => const DispatchScreen(initialTabIndex: 0),
    ),
    GoRoute(
      path: '/dispatch/customers',
      builder: (context, state) => const DispatchScreen(initialTabIndex: 1),
    ),
    GoRoute(
      path: '/contacts',
      builder: (context, state) => const DispatchScreen(initialTabIndex: 1),
    ),
    GoRoute(
      path: '/dispatch/create',
      builder: (context, state) => const DispatchScreen(initialTabIndex: 0),
    ),
    GoRoute(
      path: '/rework',
      builder: (context, state) => const QualityScreen(initialTabIndex: 2),
    ),
    GoRoute(
      path: '/costing',
      builder: (context, state) => const ReportsScreen(initialTabIndex: 0),
    ),
    GoRoute(
      path: '/roles',
      builder: (context, state) => const RolesScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) {
        final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
        return ReportsScreen(initialTabIndex: tab);
      },
    ),
    GoRoute(
      path: '/reports/center',
      builder: (context, state) => const ReportsScreen(initialTabIndex: 1),
    ),
    GoRoute(
      path: '/reports/oee',
      builder: (context, state) => const ReportsScreen(initialTabIndex: 2),
    ),
    GoRoute(
      path: '/reports/production',
      builder: (context, state) => const ReportsScreen(initialTabIndex: 0),
    ),
    GoRoute(
      path: '/staff',
      builder: (context, state) => const StaffScreen(initialTabIndex: 0),
    ),
    GoRoute(
      path: '/staff/attendance',
      builder: (context, state) => const StaffScreen(initialTabIndex: 1),
    ),
    GoRoute(
      path: '/settings/profile',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/activity',
      builder: (context, state) => const TasksScreen(initialMode: TaskTabMode.history),
    ),
    GoRoute(
      path: '/settings/api',
      builder: (context, state) => const ApiSettingsScreen(),
    ),
  ];
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.factory,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Manufacturing ERP',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 16),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  
  const _MainShell({required this.navigationShell});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subState = ref.watch(subscriptionProvider);
    final isExpired = subState.status == SubscriptionStatus.expired;

    if (isExpired) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1120),
        body: _SubscriptionLockoutPaywall(subState: subState),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          const ImpersonationBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_center_outlined),
            selectedIcon: Icon(Icons.business_center),
            label: 'Management',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _SubscriptionLockoutPaywall extends ConsumerStatefulWidget {
  final SubscriptionState subState;

  const _SubscriptionLockoutPaywall({required this.subState});

  @override
  ConsumerState<_SubscriptionLockoutPaywall> createState() => _SubscriptionLockoutPaywallState();
}

class _SubscriptionLockoutPaywallState extends ConsumerState<_SubscriptionLockoutPaywall> {
  String _selectedPlan = 'PRO_ANNUAL';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final companyName = authState.userName ?? 'Your Company';
    final rawCompanyCode = authState.companyId ?? 'GOOGLE';
    final companyCode = (rawCompanyCode.length == 24 && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(rawCompanyCode))
        ? (companyName.toLowerCase().contains('google') ? 'GOOGLE' : 'MFG-COMP')
        : rawCompanyCode;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red Glowing Lock Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEF4444), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.lock_rounded, size: 36, color: Color(0xFFEF4444)),
              ),
              const SizedBox(height: 20),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF7F1D1D),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFB91C1C)),
                ),
                child: const Text(
                  'ACCESS LOCKED • 7-DAY TRIAL EXPIRED',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Color(0xFFFCA5A5),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title & Subtitle
              Text(
                'Unlock $companyName Floor Operations',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Company Code: $companyCode • All production orders, machines, tasks, and inventory access are paused until subscription payment is completed.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),

              // Option 1: Annual Plan
              GestureDetector(
                onTap: () => setState(() => _selectedPlan = 'PRO_ANNUAL'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedPlan == 'PRO_ANNUAL'
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedPlan == 'PRO_ANNUAL'
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF1E293B),
                      width: _selectedPlan == 'PRO_ANNUAL' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedPlan == 'PRO_ANNUAL' ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: _selectedPlan == 'PRO_ANNUAL' ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Pro Annual (365 Days)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF064E3B),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'SAVE 20%',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF34D399),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Instant unlock for 1 full year • Unlimited offline syncing',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '₹24,999',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: Monthly Plan
              GestureDetector(
                onTap: () => setState(() => _selectedPlan = 'PRO_MONTHLY'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedPlan == 'PRO_MONTHLY'
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedPlan == 'PRO_MONTHLY'
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF1E293B),
                      width: _selectedPlan == 'PRO_MONTHLY' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedPlan == 'PRO_MONTHLY' ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: _selectedPlan == 'PRO_MONTHLY' ? const Color(0xFF38BDF8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pro Monthly (30 Days)',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              '30-day full access • Flexible renewal',
                              style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        '₹2,499',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Features checklist
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: const Column(
                  children: [
                    _PaywallFeatureRow('Full Shop Floor, Lines & Work Order operations'),
                    SizedBox(height: 8),
                    _PaywallFeatureRow('Custom Staff Roles & PIN-authenticated access'),
                    SizedBox(height: 8),
                    _PaywallFeatureRow('Multi-device cloud synchronization & SQLite caching'),
                    SizedBox(height: 8),
                    _PaywallFeatureRow('Automated Quality Inspection & Machine Maintenance'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Pay via Cashfree PG
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  icon: _isProcessing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.payment_rounded, size: 20),
                  label: Text(
                    _isProcessing
                        ? 'Opening Cashfree Gateway…'
                        : 'Pay with Cashfree PG (${_selectedPlan == 'PRO_ANNUAL' ? '₹24,999' : '₹2,499'})',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  onPressed: _isProcessing
                      ? null
                      : () async {
                          setState(() => _isProcessing = true);
                          try {
                            final order = await ref.read(subscriptionProvider.notifier).createCashfreeOrder(
                              plan: _selectedPlan,
                              amount: _selectedPlan == 'PRO_ANNUAL' ? 24999 : 2499,
                            );

                            final orderData = order['data'] as Map<String, dynamic>? ?? {};
                            final orderId = orderData['orderId']?.toString() ?? 'order_${DateTime.now().millisecondsSinceEpoch}';
                            final paymentSessionId = orderData['paymentSessionId']?.toString() ?? '';
                            final stubMode = orderData['stubMode'] == true;

                            setState(() => _isProcessing = false);

                            if (!context.mounted) return;

                            // Open interactive Cashfree Gateway checkout modal
                            await CashfreeGatewayModal.show(
                              context,
                              orderId: orderId,
                              paymentSessionId: paymentSessionId,
                              amount: _selectedPlan == 'PRO_ANNUAL' ? 24999 : 2499,
                              plan: _selectedPlan,
                              companyCode: companyCode,
                              companyName: companyName,
                              stubMode: stubMode,
                              onSuccess: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🎉 Payment Verified via Cashfree! Your ${_selectedPlan == 'PRO_ANNUAL' ? 'Annual Pro' : 'Monthly Pro'} plan is active. All features unlocked!'),
                                    backgroundColor: const Color(0xFF10B981),
                                    duration: const Duration(seconds: 4),
                                  ),
                                );
                              },
                            );
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isProcessing = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Could not open Cashfree PG: $e'),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          }
                        },
                ),
              ),
              const SizedBox(height: 12),

              // Instant Test Activation button
              TextButton.icon(
                icon: const Icon(Icons.flash_on_rounded, size: 16, color: Color(0xFF10B981)),
                label: const Text(
                  '⚡ Instant Test Activation (Dev / Sandbox Unlock)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                ),
                onPressed: _isProcessing
                    ? null
                    : () async {
                        setState(() => _isProcessing = true);
                        try {
                          await ref.read(subscriptionProvider.notifier).renewSubscription(plan: _selectedPlan);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('⚡ Instant Pro Activated for ${_selectedPlan == 'PRO_ANNUAL' ? '1 Year' : '30 Days'}! All features unlocked.'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            setState(() => _isProcessing = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Activation failed: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
              ),
              const SizedBox(height: 16),

              // Sign Out button
              TextButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 15, color: Color(0xFF64748B)),
                label: const Text(
                  'Sign out of session',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                onPressed: () => ref.read(authStateProvider.notifier).logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaywallFeatureRow extends StatelessWidget {
  final String text;
  const _PaywallFeatureRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF38BDF8)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1)),
          ),
        ),
      ],
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String error;
  
  const _ErrorScreen({required this.error});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// Real Module Detail & Utility Screens
// =========================================================================




class ApiSettingsScreen extends ConsumerStatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  ConsumerState<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends ConsumerState<ApiSettingsScreen> {
  late final TextEditingController _urlController;
  String? _pingResult;
  bool _pinging = false;

  @override
  void initState() {
    super.initState();
    final api = ref.read(apiServiceProvider);
    _urlController = TextEditingController(text: api.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testPing() async {
    setState(() {
      _pinging = true;
      _pingResult = null;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final api = ref.read(apiServiceProvider);
      final health = await api.getHealth();
      stopwatch.stop();
      setState(() {
        _pingResult = 'Connected: Status ${health.status} (${stopwatch.elapsedMilliseconds}ms)';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _pingResult = 'Connection Failed: $e';
      });
    } finally {
      setState(() => _pinging = false);
    }
  }

  void _saveUrl() {
    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty) {
      ref.read(apiServiceProvider).updateBaseUrl(newUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API Base URL saved: $newUrl')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Backend API Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('API Server Endpoint', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Configure the REST API endpoint used for all factory queries and synchronization.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'API Base URL',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pinging ? null : _testPing,
                          icon: _pinging
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.network_check),
                          label: const Text('Ping Health'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saveUrl,
                          icon: const Icon(Icons.save),
                          label: const Text('Save URL'),
                        ),
                      ),
                    ],
                  ),
                  if (_pingResult != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _pingResult!.startsWith('Connected')
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _pingResult!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _pingResult!.startsWith('Connected')
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}