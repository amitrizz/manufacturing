import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

class DispatchScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const DispatchScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<DispatchScreen> createState() => _DispatchScreenState();
}

class _DispatchScreenState extends ConsumerState<DispatchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Search & Filter state
  String _dispatchSearch = '';
  String _dispatchFilter = 'ALL';
  String _customerSearch = '';

  // Local data state
  bool _isLoading = false;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
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

    List<Map<String, dynamic>> ordersList = [];
    List<Map<String, dynamic>> customersList = [];
    List<Map<String, dynamic>> productsList = [];

    try {
      final res = await api.getCollection('dispatch_orders', queryParams: {'limit': 100});
      ordersList = res.data;
    } catch (_) {}

    try {
      final res = await api.getCollection('customers', queryParams: {'limit': 100});
      customersList = res.data;
    } catch (_) {}

    try {
      final res = await api.getCollection('products', queryParams: {'limit': 100});
      productsList = res.data;
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _orders = ordersList;
      _customers = customersList;
      _products = productsList;
      _isLoading = false;
    });
  }

  void _triggerTabFabAction() {
    if (_tabController.index == 0) {
      _showNewDispatchSheet();
    } else {
      _showCustomerSheet();
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
          'Dispatch & Logistics',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
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
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text('Dispatch Orders (${_orders.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.business_outlined, size: 16),
                  const SizedBox(width: 8),
                  Text('Customers (${_customers.length})', style: const TextStyle(fontWeight: FontWeight.w700)),
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
                  _buildDispatchOrdersTab(isDark),
                  _buildCustomersTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        onPressed: _triggerTabFabAction,
        icon: Icon(_tabController.index == 0 ? Icons.add_road : Icons.person_add_alt_1, size: 20),
        label: Text(
          _tabController.index == 0 ? '+ New Challan' : '+ Add Customer',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // =========================================================================
  // Top KPI Summary Banner
  // =========================================================================
  Widget _buildKpiBanner() {
    final readyCount = _orders.where((o) => o['status'] == 'READY' || o['status'] == 'PENDING').length;
    final dispatchedCount = _orders.where((o) => o['status'] == 'DISPATCHED').length;
    final deliveredCount = _orders.where((o) => o['status'] == 'DELIVERED').length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0E2544),
        border: Border(bottom: BorderSide(color: Color(0xFF1E3A5F))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildKpiMetric('Ready to Ship', '$readyCount', const Color(0xFFFBBF24), Icons.pending_actions_outlined),
          _buildKpiDivider(),
          _buildKpiMetric('In Transit', '$dispatchedCount', const Color(0xFF38BDF8), Icons.local_shipping_outlined),
          _buildKpiDivider(),
          _buildKpiMetric('Delivered', '$deliveredCount', const Color(0xFF34D399), Icons.check_circle_outline),
          _buildKpiDivider(),
          _buildKpiMetric('Clients', '${_customers.length}', const Color(0xFFA78BFA), Icons.business_outlined),
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
              style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800),
            ),
            Text(
              label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10.5, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiDivider() {
    return Container(height: 24, width: 1, color: const Color(0xFF1E3A5F));
  }

  // =========================================================================
  // TAB 0: DISPATCH ORDERS
  // =========================================================================
  Widget _buildDispatchOrdersTab(bool isDark) {
    if (_isLoading && _orders.isEmpty) {
      return const DispatchScreenShimmer();
    }

    final filtered = _orders.where((o) {
      final q = _dispatchSearch.toLowerCase();
      final matchesSearch = _dispatchSearch.isEmpty ||
          (o['dispatch_number'] ?? '').toString().toLowerCase().contains(q) ||
          (o['customer_name'] ?? '').toString().toLowerCase().contains(q) ||
          (o['product_name'] ?? '').toString().toLowerCase().contains(q) ||
          (o['vehicle_number'] ?? '').toString().toLowerCase().contains(q);

      final matchesFilter = _dispatchFilter == 'ALL' || (o['status'] ?? '') == _dispatchFilter;
      return matchesSearch && matchesFilter;
    }).toList();

    return Column(
      children: [
        // Search & Filters Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search challan #, customer, product, vehicle…',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _dispatchSearch.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _dispatchSearch = ''))
                      : null,
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                ),
                onChanged: (val) => setState(() => _dispatchSearch = val),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All (${_orders.length})', _dispatchFilter, (s) => setState(() => _dispatchFilter = s)),
                    _buildFilterChip('READY', 'Ready to Ship', _dispatchFilter, (s) => setState(() => _dispatchFilter = s)),
                    _buildFilterChip('DISPATCHED', 'Dispatched', _dispatchFilter, (s) => setState(() => _dispatchFilter = s)),
                    _buildFilterChip('DELIVERED', 'Delivered', _dispatchFilter, (s) => setState(() => _dispatchFilter = s)),
                    _buildFilterChip('CANCELLED', 'Cancelled', _dispatchFilter, (s) => setState(() => _dispatchFilter = s)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('No dispatch challans found', Icons.local_shipping_outlined, 'Generate delivery challans to ship finished goods from warehouse')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final d = filtered[index];
                    return _buildDispatchCard(d, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDispatchCard(Map<String, dynamic> d, bool isDark) {
    final status = (d['status'] ?? 'READY').toString().toUpperCase();
    final dNumber = (d['dispatch_number'] ?? 'DSP-0000').toString();
    final customer = (d['customer_name'] ?? 'Client Unassigned').toString();
    final prodName = (d['product_name'] ?? 'Product').toString();
    final qty = (d['quantity'] as num?)?.toDouble() ?? 0.0;
    final vehicle = (d['vehicle_number'] ?? '').toString();
    final driver = (d['driver_name'] ?? '').toString();
    final address = (d['delivery_address'] ?? '').toString();
    final date = d['created_at'] != null
        ? Formatters.formatDateTime(DateTime.fromMillisecondsSinceEpoch(d['created_at'] as int))
        : 'N/A';

    Color badgeColor;
    Color badgeBg;
    switch (status) {
      case 'READY':
        badgeColor = const Color(0xFFD97706);
        badgeBg = const Color(0xFFFEF3C7);
        break;
      case 'DISPATCHED':
        badgeColor = const Color(0xFF0284C7);
        badgeBg = const Color(0xFFE0F2FE);
        break;
      case 'DELIVERED':
        badgeColor = const Color(0xFF16A34A);
        badgeBg = const Color(0xFFDCFCE7);
        break;
      case 'CANCELLED':
        badgeColor = const Color(0xFFDC2626);
        badgeBg = const Color(0xFFFEE2E2);
        break;
      default:
        badgeColor = const Color(0xFF64748B);
        badgeBg = const Color(0xFFF1F5F9);
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
                        color: const Color(0xFF1565C0).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.local_shipping_outlined, color: Color(0xFF1565C0), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dNumber,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0A1E38),
                          ),
                        ),
                        Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: badgeColor),
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
                      Expanded(
                        child: Text(
                          customer,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${Formatters.formatNumber(qty.toInt())} units',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1565C0)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Product: $prodName', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                ],
              ),
            ),

            if (vehicle.isNotEmpty || driver.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (vehicle.isNotEmpty) ...[
                    const Icon(Icons.directions_car_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(vehicle, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                    const SizedBox(width: 12),
                  ],
                  if (driver.isNotEmpty) ...[
                    const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(driver, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  ],
                ],
              ),
            ],

            if (address.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(address, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status == 'READY' || status == 'PENDING') ...[
                  FilledButton.icon(
                    onPressed: () => _confirmDispatchOrder(d),
                    icon: const Icon(Icons.local_shipping, size: 14),
                    label: const Text('Confirm & Ship', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (status == 'DISPATCHED') ...[
                  FilledButton.icon(
                    onPressed: () => _updateOrderStatus(d, 'DELIVERED'),
                    icon: const Icon(Icons.check_circle_outline, size: 14),
                    label: const Text('Mark Delivered', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                  tooltip: 'Delete Challan',
                  onPressed: () => _confirmDeleteDispatch(d),
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
  // TAB 1: CUSTOMERS DIRECTORY
  // =========================================================================
  Widget _buildCustomersTab(bool isDark) {
    if (_isLoading && _customers.isEmpty) {
      return const DispatchScreenShimmer();
    }

    final filtered = _customers.where((c) {
      final q = _customerSearch.toLowerCase();
      return _customerSearch.isEmpty ||
          (c['name'] ?? '').toString().toLowerCase().contains(q) ||
          (c['company'] ?? '').toString().toLowerCase().contains(q) ||
          (c['phone'] ?? '').toString().toLowerCase().contains(q) ||
          (c['email'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Search Header
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search customer name, company, phone, email…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _customerSearch.isNotEmpty
                  ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _customerSearch = ''))
                  : null,
              isDense: true,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            ),
            onChanged: (val) => setState(() => _customerSearch = val),
          ),
        ),

        // List
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('No registered customers found', Icons.people_outline, 'Add client accounts to generate customized delivery challans')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final cust = filtered[index];
                    return _buildCustomerCard(cust, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> c, bool isDark) {
    final name = (c['name'] ?? 'Customer').toString();
    final company = (c['company'] ?? '').toString();
    final contact = (c['contact_person'] ?? '').toString();
    final phone = (c['phone'] ?? '').toString();
    final email = (c['email'] ?? '').toString();
    final address = (c['delivery_address'] ?? c['address'] ?? '').toString();
    final gst = (c['gst_number'] ?? '').toString();

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
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00695C).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business_outlined, color: Color(0xFF00695C), size: 18),
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
                      if (company.isNotEmpty)
                        Text(company, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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

            if (address.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(address, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showNewDispatchSheet(preselectedCustomer: c),
                  icon: const Icon(Icons.add_road, size: 14),
                  label: const Text('Create Challan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1565C0),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0A1E38)),
                  tooltip: 'Edit Customer',
                  onPressed: () => _showCustomerSheet(existing: c),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                  tooltip: 'Delete Customer',
                  onPressed: () => _confirmDeleteCustomer(c),
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
            color: isSelected ? const Color(0xFF1565C0) : const Color(0xFFE2E8F0),
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
                color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: const Color(0xFF1565C0)),
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
  Future<void> _updateOrderStatus(Map<String, dynamic> d, String newStatus) async {
    final id = (d['id'] ?? d['_id'])?.toString();
    if (id == null) return;
    try {
      final api = ref.read(apiServiceProvider);
      await api.updateCollectionItem('dispatch_orders', id, {
        'status': newStatus,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Challan marked as $newStatus'), backgroundColor: const Color(0xFF16A34A)),
      );
      _loadAllData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: const Color(0xFFDC2626)),
      );
    }
  }

  void _confirmDispatchOrder(Map<String, dynamic> d) {
    final id = (d['id'] ?? d['_id'])?.toString();
    final dNum = d['dispatch_number'] ?? 'Challan';
    final qty = d['quantity'] ?? 0;
    final cust = d['customer_name'] ?? 'Customer';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ship $dNum?'),
        content: Text('Confirm shipment of $qty units to $cust?\n\nThis will mark the order as DISPATCHED and update finished goods inventory.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = ref.read(apiServiceProvider);
                final now = DateTime.now().millisecondsSinceEpoch;
                await api.updateCollectionItem('dispatch_orders', id!, {
                  'status': 'DISPATCHED',
                  'dispatched_at': now,
                  'updated_at': now,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Challan $dNum has been shipped!'), backgroundColor: const Color(0xFF16A34A)),
                  );
                  _loadAllData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Dispatch failed: $e'), backgroundColor: const Color(0xFFDC2626)),
                  );
                }
              }
            },
            child: const Text('Confirm & Ship'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDispatch(Map<String, dynamic> d) {
    final id = (d['id'] ?? d['_id'])?.toString();
    final dNum = d['dispatch_number'] ?? 'Challan';
    if (id == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $dNum?'),
        content: const Text('Are you sure you want to delete this delivery challan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = ref.read(apiServiceProvider);
                await api.deleteCollectionItem('dispatch_orders', id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deleted $dNum')));
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

  void _confirmDeleteCustomer(Map<String, dynamic> c) {
    final id = (c['id'] ?? c['_id'])?.toString();
    final name = c['name'] ?? 'Customer';
    if (id == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text('Are you sure you want to delete this customer account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final api = ref.read(apiServiceProvider);
                await api.deleteCollectionItem('customers', id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Customer $name deleted')));
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
  void _showNewDispatchSheet({Map<String, dynamic>? preselectedCustomer}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewDispatchSheet(
        customers: _customers,
        products: _products,
        preselectedCustomer: preselectedCustomer,
        onCreated: () {
          _loadAllData();
          _tabController.animateTo(0);
        },
      ),
    );
  }

  void _showCustomerSheet({Map<String, dynamic>? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomerFormSheet(
        existing: existing,
        onSaved: () {
          _loadAllData();
          _tabController.animateTo(1);
        },
      ),
    );
  }
}

// ===========================================================================
// SUB-WIDGET: New Dispatch Order Sheet
// ===========================================================================
class _NewDispatchSheet extends ConsumerStatefulWidget {
  final List<Map<String, dynamic>> customers;
  final List<Map<String, dynamic>> products;
  final Map<String, dynamic>? preselectedCustomer;
  final VoidCallback onCreated;

  const _NewDispatchSheet({
    required this.customers,
    required this.products,
    this.preselectedCustomer,
    required this.onCreated,
  });

  @override
  ConsumerState<_NewDispatchSheet> createState() => _NewDispatchSheetState();
}

class _NewDispatchSheetState extends ConsumerState<_NewDispatchSheet> {
  String? _customerId;
  String? _productId;
  final _qtyController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _driverController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.preselectedCustomer != null) {
      _customerId = (widget.preselectedCustomer!['id'] ?? widget.preselectedCustomer!['_id'])?.toString();
      _addressController.text = widget.preselectedCustomer!['delivery_address'] ?? widget.preselectedCustomer!['address'] ?? '';
    } else if (widget.customers.isNotEmpty) {
      _customerId = (widget.customers.first['id'] ?? widget.customers.first['_id'])?.toString();
      _addressController.text = widget.customers.first['delivery_address'] ?? widget.customers.first['address'] ?? '';
    }

    if (widget.products.isNotEmpty) {
      _productId = (widget.products.first['id'] ?? widget.products.first['_id'])?.toString();
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _vehicleController.dispose();
    _driverController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final qty = double.tryParse(_qtyController.text.trim()) ?? 0.0;
    if (_customerId == null || _productId == null || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select customer, product, and valid quantity (>0)'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final api = ref.read(apiServiceProvider);
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      int totalCount = 0;
      try {
        final existing = await api.getCollection('dispatch_orders', queryParams: {'limit': 1});
        totalCount = existing.pagination.total;
      } catch (_) {}
      final dNumber = 'DSP-${(totalCount + 1).toString().padLeft(4, '0')}';

      final cust = widget.customers.firstWhere((c) => (c['id'] ?? c['_id'])?.toString() == _customerId, orElse: () => {});
      final prod = widget.products.firstWhere((p) => (p['id'] ?? p['_id'])?.toString() == _productId, orElse: () => {});

      final doc = {
        'id': 'dsp-$now',
        'dispatch_number': dNumber,
        'customer_id': _customerId,
        'customer_name': cust['name'] ?? 'Customer',
        'product_id': _productId,
        'product_code': prod['code'] ?? '',
        'product_name': prod['name'] ?? 'Product',
        'quantity': qty,
        'delivery_address': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        'vehicle_number': _vehicleController.text.trim().isNotEmpty ? _vehicleController.text.trim() : null,
        'driver_name': _driverController.text.trim().isNotEmpty ? _driverController.text.trim() : null,
        'notes': _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        'status': 'READY',
        'created_at': now,
        'updated_at': now,
      };

      await api.createCollectionItem('dispatch_orders', doc);

      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delivery Challan $dNumber generated'), backgroundColor: const Color(0xFF16A34A)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create challan: $e'), backgroundColor: const Color(0xFFDC2626)),
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
                  'New Delivery Challan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0A1E38)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            const Text('Customer Account *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _customerId,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: widget.customers.map((c) {
                final id = (c['id'] ?? c['_id'])?.toString() ?? '';
                final name = c['name'] ?? 'Customer';
                return DropdownMenuItem(value: id, child: Text(name, style: const TextStyle(fontSize: 13.5)));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _customerId = val;
                  final c = widget.customers.firstWhere((x) => (x['id'] ?? x['_id'])?.toString() == val, orElse: () => {});
                  _addressController.text = c['delivery_address'] ?? c['address'] ?? '';
                });
              },
            ),
            const SizedBox(height: 14),

            const Text('Finished Product *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _productId,
              isExpanded: true,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: widget.products.map((p) {
                final id = (p['id'] ?? p['_id'])?.toString() ?? '';
                final name = p['name'] ?? 'Product';
                final code = p['code'] ?? '';
                return DropdownMenuItem(value: id, child: Text('$name ($code)', style: const TextStyle(fontSize: 13.5)));
              }).toList(),
              onChanged: (val) => setState(() => _productId = val),
            ),
            const SizedBox(height: 14),

            const Text('Dispatch Quantity *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 150',
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
                      const Text('Vehicle Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _vehicleController,
                        decoration: InputDecoration(
                          hintText: 'MH-14-GH-4589',
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
                      const Text('Driver Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _driverController,
                        decoration: InputDecoration(
                          hintText: 'Balram Yadav',
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

            const Text('Delivery Destination Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Plot 14, MIDC Pimpri, Pune',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),

            const Text('Notes / Instructions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'e.g. Include physical QC pass test certificates',
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
                  backgroundColor: const Color(0xFF1565C0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Delivery Challan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// SUB-WIDGET: Customer Create & Edit Form Sheet
// ===========================================================================
class _CustomerFormSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  const _CustomerFormSheet({this.existing, required this.onSaved});

  @override
  ConsumerState<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends ConsumerState<_CustomerFormSheet> {
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _nameController.text = e['name'] ?? '';
      _companyController.text = e['company'] ?? '';
      _contactController.text = e['contact_person'] ?? '';
      _phoneController.text = e['phone'] ?? '';
      _emailController.text = e['email'] ?? '';
      _addressController.text = e['delivery_address'] ?? e['address'] ?? '';
      _gstController.text = e['gst_number'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter customer name'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final api = ref.read(apiServiceProvider);
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      final data = {
        'name': name,
        'company': _companyController.text.trim().isNotEmpty ? _companyController.text.trim() : name,
        'contact_person': _contactController.text.trim().isNotEmpty ? _contactController.text.trim() : null,
        'phone': _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        'email': _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        'delivery_address': _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : null,
        'gst_number': _gstController.text.trim().isNotEmpty ? _gstController.text.trim() : null,
        'updated_at': now,
      };

      if (widget.existing != null) {
        final id = (widget.existing!['id'] ?? widget.existing!['_id'])?.toString();
        if (id != null) {
          await api.updateCollectionItem('customers', id, data);
        }
      } else {
        data['id'] = 'cust-$now';
        data['code'] = 'CUST-${now % 1000}';
        data['created_at'] = now;
        await api.createCollectionItem('customers', data);
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.existing != null ? 'Customer updated' : 'Customer account enrolled'), backgroundColor: const Color(0xFF16A34A)),
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
                  isEdit ? 'Edit Customer' : 'Add New Customer',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0A1E38)),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            const Text('Customer Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Tata Motors Ltd',
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
                      const Text('Company / Brand', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _companyController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Tata Commercial',
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
                          hintText: 'e.g. Suresh Patil',
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
                          hintText: '+91 9823012345',
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
                          hintText: 'spatil@tatamotors.com',
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

            const Text('GSTIN Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _gstController,
              decoration: InputDecoration(
                hintText: '27AAACT2727Q1ZW',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),

            const Text('Delivery Destination Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Plot 14, MIDC Pimpri, Pune, MH 411018',
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
                  backgroundColor: const Color(0xFF00695C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isEdit ? 'Save Changes' : 'Enroll Customer', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}