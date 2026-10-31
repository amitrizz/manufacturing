import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

class PurchaseScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const PurchaseScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends ConsumerState<PurchaseScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filter state
  String _poSearch = '';
  String _poFilter = 'ALL';

  String _prSearch = '';
  String _prFilter = 'ALL';

  String _grnSearch = '';
  String _supplierSearch = '';

  // Local caching & loading states
  bool _isLoading = false;
  List<Map<String, dynamic>> _pos = [];
  List<Map<String, dynamic>> _prs = [];
  List<Map<String, dynamic>> _grns = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _materials = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final api = ref.read(apiServiceProvider);

    List<Map<String, dynamic>> posList = [];
    List<Map<String, dynamic>> prsList = [];
    List<Map<String, dynamic>> grnList = [];
    List<Map<String, dynamic>> supList = [];
    List<Map<String, dynamic>> matList = [];

    try {
      final res = await api.getCollection('purchase_orders', queryParams: {'limit': 100});
      posList = res.data;
    } catch (_) {}

    try {
      final res = await api.getCollection('purchase_requests', queryParams: {'limit': 100});
      prsList = res.data;
    } catch (_) {}

    try {
      final res = await api.get('/purchase/grn-receipts');
      if (res is List) {
        grnList = res.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {}

    try {
      final res = await api.getCollection('suppliers', queryParams: {'limit': 100});
      supList = res.data;
    } catch (_) {}

    try {
      final res = await api.getCollection('materials', queryParams: {'limit': 100});
      matList = res.data;
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _pos = posList;
      _prs = prsList;
      _grns = grnList;
      _suppliers = supList;
      _materials = matList;
      _isLoading = false;
    });
  }

  void _triggerTabFabAction() {
    switch (_tabController.index) {
      case 0:
        _showNewPoSheet();
        break;
      case 1:
        _showNewPrSheet();
        break;
      case 2:
        _showReceiveGrnSheet();
        break;
      case 3:
        _showSupplierSheet();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E38),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back to Management',
          onPressed: () => context.canPop() ? context.pop() : context.go('/management'),
        ),
        title: const Text(
          'Purchase & Suppliers',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh All',
            onPressed: _loadAllData,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF38BDF8), size: 26),
            tooltip: 'New Entry',
            onPressed: _triggerTabFabAction,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('Orders (${_pos.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.assignment_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('Requests (${_prs.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('GRN (${_grns.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Icon(Icons.business_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('Suppliers (${_suppliers.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: Column(
          children: [
            _buildKpiBanner(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersTab(isDark),
                  _buildRequestsTab(isDark),
                  _buildGrnTab(isDark),
                  _buildSuppliersTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        onPressed: _triggerTabFabAction,
        icon: Icon(
          _tabController.index == 0
              ? Icons.add_shopping_cart
              : _tabController.index == 1
                  ? Icons.add_task
                  : _tabController.index == 2
                      ? Icons.move_to_inbox
                      : Icons.person_add_alt_1,
          size: 20,
        ),
        label: Text(
          _tabController.index == 0
              ? '+ New PO'
              : _tabController.index == 1
                  ? '+ New Request'
                  : _tabController.index == 2
                      ? '+ Receive Goods'
                      : '+ Add Supplier',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // =========================================================================
  // Top KPI Summary Header
  // =========================================================================
  Widget _buildKpiBanner() {
    final activePos = _pos.where((p) => p['status'] != 'RECEIVED' && p['status'] != 'CANCELLED').length;
    final pendingPrs = _prs.where((r) => r['status'] == 'PENDING').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0E2544),
        border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildKpiMetric('Active POs', '$activePos', const Color(0xFF38BDF8), Icons.shopping_bag_outlined),
          _buildKpiDivider(),
          _buildKpiMetric('Pending PRs', '$pendingPrs', const Color(0xFFFBBF24), Icons.pending_actions_outlined),
          _buildKpiDivider(),
          _buildKpiMetric('GRN Inward', '${_grns.length}', const Color(0xFF34D399), Icons.archive_outlined),
          _buildKpiDivider(),
          _buildKpiMetric('Vendors', '${_suppliers.length}', const Color(0xFFA78BFA), Icons.storefront_outlined),
        ],
      ),
    );
  }

  Widget _buildKpiMetric(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiDivider() {
    return Container(
      height: 24,
      width: 1,
      color: const Color(0xFF1E3A5F),
    );
  }

  // =========================================================================
  // TAB 1: PURCHASE ORDERS (PO)
  // =========================================================================
  Widget _buildOrdersTab(bool isDark) {
    if (_isLoading && _pos.isEmpty) {
      return const PurchaseScreenShimmer();
    }

    final filtered = _pos.where((p) {
      final matchesSearch = _poSearch.isEmpty ||
          (p['po_number'] ?? '').toString().toLowerCase().contains(_poSearch.toLowerCase()) ||
          (p['supplier_name'] ?? '').toString().toLowerCase().contains(_poSearch.toLowerCase());
      final matchesFilter = _poFilter == 'ALL' || (p['status'] ?? '') == _poFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search PO number, supplier…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _poSearch.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _poSearch = ''))
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                ),
                onChanged: (val) => setState(() => _poSearch = val),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All (${_pos.length})', _poFilter, (s) => setState(() => _poFilter = s)),
                    _buildFilterChip('PLACED', 'Placed', _poFilter, (s) => setState(() => _poFilter = s)),
                    _buildFilterChip('PARTIALLY_RECEIVED', 'Partially Received', _poFilter, (s) => setState(() => _poFilter = s)),
                    _buildFilterChip('RECEIVED', 'Received', _poFilter, (s) => setState(() => _poFilter = s)),
                    _buildFilterChip('CANCELLED', 'Cancelled', _poFilter, (s) => setState(() => _poFilter = s)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('No purchase orders found', Icons.shopping_cart_outlined, 'Create a new purchase order for authorized vendors')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final po = filtered[index];
                    return _buildPoCard(po, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPoCard(Map<String, dynamic> po, bool isDark) {
    final status = (po['status'] ?? 'PLACED').toString().toUpperCase();
    final poNumber = (po['po_number'] ?? 'PO-0000').toString();
    final supplierName = (po['supplier_name'] ?? 'Supplier Unassigned').toString();
    final totalAmount = (po['total_amount'] as num?)?.toDouble() ?? 0.0;
    final orderDate = po['order_date'] != null
        ? Formatters.formatDate(DateTime.fromMillisecondsSinceEpoch(po['order_date'] as int))
        : 'N/A';
    final expDate = po['expected_delivery_date'] != null
        ? Formatters.formatDate(DateTime.fromMillisecondsSinceEpoch(po['expected_delivery_date'] as int))
        : null;

    Color badgeColor;
    Color badgeBg;
    switch (status) {
      case 'RECEIVED':
        badgeColor = const Color(0xFF16A34A);
        badgeBg = const Color(0xFFDCFCE7);
        break;
      case 'PARTIALLY_RECEIVED':
        badgeColor = const Color(0xFFD97706);
        badgeBg = const Color(0xFFFEF3C7);
        break;
      case 'CANCELLED':
        badgeColor = const Color(0xFFDC2626);
        badgeBg = const Color(0xFFFEE2E2);
        break;
      default:
        badgeColor = const Color(0xFF0284C7);
        badgeBg = const Color(0xFFE0F2FE);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_outlined, color: Color(0xFF0284C7), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          poNumber,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0A1E38),
                          ),
                        ),
                        Text(
                          'Ordered: $orderDate',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SUPPLIER / VENDOR',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          supplierName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'TOTAL VALUE',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${Formatters.formatNumber(totalAmount.toInt())}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (expDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.event_available_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text('Expected Delivery: $expDate', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ],

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showPoDetailDialog(po),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('Items', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF0284C7),
                  ),
                ),
                const SizedBox(width: 8),
                if (status != 'RECEIVED')
                  FilledButton.icon(
                    onPressed: () => _showReceiveGrnSheet(preselectedPo: po),
                    icon: const Icon(Icons.move_to_inbox, size: 14),
                    label: const Text('Receive GRN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                  tooltip: 'Delete PO',
                  onPressed: () => _confirmDeletePo(po),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 2: MATERIAL REQUESTS (PR)
  // =========================================================================
  Widget _buildRequestsTab(bool isDark) {
    if (_isLoading && _prs.isEmpty) {
      return const PurchaseScreenShimmer();
    }

    final filtered = _prs.where((r) {
      final matchesSearch = _prSearch.isEmpty ||
          (r['request_number'] ?? '').toString().toLowerCase().contains(_prSearch.toLowerCase()) ||
          (r['material_name'] ?? '').toString().toLowerCase().contains(_prSearch.toLowerCase()) ||
          (r['reason'] ?? '').toString().toLowerCase().contains(_prSearch.toLowerCase());
      final matchesFilter = _prFilter == 'ALL' || (r['status'] ?? '') == _prFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search request #, material, reason…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _prSearch.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _prSearch = ''))
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                ),
                onChanged: (val) => setState(() => _prSearch = val),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All (${_prs.length})', _prFilter, (s) => setState(() => _prFilter = s)),
                    _buildFilterChip('PENDING', 'Pending', _prFilter, (s) => setState(() => _prFilter = s)),
                    _buildFilterChip('APPROVED', 'Approved', _prFilter, (s) => setState(() => _prFilter = s)),
                    _buildFilterChip('REJECTED', 'Rejected', _prFilter, (s) => setState(() => _prFilter = s)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('No material requests found', Icons.assignment_outlined, 'Create a purchase request for raw materials needed on floor')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final pr = filtered[index];
                    return _buildRequestCard(pr, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> pr, bool isDark) {
    final status = (pr['status'] ?? 'PENDING').toString().toUpperCase();
    final reqNumber = (pr['request_number'] ?? 'PR-0000').toString();
    final matName = (pr['material_name'] ?? 'Raw Material').toString();
    final qty = (pr['quantity'] as num?)?.toDouble() ?? 0.0;
    final unit = (pr['material_unit'] ?? 'units').toString();
    final reason = (pr['reason'] ?? '').toString();
    final reqDate = pr['required_by_date'] != null
        ? Formatters.formatDate(DateTime.fromMillisecondsSinceEpoch(pr['required_by_date'] as int))
        : null;

    Color badgeColor;
    Color badgeBg;
    switch (status) {
      case 'APPROVED':
        badgeColor = const Color(0xFF16A34A);
        badgeBg = const Color(0xFFDCFCE7);
        break;
      case 'REJECTED':
        badgeColor = const Color(0xFFDC2626);
        badgeBg = const Color(0xFFFEE2E2);
        break;
      default:
        badgeColor = const Color(0xFFD97706);
        badgeBg = const Color(0xFFFEF3C7);
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.assignment_outlined, color: Color(0xFFD97706), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reqNumber,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0A1E38),
                          ),
                        ),
                        if (reqDate != null)
                          Text('Needed By: $reqDate', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('REQUESTED MATERIAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(
                          matName,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('QUANTITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                      const SizedBox(height: 2),
                      Text(
                        '${Formatters.formatNumber(qty.toInt())} $unit',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFFD97706)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Reason: $reason', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontStyle: FontStyle.italic)),
            ],

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'PENDING') ...[
                  OutlinedButton(
                    onPressed: () => _updatePrStatus(pr, 'REJECTED'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => _updatePrStatus(pr, 'APPROVED'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Approve', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                ],
                if (status == 'APPROVED')
                  FilledButton.icon(
                    onPressed: () => _showNewPoSheet(preselectedMaterialId: (pr['material_id'] ?? '').toString(), preselectedQty: qty),
                    icon: const Icon(Icons.shopping_cart_checkout, size: 14),
                    label: const Text('Create PO', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                  tooltip: 'Delete Request',
                  onPressed: () => _confirmDeletePr(pr),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 3: GOODS RECEIVED NOTES (GRN)
  // =========================================================================
  Widget _buildGrnTab(bool isDark) {
    if (_isLoading && _grns.isEmpty) {
      return const PurchaseScreenShimmer();
    }

    final filtered = _grns.where((g) {
      return _grnSearch.isEmpty ||
          (g['grn_number'] ?? '').toString().toLowerCase().contains(_grnSearch.toLowerCase()) ||
          (g['po_number'] ?? '').toString().toLowerCase().contains(_grnSearch.toLowerCase()) ||
          (g['supplier_name'] ?? '').toString().toLowerCase().contains(_grnSearch.toLowerCase()) ||
          (g['invoice_number'] ?? '').toString().toLowerCase().contains(_grnSearch.toLowerCase());
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search GRN #, PO #, invoice, supplier…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _grnSearch.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _grnSearch = ''))
                  : null,
              isDense: true,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            ),
            onChanged: (val) => setState(() => _grnSearch = val),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('No goods receipts recorded', Icons.receipt_long_outlined, 'Record direct inward or receive deliveries from purchase orders')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final grn = filtered[index];
                    return _buildGrnCard(grn, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGrnCard(Map<String, dynamic> grn, bool isDark) {
    final grnNumber = (grn['grn_number'] ?? 'GRN-0000').toString();
    final supplierName = (grn['supplier_name'] ?? 'Supplier Unassigned').toString();
    final poNumber = grn['po_number'] != null ? 'PO: ${grn['po_number']}' : 'Direct Material Inward';
    final invoice = (grn['invoice_number'] ?? '').toString();
    final itemsSummary = (grn['items_summary'] ?? 'Items received').toString();
    final date = grn['created_at'] != null || grn['received_date'] != null
        ? Formatters.formatDateTime(DateTime.fromMillisecondsSinceEpoch((grn['created_at'] ?? grn['received_date']) as int))
        : 'N/A';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.archive_outlined, color: Color(0xFF16A34A), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grnNumber,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0A1E38),
                          ),
                        ),
                        Text(
                          date,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'INWARD STOCK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        supplierName,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      Text(
                        poNumber,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0284C7)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Items: $itemsSummary',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                  ),
                  if (invoice.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Invoice #: $invoice',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _confirmRevertGrn(grn),
                  icon: const Icon(Icons.undo, size: 14, color: Color(0xFFDC2626)),
                  label: const Text('Revert Receipt', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 4: SUPPLIERS DIRECTORY
  // =========================================================================
  Widget _buildSuppliersTab(bool isDark) {
    if (_isLoading && _suppliers.isEmpty) {
      return const PurchaseScreenShimmer();
    }

    final filtered = _suppliers.where((s) {
      return _supplierSearch.isEmpty ||
          (s['name'] ?? '').toString().toLowerCase().contains(_supplierSearch.toLowerCase()) ||
          (s['contact_person'] ?? '').toString().toLowerCase().contains(_supplierSearch.toLowerCase()) ||
          (s['supplied_items'] ?? '').toString().toLowerCase().contains(_supplierSearch.toLowerCase()) ||
          (s['phone'] ?? '').toString().toLowerCase().contains(_supplierSearch.toLowerCase());
    }).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search vendor name, contact person, items…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _supplierSearch.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _supplierSearch = ''))
                  : null,
              isDense: true,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            ),
            onChanged: (val) => setState(() => _supplierSearch = val),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('No suppliers registered', Icons.business_outlined, 'Enroll authorized suppliers to generate vendor POs and track shipments')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final sup = filtered[index];
                    return _buildSupplierCard(sup, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> sup, bool isDark) {
    final name = (sup['name'] ?? 'Supplier').toString();
    final code = (sup['code'] ?? 'SUP').toString();
    final contact = (sup['contact_person'] ?? '').toString();
    final phone = (sup['phone'] ?? '').toString();
    final email = (sup['email'] ?? '').toString();
    final items = (sup['supplied_items'] ?? '').toString();
    final gst = (sup['gst_number'] ?? '').toString();
    final rating = (sup['rating'] as num?)?.toDouble() ?? 5.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.storefront_outlined, color: Color(0xFF7C3AED), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0A1E38),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text('Code: $code', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Color(0xFFD97706)),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (contact.isNotEmpty || phone.isNotEmpty) ...[
              Row(
                children: [
                  if (contact.isNotEmpty) ...[
                    const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(contact, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                    const SizedBox(width: 12),
                  ],
                  if (phone.isNotEmpty) ...[
                    const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(phone, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                  ],
                ],
              ),
              const SizedBox(height: 6),
            ],

            if (email.isNotEmpty || gst.isNotEmpty) ...[
              Row(
                children: [
                  if (email.isNotEmpty) ...[
                    const Icon(Icons.email_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(email, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  if (gst.isNotEmpty)
                    Text('GST: $gst', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                ],
              ),
              const SizedBox(height: 6),
            ],

            if (items.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Supplies: $items',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showNewPoSheet(preselectedSupplierId: (sup['id'] ?? sup['_id'])?.toString()),
                  icon: const Icon(Icons.add_shopping_cart, size: 14),
                  label: const Text('Create PO', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0A1E38)),
                  tooltip: 'Edit Supplier',
                  onPressed: () => _showSupplierSheet(existing: sup),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                  tooltip: 'Delete Supplier',
                  onPressed: () => _confirmDeleteSupplier(sup),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Helpers & Empty State
  // =========================================================================
  Widget _buildFilterChip(String value, String label, String currentVal, Function(String) onSelect) {
    final isSelected = currentVal == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, IconData icon, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: const Color(0xFF0284C7)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0A1E38)),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Actions & CRUD handlers
  // =========================================================================
  Future<void> _updatePrStatus(Map<String, dynamic> pr, String newStatus) async {
    final id = (pr['id'] ?? pr['_id'])?.toString();
    if (id == null) return;
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateCollectionItem('purchase_requests', id, {'status': newStatus, 'updated_at': DateTime.now().millisecondsSinceEpoch});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request marked as $newStatus'), backgroundColor: const Color(0xFF16A34A)));
      _loadAllData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFFDC2626)));
    }
  }

  void _confirmDeletePo(Map<String, dynamic> po) {
    final id = (po['id'] ?? po['_id'])?.toString();
    final poNum = po['po_number'] ?? 'PO';
    if (id == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $poNum?'),
        content: const Text('Are you sure you want to delete this purchase order? Linked items will also be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = ref.read(apiServiceProvider);
                await api.deleteCollectionItem('purchase_orders', id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PO $poNum deleted')));
                  _loadAllData();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePr(Map<String, dynamic> pr) {
    final id = (pr['id'] ?? pr['_id'])?.toString();
    final prNum = pr['request_number'] ?? 'PR';
    if (id == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $prNum?'),
        content: const Text('Are you sure you want to delete this material request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = ref.read(apiServiceProvider);
                await api.deleteCollectionItem('purchase_requests', id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request $prNum deleted')));
                  _loadAllData();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmRevertGrn(Map<String, dynamic> grn) {
    final id = (grn['id'] ?? grn['_id'])?.toString();
    final grnNum = grn['grn_number'] ?? 'GRN';
    if (id == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Revert $grnNum?'),
        content: const Text('Reverting this goods receipt will reverse added raw material stock and reset PO received quantities. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = ref.read(apiServiceProvider);
                await api.delete('/purchase/delete-grn/$id');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$grnNum reverted and stock updated.')));
                  _loadAllData();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Revert failed: $e')));
              }
            },
            child: const Text('Revert'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSupplier(Map<String, dynamic> sup) {
    final id = (sup['id'] ?? sup['_id'])?.toString();
    final name = sup['name'] ?? 'Supplier';
    if (id == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text('Are you sure you want to delete this supplier from your vendor directory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = ref.read(apiServiceProvider);
                await api.deleteCollectionItem('suppliers', id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Supplier $name deleted')));
                  _loadAllData();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // MODALS & FORMS
  // =========================================================================
  void _showNewPoSheet({String? preselectedSupplierId, String? preselectedMaterialId, double? preselectedQty}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewPoSheet(
        suppliers: _suppliers,
        materials: _materials,
        preselectedSupplierId: preselectedSupplierId,
        preselectedMaterialId: preselectedMaterialId,
        preselectedQty: preselectedQty,
        onCreated: () {
          _loadAllData();
          _tabController.animateTo(0);
        },
      ),
    );
  }

  void _showNewPrSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewPrSheet(
        materials: _materials,
        onCreated: () {
          _loadAllData();
          _tabController.animateTo(1);
        },
      ),
    );
  }

  void _showReceiveGrnSheet({Map<String, dynamic>? preselectedPo}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReceiveGrnSheet(
        pos: _pos.where((p) => p['status'] != 'RECEIVED' && p['status'] != 'CANCELLED').toList(),
        suppliers: _suppliers,
        materials: _materials,
        preselectedPo: preselectedPo,
        onProcessed: () {
          _loadAllData();
          _tabController.animateTo(2);
        },
      ),
    );
  }

  void _showSupplierSheet({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SupplierFormSheet(
        existing: existing,
        onSaved: () {
          _loadAllData();
          _tabController.animateTo(3);
        },
      ),
    );
  }

  void _showPoDetailDialog(Map<String, dynamic> po) {
    showDialog(
      context: context,
      builder: (ctx) => _PoDetailDialog(po: po),
    );
  }
}

// ===========================================================================
// SUB-WIDGET: New PO Form Sheet
// ===========================================================================
class _NewPoSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> suppliers;
  final List<Map<String, dynamic>> materials;
  final String? preselectedSupplierId;
  final String? preselectedMaterialId;
  final double? preselectedQty;
  final VoidCallback onCreated;

  const _NewPoSheet({
    required this.suppliers,
    required this.materials,
    this.preselectedSupplierId,
    this.preselectedMaterialId,
    this.preselectedQty,
    required this.onCreated,
  });

  @override
  ConsumerState<_NewPoSheet> createState() => _NewPoSheetState();
}

class _NewPoSheetState extends ConsumerState<_NewPoSheet> {
  String? _supplierId;
  String? _materialId;
  final _qtyController = TextEditingController();
  final _rateController = TextEditingController();
  final _termsController = TextEditingController(text: 'Net 30 days. Delivery at Factory Store.');
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.suppliers.isNotEmpty) {
      _supplierId = widget.preselectedSupplierId ?? (widget.suppliers.first['id'] ?? widget.suppliers.first['_id'])?.toString();
    }
    if (widget.materials.isNotEmpty) {
      _materialId = widget.preselectedMaterialId ?? (widget.materials.first['id'] ?? widget.materials.first['_id'])?.toString();
    }
    if (widget.preselectedQty != null) {
      _qtyController.text = widget.preselectedQty!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _rateController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0.0;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0.0;

    if (_supplierId == null || _materialId == null || qty <= 0 || rate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select supplier, material, quantity (>0), and rate (>0)'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(apiServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final poId = 'po-${DateTime.now().millisecondsSinceEpoch}';

      int totalCount = 0;
      try {
        final existingPos = await api.getCollection('purchase_orders', queryParams: {'limit': 1});
        totalCount = existingPos.pagination.total;
      } catch (_) {}
      final poNumber = 'PO-${(totalCount + 1).toString().padLeft(4, '0')}';

      final sup = widget.suppliers.firstWhere((s) => (s['id'] ?? s['_id'])?.toString() == _supplierId, orElse: () => {});
      final mat = widget.materials.firstWhere((m) => (m['id'] ?? m['_id'])?.toString() == _materialId, orElse: () => {});

      final totalAmount = qty * rate;

      await api.createCollectionItem('purchase_orders', {
        'id': poId,
        'po_number': poNumber,
        'supplier_id': _supplierId,
        'supplier_name': sup['name'] ?? 'Supplier',
        'order_date': now,
        'expected_delivery_date': now + (7 * 86400000),
        'terms': _termsController.text.trim(),
        'status': 'PLACED',
        'total_amount': totalAmount,
        'created_at': now,
        'updated_at': now,
      });

      final itemId = 'poi-${DateTime.now().millisecondsSinceEpoch}';
      await api.createCollectionItem('purchase_order_items', {
        'id': itemId,
        'po_id': poId,
        'material_id': _materialId,
        'material_code': mat['code'] ?? '',
        'material_name': mat['name'] ?? 'Material',
        'unit': mat['unit'] ?? 'pcs',
        'quantity': qty,
        'unit_price': rate,
        'total_price': totalAmount,
        'received_quantity': 0,
        'created_at': now,
        'updated_at': now,
      });

      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created Purchase Order $poNumber'), backgroundColor: const Color(0xFF16A34A)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create PO: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Create Purchase Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0A1E38)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            const Text('Supplier / Vendor *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _supplierId,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: widget.suppliers.map((s) {
                final id = (s['id'] ?? s['_id'])?.toString() ?? '';
                final name = s['name'] ?? 'Supplier';
                return DropdownMenuItem(value: id, child: Text(name, style: const TextStyle(fontSize: 13.5)));
              }).toList(),
              onChanged: (val) => setState(() => _supplierId = val),
            ),
            const SizedBox(height: 14),

            const Text('Raw Material *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _materialId,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: widget.materials.map((m) {
                final id = (m['id'] ?? m['_id'])?.toString() ?? '';
                final name = m['name'] ?? 'Material';
                final unit = m['unit'] ?? 'pcs';
                return DropdownMenuItem(value: id, child: Text('$name ($unit)', style: const TextStyle(fontSize: 13.5)));
              }).toList(),
              onChanged: (val) => setState(() => _materialId = val),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Quantity *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 500',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                      const Text('Unit Rate (₹) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _rateController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 150',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            const Text('Delivery & Payment Terms', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _termsController,
              maxLines: 2,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Place Purchase Order', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// SUB-WIDGET: New PR Form Sheet
// ===========================================================================
class _NewPrSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> materials;
  final VoidCallback onCreated;

  const _NewPrSheet({required this.materials, required this.onCreated});

  @override
  ConsumerState<_NewPrSheet> createState() => _NewPrSheetState();
}

class _NewPrSheetState extends ConsumerState<_NewPrSheet> {
  String? _materialId;
  final _qtyController = TextEditingController();
  final _reasonController = TextEditingController();
  int _requiredDays = 7;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.materials.isNotEmpty) {
      _materialId = (widget.materials.first['id'] ?? widget.materials.first['_id'])?.toString();
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0.0;
    if (_materialId == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a material and enter quantity (>0)'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(apiServiceProvider);
      final now = DateTime.now().millisecondsSinceEpoch;
      final prId = 'pr-${DateTime.now().millisecondsSinceEpoch}';

      int totalCount = 0;
      try {
        final existingPrs = await api.getCollection('purchase_requests', queryParams: {'limit': 1});
        totalCount = existingPrs.pagination.total;
      } catch (_) {}
      final prNumber = 'PR-${(totalCount + 1).toString().padLeft(4, '0')}';

      final mat = widget.materials.firstWhere((m) => (m['id'] ?? m['_id'])?.toString() == _materialId, orElse: () => {});

      await api.createCollectionItem('purchase_requests', {
        'id': prId,
        'request_number': prNumber,
        'material_id': _materialId,
        'material_code': mat['code'] ?? '',
        'material_name': mat['name'] ?? 'Material',
        'material_unit': mat['unit'] ?? 'pcs',
        'quantity': qty,
        'required_by_date': now + (_requiredDays * 86400000),
        'reason': _reasonController.text.trim(),
        'status': 'PENDING',
        'created_at': now,
        'updated_at': now,
      });

      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Material Request $prNumber created'), backgroundColor: const Color(0xFF16A34A)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create request: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Material Request',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0A1E38)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            const Text('Required Material *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _materialId,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: widget.materials.map((m) {
                final id = (m['id'] ?? m['_id'])?.toString() ?? '';
                final name = m['name'] ?? 'Material';
                final unit = m['unit'] ?? 'pcs';
                return DropdownMenuItem(value: id, child: Text('$name ($unit)', style: const TextStyle(fontSize: 13.5)));
              }).toList(),
              onChanged: (val) => setState(() => _materialId = val),
            ),
            const SizedBox(height: 14),

            const Text('Quantity *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 100',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),

            const Text('Needed Within', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            Row(
              children: [3, 7, 14, 30].map((days) {
                final isSelected = _requiredDays == days;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$days days'),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _requiredDays = days),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            const Text('Reason / Purpose', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Urgent production line 2 shortage',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// SUB-WIDGET: Receive GRN Sheet (Supports PO-based & Direct Inward)
// ===========================================================================
class _ReceiveGrnSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> pos;
  final List<Map<String, dynamic>> suppliers;
  final List<Map<String, dynamic>> materials;
  final Map<String, dynamic>? preselectedPo;
  final VoidCallback onProcessed;

  const _ReceiveGrnSheet({
    required this.pos,
    required this.suppliers,
    required this.materials,
    this.preselectedPo,
    required this.onProcessed,
  });

  @override
  ConsumerState<_ReceiveGrnSheet> createState() => _ReceiveGrnSheetState();
}

class _ReceiveGrnSheetState extends ConsumerState<_ReceiveGrnSheet> {
  String _mode = 'PO';
  String? _selectedPoId;
  String? _supplierId;
  String? _directMaterialId;
  final _directQtyController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _notesController = TextEditingController();

  List<Map<String, dynamic>> _poItems = [];
  final Map<String, TextEditingController> _itemControllers = {};
  bool _isLoadingItems = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedPo != null) {
      _mode = 'PO';
      _selectedPoId = (widget.preselectedPo!['id'] ?? widget.preselectedPo!['_id'])?.toString();
      if (_selectedPoId != null) _loadPoItems(_selectedPoId!);
    } else if (widget.pos.isNotEmpty) {
      _selectedPoId = (widget.pos.first['id'] ?? widget.pos.first['_id'])?.toString();
      if (_selectedPoId != null) _loadPoItems(_selectedPoId!);
    } else {
      _mode = 'DIRECT';
    }

    if (widget.suppliers.isNotEmpty) {
      _supplierId = (widget.suppliers.first['id'] ?? widget.suppliers.first['_id'])?.toString();
    }
    if (widget.materials.isNotEmpty) {
      _directMaterialId = (widget.materials.first['id'] ?? widget.materials.first['_id'])?.toString();
    }
  }

  @override
  void dispose() {
    _directQtyController.dispose();
    _invoiceController.dispose();
    _notesController.dispose();
    for (final c in _itemControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPoItems(String poId) async {
    setState(() => _isLoadingItems = true);
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.getCollection('purchase_order_items', queryParams: {'limit': 50});
      final items = resp.data.where((it) => (it['po_id'] ?? '').toString() == poId).toList();

      for (final c in _itemControllers.values) {
        c.dispose();
      }
      _itemControllers.clear();

      for (final it in items) {
        final matId = (it['material_id'] ?? '').toString();
        final ordered = (it['quantity'] as num?)?.toDouble() ?? 0.0;
        final received = (it['received_quantity'] as num?)?.toDouble() ?? 0.0;
        final remaining = (ordered - received).clamp(0.0, ordered);
        _itemControllers[matId] = TextEditingController(text: remaining.toStringAsFixed(0));
      }

      if (mounted) {
        setState(() {
          _poItems = items;
          _isLoadingItems = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingItems = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final api = ref.read(apiServiceProvider);

    try {
      if (_mode == 'DIRECT') {
        final qty = double.tryParse(_directQtyController.text.trim()) ?? 0.0;
        if (_directMaterialId == null || qty <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select material and enter valid received quantity'), backgroundColor: Color(0xFFDC2626)),
          );
          setState(() => _isSubmitting = false);
          return;
        }

        final payload = {
          'po_id': null,
          'supplier_id': _supplierId,
          'invoice_number': _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
          'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          'received_items': [
            {
              'material_id': _directMaterialId,
              'received_qty': qty,
            }
          ],
        };

        await api.post('/purchase/receive-grn', data: payload);
      } else {
        if (_selectedPoId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a purchase order'), backgroundColor: Color(0xFFDC2626)),
          );
          setState(() => _isSubmitting = false);
          return;
        }

        final receivedItems = <Map<String, dynamic>>[];
        for (final it in _poItems) {
          final matId = (it['material_id'] ?? '').toString();
          final qty = double.tryParse(_itemControllers[matId]?.text.trim() ?? '0') ?? 0.0;
          if (qty > 0) {
            receivedItems.add({
              'material_id': matId,
              'received_qty': qty,
            });
          }
        }

        if (receivedItems.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter at least one item quantity > 0 to receive'), backgroundColor: Color(0xFFDC2626)),
          );
          setState(() => _isSubmitting = false);
          return;
        }

        final po = widget.pos.firstWhere((p) => (p['id'] ?? p['_id'])?.toString() == _selectedPoId, orElse: () => {});
        final supId = po['supplier_id']?.toString();

        final payload = {
          'po_id': _selectedPoId,
          'supplier_id': supId,
          'invoice_number': _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
          'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          'received_items': receivedItems,
        };

        await api.post('/purchase/receive-grn', data: payload);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onProcessed();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GRN processed successfully! Stock inventory updated.'), backgroundColor: Color(0xFF16A34A)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process GRN: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Receive Goods (GRN)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0A1E38)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _mode = 'PO'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _mode == 'PO' ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'From Purchase Order',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _mode == 'PO' ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _mode = 'DIRECT'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _mode == 'DIRECT' ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Direct Inward',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _mode == 'DIRECT' ? Colors.white : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_mode == 'PO') ...[
              const Text('Select Purchase Order *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedPoId,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: widget.pos.map((p) {
                  final id = (p['id'] ?? p['_id'])?.toString() ?? '';
                  final num = p['po_number'] ?? 'PO';
                  final sup = p['supplier_name'] ?? 'Vendor';
                  return DropdownMenuItem(value: id, child: Text('$num ($sup)', style: const TextStyle(fontSize: 13.5)));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedPoId = val);
                    _loadPoItems(val);
                  }
                },
              ),
              const SizedBox(height: 14),

              const Text('Ordered Items & Received Quantity *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              if (_isLoadingItems)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else if (_poItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                  child: const Text('No line items found for this PO.', style: TextStyle(fontSize: 12, color: Color(0xFF92400E))),
                )
              else
                Column(
                  children: _poItems.map((it) {
                    final matId = (it['material_id'] ?? '').toString();
                    final matName = it['material_name'] ?? 'Material';
                    final ordered = (it['quantity'] as num?)?.toDouble() ?? 0.0;
                    final received = (it['received_quantity'] as num?)?.toDouble() ?? 0.0;
                    final unit = it['unit'] ?? 'pcs';
                    final controller = _itemControllers[matId];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(matName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                Text('Ordered: $ordered $unit | Recv: $received $unit', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Received',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ] else ...[
              const Text('Supplier / Vendor', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _supplierId,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: widget.suppliers.map((s) {
                  final id = (s['id'] ?? s['_id'])?.toString() ?? '';
                  final name = s['name'] ?? 'Supplier';
                  return DropdownMenuItem(value: id, child: Text(name, style: const TextStyle(fontSize: 13.5)));
                }).toList(),
                onChanged: (val) => setState(() => _supplierId = val),
              ),
              const SizedBox(height: 14),

              const Text('Raw Material *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _directMaterialId,
                isExpanded: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: widget.materials.map((m) {
                  final id = (m['id'] ?? m['_id'])?.toString() ?? '';
                  final name = m['name'] ?? 'Material';
                  final unit = m['unit'] ?? 'pcs';
                  return DropdownMenuItem(value: id, child: Text('$name ($unit)', style: const TextStyle(fontSize: 13.5)));
                }).toList(),
                onChanged: (val) => setState(() => _directMaterialId = val),
              ),
              const SizedBox(height: 14),

              const Text('Received Quantity *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
              const SizedBox(height: 6),
              TextField(
                controller: _directQtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 250',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delivery Invoice #', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _invoiceController,
                        decoration: InputDecoration(
                          hintText: 'INV-2026-001',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            const Text('Storage Bin / Inspection Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'e.g. Verified weight and placed in Store Bay C-4',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm & Receive Goods', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// SUB-WIDGET: Supplier Create & Edit Form Sheet
// ===========================================================================
class _SupplierFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  const _SupplierFormSheet({this.existing, required this.onSaved});

  @override
  ConsumerState<_SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends ConsumerState<_SupplierFormSheet> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _itemsController = TextEditingController();
  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameController.text = e['name'] ?? '';
      _codeController.text = e['code'] ?? '';
      _contactController.text = e['contact_person'] ?? '';
      _phoneController.text = e['phone'] ?? '';
      _emailController.text = e['email'] ?? '';
      _addressController.text = e['address'] ?? '';
      _gstController.text = e['gst_number'] ?? '';
      _itemsController.text = e['supplied_items'] ?? '';
      _rating = (e['rating'] as num?)?.toDouble() ?? 5.0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _itemsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter supplier company name'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final api = ref.read(apiServiceProvider);
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      final data = {
        'name': name,
        'code': _codeController.text.trim().isNotEmpty ? _codeController.text.trim() : 'SUP-${now % 1000}',
        'contact_person': _contactController.text.trim().isNotEmpty ? _contactController.text.trim() : null,
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        'address': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        'gst_number': _gstController.text.trim().isNotEmpty ? _gstController.text.trim() : null,
        'supplied_items': _itemsController.text.trim().isNotEmpty ? _itemsController.text.trim() : null,
        'rating': _rating,
        'updated_at': now,
      };

      if (widget.existing != null) {
        final id = (widget.existing!['id'] ?? widget.existing!['_id'])?.toString();
        if (id != null) {
          await api.updateCollectionItem('suppliers', id, data);
        }
      } else {
        data['id'] = 'sup-$now';
        data['created_at'] = now;
        await api.createCollectionItem('suppliers', data);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.existing != null ? 'Supplier updated' : 'Supplier enrolled successfully'), backgroundColor: const Color(0xFF16A34A)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.existing != null;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Supplier' : 'Add New Supplier',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0A1E38)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            const Text('Company / Vendor Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Apex Industrial Steel Corp',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Vendor Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          hintText: 'e.g. SUP-01',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                      const Text('Contact Person', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _contactController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Rajesh Kumar',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '+91 9876543210',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                      const Text('Email Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'vendor@apex.com',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            const Text('Supplied Items / Categories', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _itemsController,
              decoration: InputDecoration(
                hintText: 'e.g. Steel Sheets, Aluminum Rods, Fasteners',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),

            const Text('GSTIN Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _gstController,
              decoration: InputDecoration(
                hintText: '27AAAAA0000A1Z5',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),

            const Text('Vendor Rating (1.0 - 5.0)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            Slider(
              value: _rating,
              min: 1.0,
              max: 5.0,
              divisions: 8,
              label: _rating.toStringAsFixed(1),
              activeColor: const Color(0xFF0284C7),
              onChanged: (val) => setState(() => _rating = val),
            ),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? 'Save Changes' : 'Enroll Supplier', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// SUB-WIDGET: PO Line Items Detail Dialog
// ===========================================================================
class _PoDetailDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> po;

  const _PoDetailDialog({required this.po});

  @override
  ConsumerState<_PoDetailDialog> createState() => _PoDetailDialogState();
}

class _PoDetailDialogState extends ConsumerState<_PoDetailDialog> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final poId = (widget.po['id'] ?? widget.po['_id'])?.toString();
    if (poId == null) return;
    try {
      final api = ref.read(apiServiceProvider);
      final resp = await api.getCollection('purchase_order_items', queryParams: {'limit': 50});
      final hits = resp.data.where((it) => (it['po_id'] ?? '').toString() == poId).toList();
      if (mounted) setState(() { _items = hits; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final poNumber = widget.po['po_number'] ?? 'PO';
    final supplier = widget.po['supplier_name'] ?? 'Vendor';
    final terms = widget.po['terms'] ?? '';

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(poNumber, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          Text('Vendor: $supplier', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: _loading
            ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            : _items.isEmpty
                ? const Text('No line items found for this purchase order.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 12),
                          itemBuilder: (ctx, i) {
                            final it = _items[i];
                            final mat = it['material_name'] ?? 'Material';
                            final qty = (it['quantity'] as num?)?.toDouble() ?? 0.0;
                            final rec = (it['received_quantity'] as num?)?.toDouble() ?? 0.0;
                            final rate = (it['unit_price'] as num?)?.toDouble() ?? 0.0;
                            final total = (it['total_price'] as num?)?.toDouble() ?? (qty * rate);
                            final unit = it['unit'] ?? 'pcs';

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(mat, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                      Text('Ordered: $qty $unit (Recv: $rec $unit)', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('₹${Formatters.formatNumber(total.toInt())}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0284C7))),
                                    Text('@ ₹$rate / $unit', style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (terms.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                          child: Text('Terms: $terms', style: const TextStyle(fontSize: 11, color: Color(0xFF475569))),
                        ),
                      ],
                    ],
                  ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}