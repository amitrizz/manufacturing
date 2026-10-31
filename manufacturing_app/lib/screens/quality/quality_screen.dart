import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

class QualityScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  final String? initialOrderId;

  const QualityScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialOrderId,
  });

  @override
  ConsumerState<QualityScreen> createState() => _QualityScreenState();
}

class _QualityScreenState extends ConsumerState<QualityScreen> {
  int _selectedTab = 0; // 0: Waiting for QC, 1: Inspection History, 2: Rework Queue
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> _waitingOrders = [];
  List<Map<String, dynamic>> _allOrders = [];
  List<Map<String, dynamic>> _inspections = [];
  List<Map<String, dynamic>> _reworkOrders = [];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex.clamp(0, 2);
    _loadData().then((_) {
      if (widget.initialOrderId != null && mounted) {
        _openInspectionModal(preselectedOrderId: widget.initialOrderId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);

      // Fetch all required collections
      List<Map<String, dynamic>> allOrdersList = [];
      List<Map<String, dynamic>> rawInspections = [];
      List<Map<String, dynamic>> rawReworks = [];
      List<Map<String, dynamic>> rawProducts = [];

      try {
        final res = await apiService.getCollection('production_orders', queryParams: {'limit': 200});
        allOrdersList = res.data;
      } catch (_) {}

      try {
        final res = await apiService.getCollection('quality_inspections', queryParams: {'limit': 200});
        rawInspections = res.data;
      } catch (_) {}

      try {
        final res = await apiService.getCollection('rework_orders', queryParams: {'limit': 200});
        rawReworks = res.data;
      } catch (_) {}

      try {
        final res = await apiService.getCollection('products', queryParams: {'limit': 300});
        rawProducts = res.data;
      } catch (_) {}

      // Build product map
      final prodMap = <String, Map<String, dynamic>>{};
      for (final p in rawProducts) {
        final id = p['id']?.toString() ?? p['_id']?.toString() ?? '';
        if (id.isNotEmpty) prodMap[id] = p;
      }

      // Build order map
      final ordMap = <String, Map<String, dynamic>>{};
      for (final o in allOrdersList) {
        final id = o['id']?.toString() ?? o['_id']?.toString() ?? '';
        if (id.isNotEmpty) ordMap[id] = o;
      }

      // Enriched Waiting Orders: Active orders waiting for QC approval
      final waiting = allOrdersList.where((o) {
        final status = (o['status']?.toString() ?? '').toUpperCase();
        if (status == 'CANCELLED') return false;
        final qcStatus = (o['qc_status']?.toString() ?? '').toUpperCase();
        return qcStatus != 'PASSED' && qcStatus != 'WAIVED';
      }).map((o) {
        final prodId = o['product_id']?.toString() ?? '';
        final prod = prodMap[prodId];
        return {
          ...o,
          'product_name': o['product_name'] ?? prod?['name'] ?? 'Product',
          'product_code': o['product_code'] ?? prod?['code'] ?? '',
        };
      }).toList();

      // Enriched Inspections
      final enrichedInspections = rawInspections.map((i) {
        final orderId = i['production_order_id']?.toString() ?? '';
        final prodId = i['product_id']?.toString() ?? '';
        final ord = ordMap[orderId];
        final prod = prodMap[prodId] ?? (ord != null ? prodMap[ord['product_id']?.toString() ?? ''] : null);

        return {
          ...i,
          'order_number': i['order_number'] ?? ord?['order_number'] ?? '',
          'product_name': i['product_name'] ?? prod?['name'] ?? ord?['product_name'] ?? '',
          'product_code': i['product_code'] ?? prod?['code'] ?? ord?['product_code'] ?? '',
        };
      }).toList();

      // Sort inspections newest first
      enrichedInspections.sort((a, b) {
        final tA = (a['inspected_at'] ?? a['created_at'] ?? 0) as num;
        final tB = (b['inspected_at'] ?? b['created_at'] ?? 0) as num;
        return tB.compareTo(tA);
      });

      // Enriched Reworks
      final enrichedReworks = rawReworks.map((r) {
        final prodId = r['product_id']?.toString() ?? '';
        final prod = prodMap[prodId];
        return {
          ...r,
          'product_name': r['product_name'] ?? prod?['name'] ?? 'Product',
          'product_code': r['product_code'] ?? prod?['code'] ?? '',
        };
      }).toList();

      enrichedReworks.sort((a, b) {
        final tA = (a['created_at'] ?? 0) as num;
        final tB = (b['created_at'] ?? 0) as num;
        return tB.compareTo(tA);
      });

      if (mounted) {
        setState(() {
          _allOrders = allOrdersList;
          _waitingOrders = waiting;
          _inspections = enrichedInspections;
          _reworkOrders = enrichedReworks;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // Stats calculation
  int get _passCount => _inspections.where((i) {
        final res = (i['overall_result'] ?? i['result'] ?? '').toString().toUpperCase();
        return res == 'PASS' || res == 'PASSED';
      }).length;

  int get _passRate => _inspections.isNotEmpty
      ? ((_passCount / _inspections.length) * 100).round()
      : 100;

  // Filtered lists based on search query
  List<Map<String, dynamic>> get _filteredWaiting {
    if (_searchQuery.trim().isEmpty) return _waitingOrders;
    final q = _searchQuery.trim().toLowerCase();
    return _waitingOrders.where((o) {
      final orderNum = (o['order_number']?.toString() ?? '').toLowerCase();
      final prodName = (o['product_name']?.toString() ?? '').toLowerCase();
      final prodCode = (o['product_code']?.toString() ?? '').toLowerCase();
      return orderNum.contains(q) || prodName.contains(q) || prodCode.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredInspections {
    if (_searchQuery.trim().isEmpty) return _inspections;
    final q = _searchQuery.trim().toLowerCase();
    return _inspections.where((i) {
      final batch = (i['batch_number']?.toString() ?? i['inspection_number']?.toString() ?? '').toLowerCase();
      final insp = (i['inspector']?.toString() ?? '').toLowerCase();
      final orderNum = (i['order_number']?.toString() ?? '').toLowerCase();
      final prodName = (i['product_name']?.toString() ?? '').toLowerCase();
      return batch.contains(q) || insp.contains(q) || orderNum.contains(q) || prodName.contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredReworks {
    if (_searchQuery.trim().isEmpty) return _reworkOrders;
    final q = _searchQuery.trim().toLowerCase();
    return _reworkOrders.where((r) {
      final num = (r['rework_number']?.toString() ?? '').toLowerCase();
      final reason = (r['reason'] ?? r['defect_reason'] ?? '').toString().toLowerCase();
      final prodName = (r['product_name']?.toString() ?? '').toLowerCase();
      return num.contains(q) || reason.contains(q) || prodName.contains(q);
    }).toList();
  }

  void _onBackPress() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/management');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E38),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          tooltip: 'Back to Management',
          onPressed: _onBackPress,
        ),
        title: const Text(
          'Quality Assurance & Control',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            tooltip: 'Refresh Data',
            onPressed: _loadData,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: () => _openInspectionModal(),
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: const Text(
                'New Inspection',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner
              _buildHeaderBanner(),
              const SizedBox(height: 12),

              // KPI Row (3 Interactive Cards)
              _buildKpiRow(),
              const SizedBox(height: 16),

              // Segment Switcher (3 Tabs)
              _buildSegmentSwitcher(),
              const SizedBox(height: 12),

              // Search Bar
              _buildSearchBar(),
              const SizedBox(height: 16),

              // Error banner if any
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadData,
                        child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Content based on selected tab
              if (_loading && _waitingOrders.isEmpty && _inspections.isEmpty && _reworkOrders.isEmpty)
                AppShimmer(
                  child: Column(
                    children: List.generate(4, (_) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ShimmerBox(width: 100, height: 16, borderRadius: 4),
                              ShimmerBox(width: 70, height: 20, borderRadius: 10),
                            ],
                          ),
                          SizedBox(height: 8),
                          ShimmerBox(width: 200, height: 17, borderRadius: 4),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              ShimmerBox(width: 90, height: 12, borderRadius: 4),
                              SizedBox(width: 8),
                              ShimmerBox(width: 80, height: 12, borderRadius: 4),
                            ],
                          ),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ShimmerBox(width: 110, height: 14, borderRadius: 4),
                              ShimmerBox(width: 80, height: 14, borderRadius: 4),
                            ],
                          ),
                        ],
                      ),
                    )),
                  ),
                )
              else if (_selectedTab == 0)
                _buildWaitingTab()
              else if (_selectedTab == 1)
                _buildHistoryTab()
              else
                _buildReworkTab(),
            ],
          ),
        ),
      ),
    );
  }

  // Header Banner
  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Icon(Icons.verified_user_rounded, color: Color(0xFF0284C7), size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quality Assurance & Control',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pre-production clearance, inspection checks & production approvals',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3 Interactive KPI Cards
  Widget _buildKpiRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final cards = [
          _buildKpiCard(
            tabIndex: 0,
            label: 'WAITING FOR QC',
            value: '${_waitingOrders.length}',
            sub: 'Orders waiting for start',
            icon: Icons.warning_amber_rounded,
            iconColor: _waitingOrders.isNotEmpty ? const Color(0xFFF59E0B) : const Color(0xFF94A3B8),
            valueColor: _waitingOrders.isNotEmpty ? const Color(0xFFD97706) : const Color(0xFF0F172A),
          ),
          _buildKpiCard(
            tabIndex: 1,
            label: 'PASS RATE',
            value: '$_passRate%',
            sub: '${_inspections.length} recorded tests',
            icon: Icons.shield_rounded,
            iconColor: const Color(0xFF16A34A),
            valueColor: const Color(0xFF16A34A),
          ),
          _buildKpiCard(
            tabIndex: 2,
            label: 'REWORK QUEUE',
            value: '${_reworkOrders.length}',
            sub: 'Defect items in rework',
            icon: Icons.refresh_rounded,
            iconColor: _reworkOrders.isNotEmpty ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
            valueColor: _reworkOrders.isNotEmpty ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
          ),
        ];

        if (isNarrow) {
          return Column(
            children: cards
                .map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c))
                .toList(),
          );
        }

        return Row(
          children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required int tabIndex,
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color iconColor,
    required Color valueColor,
  }) {
    final isActive = _selectedTab == tabIndex;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = tabIndex;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: isActive ? 0.06 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isActive ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                    letterSpacing: 0.5,
                  ),
                ),
                Icon(icon, size: 16, color: iconColor),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Segment Switcher (3 Tabs)
  Widget _buildSegmentSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildSegmentItem(0, 'Waiting for QC (${_waitingOrders.length})'),
          _buildSegmentItem(1, 'Inspection History (${_inspections.length})'),
          _buildSegmentItem(2, 'Rework (${_reworkOrders.length})'),
        ],
      ),
    );
  }

  Widget _buildSegmentItem(int index, String title) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              color: isActive ? const Color(0xFF0A1E38) : const Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // Search Bar
  Widget _buildSearchBar() {
    String placeholder;
    switch (_selectedTab) {
      case 0:
        placeholder = 'Search pending orders by number/product...';
        break;
      case 1:
        placeholder = 'Search inspections by batch/inspector/order...';
        break;
      case 2:
      default:
        placeholder = 'Search rework orders by number/reason...';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            InkWell(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
              child: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
            ),
        ],
      ),
    );
  }

  // Tab 0: Waiting for QC
  Widget _buildWaitingTab() {
    final list = _filteredWaiting;

    if (list.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 48, color: Color(0xFF16A34A)),
            const SizedBox(height: 12),
            const Text(
              'All Orders Cleared',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            const Text(
              'There are currently no orders pending pre-production quality inspection. All work orders are approved and can run.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go('/production'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0A1E38),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('View Production Orders →', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
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
        return _buildWaitingOrderCard(order);
      },
    );
  }

  Widget _buildWaitingOrderCard(Map<String, dynamic> order) {
    final orderId = order['id']?.toString() ?? order['_id']?.toString() ?? '';
    final orderNum = order['order_number']?.toString() ?? 'ORD-000';
    final prodName = order['product_name']?.toString() ?? order['product_code']?.toString() ?? 'Product';
    final lineCode = order['line_code']?.toString() ?? order['line_id']?.toString() ?? 'Line A';
    final machineCode = order['machine_code']?.toString() ?? order['machine_id']?.toString() ?? 'Auto-assign';
    final priority = (order['priority']?.toString() ?? 'MEDIUM').toUpperCase();
    final targetQty = (order['target_quantity'] as num?)?.toInt() ?? 0;

    final isUrgent = priority == 'CRITICAL' || priority == 'HIGH';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Number & Warning Badge & Priority
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          orderNum,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFB45309)),
                              SizedBox(width: 4),
                              Text(
                                'AWAITING PRE-PRODUCTION QC',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFB45309),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      prodName,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        text: 'Line: ',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        children: [
                          TextSpan(
                            text: lineCode,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                          const TextSpan(text: ' • Machine: '),
                          TextSpan(
                            text: machineCode,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isUrgent ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Stats Row: Target Output & Production State
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Target Output', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(
                    '${Formatters.formatNumber(targetQty)} pcs',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Production State', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.lock, size: 12, color: Color(0xFFD97706)),
                      SizedBox(width: 4),
                      Text(
                        'Locked (QC Required)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Button: Inspect & Approve
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openInspectionModal(preselectedOrderId: orderId),
              icon: const Icon(Icons.shield_rounded, size: 16, color: Colors.white),
              label: const Text(
                'Inspect & Approve for Production →',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tab 1: Inspection History
  Widget _buildHistoryTab() {
    final list = _filteredInspections;

    if (list.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 48, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'No Inspection Records',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
            SizedBox(height: 6),
            Text(
              'No quality inspection tests have been completed yet.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildHistoryCard(item);
      },
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final batchNum = item['batch_number']?.toString() ?? item['inspection_number']?.toString() ?? 'BATCH';
    final orderNum = item['order_number']?.toString();
    final prodName = item['product_name']?.toString();
    final inspector = item['inspector']?.toString() ?? 'QC Inspector';
    final overallResult = (item['overall_result'] ?? item['result'] ?? 'PASS').toString().toUpperCase();
    final isPass = overallResult == 'PASS' || overallResult == 'PASSED';
    final rejectionReason = item['rejection_reason']?.toString();
    final rejectionAction = item['rejection_action']?.toString() ?? 'HOLD';

    final timestamp = (item['inspected_at'] ?? item['created_at']) as num?;
    String dateStr = 'Unknown date';
    if (timestamp != null && timestamp > 0) {
      dateStr = Formatters.formatDateTime(DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batchNum,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    if (orderNum != null && orderNum.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Order: $orderNum${prodName != null && prodName.isNotEmpty ? ' • $prodName' : ''}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      'Inspector: $inspector • $dateStr',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPass ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPass ? 'PASS' : 'FAIL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isPass ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
              ),
            ],
          ),

          if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reason: $rejectionReason ($rejectionAction)',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Tab 2: Rework Queue
  Widget _buildReworkTab() {
    final list = _filteredReworks;
    final openCount = _reworkOrders.where((r) => (r['status']?.toString() ?? '').toUpperCase() != 'COMPLETED').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rework & Defect Action Banner
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE9E7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh_rounded, color: Color(0xFFD84315), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rework & Defect Tickets',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_reworkOrders.length} tickets total • $openCount awaiting rework',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _openLogDefectModal,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD84315),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add_alert_rounded, size: 16),
                label: const Text('Log Defect', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),

        if (list.isEmpty)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.restart_alt_rounded, size: 48, color: Color(0xFF94A3B8)),
                const SizedBox(height: 12),
                const Text(
                  'Rework Queue Empty',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                const Text(
                  'No defective batches require rework at this time. Click "Log Defect" to report a defective batch.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _openLogDefectModal,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Log New Defect'),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = list[index];
              return _buildReworkCard(item);
            },
          ),
      ],
    );
  }

  Widget _buildReworkCard(Map<String, dynamic> item) {
    final reworkId = item['id']?.toString() ?? item['_id']?.toString() ?? '';
    final reworkNum = item['rework_number']?.toString() ?? 'RWK-000';
    final reason = item['defect_reason']?.toString() ?? item['reason']?.toString() ?? 'Defects observed';
    final status = (item['status']?.toString() ?? 'OPEN').toUpperCase();
    final isCompleted = status == 'COMPLETED';
    final qty = (item['quantity'] as num?)?.toInt() ?? 0;
    final batchNum = item['batch_number']?.toString() ?? '';
    final prodName = item['product_name']?.toString() ?? '';
    final notes = item['notes']?.toString();

    final timestamp = (item['created_at']) as num?;
    String dateStr = 'Recent';
    if (timestamp != null && timestamp > 0) {
      dateStr = Formatters.formatDateTime(DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()));
    }

    final completedTimestamp = (item['completed_at']) as num?;
    String completedDateStr = '';
    if (completedTimestamp != null && completedTimestamp > 0) {
      completedDateStr = Formatters.formatDateTime(DateTime.fromMillisecondsSinceEpoch(completedTimestamp.toInt()));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reworkNum,
                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    if (prodName.isNotEmpty || batchNum.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${prodName.isNotEmpty ? prodName : "Product"}${batchNum.isNotEmpty ? " • Batch: $batchNum" : ""}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      'Defect: $reason • Logged: $dateStr',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isCompleted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  text: 'Defect Qty: ',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  children: [
                    TextSpan(
                      text: '${Formatters.formatNumber(qty)} pcs',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFD84315)),
                    ),
                  ],
                ),
              ),
              if (!isCompleted)
                FilledButton.tonal(
                  onPressed: () => _showCompleteReworkDialog(reworkId, reworkNum),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFECFDF5),
                    foregroundColor: const Color(0xFF15803D),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Complete Rework', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
                )
              else if (completedDateStr.isNotEmpty)
                Text(
                  'Resolved $completedDateStr',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                ),
            ],
          ),
          if (isCompleted && notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Action: $notes',
                style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF166534)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCompleteReworkDialog(String reworkId, String reworkNum) {
    final notesController = TextEditingController();
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: Text('Complete Rework ($reworkNum)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter resolution notes or corrective action taken for this defective batch:',
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Re-machined to tolerance, re-tested and passed',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                  onPressed: submitting
                      ? null
                      : () async {
                          setDialogState(() => submitting = true);
                          await _completeRework(reworkId, notes: notesController.text.trim());
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  child: submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm Completed'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _completeRework(String reworkId, {String? notes}) async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      await apiService.updateCollectionItem('rework_orders', reworkId, {
        'status': 'COMPLETED',
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'completed_at': now,
        'updated_at': now,
      });

      // Activity log
      try {
        await apiService.createCollectionItem('activity_history', {
          'event_type': 'REWORK_COMPLETED',
          'title': 'Rework ticket completed',
          'description': notes ?? 'Rework batch corrected and verified',
          'reference_type': 'rework_order',
          'reference_id': reworkId,
          'timestamp': now,
          'created_at': now,
        });
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rework marked as completed!'), backgroundColor: Color(0xFF16A34A)),
        );
      }
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update rework: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Modal to log a new defect / rework ticket
  void _openLogDefectModal() {
    final validOrders = _allOrders.where((o) => (o['status']?.toString() ?? '').toUpperCase() != 'CANCELLED').toList();
    if (validOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active production orders available to log defects for.')),
      );
      return;
    }

    String selectedOrderId = validOrders.first['id']?.toString() ?? validOrders.first['_id']?.toString() ?? '';
    final qtyController = TextEditingController(text: '5');
    final reasonController = TextEditingController();
    final batchController = TextEditingController(
      text: validOrders.first['batch_number']?.toString() ?? 'BATCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    String selectedDefectTag = 'Tolerance Deviation';
    bool submitting = false;

    final defectTags = [
      'Tolerance Deviation',
      'Surface Scratch',
      'Assembly Flaw',
      'Warping / Dent',
      'Material Flaw',
      'Dimension Out of Bounds',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentOrder = validOrders.firstWhere(
              (o) => (o['id']?.toString() == selectedOrderId) || (o['_id']?.toString() == selectedOrderId),
              orElse: () => validOrders.first,
            );

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.report_problem_rounded, color: Color(0xFFD84315), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Log Defect / Rework Order',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Order Selector
                    const Text('Select Production Order *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedOrderId,
                          isExpanded: true,
                          items: validOrders.map((o) {
                            final id = o['id']?.toString() ?? o['_id']?.toString() ?? '';
                            final num = o['order_number'] ?? 'Order';
                            final prod = o['product_name'] ?? 'Product';
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text('$num - $prod', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                selectedOrderId = val;
                                final ord = validOrders.firstWhere(
                                  (o) => (o['id']?.toString() == val) || (o['_id']?.toString() == val),
                                );
                                if (ord['batch_number'] != null) {
                                  batchController.text = ord['batch_number'].toString();
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Batch & Quantity Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Batch Number *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: batchController,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Defect Qty (pcs) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: qtyController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Defect Category Chips
                    const Text('Defect Category *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: defectTags.map((tag) {
                        final isSelected = selectedDefectTag == tag;
                        return InkWell(
                          onTap: () => setSheetState(() => selectedDefectTag = tag),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFD84315) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFD84315) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : const Color(0xFF475569),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Detailed Description / Notes
                    const Text('Defect Notes / Specific Reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Dimensional tolerance +0.8mm exceeding allowable bounds',
                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit & Cancel buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: submitting ? null : () => Navigator.pop(sheetCtx),
                          child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: submitting
                              ? null
                              : () async {
                                  final qty = int.tryParse(qtyController.text.trim()) ?? 0;
                                  if (qty <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a valid defective quantity greater than 0.')),
                                    );
                                    return;
                                  }

                                  setSheetState(() => submitting = true);
                                  try {
                                    final apiService = ref.read(apiServiceProvider);
                                    final now = DateTime.now().millisecondsSinceEpoch;
                                    final seq = (_reworkOrders.length + 1).toString().padLeft(4, '0');
                                    final reworkNumber = 'RWK-$seq';
                                    final reworkId = 'rwk_${now}_$seq';

                                    final defectReason = reasonController.text.trim().isNotEmpty
                                        ? '$selectedDefectTag: ${reasonController.text.trim()}'
                                        : selectedDefectTag;

                                    // Create rework order in MongoDB
                                    await apiService.createCollectionItem('rework_orders', {
                                      '_id': reworkId,
                                      'id': reworkId,
                                      'rework_number': reworkNumber,
                                      'production_order_id': selectedOrderId,
                                      'product_id': currentOrder['product_id'] ?? '',
                                      'batch_number': batchController.text.trim(),
                                      'quantity': qty,
                                      'defect_reason': defectReason,
                                      'status': 'OPEN',
                                      'created_at': now,
                                      'updated_at': now,
                                    });

                                    // Activity Log
                                    try {
                                      await apiService.createCollectionItem('activity_history', {
                                        'event_type': 'DEFECT_LOGGED',
                                        'title': 'Defect logged: $reworkNumber',
                                        'description': '$qty pcs flagged for rework: $defectReason',
                                        'reference_type': 'rework_order',
                                        'reference_id': reworkId,
                                        'timestamp': now,
                                        'created_at': now,
                                      });
                                    } catch (_) {}

                                    if (mounted && sheetCtx.mounted) {
                                      Navigator.pop(sheetCtx);
                                    }
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Defect logged successfully ($reworkNumber)!'),
                                          backgroundColor: const Color(0xFF16A34A),
                                        ),
                                      );
                                      _loadData();
                                    }
                                  } catch (e) {
                                    setSheetState(() => submitting = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to log defect: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFD84315),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: submitting
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Log Defect & Queue Rework', style: TextStyle(fontWeight: FontWeight.w700)),
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

  // Pre-Production Quality Inspection Modal
  void _openInspectionModal({String? preselectedOrderId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PreProductionInspectionSheet(
          waitingOrders: _waitingOrders,
          allOrders: _allOrders.where((o) => (o['status']?.toString() ?? '').toUpperCase() != 'CANCELLED').toList(),
          preselectedOrderId: preselectedOrderId,
          onComplete: () {
            _loadData();
          },
        );
      },
    );
  }
}

// Bottom Sheet / Dialog for Pre-Production Quality Check
class _PreProductionInspectionSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> waitingOrders;
  final List<Map<String, dynamic>> allOrders;
  final String? preselectedOrderId;
  final VoidCallback onComplete;

  const _PreProductionInspectionSheet({
    required this.waitingOrders,
    required this.allOrders,
    this.preselectedOrderId,
    required this.onComplete,
  });

  @override
  ConsumerState<_PreProductionInspectionSheet> createState() => _PreProductionInspectionSheetState();
}

class _PreProductionInspectionSheetState extends ConsumerState<_PreProductionInspectionSheet> {
  String _filterMode = 'waiting'; // 'waiting' | 'all'
  String _orderSearchQuery = '';
  late String _selectedOrderId;
  Map<String, dynamic>? _selectedOrder;

  // Inspector & Notes
  late TextEditingController _inspectorController;
  late TextEditingController _notesController;

  // 5 Checklist booleans
  bool _rawMaterialVerified = true;
  bool _toolingChecked = true;
  bool _firstPieceApproved = true;
  bool _machineParametersSet = true;
  bool _safetyGuardsActive = true;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    final authState = ref.read(authStateProvider);
    final defaultInspector = authState.userName != null && authState.userName!.isNotEmpty
        ? '${authState.userName} (QA Inspector)'
        : 'Quality Inspector';
    _inspectorController = TextEditingController(text: defaultInspector);
    _notesController = TextEditingController();

    // Determine initial selection
    String initialId = widget.preselectedOrderId ?? '';
    if (initialId.isEmpty && widget.waitingOrders.isNotEmpty) {
      initialId = widget.waitingOrders.first['id']?.toString() ?? widget.waitingOrders.first['_id']?.toString() ?? '';
    }
    if (initialId.isEmpty && widget.allOrders.isNotEmpty) {
      initialId = widget.allOrders.first['id']?.toString() ?? widget.allOrders.first['_id']?.toString() ?? '';
    }

    _selectedOrderId = initialId;

    if (_selectedOrderId.isNotEmpty) {
      _selectedOrder = widget.waitingOrders.firstWhere(
        (o) => (o['id']?.toString() ?? o['_id']?.toString()) == _selectedOrderId,
        orElse: () => widget.allOrders.firstWhere(
          (o) => (o['id']?.toString() ?? o['_id']?.toString()) == _selectedOrderId,
          orElse: () => <String, dynamic>{},
        ),
      );
      if (_selectedOrder!.isEmpty) _selectedOrder = null;
    }
  }

  @override
  void dispose() {
    _inspectorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _displayedOrders {
    var source = _filterMode == 'waiting' ? widget.waitingOrders : widget.allOrders;
    if (_orderSearchQuery.trim().isNotEmpty) {
      final q = _orderSearchQuery.trim().toLowerCase();
      source = source.where((o) {
        final orderNum = (o['order_number']?.toString() ?? '').toLowerCase();
        final prodName = (o['product_name']?.toString() ?? '').toLowerCase();
        final prodCode = (o['product_code']?.toString() ?? '').toLowerCase();
        return orderNum.contains(q) || prodName.contains(q) || prodCode.contains(q);
      }).toList();
    }
    return source;
  }

  void _onSelectOrder(Map<String, dynamic> order) {
    setState(() {
      _selectedOrderId = order['id']?.toString() ?? order['_id']?.toString() ?? '';
      _selectedOrder = order;
    });
  }

  Future<void> _handleApproveInspection() async {
    if (_selectedOrder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an order waiting for quality check.')),
      );
      return;
    }

    final orderNum = _selectedOrder!['order_number']?.toString() ?? 'Order';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 22),
            SizedBox(width: 8),
            Text('Approve Quality Check', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Text(
          'Approve order $orderNum for production clearance?\n\n'
          'Pre-production inspection will be recorded as PASSED. Production state will unlock.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
            child: const Text('Confirm Approval', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _submitting = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final inspector = _inspectorController.text.trim().isNotEmpty
          ? _inspectorController.text.trim()
          : 'Quality Inspector';

      final checklistParts = <String>[];
      if (_toolingChecked) checklistParts.add('Tooling Verified');
      if (_rawMaterialVerified) checklistParts.add('Raw Material Batch OK');
      if (_firstPieceApproved) checklistParts.add('1st Piece Sample Approved');
      if (_machineParametersSet) checklistParts.add('Parameters Calibrated');
      if (_safetyGuardsActive) checklistParts.add('Safety Verified');

      final notesText = _notesController.text.trim();
      final notesSummary = [
        if (notesText.isNotEmpty) notesText,
        if (checklistParts.isNotEmpty) '[${checklistParts.join(', ')}]',
      ].join(' - ');

      // 1. Update order
      await apiService.updateCollectionItem('production_orders', _selectedOrderId, {
        'qc_status': 'PASSED',
        'qc_inspected_at': now,
        'qc_inspector': inspector,
        'qc_notes': notesSummary,
        'updated_at': now,
      });

      // 2. Insert into quality_inspections
      final inspId = 'insp_${now}_${_selectedOrderId.substring(0, _selectedOrderId.length > 5 ? 5 : _selectedOrderId.length)}';
      await apiService.createCollectionItem('quality_inspections', {
        '_id': inspId,
        'id': inspId,
        'batch_number': 'PRE-QC-$orderNum',
        'inspection_number': 'INS-${now.toString().substring(now.toString().length > 6 ? now.toString().length - 6 : 0)}',
        'production_order_id': _selectedOrderId,
        'product_id': _selectedOrder!['product_id'],
        'quantity': _selectedOrder!['target_quantity'] ?? 1,
        'inspector': inspector,
        'overall_result': 'PASS',
        'status': 'COMPLETED',
        'result': 'PASS',
        'rejected_quantity': 0,
        'rejection_reason': null,
        'rejection_action': null,
        'inspected_at': now,
        'created_at': now,
        'updated_at': now,
      });

      // 3. Log to activity_history
      await apiService.createCollectionItem('activity_history', {
        'event_type': 'PRE_PRODUCTION_QC',
        'title': 'Pre-Production QC: PASSED',
        'description': '$orderNum ($inspector): ${notesSummary.isNotEmpty ? notesSummary : 'Verified offline'}',
        'reference_type': 'production_order',
        'reference_id': _selectedOrderId,
        'timestamp': now,
        'created_at': now,
      }).catchError((_) => <String, dynamic>{});

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onComplete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16A34A),
          content: Text('Order $orderNum approved. Production unlocked!'),
          action: SnackBarAction(
            label: 'View Orders',
            textColor: Colors.white,
            onPressed: () => context.go('/production'),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: const Color(0xFFDC2626), content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleRejectInspection() async {
    if (_selectedOrder == null) return;

    final orderNum = _selectedOrder!['order_number']?.toString() ?? 'Order';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('Hold Order (QC Failed)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
        content: Text(
          'Are you sure you want to reject the pre-production quality check for $orderNum?\n\n'
          'Production will remain locked.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Confirm Reject', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _submitting = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final inspector = _inspectorController.text.trim().isNotEmpty
          ? _inspectorController.text.trim()
          : 'Quality Inspector';
      final notesText = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : 'Pre-production quality check rejected by QA';

      // 1. Update order
      await apiService.updateCollectionItem('production_orders', _selectedOrderId, {
        'qc_status': 'FAILED',
        'qc_inspected_at': now,
        'qc_inspector': inspector,
        'qc_notes': notesText,
        'updated_at': now,
      });

      // 2. Insert into quality_inspections
      final inspId = 'insp_${now}_${_selectedOrderId.substring(0, _selectedOrderId.length > 5 ? 5 : _selectedOrderId.length)}';
      await apiService.createCollectionItem('quality_inspections', {
        '_id': inspId,
        'id': inspId,
        'batch_number': 'PRE-QC-$orderNum',
        'inspection_number': 'INS-${now.toString().substring(now.toString().length > 6 ? now.toString().length - 6 : 0)}',
        'production_order_id': _selectedOrderId,
        'product_id': _selectedOrder!['product_id'],
        'quantity': _selectedOrder!['target_quantity'] ?? 1,
        'inspector': inspector,
        'overall_result': 'FAIL',
        'status': 'COMPLETED',
        'result': 'FAIL',
        'rejected_quantity': 1,
        'rejection_reason': notesText,
        'rejection_action': 'HOLD',
        'inspected_at': now,
        'created_at': now,
        'updated_at': now,
      });

      // 3. Log to activity_history
      await apiService.createCollectionItem('activity_history', {
        'event_type': 'PRE_PRODUCTION_QC',
        'title': 'Pre-Production QC: FAILED',
        'description': '$orderNum ($inspector): $notesText',
        'reference_type': 'production_order',
        'reference_id': _selectedOrderId,
        'timestamp': now,
        'created_at': now,
      }).catchError((_) => <String, dynamic>{});

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onComplete();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Order $orderNum set to QC FAILED. Production is locked.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: const Color(0xFFDC2626), content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFF0284C7), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pre-Production Quality Check',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Inspect and approve pending work orders before production starts',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Order Selector Carousel
                  _buildOrderSelectorSection(),
                  const SizedBox(height: 16),

                  // 2. Selected Order Detail Card
                  if (_selectedOrder != null) ...[
                    _buildSelectedOrderDetail(),
                    const SizedBox(height: 16),
                  ],

                  // 3. Pre-Production Inspection Checklist Card
                  if (_selectedOrder != null) ...[
                    _buildChecklistCard(),
                    const SizedBox(height: 16),
                  ],

                  // 4. Inspector Name & Remarks Card
                  if (_selectedOrder != null) ...[
                    _buildInspectorAndNotesCard(),
                    const SizedBox(height: 20),

                    // 5. Action Buttons
                    _buildActionButtons(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Order Selector Section
  Widget _buildOrderSelectorSection() {
    final orders = _displayedOrders;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _filterMode == 'waiting'
                    ? 'Orders Waiting QC (${widget.waitingOrders.length})'
                    : 'All Orders (${widget.allOrders.length})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              Row(
                children: [
                  _buildModePill('waiting', 'Waiting QC'),
                  const SizedBox(width: 6),
                  _buildModePill('all', 'All Orders'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text('Select an order to inspect', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 10),

          // Search order input if many orders
          if (widget.allOrders.length > 2 || widget.waitingOrders.length > 2) ...[
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 15, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _orderSearchQuery = v),
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        hintText: 'Search order number or product...',
                        hintStyle: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Horizontal chips
          if (orders.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Text(
                _filterMode == 'waiting'
                    ? 'No orders are currently waiting for pre-production QC.'
                    : 'No matching production orders found.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            )
          else
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final o = orders[idx];
                  final oId = o['id']?.toString() ?? o['_id']?.toString() ?? '';
                  final isSelected = oId == _selectedOrderId;
                  final priority = (o['priority']?.toString() ?? 'MEDIUM').toUpperCase();
                  final isUrgent = priority == 'CRITICAL' || priority == 'HIGH';

                  return InkWell(
                    onTap: () => _onSelectOrder(o),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 170,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF0F9FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                o['order_number']?.toString() ?? 'ORD',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? const Color(0xFF0284C7) : const Color(0xFF0F172A),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isUrgent ? const Color(0xFFFEE2E2) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  priority,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: isUrgent ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            o['product_name']?.toString() ?? o['product_code']?.toString() ?? 'Product',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Qty: ${Formatters.formatNumber((o['target_quantity'] as num?)?.toInt() ?? 0)} pcs • ${o['line_code'] ?? 'Line'}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModePill(String mode, String label) {
    final isActive = _filterMode == mode;
    return InkWell(
      onTap: () => setState(() => _filterMode = mode),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // 2. Selected Order Detail Card
  Widget _buildSelectedOrderDetail() {
    final o = _selectedOrder!;
    final orderNum = o['order_number']?.toString() ?? 'ORD';
    final prodName = o['product_name']?.toString() ?? o['product_code']?.toString() ?? 'Product';
    final prodCode = o['product_code']?.toString() ?? '';
    final priority = o['priority']?.toString() ?? 'MEDIUM';
    final targetQty = (o['target_quantity'] as num?)?.toInt() ?? 0;
    final line = o['line_code']?.toString() ?? o['line_id']?.toString() ?? 'Assigned';
    final machine = o['machine_code']?.toString() ?? o['machine_id']?.toString() ?? 'Auto-assign';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                orderNum,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, size: 11, color: Color(0xFFB45309)),
                    SizedBox(width: 4),
                    Text(
                      'PRODUCTION LOCKED',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            prodName,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          Text(
            'Code: $prodCode • Priority: $priority',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Target Qty', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                    Text(
                      '${Formatters.formatNumber(targetQty)} pcs',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Production Line', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                      Text(
                        line,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
              ),
              Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Machine', style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                      Text(
                        machine,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Pre-Production Inspection Checklist
  Widget _buildChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.checklist_rounded, size: 20, color: Color(0xFF0A1E38)),
              SizedBox(width: 8),
              Text(
                'Pre-Production Inspection Checklist',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Verify all offline parameters before approving production clearance.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          _buildCheckItem(
            value: _rawMaterialVerified,
            onChanged: (v) => setState(() => _rawMaterialVerified = v),
            title: 'Raw Material Batch Verified',
            sub: 'Specifications, lot certificates, and raw inputs are within tolerance.',
          ),
          _buildCheckItem(
            value: _toolingChecked,
            onChanged: (v) => setState(() => _toolingChecked = v),
            title: 'Tooling & Machine Calibration Checked',
            sub: 'Dies, molds, cutter alignment, and speeds verified on machine.',
          ),
          _buildCheckItem(
            value: _firstPieceApproved,
            onChanged: (v) => setState(() => _firstPieceApproved = v),
            title: 'First-Piece Sample Approved',
            sub: 'Initial trial unit inspected and verified against technical drawing.',
          ),
          _buildCheckItem(
            value: _machineParametersSet,
            onChanged: (v) => setState(() => _machineParametersSet = v),
            title: 'Process Temperatures & Tolerances Set',
            sub: 'Temperature, feed rate, and pressure settings meet SOP.',
          ),
          _buildCheckItem(
            value: _safetyGuardsActive,
            onChanged: (v) => setState(() => _safetyGuardsActive = v),
            title: 'Safety Guards & Environment Clear',
            sub: 'Operator safety interlocks and workplace hygiene checked.',
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String title,
    required String sub,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: value ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: value ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    sub,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Inspector & Notes Card
  Widget _buildInspectorAndNotesCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quality Inspector *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _inspectorController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. Ramesh Verma (QA Inspector)',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Inspection Remarks / Notes (Optional)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'e.g. Offline gauge measurements in spec. Ready for shift run.',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              contentPadding: const EdgeInsets.all(12),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  // 5. Action Buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _handleApproveInspection,
            icon: _submitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
            label: Text(
              _submitting ? 'Approving...' : 'Approve Quality Check',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _submitting ? null : _handleRejectInspection,
            icon: const Icon(Icons.cancel_outlined, size: 18, color: Color(0xFFDC2626)),
            label: const Text(
              'Reject (Hold Order)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFDC2626)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFCA5A5)),
              backgroundColor: const Color(0xFFFEF2F2),
              padding: const EdgeInsets.symmetric(vertical: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}