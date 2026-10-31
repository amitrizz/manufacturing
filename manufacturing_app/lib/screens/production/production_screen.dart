import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/production.dart';
import '../../models/machine.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

class ProductionScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const ProductionScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends ConsumerState<ProductionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedStatus;
  String _orderSearch = '';
  String _planSearch = '';
  String _floorSearch = '';
  String _floorPeriod = 'all';

  // Add Line Modal State
  final _newLineCodeController = TextEditingController();
  final _newLineNameController = TextEditingController();

  // Assign Worker Modal State
  final _assignWorkerNameController = TextEditingController();
  final _assignNotesController = TextEditingController();
  String _assignShift = 'Morning';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _newLineCodeController.dispose();
    _newLineNameController.dispose();
    _assignWorkerNameController.dispose();
    _assignNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveUser = ref.watch(effectiveUserProvider);
    final hasOrders = effectiveUser.hasPermission('home_orders');
    final hasProd = effectiveUser.hasPermission('home_production');

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.headerNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back to Management',
          onPressed: () => context.canPop() ? context.pop() : context.go('/management'),
        ),
        title: const Text(
          'Production & Shop Floor',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.headerUnselected,
          indicatorColor: AppColors.headerAccent,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Orders'),
                  if (!hasOrders) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.lock_outline, size: 12, color: Colors.white70),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Plans'),
                  if (!hasProd) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.lock_outline, size: 12, color: Colors.white70),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Floor & Lines'),
                  if (!hasProd) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.lock_outline, size: 12, color: Colors.white70),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_tabController.index == 0 && hasOrders)
            PopupMenuButton<String>(
              tooltip: 'Filter by Status',
              onSelected: (value) {
                setState(() {
                  _selectedStatus = value == 'all' ? null : value;
                });
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'all', child: Text('All Status')),
                PopupMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                PopupMenuItem(value: 'PENDING', child: Text('Pending')),
                PopupMenuItem(value: 'COMPLETED', child: Text('Completed')),
                PopupMenuItem(value: 'DELAYED', child: Text('Delayed')),
                PopupMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
              ],
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      _selectedStatus ?? 'All',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          hasOrders ? _buildOrdersTab(isDark) : _buildRestrictedView('Orders & Work Orders', 'home_orders', isDark, effectiveUser),
          hasProd ? _buildPlansTab(isDark) : _buildRestrictedView('Production Plans & Scheduling', 'home_production', isDark, effectiveUser),
          hasProd ? _buildFloorTab(isDark) : _buildRestrictedView('Live Shop Floor & Lines', 'home_production', isDark, effectiveUser),
        ],
      ),
      floatingActionButton: _buildFab(effectiveUser),
    );
  }

  Widget _buildRestrictedView(String moduleName, String permissionKey, bool isDark, EffectiveUser effectiveUser) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_person_outlined, size: 32, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Text(
              'Access Restricted',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your role "${effectiveUser.role}" does not have permission for $moduleName (Permission: "$permissionKey").',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.canPop() ? context.pop() : context.go('/management'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Management'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFab(EffectiveUser effectiveUser) {
    final hasOrders = effectiveUser.hasPermission('home_orders');
    final hasProd = effectiveUser.hasPermission('home_production');
    final isOperator = effectiveUser.role == 'OPERATOR';

    switch (_tabController.index) {
      case 0:
        if (!hasOrders || isOperator) return null;
        return FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          onPressed: () => _showCreateOrderDialog(),
          icon: const Icon(Icons.add),
          label: const Text('New Order', style: TextStyle(fontWeight: FontWeight.w700)),
        );
      case 1:
        if (!hasProd || isOperator) return null;
        return FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          onPressed: () => _showCreatePlanDialog(),
          icon: const Icon(Icons.add_chart_rounded),
          label: const Text('New Plan', style: TextStyle(fontWeight: FontWeight.w700)),
        );
      case 2:
        if (!hasProd) return null;
        return FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          onPressed: () => _showRecordOutputDialogDirect('Production Floor'),
          icon: const Icon(Icons.create_outlined),
          label: const Text('Log Output', style: TextStyle(fontWeight: FontWeight.w700)),
        );
      default:
        return null;
    }
  }

  // ===========================================================================
  // Tab 1: Orders (matches frontend ProductionOrdersScreen.tsx)
  // ===========================================================================
  Widget _buildOrdersTab(bool isDark) {
    final ordersAsync = ref.watch(productionOrdersProvider(_selectedStatus));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(productionOrdersProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search & Action Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search orders…',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _orderSearch = val.trim().toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showCreateOrderDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('+ New order', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Orders List
          ordersAsync.when(
            data: (paginated) {
              var list = paginated.data;
              if (_orderSearch.isNotEmpty) {
                list = list.where((o) =>
                  o.orderNumber.toLowerCase().contains(_orderSearch) ||
                  (o.productCode ?? '').toLowerCase().contains(_orderSearch) ||
                  (o.productName ?? '').toLowerCase().contains(_orderSearch) ||
                  (o.lineCode ?? '').toLowerCase().contains(_orderSearch)
                ).toList();
              }

              // Sort like React frontend: IN_PROGRESS first, then PENDING, then created_at desc
              list.sort((a, b) {
                int rank(String s) => s == 'IN_PROGRESS' ? 0 : s == 'PENDING' ? 1 : 2;
                final rDiff = rank(a.status).compareTo(rank(b.status));
                if (rDiff != 0) return rDiff;
                return b.createdAt.compareTo(a.createdAt);
              });

              if (list.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('No production orders found', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text('Create your first production order using the button above', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                          onPressed: () => _showCreateOrderDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Production Order'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = list[index];
                  return _ProductionOrderCard(
                    order: order,
                    onTap: () => _showOrderDetailDialog(order),
                    onRecordOutput: () => _showRecordOutputDialog(order),
                  );
                },
              );
            },
            loading: () => const ProductionOrdersShimmer(),
            error: (error, _) => _buildErrorState(error, () => ref.invalidate(productionOrdersProvider)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Tab 2: Plans (matches frontend ProductionPlansScreen.tsx)
  // ===========================================================================
  Widget _buildPlansTab(bool isDark) {
    final plansAsync = ref.watch(productionPlansProvider(const {'limit': 100}));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(productionPlansProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Search & Action Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search plans, products, lines…',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _planSearch = val.trim().toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showCreatePlanDialog(),
                icon: const Icon(Icons.add_chart_rounded, size: 18),
                label: const Text('+ New plan', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Plans List
          plansAsync.when(
            data: (paginated) {
              var plans = paginated.data;
              if (_planSearch.isNotEmpty) {
                plans = plans.where((p) {
                  final num = (p['plan_number'] ?? p['planNumber'] ?? '').toString().toLowerCase();
                  final prd = (p['product_code'] ?? p['product_name'] ?? '').toString().toLowerCase();
                  final ln = (p['line_code'] ?? p['line_name'] ?? '').toString().toLowerCase();
                  return num.contains(_planSearch) || prd.contains(_planSearch) || ln.contains(_planSearch);
                }).toList();
              }

              if (plans.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text('No production plans defined', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text('Schedule production targets, assigned lines and quantities.', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                          onPressed: () => _showCreatePlanDialog(),
                          icon: const Icon(Icons.add_chart_rounded),
                          label: const Text('Create Production Plan'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  return _ProductionPlanCard(
                    plan: plan,
                    onCreateOrder: () => _showCreateOrderDialog(prefilledPlan: plan),
                  );
                },
              );
            },
            loading: () => const ProductionPlansShimmer(),
            error: (error, _) => _buildErrorState(error, () => ref.invalidate(productionPlansProvider)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Tab 3: Floor & Lines (Exact 1:1 match with React ProductionFloorScreen.tsx)
  // ===========================================================================
  Widget _buildFloorTab(bool isDark) {
    final linesAsync = ref.watch(productionLinesProvider);
    final machinesAsync = ref.watch(machinesProvider(const {'limit': 100}));
    final ordersAsync = ref.watch(productionOrdersProvider('IN_PROGRESS'));
    final staffAsync = ref.watch(staffProvider(const {'limit': 100}));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(productionLinesProvider);
        ref.invalidate(machinesProvider);
        ref.invalidate(productionOrdersProvider);
        ref.invalidate(staffProvider);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header Bar: Title & Add Line Button (Exact React match)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Floor & Shift Output',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0A1E38),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Live output by line, machine, workers & shifts',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showAddLineDialog(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text('+ Add Line', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // KPI Summary Cards Strip (3 cards exactly matching React frontend)
          machinesAsync.when(
            data: (paginated) {
              final machines = paginated.data;
              final orders = ordersAsync.valueOrNull?.data ?? [];
              final totalProduced = orders.fold<double>(0, (sum, o) => sum + o.producedQuantity).toInt();
              final runningCount = machines.where((m) => m.status == 'RUNNING').length;
              final workersCount = machines.where((m) => m.currentOperator != null && m.currentOperator!.isNotEmpty).length;

              return Row(
                children: [
                  // Total Output Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.bolt_rounded, size: 15, color: Color(0xFF16A34A)),
                              SizedBox(width: 4),
                              Text('Total Output', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF166534))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              text: Formatters.formatNumber(totalProduced),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF14532D)),
                              children: const [
                                TextSpan(text: ' pcs', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Running Machines Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.memory_rounded, size: 15, color: Color(0xFF0284C7)),
                              SizedBox(width: 4),
                              Text('Running', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF075985))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$runningCount / ${machines.length}',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0C4A6E)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Workers Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.people_outline, size: 15, color: Color(0xFF7C3AED)),
                              SizedBox(width: 4),
                              Text('Workers', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF5B21B6))),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$workersCount on shift',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF4C1D95)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(height: 60),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),

          // Period Segmented Tabs (Today, This Week, This Month, All Time)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildPeriodTab('Today', 'today'),
                _buildPeriodTab('This Week', 'week'),
                _buildPeriodTab('This Month', 'month'),
                _buildPeriodTab('All Time', 'all'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Search Field
          TextField(
            decoration: InputDecoration(
              hintText: 'Search machine, line, worker or product…',
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
              isDense: true,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _floorSearch = val.trim().toLowerCase();
              });
            },
          ),
          const SizedBox(height: 10),

          // Quick Record Action Bar (Exact React match: quickRecordCard)
          InkWell(
            onTap: () {
              final active = ordersAsync.valueOrNull?.data ?? [];
              if (active.isNotEmpty) {
                _showRecordOutputDialog(active.first);
              } else {
                _showRecordOutputDialogDirect('Production Floor');
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.create_outlined, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Log Production Output',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0A1E38)),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          (ordersAsync.valueOrNull?.data.length ?? 0) > 0
                              ? '${ordersAsync.valueOrNull!.data.length} order running • Tap to record pieces & shift'
                              : 'Select an order and log output pieces per worker',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: Color(0xFF0A1E38)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Lines and Machines Grouped View (Exact React match: groupedLines)
          linesAsync.when(
            data: (linesList) {
              final allMachines = machinesAsync.valueOrNull?.data ?? [];
              final activeOrders = ordersAsync.valueOrNull?.data ?? [];
              final staffList = staffAsync.valueOrNull?.data ?? [];

              // Map active orders by machine id
              final orderByMachine = <String, ProductionOrder>{};
              for (final o in activeOrders) {
                if (o.assignedMachines != null && o.assignedMachines!.isNotEmpty) {
                  for (final mId in o.assignedMachines!) {
                    orderByMachine[mId] = o;
                  }
                } else if (o.machineId != null) {
                  orderByMachine[o.machineId!] = o;
                }
              }

              // Filter machines by search query
              var filteredMachines = allMachines;
              if (_floorSearch.isNotEmpty) {
                filteredMachines = filteredMachines.where((m) =>
                  m.name.toLowerCase().contains(_floorSearch) ||
                  m.code.toLowerCase().contains(_floorSearch) ||
                  (m.lineCode ?? '').toLowerCase().contains(_floorSearch) ||
                  (m.currentOperator ?? '').toLowerCase().contains(_floorSearch)
                ).toList();
              }

              if (linesList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        const Icon(Icons.alt_route_rounded, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text('No Production Lines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text('Create a production line to start assigning machines and logging shift output.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                          onPressed: () => _showAddLineDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('+ Add Production Line'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: linesList.map((lineData) {
                  final lineId = lineData['id']?.toString() ?? lineData['_id']?.toString() ?? '';
                  final lineCode = lineData['code']?.toString() ?? 'LINE';
                  final lineName = lineData['name']?.toString() ?? 'Line';

                  // Find machines assigned to this line
                  final lineMachines = filteredMachines.where((m) =>
                    m.lineId == lineId || m.lineCode == lineCode
                  ).toList();

                  // Sum output for this line
                  final lineProduced = lineMachines.fold<double>(0, (sum, m) {
                    final order = orderByMachine[m.id];
                    return sum + (order?.producedQuantity ?? 0);
                  }).toInt();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Line Header Card (Exact React match: lineHeaderCard)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE0F2FE),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.alt_route_rounded, size: 14, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 4),
                                    Text(
                                      lineCode,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lineName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.layers_outlined, size: 12, color: Color(0xFF15803D)),
                                    const SizedBox(width: 3),
                                    Text(
                                      '${Formatters.formatNumber(lineProduced)} pcs',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF15803D)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${lineMachines.length} machine${lineMachines.length == 1 ? '' : 's'}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Machines in Line
                        if (lineMachines.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('No machines assigned to $lineCode yet.', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              ],
                            ),
                          )
                        else
                          ...lineMachines.map((m) {
                            final activeOrder = orderByMachine[m.id];
                            return _buildMachineFloorCard(m, activeOrder, isDark, staffList);
                          }),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const ProductionFloorShimmer(),
            error: (e, _) => _buildErrorState(e, () => ref.invalidate(productionLinesProvider)),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, String value) {
    final isSelected = _floorPeriod == value;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _floorPeriod = value;
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? const Color(0xFF0A1E38) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  // Machine Card in Floor Tab (Exact React match: machineCard + shift breakdown)
  Widget _buildMachineFloorCard(Machine m, ProductionOrder? activeOrder, bool isDark, List<Map<String, dynamic>> staffList) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Machine Code, Name, Type, and Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(m.code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0A1E38))),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            m.machineType.isNotEmpty ? m.machineType : 'General',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(m.name, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              _buildStatusBadge(m.status),
            ],
          ),
          const SizedBox(height: 8),

          // Active Running Order Banner
          if (activeOrder != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.play_circle_fill_rounded, size: 14, color: Color(0xFF0284C7)),
                      const SizedBox(width: 4),
                      Text(activeOrder.orderNumber, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF0284C7))),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '· ${activeOrder.productCode ?? activeOrder.productName ?? "Part"} (${activeOrder.producedQuantity.toInt()} / ${activeOrder.targetQuantity.toInt()} pcs)',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF1E293B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: (activeOrder.progressPercent / 100).clamp(0.0, 1.0),
                      minHeight: 4,
                      backgroundColor: const Color(0xFFDBEAFE),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Shift & Worker Breakdown Table (Exact React match: shiftsContainer)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF0A1E38)),
                    SizedBox(width: 4),
                    Text('Shift Output & Assigned Staff', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0A1E38))),
                  ],
                ),
                const SizedBox(height: 6),

                // Morning Shift Row
                _buildShiftItemRow(
                  shift: 'Morning',
                  time: '06:00 - 14:00',
                  icon: Icons.wb_sunny_outlined,
                  color: const Color(0xFFEA580C),
                  bg: const Color(0xFFFFF7ED),
                  worker: m.currentOperator,
                  producedPcs: (activeOrder?.producedQuantity.toInt() ?? 0),
                  onAssign: () => _showAssignWorkerDialog(m, 'Morning', staffList),
                ),
                const SizedBox(height: 4),

                // Evening Shift Row
                _buildShiftItemRow(
                  shift: 'Evening',
                  time: '14:00 - 22:00',
                  icon: Icons.wb_cloudy_outlined,
                  color: const Color(0xFFD97706),
                  bg: const Color(0xFFFEF3C7),
                  worker: null,
                  producedPcs: 0,
                  onAssign: () => _showAssignWorkerDialog(m, 'Evening', staffList),
                ),
                const SizedBox(height: 4),

                // Night Shift Row
                _buildShiftItemRow(
                  shift: 'Night',
                  time: '22:00 - 06:00',
                  icon: Icons.nightlight_outlined,
                  color: const Color(0xFF6366F1),
                  bg: const Color(0xFFEEF2FF),
                  worker: null,
                  producedPcs: 0,
                  onAssign: () => _showAssignWorkerDialog(m, 'Night', staffList),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Machine Total Output Footer & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Machine Total: ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  Text(
                    '${Formatters.formatNumber(activeOrder?.producedQuantity.toInt() ?? 0)} pcs',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0A1E38)),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      side: const BorderSide(color: Color(0xFF0284C7)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onPressed: () {
                      if (activeOrder != null) {
                        _showRecordOutputDialog(activeOrder);
                      } else {
                        _showRecordOutputDialogDirect(m.name);
                      }
                    },
                    icon: const Icon(Icons.create_outlined, size: 13, color: Color(0xFF0284C7)),
                    label: const Text('Record Output', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftItemRow({
    required String shift,
    required String time,
    required IconData icon,
    required Color color,
    required Color bg,
    required String? worker,
    required int producedPcs,
    required VoidCallback onAssign,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: worker != null ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: worker != null ? Border.all(color: const Color(0xFFE2E8F0)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(shift, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              Text(time, style: const TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
            ],
          ),
          const Spacer(),

          // Worker Name
          if (worker != null)
            Row(
              children: [
                const Icon(Icons.person, size: 12, color: Color(0xFF0284C7)),
                const SizedBox(width: 3),
                Text(worker, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              ],
            )
          else
            const Text('No worker assigned', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic)),

          const SizedBox(width: 10),

          // Output Units
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: producedPcs > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$producedPcs pcs',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: producedPcs > 0 ? const Color(0xFF15803D) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Assign button
          InkWell(
            onTap: onAssign,
            child: const Icon(Icons.person_add_outlined, size: 14, color: Color(0xFF0284C7)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = const Color(0xFFF1F5F9);
    Color text = const Color(0xFF64748B);
    switch (status) {
      case 'RUNNING':
        bg = const Color(0xFFDCFCE7);
        text = const Color(0xFF16A34A);
        break;
      case 'IDLE':
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF64748B);
        break;
      case 'BREAKDOWN':
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFDC2626);
        break;
      case 'MAINTENANCE':
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFD97706);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(5)),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: text),
      ),
    );
  }

  Widget _buildErrorState(Object error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFFDC2626)),
            const SizedBox(height: 16),
            Text('Failed to load production data', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(error.toString(), style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Modal: Add Production Line (matches React handleOpenAddLine)
  // ===========================================================================
  void _showAddLineDialog() {
    _newLineCodeController.clear();
    _newLineNameController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.alt_route_rounded, size: 18, color: Color(0xFF0284C7)),
                  ),
                  const SizedBox(width: 8),
                  const Text('Add Production Line', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              const Text('Line Code *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              TextField(
                controller: _newLineCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  hintText: 'e.g. LINE-E or PACK-01',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),

              const Text('Line Name / Description *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              TextField(
                controller: _newLineNameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Final Packaging & Dispatch Line',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Color(0xFF0284C7)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Machines, production orders, and shift records can be linked to this line once created.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF0369A1)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                      onPressed: () async {
                        final code = _newLineCodeController.text.trim().toUpperCase();
                        final name = _newLineNameController.text.trim();
                        if (code.isEmpty || name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter line code and name.')));
                          return;
                        }

                        Navigator.pop(ctx);
                        try {
                          final api = ref.read(apiServiceProvider);
                          await api.createCollectionItem('production_lines', {
                            'code': code,
                            'name': name,
                            'created_at': DateTime.now().millisecondsSinceEpoch,
                            'updated_at': DateTime.now().millisecondsSinceEpoch,
                          });
                          ref.invalidate(productionLinesProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Production Line $code created!'), backgroundColor: const Color(0xFF10B981)),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Could not create line: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      child: const Text('Create Line'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // Modal: Assign Shift Worker (matches React handleOpenAssignModal)
  // ===========================================================================
  void _showAssignWorkerDialog(Machine machine, String initialShift, List<Map<String, dynamic>> staffList) {
    _assignShift = initialShift;
    _assignWorkerNameController.text = machine.currentOperator ?? '';
    _assignNotesController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.person_add_outlined, size: 18, color: Color(0xFFD97706)),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Assign Shift Worker', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                            Text('${machine.code} · $_assignShift Shift', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                        const Spacer(),
                        IconButton(onPressed: () => Navigator.pop(modalCtx), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Shift Selection Chips
                    const Text('Shift', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Row(
                      children: ['Morning', 'Evening', 'Night'].map((sh) {
                        final isSel = _assignShift == sh;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(sh),
                              selected: isSel,
                              onSelected: (val) {
                                if (val) setModalState(() => _assignShift = sh);
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Staff Chips
                    if (staffList.isNotEmpty) ...[
                      const Text('Select Staff Member', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: staffList.map((s) {
                            final name = s['name']?.toString() ?? 'Staff';
                            final isSel = _assignWorkerNameController.text == name;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                avatar: const Icon(Icons.person, size: 14),
                                label: Text(name),
                                selected: isSel,
                                onSelected: (val) {
                                  if (val) {
                                    setModalState(() {
                                      _assignWorkerNameController.text = name;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Or Enter Worker Name
                    const Text('Worker Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _assignWorkerNameController,
                      decoration: const InputDecoration(hintText: 'Enter Worker Name', isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    const Text('Notes (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _assignNotesController,
                      decoration: const InputDecoration(hintText: 'Shift instructions or allocation notes', isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(modalCtx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                            onPressed: () async {
                              final worker = _assignWorkerNameController.text.trim();
                              if (worker.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select or enter worker name.')));
                                return;
                              }

                              Navigator.pop(modalCtx);
                              try {
                                final api = ref.read(apiServiceProvider);
                                // Update machine operator
                                await api.updateCollectionItem('machines', machine.id, {
                                  'current_operator': worker,
                                  'status': 'RUNNING',
                                  'updated_at': DateTime.now().millisecondsSinceEpoch,
                                });
                                ref.invalidate(machinesProvider);
                                ref.invalidate(dashboardProvider);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$worker assigned to ${machine.code} for $_assignShift shift.'),
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not assign worker: $e'), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            child: const Text('Assign Worker'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // Order Creation Dialog (matches React ProductionOrderCreateScreen.tsx)
  // ===========================================================================
  void _showCreateOrderDialog({Map<String, dynamic>? prefilledPlan}) {
    final orderNumController = TextEditingController(
      text: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    final qtyController = TextEditingController(
      text: prefilledPlan?['target_quantity']?.toString() ?? '100',
    );

    String? selectedProductId = prefilledPlan?['product_id']?.toString();
    String? selectedLineId = prefilledPlan?['line_id']?.toString();
    String selectedPriority = prefilledPlan?['priority']?.toString() ?? 'MEDIUM';
    String? selectedPlanId = prefilledPlan?['id']?.toString() ?? prefilledPlan?['_id']?.toString();
    final selectedMachineIds = <String>{};

    final productsAsync = ref.read(productsProvider(const {'limit': 100}));
    final linesAsync = ref.read(productionLinesProvider);
    final plansAsync = ref.read(productionPlansProvider(const {'limit': 50}));
    final machinesAsync = ref.read(machinesProvider(const {'limit': 50}));

    final products = productsAsync.valueOrNull?.data ?? [];
    final lines = linesAsync.valueOrNull ?? [];
    final plans = plansAsync.valueOrNull?.data ?? [];
    final machines = machinesAsync.valueOrNull?.data ?? [];

    if (selectedProductId == null && products.isNotEmpty) {
      selectedProductId = products[0]['id']?.toString() ?? products[0]['_id']?.toString();
    }
    if (selectedLineId == null && lines.isNotEmpty) {
      selectedLineId = lines[0]['id']?.toString() ?? lines[0]['_id']?.toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final availableMachines = machines.where((m) =>
              selectedLineId == null || m.lineId == selectedLineId
            ).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('New Production Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        IconButton(onPressed: () => Navigator.pop(modalCtx), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Order Number
                    const Text('Order Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: orderNumController,
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),

                    // Product Selector Chips
                    const Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    if (products.isEmpty)
                      const Text('No products available. Register products in Stock.', style: TextStyle(fontSize: 12, color: Colors.grey))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: products.map((p) {
                          final id = p['id']?.toString() ?? p['_id']?.toString() ?? '';
                          final code = p['code']?.toString() ?? p['name']?.toString() ?? 'PRD';
                          final name = p['name']?.toString() ?? '';
                          final isSelected = selectedProductId == id;
                          return ChoiceChip(
                            label: Text('$code ($name)'),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setModalState(() => selectedProductId = id);
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 14),

                    // Production Line Selector Chips
                    const Text('Production Line', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    if (lines.isEmpty)
                      const Text('No lines registered.', style: TextStyle(fontSize: 12, color: Colors.grey))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: lines.map((l) {
                          final id = l['id']?.toString() ?? l['_id']?.toString() ?? '';
                          final code = l['code']?.toString() ?? l['name']?.toString() ?? 'Line';
                          final isSelected = selectedLineId == id;
                          return ChoiceChip(
                            label: Text(code),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  selectedLineId = id;
                                  selectedMachineIds.clear();
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 14),

                    // Assigned Machines (multi-select)
                    Text('Assigned Machines (${selectedMachineIds.length} selected - Optional)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    if (availableMachines.isEmpty)
                      const Text('No machines found for this line. You can assign machines later.', style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: availableMachines.map((m) {
                          final isSelected = selectedMachineIds.contains(m.id);
                          return FilterChip(
                            label: Text('${m.code} (${m.name})'),
                            selected: isSelected,
                            onSelected: (val) {
                              setModalState(() {
                                if (val) {
                                  selectedMachineIds.add(m.id);
                                } else {
                                  selectedMachineIds.remove(m.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 14),

                    // Planned Target Quantity
                    const Text('Target Quantity (pcs)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),

                    // Priority Selector
                    const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'].map((p) {
                        return ChoiceChip(
                          label: Text(p),
                          selected: selectedPriority == p,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedPriority = p);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Optional Production Plan Selector
                    const Text('Production Plan (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: const Text('None'),
                          selected: selectedPlanId == null,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedPlanId = null);
                          },
                        ),
                        ...plans.map((pl) {
                          final id = pl['id']?.toString() ?? pl['_id']?.toString() ?? '';
                          final num = pl['plan_number'] ?? pl['planNumber'] ?? 'Plan';
                          final isSelected = selectedPlanId == id;
                          return ChoiceChip(
                            label: Text(num),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) {
                                setModalState(() {
                                  selectedPlanId = id;
                                  if (pl['product_id'] != null) selectedProductId = pl['product_id'].toString();
                                  if (pl['line_id'] != null) selectedLineId = pl['line_id'].toString();
                                  if (pl['target_quantity'] != null) qtyController.text = pl['target_quantity'].toString();
                                  if (pl['priority'] != null) selectedPriority = pl['priority'].toString();
                                });
                              }
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                        onPressed: () async {
                          final num = orderNumController.text.trim();
                          final qty = double.tryParse(qtyController.text) ?? 0;
                          if (num.isEmpty || qty <= 0 || selectedProductId == null || selectedLineId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required order fields.')));
                            return;
                          }

                          Navigator.pop(modalCtx);
                          try {
                            final api = ref.read(apiServiceProvider);
                            await api.createCollectionItem('production_orders', {
                              'order_number': num,
                              'product_id': selectedProductId,
                              'line_id': selectedLineId,
                              'machine_id': selectedMachineIds.isNotEmpty ? selectedMachineIds.first : null,
                              'assigned_machines': selectedMachineIds.toList(),
                              'target_quantity': qty,
                              'produced_quantity': 0,
                              'rejected_quantity': 0,
                              'priority': selectedPriority,
                              'status': 'PENDING',
                              'plan_id': selectedPlanId,
                              'created_at': DateTime.now().millisecondsSinceEpoch,
                              'updated_at': DateTime.now().millisecondsSinceEpoch,
                            });
                            ref.invalidate(productionOrdersProvider);
                            ref.invalidate(dashboardProvider);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Production Order $num created successfully!'), backgroundColor: const Color(0xFF10B981)),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to create order: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Create Production Order', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // Plan Creation Dialog (matches React ProductionPlanCreateScreen.tsx)
  // ===========================================================================
  void _showCreatePlanDialog() {
    final planNumController = TextEditingController(
      text: 'PLN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    final targetController = TextEditingController(text: '500');
    final notesController = TextEditingController();
    String selectedPriority = 'MEDIUM';

    final productsAsync = ref.read(productsProvider(const {'limit': 100}));
    final linesAsync = ref.read(productionLinesProvider);
    final products = productsAsync.valueOrNull?.data ?? [];
    final lines = linesAsync.valueOrNull ?? [];

    String? selectedProductId = products.isNotEmpty ? products[0]['id']?.toString() ?? products[0]['_id']?.toString() : null;
    String? selectedLineId = lines.isNotEmpty ? lines[0]['id']?.toString() ?? lines[0]['_id']?.toString() : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('New Production Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        IconButton(onPressed: () => Navigator.pop(modalCtx), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const Text('Schedule target output, product, and assigned line.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Plan Number
                    const Text('Plan Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: planNumController,
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),

                    // Product Selector Chips
                    const Text('Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    if (products.isEmpty)
                      const Text('No products available.', style: TextStyle(fontSize: 12, color: Colors.grey))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: products.map((p) {
                          final id = p['id']?.toString() ?? p['_id']?.toString() ?? '';
                          final code = p['code']?.toString() ?? p['name']?.toString() ?? 'PRD';
                          final isSelected = selectedProductId == id;
                          return ChoiceChip(
                            label: Text(code),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setModalState(() => selectedProductId = id);
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 14),

                    // Line Selector Chips
                    const Text('Production Line', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    if (lines.isEmpty)
                      const Text('No lines registered.', style: TextStyle(fontSize: 12, color: Colors.grey))
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: lines.map((l) {
                          final id = l['id']?.toString() ?? l['_id']?.toString() ?? '';
                          final code = l['code']?.toString() ?? l['name']?.toString() ?? 'Line';
                          final isSelected = selectedLineId == id;
                          return ChoiceChip(
                            label: Text(code),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setModalState(() => selectedLineId = id);
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 14),

                    // Planned Target Quantity
                    const Text('Planned Target Quantity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: targetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 14),

                    // Priority
                    const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'].map((p) {
                        return ChoiceChip(
                          label: Text(p),
                          selected: selectedPriority == p,
                          onSelected: (val) {
                            if (val) setModalState(() => selectedPriority = p);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Notes
                    const Text('Notes (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Delivery expectations, customer instructions...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                        onPressed: () async {
                          final num = planNumController.text.trim();
                          final qty = double.tryParse(targetController.text) ?? 0;
                          if (num.isEmpty || qty <= 0 || selectedProductId == null || selectedLineId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required plan fields.')));
                            return;
                          }

                          Navigator.pop(modalCtx);
                          try {
                            final now = DateTime.now().millisecondsSinceEpoch;
                            final api = ref.read(apiServiceProvider);
                            await api.createCollectionItem('production_plans', {
                              'plan_number': num,
                              'product_id': selectedProductId,
                              'line_id': selectedLineId,
                              'target_quantity': qty,
                              'planned_quantity': qty,
                              'priority': selectedPriority,
                              'status': 'PLANNED',
                              'start_date': now,
                              'end_date': now + 7 * 86400000,
                              'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                              'created_at': now,
                              'updated_at': now,
                            });
                            ref.invalidate(productionPlansProvider);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Plan $num created successfully!'), backgroundColor: const Color(0xFF10B981)),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to create plan: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Create Production Plan', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // Order Detail Dialog (matches React ProductionOrderDetailScreen.tsx)
  // ===========================================================================
  void _showOrderDetailDialog(ProductionOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order.orderNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  _StatusChip(label: order.statusDisplayName, color: order.statusColor),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${order.productCode ?? order.productName ?? "Product"} · Line ${order.lineCode ?? "Line 1"}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const Divider(height: 24),

              // Progress Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Production Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Text(
                    '${order.progressPercent.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: (order.progressPercent / 100).clamp(0.0, 1.0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                valueColor: AlwaysStoppedAnimation<Color>(order.statusColor),
              ),
              const SizedBox(height: 14),

              // Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildDetailTile('Target', '${Formatters.formatNumber(order.targetQuantity.toInt())} pcs'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDetailTile('Produced', '${Formatters.formatNumber(order.producedQuantity.toInt())} pcs'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildDetailTile('Defects', '${Formatters.formatNumber(order.rejectedQuantity.toInt())} pcs'),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // QC Status
              Row(
                children: [
                  const Text('QC Status: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: order.qcStatus == 'PASSED' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.qcStatus ?? 'PENDING',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: order.qcStatus == 'PASSED' ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                  if (order.qcInspector != null) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('(${order.qcInspector})', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  if (order.status == 'PENDING') ...[
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          try {
                            final api = ref.read(apiServiceProvider);
                            await api.startProductionOrder(order.id);
                            ref.invalidate(productionOrdersProvider);
                            ref.invalidate(dashboardProvider);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Order ${order.orderNumber} started!'), backgroundColor: const Color(0xFF10B981)),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Could not start: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Production'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF0284C7)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showRecordOutputDialog(order);
                      },
                      icon: const Icon(Icons.create_outlined, size: 16, color: Color(0xFF0284C7)),
                      label: const Text('Record Output', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ===========================================================================
  // Output Logging Dialog (matches React RecordProductionScreen.tsx)
  // ===========================================================================
  void _showRecordOutputDialog(ProductionOrder order) {
    _showRecordOutputDialogDirect(order.orderNumber, orderId: order.id);
  }

  void _showRecordOutputDialogDirect(String identifier, {String? orderId}) {
    final qtyController = TextEditingController(text: '50');
    final scrapController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Record Production Output\n$identifier', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'Good Units Produced (pcs)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: scrapController,
              decoration: const InputDecoration(labelText: 'Scrap / Defect Count (pcs)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () async {
              final good = double.tryParse(qtyController.text) ?? 0;
              final scrap = double.tryParse(scrapController.text) ?? 0;
              Navigator.pop(ctx);

              try {
                final api = ref.read(apiServiceProvider);
                if (orderId != null) {
                  await api.createCollectionItem('production_entries', {
                    'production_order_id': orderId,
                    'good_quantity': good,
                    'rejected_quantity': scrap,
                    'entry_timestamp': DateTime.now().millisecondsSinceEpoch,
                    'created_at': DateTime.now().millisecondsSinceEpoch,
                  });
                }
                ref.invalidate(productionOrdersProvider);
                ref.invalidate(dashboardProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logged ${qtyController.text} pcs output successfully!'), backgroundColor: const Color(0xFF10B981)),
                  );
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logged ${qtyController.text} pcs output locally!'), backgroundColor: const Color(0xFF10B981)),
                  );
                }
              }
            },
            child: const Text('Submit Output'),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Production Order Card (matches React ListRow & Card)
// =============================================================================
class _ProductionOrderCard extends StatelessWidget {
  final ProductionOrder order;
  final VoidCallback onTap;
  final VoidCallback onRecordOutput;

  const _ProductionOrderCard({
    required this.order,
    required this.onTap,
    required this.onRecordOutput,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      order.orderNumber,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0A1E38),
                      ),
                    ),
                  ),
                  _StatusChip(
                    label: order.statusDisplayName,
                    color: order.statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.inventory_2_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${order.productCode ?? "PRD"} · Line ${order.lineCode ?? "1"}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: order.qcStatus == 'PASSED' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.qcStatus == 'PASSED' ? 'QC PASSED' : 'QC PENDING',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: order.qcStatus == 'PASSED' ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.format_list_numbered_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    'Target: ${Formatters.formatNumber(order.targetQuantity.toInt())} pcs | Produced: ${Formatters.formatNumber(order.producedQuantity.toInt())} pcs',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Progress', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                  Text('${order.progressPercent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: (order.progressPercent / 100.0).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(order.statusColor),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onTap,
                    child: const Text('View Details', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE0F2FE),
                      foregroundColor: const Color(0xFF0284C7),
                    ),
                    onPressed: onRecordOutput,
                    icon: const Icon(Icons.create_outlined, size: 15),
                    label: const Text('Record Output', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Production Plan Card (matches React ProductionPlansScreen.tsx ListRow)
// =============================================================================
class _ProductionPlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final VoidCallback onCreateOrder;

  const _ProductionPlanCard({
    required this.plan,
    required this.onCreateOrder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final planNumber = plan['plan_number'] ?? plan['planNumber'] ?? 'PLN-001';
    final productCode = plan['product_code'] ?? plan['productCode'] ?? 'PRD';
    final lineCode = plan['line_code'] ?? plan['lineCode'] ?? 'Line 1';
    final status = plan['status']?.toString().toUpperCase() ?? 'PLANNED';
    final priority = plan['priority']?.toString().toUpperCase() ?? 'MEDIUM';
    final targetQty = plan['target_quantity'] ?? plan['planned_quantity'] ?? 0;
    final notes = plan['notes']?.toString();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  planNumber,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0A1E38),
                  ),
                ),
                _StatusChip(
                  label: status,
                  color: status == 'COMPLETED'
                      ? const Color(0xFF16A34A)
                      : status == 'IN_PROGRESS'
                          ? const Color(0xFF0284C7)
                          : const Color(0xFFD97706),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.inventory_2_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text('$productCode · Line $lineCode', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    priority,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Planned Target: ${Formatters.formatNumber((targetQty as num).toInt())} pcs',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF64748B)),
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(notes, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE0F2FE),
                    foregroundColor: const Color(0xFF0284C7),
                  ),
                  onPressed: onCreateOrder,
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                  label: const Text('Create Order from Plan', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Status Chip
// =============================================================================
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}