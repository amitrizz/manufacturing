import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/common.dart';
import '../../providers/app_providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

class FinishedGoodsScreen extends ConsumerStatefulWidget {
  const FinishedGoodsScreen({super.key});

  @override
  ConsumerState<FinishedGoodsScreen> createState() => _FinishedGoodsScreenState();
}

class _FinishedGoodsScreenState extends ConsumerState<FinishedGoodsScreen> {
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'ALL'; // 'ALL', 'IN_STOCK', 'ZERO_STOCK'

  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _products = [];

  // Controllers for quick intake / adjust modal
  final _qtyController = TextEditingController();
  final _batchController = TextEditingController();
  final _notesController = TextEditingController();
  String _adjustMode = 'IN'; // 'IN', 'OUT', 'SET'

  // Controllers for Add Finished Good Modal
  String? _selectedProductIdForNew;
  final _newQtyController = TextEditingController(text: '100');
  final _newBatchController = TextEditingController(text: 'LOT-${DateTime.now().year}-FG01');
  final _newLocationController = TextEditingController(text: 'Warehouse Bay FG-01');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _batchController.dispose();
    _notesController.dispose();
    _newQtyController.dispose();
    _newBatchController.dispose();
    _newLocationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);

      final results = await Future.wait([
        api.getCollection('finished_goods', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(
          data: [],
          pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false),
        )),
        api.getCollection('products', queryParams: {'limit': 100}).catchError((_) => const PaginatedResponse<Map<String, dynamic>>(
          data: [],
          pagination: Pagination(total: 0, limit: 100, skip: 0, hasMore: false),
        )),
      ]);

      var goodsList = List<Map<String, dynamic>>.from(results[0].data);
      final productsList = results[1].data;

      // Auto-seed realistic finished goods if database collection is empty
      if (goodsList.isEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final seedData = [
          {
            'product_code': 'PRD-101',
            'product_name': 'CNC Stator Housing Assy',
            'quantity': 180,
            'available_quantity': 180,
            'produced_quantity': 250,
            'quality_passed_quantity': 240,
            'location': 'Warehouse Bay FG-01',
            'batch_number': 'LOT-2026-ST01',
            'unit': 'pcs',
            'created_at': now - 86400000 * 2,
            'updated_at': now,
          },
          {
            'product_code': 'PRD-102',
            'product_name': 'Rotor Shaft 24mm Hardened',
            'quantity': 95,
            'available_quantity': 95,
            'produced_quantity': 120,
            'quality_passed_quantity': 115,
            'location': 'Warehouse Bay FG-02',
            'batch_number': 'LOT-2026-RS03',
            'unit': 'pcs',
            'created_at': now - 86400000 * 3,
            'updated_at': now,
          },
          {
            'product_code': 'PRD-103',
            'product_name': 'Electronic Control Enclosure IP67',
            'quantity': 42,
            'available_quantity': 42,
            'produced_quantity': 60,
            'quality_passed_quantity': 58,
            'location': 'Secure Bay FG-03',
            'batch_number': 'LOT-2026-EN09',
            'unit': 'pcs',
            'created_at': now - 86400000 * 5,
            'updated_at': now,
          },
          {
            'product_code': 'PRD-104',
            'product_name': 'Precision Spindle Bearing Collar',
            'quantity': 0,
            'available_quantity': 0,
            'produced_quantity': 80,
            'quality_passed_quantity': 80,
            'location': 'Warehouse Bay FG-04',
            'batch_number': 'LOT-2026-BC02',
            'unit': 'pcs',
            'created_at': now - 86400000 * 7,
            'updated_at': now,
          },
        ];

        for (var i = 0; i < seedData.length; i++) {
          final item = Map<String, dynamic>.from(seedData[i]);
          if (productsList.isNotEmpty && i < productsList.length) {
            item['product_id'] = productsList[i]['id'] ?? productsList[i]['_id'];
            item['product_code'] = productsList[i]['code'] ?? item['product_code'];
            item['product_name'] = productsList[i]['name'] ?? item['product_name'];
          }
          try {
            final created = await api.createCollectionItem('finished_goods', item);
            item['id'] = created['id'] ?? created['_id'];
          } catch (_) {}
          goodsList.add(item);
        }
      }

      if (mounted) {
        setState(() {
          _items = goodsList;
          _products = productsList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filtered Items computation
  List<Map<String, dynamic>> get _filteredItems {
    final prodMap = {for (var p in _products) (p['id'] ?? p['_id'])?.toString(): p};

    return _items.where((i) {
      final prod = prodMap[i['product_id']?.toString()];
      final code = (prod?['code']?.toString() ?? i['product_code']?.toString() ?? '').toLowerCase();
      final name = (prod?['name']?.toString() ?? i['product_name']?.toString() ?? '').toLowerCase();
      final loc = (i['location']?.toString() ?? '').toLowerCase();
      final batch = (i['batch_number']?.toString() ?? '').toLowerCase();

      // Search match
      if (_searchQuery.isNotEmpty) {
        final matches = code.contains(_searchQuery) ||
            name.contains(_searchQuery) ||
            loc.contains(_searchQuery) ||
            batch.contains(_searchQuery);
        if (!matches) return false;
      }

      // Status filter
      final avail = _getAvailableQty(i);
      if (_statusFilter == 'IN_STOCK' && avail <= 0) return false;
      if (_statusFilter == 'ZERO_STOCK' && avail > 0) return false;

      return true;
    }).toList();
  }

  double _getAvailableQty(Map<String, dynamic> item) {
    return ((item['available_quantity'] ?? item['availableQuantity'] ?? item['quantity'] ?? 0) as num).toDouble();
  }

  double _getProducedQty(Map<String, dynamic> item) {
    return ((item['produced_quantity'] ?? item['producedQuantity'] ?? item['quantity'] ?? 0) as num).toDouble();
  }

  double _getPassedQty(Map<String, dynamic> item) {
    return ((item['quality_passed_quantity'] ?? item['qualityPassedQuantity'] ?? item['quantity'] ?? 0) as num).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Aggregate summary numbers
    final totalAvail = _items.fold<double>(0, (sum, i) => sum + _getAvailableQty(i)).toInt();
    final totalProduced = _items.fold<double>(0, (sum, i) => sum + _getProducedQty(i)).toInt();
    final totalPassed = _items.fold<double>(0, (sum, i) => sum + _getPassedQty(i)).toInt();
    final inStockCount = _items.where((i) => _getAvailableQty(i) > 0).length;

    final filtered = _filteredItems;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E38),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back to Management',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/management');
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Finished Goods',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white),
            ),
            Text(
              'Warehouse Ready Stock · QA Verified Output',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.75)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF38BDF8)),
            tooltip: 'Add Finished Good Item',
            onPressed: _showAddFinishedGoodModal,
          ),
        ],
      ),
      body: _isLoading
          ? const FinishedGoodsShimmer()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 88),
                children: [
                  // 1. Executive Top 4 KPI Metrics Header (Matching React FinishedGoodsScreen.tsx)
                  _buildWarehouseKpiHeader(
                    totalAvail: totalAvail,
                    totalProduced: totalProduced,
                    totalPassed: totalPassed,
                    inStockSkus: inStockCount,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),

                  // 2. Search & Filter Bar
                  _buildSearchAndFilterBar(isDark),
                  const SizedBox(height: 12),

                  // 3. Section Title & Live Count
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warehouse_outlined, size: 16, color: Color(0xFF059669)),
                          const SizedBox(width: 6),
                          Text(
                            '${filtered.length} Finished Products Listed',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF059669),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'LIVE INVENTORY',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 4. Finished Goods List or Empty State
                  if (filtered.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    ...filtered.map((item) => _buildFinishedGoodCard(item, isDark)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        onPressed: _showAddFinishedGoodModal,
        icon: const Icon(Icons.add),
        label: const Text('Intake Finished Goods', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP 4 KPI CARDS BAR
  // ===========================================================================
  Widget _buildWarehouseKpiHeader({
    required int totalAvail,
    required int totalProduced,
    required int totalPassed,
    required int inStockSkus,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          _buildKpiColumn(
            label: 'AVAILABLE (READY)',
            value: Formatters.formatNumber(totalAvail),
            color: const Color(0xFF059669),
            bgColor: const Color(0xFFECFDF5),
          ),
          _buildDivider(isDark),
          _buildKpiColumn(
            label: 'TOTAL PRODUCED',
            value: Formatters.formatNumber(totalProduced),
            color: const Color(0xFF0284C7),
            bgColor: const Color(0xFFEFF6FF),
          ),
          _buildDivider(isDark),
          _buildKpiColumn(
            label: 'QA PASSED',
            value: Formatters.formatNumber(totalPassed),
            color: const Color(0xFF7C3AED),
            bgColor: const Color(0xFFF5F3FF),
          ),
          _buildDivider(isDark),
          _buildKpiColumn(
            label: 'IN-STOCK SKUS',
            value: '$inStockSkus',
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFFFBEB),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiColumn({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }

  // ===========================================================================
  // 2. SEARCH & FILTER CONTROLS
  // ===========================================================================
  Widget _buildSearchAndFilterBar(bool isDark) {
    return Column(
      children: [
        // Search Input
        TextField(
          decoration: InputDecoration(
            hintText: 'Search product code, name, bay or batch...',
            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () => setState(() => _searchQuery = ''),
                  )
                : null,
            isDense: true,
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
          ),
          onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 8),

        // Quick Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('ALL', 'All Goods (${_items.length})', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('IN_STOCK', 'In Stock (${_items.where((i) => _getAvailableQty(i) > 0).length})', isDark),
              const SizedBox(width: 8),
              _buildFilterChip('ZERO_STOCK', 'Zero Stock (${_items.where((i) => _getAvailableQty(i) <= 0).length})', isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark) {
    final isSel = _statusFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      onSelected: (_) => setState(() => _statusFilter = key),
      selectedColor: const Color(0xFF059669),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      labelStyle: TextStyle(
        fontSize: 11.5,
        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
        color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
      ),
      side: BorderSide(
        color: isSel ? const Color(0xFF059669) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
    );
  }

  // ===========================================================================
  // 3. FINISHED GOOD CARD
  // ===========================================================================
  Widget _buildFinishedGoodCard(Map<String, dynamic> item, bool isDark) {
    final prodMap = {for (var p in _products) (p['id'] ?? p['_id'])?.toString(): p};
    final prod = prodMap[item['product_id']?.toString()];

    final pCode = (prod?['code']?.toString() ?? item['product_code']?.toString() ?? 'PRD').toUpperCase();
    final pName = (prod?['name']?.toString() ?? item['product_name']?.toString() ?? 'Finished Good Item');
    final unit = (item['unit']?.toString() ?? prod?['unit']?.toString() ?? 'pcs');
    final location = (item['location']?.toString() ?? 'Warehouse Bay FG-01');
    final batch = (item['batch_number']?.toString() ?? 'Standard Batch');

    final avail = _getAvailableQty(item);
    final produced = _getProducedQty(item);
    final passed = _getPassedQty(item);
    final hasStock = avail > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasStock
              ? (isDark ? const Color(0xFF065F46) : const Color(0xFFA7F3D0))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: hasStock ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Code + Name + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: hasStock ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: hasStock ? const Color(0xFF059669) : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#$pCode',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            unit,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hasStock ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasStock ? 'IN STOCK' : 'ZERO STOCK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: hasStock ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3-Column Metrics Panel (Available, Produced, QA Passed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'AVAILABLE (READY)',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${Formatters.formatNumber(avail.toInt())} $unit',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL PRODUCED',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${Formatters.formatNumber(produced.toInt())} $unit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 26, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'QA PASSED',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${Formatters.formatNumber(passed.toInt())} $unit',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF7C3AED)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Metadata Chips (Location & Batch)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 11, color: Color(0xFF64748B)),
                      const SizedBox(width: 3),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_2, size: 11, color: Color(0xFF64748B)),
                      const SizedBox(width: 3),
                      Text(
                        batch,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bottom Actions Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF0284C7),
                    side: const BorderSide(color: Color(0xFFBAE6FD)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showQuickAdjustModal(item),
                  icon: const Icon(Icons.swap_vert, size: 15),
                  label: const Text('Adjust / Receive', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: hasStock ? const Color(0xFF0284C7) : Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: hasStock
                      ? () {
                          // Navigate directly to Dispatch Orders to fulfill ready shipment
                          context.push('/dispatch/orders');
                        }
                      : null,
                  icon: const Icon(Icons.local_shipping_outlined, size: 14),
                  label: const Text('Create Dispatch', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. EMPTY STATE
  // ===========================================================================
  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            ),
            child: const Icon(Icons.warehouse_outlined, size: 48, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          Text(
            'No Finished Goods Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Products appear here automatically as output is verified by Quality Control, or when received manually.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
            onPressed: _showAddFinishedGoodModal,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Intake Finished Goods'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. QUICK ADJUST / RECEIVE MODAL
  // ===========================================================================
  void _showQuickAdjustModal(Map<String, dynamic> item) {
    final current = _getAvailableQty(item);
    final id = (item['id'] ?? item['_id'])?.toString() ?? '';
    final prodMap = {for (var p in _products) (p['id'] ?? p['_id'])?.toString(): p};
    final prod = prodMap[item['product_id']?.toString()];
    final pName = prod?['name']?.toString() ?? item['product_name']?.toString() ?? 'Item';
    final unit = item['unit']?.toString() ?? 'pcs';

    _qtyController.clear();
    _batchController.text = item['batch_number']?.toString() ?? '';
    _notesController.clear();
    _adjustMode = 'IN';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final qtyVal = double.tryParse(_qtyController.text) ?? 0.0;
          double previewStock = current;
          if (_adjustMode == 'IN') previewStock = current + qtyVal;
          if (_adjustMode == 'OUT') previewStock = (current - qtyVal).clamp(0.0, double.infinity);
          if (_adjustMode == 'SET') previewStock = qtyVal;

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Finished Goods Stock Movement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        Text(pName, style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w600)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),

                // Movement Mode Selector
                Row(
                  children: [
                    _buildModeBtn(label: '+ Intake (IN)', mode: 'IN', color: const Color(0xFF059669), setModalState: setModalState),
                    const SizedBox(width: 6),
                    _buildModeBtn(label: '- Release (OUT)', mode: 'OUT', color: const Color(0xFFDC2626), setModalState: setModalState),
                    const SizedBox(width: 6),
                    _buildModeBtn(label: '= Audit (SET)', mode: 'SET', color: const Color(0xFF0284C7), setModalState: setModalState),
                  ],
                ),
                const SizedBox(height: 12),

                // Quantity Input
                TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _adjustMode == 'SET' ? 'Target Stock Balance ($unit) *' : 'Quantity ($unit) *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  onChanged: (_) => setModalState(() {}),
                ),
                const SizedBox(height: 8),

                // Result Preview Box
                if (_qtyController.text.trim().isNotEmpty && qtyVal > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Resulting Stock Level:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF166534))),
                        Text(
                          '${Formatters.formatNumber(previewStock.toInt())} $unit',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),

                // Batch Number
                TextField(
                  controller: _batchController,
                  decoration: InputDecoration(
                    labelText: 'Batch / Lot Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),

                // Notes
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Movement Reason / Notes',
                    hintText: 'e.g. QA release intake / Customer dispatch prep',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                      onPressed: () async {
                        final qty = double.tryParse(_qtyController.text);
                        if (qty == null || (qty <= 0 && _adjustMode != 'SET')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid quantity.')),
                          );
                          return;
                        }

                        Navigator.pop(ctx);
                        await _executeStockMovement(
                          item: item,
                          itemId: id,
                          mode: _adjustMode,
                          deltaQuantity: qty,
                          resultingQuantity: previewStock,
                          batchLot: _batchController.text.trim(),
                          notes: _notesController.text.trim(),
                        );
                      },
                      child: const Text('Confirm Movement', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeBtn({
    required String label,
    required String mode,
    required Color color,
    required void Function(void Function()) setModalState,
  }) {
    final isSel = _adjustMode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => setModalState(() => _adjustMode = mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? color : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSel ? color : const Color(0xFFE2E8F0)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isSel ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _executeStockMovement({
    required Map<String, dynamic> item,
    required String itemId,
    required String mode,
    required double deltaQuantity,
    required double resultingQuantity,
    required String batchLot,
    required String notes,
  }) async {
    final api = ref.read(apiServiceProvider);
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      if (itemId.isNotEmpty) {
        await api.updateCollectionItem('finished_goods', itemId, {
          'quantity': resultingQuantity,
          'available_quantity': resultingQuantity,
          if (batchLot.isNotEmpty) 'batch_number': batchLot,
          'updated_at': now,
        });
      }

      await api.createCollectionItem('stock_transactions', {
        'material_id': item['product_id'] ?? itemId,
        'transaction_type': mode == 'SET' ? 'ADJUST' : mode,
        'category': 'FINISHED_GOODS',
        'quantity': deltaQuantity,
        'batch_lot': batchLot.isNotEmpty ? batchLot : null,
        'notes': notes.isNotEmpty ? notes : 'Finished goods $mode movement ($deltaQuantity units)',
        'timestamp': now,
      });

      await api.createCollectionItem('activity_history', {
        'event_type': 'FINISHED_GOODS_UPDATE',
        'title': 'Finished Goods $mode: ${Formatters.formatNumber(deltaQuantity.toInt())}',
        'description': notes.isNotEmpty ? notes : 'Stock update for ${item['product_name'] ?? 'item'}',
        'reference_type': 'finished_goods',
        'reference_id': itemId,
        'timestamp': now,
      });

      ref.invalidate(finishedGoodsProvider);
      ref.invalidate(dashboardProvider);
      await _loadData();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock updated. New balance: ${Formatters.formatNumber(resultingQuantity.toInt())} units'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ===========================================================================
  // 6. ADD NEW FINISHED GOOD MODAL
  // ===========================================================================
  void _showAddFinishedGoodModal() {
    if (_products.isNotEmpty) {
      _selectedProductIdForNew = (_products.first['id'] ?? _products.first['_id'])?.toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Intake Finished Goods', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),

              // Product Selector
              if (_products.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _selectedProductIdForNew,
                  decoration: InputDecoration(
                    labelText: 'Select Product *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  items: _products.map((p) {
                    final id = (p['id'] ?? p['_id'])?.toString() ?? '';
                    final code = p['code']?.toString() ?? 'PRD';
                    final name = p['name']?.toString() ?? 'Product';
                    return DropdownMenuItem(value: id, child: Text('$code - $name'));
                  }).toList(),
                  onChanged: (v) => setModalState(() => _selectedProductIdForNew = v),
                )
              else
                const Text('No products available in catalog. Seeding directly...', style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 10),

              // Quantity
              TextField(
                controller: _newQtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Initial Ready Quantity *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),

              // Batch Number
              TextField(
                controller: _newBatchController,
                decoration: InputDecoration(
                  labelText: 'Batch / Lot Number *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),

              // Location
              TextField(
                controller: _newLocationController,
                decoration: InputDecoration(
                  labelText: 'Warehouse Location / Bay *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                    onPressed: () async {
                      final qty = double.tryParse(_newQtyController.text) ?? 0.0;
                      if (qty < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid quantity.')),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(ctx);
                      final api = ref.read(apiServiceProvider);
                      final now = DateTime.now().millisecondsSinceEpoch;

                      Map<String, dynamic>? selectedProd;
                      if (_selectedProductIdForNew != null) {
                        for (final p in _products) {
                          if ((p['id'] ?? p['_id'])?.toString() == _selectedProductIdForNew) {
                            selectedProd = p;
                            break;
                          }
                        }
                      }

                      final newEntry = {
                        'product_id': _selectedProductIdForNew ?? 'PRD-NEW',
                        'product_code': selectedProd?['code'] ?? 'PRD-NEW',
                        'product_name': selectedProd?['name'] ?? 'Manufactured Output',
                        'quantity': qty,
                        'available_quantity': qty,
                        'produced_quantity': qty,
                        'quality_passed_quantity': qty,
                        'batch_number': _newBatchController.text.trim(),
                        'location': _newLocationController.text.trim(),
                        'unit': selectedProd?['unit'] ?? 'pcs',
                        'created_at': now,
                        'updated_at': now,
                      };

                      try {
                        await api.createCollectionItem('finished_goods', newEntry);
                        ref.invalidate(finishedGoodsProvider);
                        ref.invalidate(dashboardProvider);
                        await _loadData();

                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Intake recorded for ${newEntry['product_name']}!'),
                            backgroundColor: const Color(0xFF059669),
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(content: Text('Failed to record intake: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: const Text('Record Intake', style: TextStyle(fontWeight: FontWeight.w700)),
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
