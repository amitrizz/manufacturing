import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const InventoryScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 0 (Stock Inventory - matches React StockHomeScreen.tsx) State
  String _stockSegment = 'raw'; // 'raw' or 'ledger'
  String _stockSearch = '';
  String? _selectedMaterialIdForMove;
  String _updateStockMode = 'IN'; // 'IN', 'OUT', 'SET'
  final _moveQtyController = TextEditingController();
  final _moveBatchLotController = TextEditingController();
  final _moveNotesController = TextEditingController();

  // Material Create / Edit State
  final _matCodeController = TextEditingController();
  final _matNameController = TextEditingController();
  final _matCategoryController = TextEditingController(text: 'RAW_MATERIAL');
  final _matOpeningStockController = TextEditingController(text: '0');
  final _matMinStockController = TextEditingController(text: '10');
  final _matMaxStockController = TextEditingController(text: '1000');
  String _matUnit = 'pcs';

  // Tab 1 (Stores & Materials - matches React MaterialsScreen.tsx) State
  String _materialsSearch = '';
  String _materialsFilter = 'all'; // 'all' or 'low'

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _moveQtyController.dispose();
    _moveBatchLotController.dispose();
    _moveNotesController.dispose();
    _matCodeController.dispose();
    _matNameController.dispose();
    _matCategoryController.dispose();
    _matOpeningStockController.dispose();
    _matMinStockController.dispose();
    _matMaxStockController.dispose();
    super.dispose();
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
          'Inventory & Warehouse',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Stock Inventory'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_outlined, size: 16),
                  SizedBox(width: 6),
                  Text('Stores & Materials'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStockInventoryTab(isDark),
          _buildStoresMaterialsTab(isDark),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    switch (_tabController.index) {
      case 0:
        return FloatingActionButton.extended(
          backgroundColor: const Color(0xFF0284C7),
          foregroundColor: Colors.white,
          onPressed: () => _showUpdateStockModal(),
          icon: const Icon(Icons.swap_vert_rounded),
          label: const Text('Update Stock', style: TextStyle(fontWeight: FontWeight.w700)),
        );
      case 1:
        return FloatingActionButton.extended(
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          onPressed: () => _showAddEditMaterialModal(),
          icon: const Icon(Icons.add),
          label: const Text('Add Material', style: TextStyle(fontWeight: FontWeight.w700)),
        );
      default:
        return null;
    }
  }

  // ===========================================================================
  // TAB 0: Stock Inventory (Exact 1:1 match with React StockHomeScreen.tsx)
  // ===========================================================================
  Widget _buildStockInventoryTab(bool isDark) {
    final materialsAsync = ref.watch(materialsProvider(const {'limit': 100}));
    final transactionsAsync = ref.watch(stockTransactionsProvider(const {'limit': 50}));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(materialsProvider);
        ref.invalidate(stockTransactionsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Segment Switcher (Raw & Components vs Ledger)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _stockSegment = 'raw'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _stockSegment == 'raw' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _stockSegment == 'raw'
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Raw & Components (${materialsAsync.valueOrNull?.data.length ?? 0})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _stockSegment == 'raw' ? FontWeight.w700 : FontWeight.w600,
                          color: _stockSegment == 'raw' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _stockSegment = 'ledger'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _stockSegment == 'ledger' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: _stockSegment == 'ledger'
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        'Ledger (${transactionsAsync.valueOrNull?.data.length ?? 0})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _stockSegment == 'ledger' ? FontWeight.w700 : FontWeight.w600,
                          color: _stockSegment == 'ledger' ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Row (Search & Action Buttons)
          if (_stockSegment == 'raw') ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search items by code/name…',
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      ),
                    ),
                    onChanged: (v) => setState(() => _stockSearch = v.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showAddEditMaterialModal(),
                  child: const Text('+ Add Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0284C7))),
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showUpdateStockModal(),
                  icon: const Icon(Icons.swap_vert, size: 16),
                  label: const Text('Update', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Inventory Transactions',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0A1E38)),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showUpdateStockModal(),
                  icon: const Icon(Icons.swap_vert, size: 16),
                  label: const Text('Update Stock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          // Content List
          if (_stockSegment == 'raw')
            materialsAsync.when(
              data: (paginated) {
                var items = paginated.data;
                if (_stockSearch.isNotEmpty) {
                  items = items.where((m) {
                    final name = (m['name']?.toString() ?? '').toLowerCase();
                    final code = (m['code']?.toString() ?? '').toLowerCase();
                    return name.contains(_stockSearch) || code.contains(_stockSearch);
                  }).toList();
                }

                if (items.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text('No materials found', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                        const SizedBox(height: 10),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                          onPressed: () => _showAddEditMaterialModal(),
                          child: const Text('+ Add Material Item'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: items.map((m) => _buildStockMaterialCard(m, isDark)).toList(),
                );
              },
              loading: () => AppShimmer(
                child: Column(
                  children: List.generate(5, (_) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ShimmerBox(width: 70, height: 14, borderRadius: 4),
                                  SizedBox(width: 8),
                                  ShimmerBox(width: 65, height: 14, borderRadius: 4),
                                ],
                              ),
                              SizedBox(height: 6),
                              ShimmerBox(width: 170, height: 16, borderRadius: 4),
                              SizedBox(height: 6),
                              ShimmerBox(width: 130, height: 12, borderRadius: 4),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ShimmerBox(width: 65, height: 20, borderRadius: 6),
                            SizedBox(height: 6),
                            ShimmerBox(width: 45, height: 12, borderRadius: 4),
                          ],
                        ),
                      ],
                    ),
                  )),
                ),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            )
          else
            transactionsAsync.when(
              data: (paginated) {
                final txs = paginated.data;
                final materials = materialsAsync.valueOrNull?.data ?? [];
                final matMap = {for (var m in materials) (m['id'] ?? m['_id'])?.toString(): m['name']?.toString()};

                if (txs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    alignment: Alignment.center,
                    child: const Text('No stock transactions in ledger', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                  );
                }

                return Column(
                  children: txs.map((tx) {
                    final matName = matMap[tx['material_id']?.toString()] ?? tx['material_name'] ?? tx['product_name'] ?? 'Inventory Item';
                    return _buildStockLedgerCard(tx, matName, isDark);
                  }).toList(),
                );
              },
              loading: () => AppShimmer(
                child: Column(
                  children: List.generate(4, (_) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(width: 80, height: 14, borderRadius: 4),
                            SizedBox(height: 6),
                            ShimmerBox(width: 150, height: 16, borderRadius: 4),
                          ],
                        ),
                        ShimmerBox(width: 60, height: 22, borderRadius: 6),
                      ],
                    ),
                  )),
                ),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
        ],
      ),
    );
  }

  Widget _buildStockMaterialCard(Map<String, dynamic> item, bool isDark) {
    final currentStock = (item['current_stock'] as num?)?.toDouble() ?? 0.0;
    final minStock = (item['minimum_stock'] as num?)?.toDouble() ?? 0.0;
    final maxStock = (item['maximum_stock'] as num?)?.toDouble() ?? 0.0;
    final unit = item['unit']?.toString() ?? 'pcs';
    final isLow = currentStock <= minStock;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Code • Category, Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name']?.toString() ?? 'Material',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0A1E38)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item['code'] ?? ''} • ${item['category'] ?? 'RAW_MATERIAL'}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isLow ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isLow ? 'LOW STOCK' : 'AVAILABLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isLow ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stock Numbers Row
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Stock', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.formatNumber(currentStock.toInt())} $unit',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isLow ? const Color(0xFFDC2626) : const Color(0xFF0A1E38),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Min Required', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.formatNumber(minStock.toInt())} $unit',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0A1E38)),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Max Cap', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.formatNumber(maxStock.toInt())} $unit',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0A1E38)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Actions Row (Edit, Delete, Update Stock)
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => _showAddEditMaterialModal(existing: item),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 12, color: Color(0xFF0A1E38)),
                            SizedBox(width: 4),
                            Text('Edit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0A1E38))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _confirmDeleteMaterial(item),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          border: Border.all(color: const Color(0xFFFECACA)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline, size: 12, color: Color(0xFFDC2626)),
                            SizedBox(width: 4),
                            Text('Delete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _showUpdateStockModal(preselectedMaterialId: (item['id'] ?? item['_id'])?.toString()),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      border: Border.all(color: const Color(0xFFBAE6FD)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.swap_vert, size: 14, color: Color(0xFF0284C7)),
                        SizedBox(width: 4),
                        Text('Update Stock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockLedgerCard(Map<String, dynamic> tx, String matName, bool isDark) {
    final type = tx['transaction_type']?.toString().toUpperCase() ?? 'IN';
    final qty = (tx['quantity'] as num?)?.toDouble() ?? 0.0;
    final isIn = type == 'IN';
    final refType = tx['reference_type']?.toString() ?? 'MANUAL';
    final createdAt = tx['created_at'];
    final notes = tx['notes']?.toString();

    DateTime dt;
    if (createdAt is num) {
      dt = DateTime.fromMillisecondsSinceEpoch(createdAt.toInt());
    } else {
      dt = DateTime.now();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      matName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0A1E38)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.formatDateTime(dt)} • $refType',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isIn ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${isIn ? '+' : '-'} ${Formatters.formatNumber(qty.toInt())}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isIn ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Notes: $notes',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: Stores & Materials (Matches React MaterialsScreen.tsx)
  // ===========================================================================
  Widget _buildStoresMaterialsTab(bool isDark) {
    final materialsAsync = ref.watch(materialsProvider(const {'limit': 100}));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(materialsProvider),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // BOM Matrix Link Banner (Exact React match: bomLink)
          InkWell(
            onTap: () {
              _tabController.animateTo(2); // Switch to Products & BOM tab
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                border: Border.all(color: const Color(0xFFBFDBFE)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hub_outlined, size: 16, color: Color(0xFF0284C7)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Material qty per product (BOM) →',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: Color(0xFF0284C7)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            decoration: InputDecoration(
              hintText: 'Search materials…',
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
              isDense: true,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
            ),
            onChanged: (v) => setState(() => _materialsSearch = v.trim().toLowerCase()),
          ),
          const SizedBox(height: 10),

          // Filter Chips (All materials vs Low stock)
          Row(
            children: [
              _buildFilterChip('All materials', _materialsFilter == 'all', () {
                setState(() => _materialsFilter = 'all');
              }),
              const SizedBox(width: 8),
              _buildFilterChip('Low stock', _materialsFilter == 'low', () {
                setState(() => _materialsFilter = 'low');
              }),
            ],
          ),
          const SizedBox(height: 12),

          // Materials List
          materialsAsync.when(
            data: (paginated) {
              var items = paginated.data;
              if (_materialsSearch.isNotEmpty) {
                items = items.where((m) {
                  final name = (m['name']?.toString() ?? '').toLowerCase();
                  final code = (m['code']?.toString() ?? '').toLowerCase();
                  return name.contains(_materialsSearch) || code.contains(_materialsSearch);
                }).toList();
              }
              if (_materialsFilter == 'low') {
                items = items.where((m) {
                  final current = (m['current_stock'] as num?)?.toDouble() ?? 0.0;
                  final min = (m['minimum_stock'] as num?)?.toDouble() ?? 0.0;
                  return current <= min;
                }).toList();
              }

              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  child: const Text('No materials found matching criteria', style: TextStyle(color: Color(0xFF64748B))),
                );
              }

              return Column(
                children: items.map((m) {
                  final current = (m['current_stock'] as num?)?.toDouble() ?? 0.0;
                  final min = (m['minimum_stock'] as num?)?.toDouble() ?? 0.0;
                  final unit = m['unit']?.toString() ?? 'pcs';
                  final level = current <= 0
                      ? 'SHORTAGE'
                      : current <= min
                          ? 'NEAR_MINIMUM'
                          : 'AVAILABLE';

                  Color levelColor = const Color(0xFF16A34A);
                  Color levelBg = const Color(0xFFDCFCE7);
                  if (level == 'SHORTAGE') {
                    levelColor = const Color(0xFFDC2626);
                    levelBg = const Color(0xFFFEE2E2);
                  } else if (level == 'NEAR_MINIMUM') {
                    levelColor = const Color(0xFFD97706);
                    levelBg = const Color(0xFFFEF3C7);
                  }

                  return InkWell(
                    onTap: () => _showMaterialDetailModal(m),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      m['code']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: levelBg, borderRadius: BorderRadius.circular(4)),
                                      child: Text(level, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: levelColor)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  m['name']?.toString() ?? 'Material',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Stock ${Formatters.formatNumber(current.toInt())} $unit (min ${Formatters.formatNumber(min.toInt())})',
                                  style: TextStyle(fontSize: 11, color: levelColor, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => AppShimmer(
              child: Column(
                children: List.generate(4, (_) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBox(width: 70, height: 13, borderRadius: 4),
                            SizedBox(height: 4),
                            ShimmerBox(width: 160, height: 14, borderRadius: 4),
                          ],
                        ),
                      ),
                      ShimmerBox(width: 60, height: 20, borderRadius: 6),
                    ],
                  ),
                )),
              ),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }



  // ===========================================================================
  // MODALS & DIALOGS (Update Stock, Add/Edit Material, Create Product, BOM)
  // ===========================================================================

  // 1. Update Stock Modal (Matches React handleRecordMovement)
  void _showUpdateStockModal({String? preselectedMaterialId}) {
    final materials = ref.read(materialsProvider(const {'limit': 100})).valueOrNull?.data ?? [];
    if (materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No materials found. Add a material first.')),
      );
      return;
    }

    _selectedMaterialIdForMove = preselectedMaterialId ?? (materials.first['id'] ?? materials.first['_id'])?.toString();
    _updateStockMode = 'IN';
    _moveQtyController.clear();
    _moveBatchLotController.clear();
    _moveNotesController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final selMat = materials.firstWhere(
            (m) => (m['id'] ?? m['_id'])?.toString() == _selectedMaterialIdForMove,
            orElse: () => materials.first,
          );
          final currentStock = (selMat['current_stock'] as num?)?.toDouble() ?? 0.0;
          final unit = selMat['unit']?.toString() ?? 'pcs';
          final qtyVal = double.tryParse(_moveQtyController.text) ?? 0.0;

          double previewStock = currentStock;
          if (_updateStockMode == 'SET') {
            previewStock = qtyVal > 0 ? qtyVal : 0.0;
          } else if (_updateStockMode == 'IN') {
            previewStock = currentStock + qtyVal;
          } else if (_updateStockMode == 'OUT') {
            previewStock = (currentStock - qtyVal).clamp(0.0, double.infinity);
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.swap_vert, size: 20, color: Color(0xFF0284C7)),
                          SizedBox(width: 8),
                          Text('Update Stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Material Summary Card
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(selMat['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text('${selMat['code']} • ${selMat['category']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBAE6FD)),
                          ),
                          child: Text(
                            'Current: ${Formatters.formatNumber(currentStock.toInt())} $unit',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mode Selector (+ Add In, - Deduct Out, = Set Exact)
                  const Text('Adjustment Action *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => _updateStockMode = 'IN'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _updateStockMode == 'IN' ? const Color(0xFF16A34A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _updateStockMode == 'IN' ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_downward, size: 14, color: _updateStockMode == 'IN' ? Colors.white : const Color(0xFF16A34A)),
                                const SizedBox(width: 4),
                                Text(
                                  '+ Add (In)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _updateStockMode == 'IN' ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => _updateStockMode = 'OUT'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _updateStockMode == 'OUT' ? const Color(0xFFDC2626) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _updateStockMode == 'OUT' ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_upward, size: 14, color: _updateStockMode == 'OUT' ? Colors.white : const Color(0xFFDC2626)),
                                const SizedBox(width: 4),
                                Text(
                                  '- Deduct (Out)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _updateStockMode == 'OUT' ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => _updateStockMode = 'SET'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _updateStockMode == 'SET' ? const Color(0xFF0284C7) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _updateStockMode == 'SET' ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.compare_arrows, size: 14, color: _updateStockMode == 'SET' ? Colors.white : const Color(0xFF0284C7)),
                                const SizedBox(width: 4),
                                Text(
                                  '= Set Exact',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _updateStockMode == 'SET' ? Colors.white : const Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Material Selector Chips
                  const Text('Select Material Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: materials.map((m) {
                        final id = (m['id'] ?? m['_id'])?.toString();
                        final isSel = id == _selectedMaterialIdForMove;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(m['name']?.toString() ?? 'Material'),
                            selected: isSel,
                            onSelected: (_) => setModalState(() => _selectedMaterialIdForMove = id),
                            selectedColor: const Color(0xFF0284C7),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : const Color(0xFF1E293B),
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Quantity Input
                  Text(
                    _updateStockMode == 'SET' ? 'New Target Stock Balance *' : 'Quantity *',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _moveQtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: _updateStockMode == 'SET' ? 'e.g. 500' : 'e.g. 100',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 8),

                  // Dynamic Resulting Level Preview Box (Exact React match: balancePreviewBox)
                  if (_moveQtyController.text.trim().isNotEmpty && qtyVal > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Resulting Stock Level:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0369A1))),
                          Text(
                            '${Formatters.formatNumber(previewStock.toInt())} $unit ${_updateStockMode != 'SET' ? "(${_updateStockMode == 'IN' ? '+' : '-'}${qtyVal.toInt()})" : ""}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Batch/Lot & Notes
                  const Text('Batch / Lot Number (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _moveBatchLotController,
                    decoration: InputDecoration(
                      hintText: 'e.g. LOT-2026-B1',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text('Purpose / Reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _moveNotesController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Physical inventory audit / Workshop intake',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Confirm Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      const SizedBox(width: 10),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final qty = double.tryParse(_moveQtyController.text);
                          if (qty == null || (qty <= 0 && _updateStockMode != 'SET')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid positive quantity.')),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          await _executeStockMovement(
                            material: selMat,
                            mode: _updateStockMode,
                            quantity: qty,
                            batchLot: _moveBatchLotController.text.trim(),
                            notes: _moveNotesController.text.trim(),
                          );
                        },
                        child: const Text('Confirm Stock Update', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _executeStockMovement({
    required Map<String, dynamic> material,
    required String mode,
    required double quantity,
    required String batchLot,
    required String notes,
  }) async {
    final apiService = ref.read(apiServiceProvider);
    final matId = (material['id'] ?? material['_id'])?.toString() ?? '';
    final currentStock = (material['current_stock'] as num?)?.toDouble() ?? 0.0;
    final unit = material['unit']?.toString() ?? 'pcs';

    String txType = 'IN';
    double deltaQty = quantity;
    double newStock = currentStock;

    if (mode == 'IN') {
      txType = 'IN';
      deltaQty = quantity;
      newStock = currentStock + quantity;
    } else if (mode == 'OUT') {
      txType = 'OUT';
      deltaQty = quantity;
      newStock = (currentStock - quantity).clamp(0.0, double.infinity);
    } else if (mode == 'SET') {
      final diff = quantity - currentStock;
      if (diff == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entered balance matches current stock.')),
        );
        return;
      }
      txType = diff > 0 ? 'IN' : 'OUT';
      deltaQty = diff.abs();
      newStock = quantity.clamp(0.0, double.infinity);
    }

    try {
      // 1. Record stock transaction in ledger
      await apiService.createCollectionItem('stock_transactions', {
        'material_id': matId,
        'transaction_type': txType,
        'category': 'RAW_MATERIAL',
        'quantity': deltaQty,
        'batch_lot': batchLot.isNotEmpty ? batchLot : null,
        'reference_type': 'MANUAL',
        'notes': notes.isNotEmpty
            ? notes
            : (mode == 'SET'
                ? 'Stock count balance adjusted to $quantity $unit'
                : 'Stock $mode recorded'),
      });

      // 2. Update material current_stock in materials collection
      await apiService.updateCollectionItem('materials', matId, {
        'current_stock': newStock,
      });

      // 3. Log to activity_history
      await apiService.createCollectionItem('activity_history', {
        'event_type': 'STOCK_MOVEMENT',
        'title': '$txType ${Formatters.formatNumber(deltaQty.toInt())} $unit',
        'description': notes.isNotEmpty ? notes : 'Stock $mode update for ${material['name']}',
        'reference_type': 'stock_transaction',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      ref.invalidate(materialsProvider);
      ref.invalidate(stockTransactionsProvider);
      ref.invalidate(dashboardProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock updated for "${material['name']}". New balance: ${Formatters.formatNumber(newStock.toInt())} $unit'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating stock: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 2. Add / Edit Material Modal (Matches React openCreateMaterial / openEditMaterial)
  void _showAddEditMaterialModal({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    if (isEdit) {
      _matCodeController.text = existing['code']?.toString() ?? '';
      _matNameController.text = existing['name']?.toString() ?? '';
      _matCategoryController.text = existing['category']?.toString() ?? 'RAW_MATERIAL';
      _matUnit = existing['unit']?.toString() ?? 'pcs';
      _matMinStockController.text = (existing['minimum_stock']?.toString() ?? '10');
      _matMaxStockController.text = (existing['maximum_stock']?.toString() ?? '1000');
    } else {
      _matCodeController.text = 'MAT-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      _matNameController.clear();
      _matCategoryController.text = 'RAW_MATERIAL';
      _matOpeningStockController.text = '0';
      _matMinStockController.text = '10';
      _matMaxStockController.text = '1000';
      _matUnit = 'pcs';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(isEdit ? Icons.edit_outlined : Icons.inventory_2_outlined, size: 20, color: const Color(0xFF0284C7)),
                        const SizedBox(width: 8),
                        Text(isEdit ? 'Edit Material Item' : 'New Material Item', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),

                // Code & Unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Code *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _matCodeController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              hintText: 'e.g. MAT-010',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Unit *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: _matUnit,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                              DropdownMenuItem(value: 'kg', child: Text('kg')),
                              DropdownMenuItem(value: 'meter', child: Text('meter')),
                              DropdownMenuItem(value: 'ltr', child: Text('ltr')),
                              DropdownMenuItem(value: 'box', child: Text('box')),
                              DropdownMenuItem(value: 'roll', child: Text('roll')),
                              DropdownMenuItem(value: 'set', child: Text('set')),
                            ],
                            onChanged: (val) {
                              if (val != null) setModalState(() => _matUnit = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Material Name
                const Text('Material Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                TextField(
                  controller: _matNameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Steel Pipe 50mm / Hex Bolt M8',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),

                // Category
                const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                const SizedBox(height: 4),
                TextField(
                  controller: _matCategoryController,
                  decoration: InputDecoration(
                    hintText: 'e.g. RAW_MATERIAL, FASTENER, CHEMICAL, PACKAGING',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),

                if (!isEdit) ...[
                  const Text('Initial Stock Balance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _matOpeningStockController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Min & Max Stock Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Min Stock (Alert)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _matMinStockController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '10',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Max Stock Cap', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _matMaxStockController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '1000',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    const SizedBox(width: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final code = _matCodeController.text.trim().toUpperCase();
                        final name = _matNameController.text.trim();
                        if (code.isEmpty || name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter both item code and material name.')),
                          );
                          return;
                        }

                        final min = double.tryParse(_matMinStockController.text) ?? 10.0;
                        final max = double.tryParse(_matMaxStockController.text) ?? 1000.0;
                        final opening = double.tryParse(_matOpeningStockController.text) ?? 0.0;
                        final cat = _matCategoryController.text.trim().isNotEmpty
                            ? _matCategoryController.text.trim()
                            : 'RAW_MATERIAL';

                        Navigator.pop(ctx);
                        final apiService = ref.read(apiServiceProvider);

                        try {
                          if (isEdit) {
                            final id = (existing['id'] ?? existing['_id'])?.toString() ?? '';
                            await apiService.updateCollectionItem('materials', id, {
                              'code': code,
                              'name': name,
                              'category': cat,
                              'unit': _matUnit,
                              'minimum_stock': min,
                              'maximum_stock': max,
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Updated "$name".'), backgroundColor: const Color(0xFF16A34A)),
                            );
                          } else {
                            final res = await apiService.createCollectionItem('materials', {
                              'code': code,
                              'name': name,
                              'category': cat,
                              'unit': _matUnit,
                              'current_stock': opening,
                              'minimum_stock': min,
                              'maximum_stock': max,
                            });
                            if (opening > 0) {
                              final newId = res['id'] ?? res['_id'];
                              await apiService.createCollectionItem('stock_transactions', {
                                'material_id': newId,
                                'transaction_type': 'IN',
                                'category': 'RAW_MATERIAL',
                                'quantity': opening,
                                'notes': 'Initial opening stock intake',
                              });
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Created material "$name".'), backgroundColor: const Color(0xFF16A34A)),
                            );
                          }
                          ref.invalidate(materialsProvider);
                          ref.invalidate(stockTransactionsProvider);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: Text(isEdit ? 'Save Changes' : 'Create Item', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 3. Delete Material Confirmation
  void _confirmDeleteMaterial(Map<String, dynamic> item) {
    final id = (item['id'] ?? item['_id'])?.toString() ?? '';
    final name = item['name']?.toString() ?? 'Material';
    final code = item['code']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Material', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to delete "$name" ($code)?\n\nThis will remove the item from inventory. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final apiService = ref.read(apiServiceProvider);
                await apiService.deleteCollectionItem('materials', id);
                ref.invalidate(materialsProvider);
                ref.invalidate(stockTransactionsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted "$name".')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not delete: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // 4. Material Detail Modal (Matches React MaterialDetailScreen.tsx)
  void _showMaterialDetailModal(Map<String, dynamic> item) {
    final current = (item['current_stock'] as num?)?.toDouble() ?? 0.0;
    final min = (item['minimum_stock'] as num?)?.toDouble() ?? 0.0;
    final max = (item['maximum_stock'] as num?)?.toDouble() ?? 0.0;
    final unit = item['unit']?.toString() ?? 'pcs';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
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
                    Text(item['code']?.toString() ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                    Text(item['name']?.toString() ?? 'Material', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0A1E38))),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('Current Stock', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text('${Formatters.formatNumber(current.toInt())} $unit', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0284C7))),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Min Required', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text('${Formatters.formatNumber(min.toInt())} $unit', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Max Capacity', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      Text('${Formatters.formatNumber(max.toInt())} $unit', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddEditMaterialModal(existing: item);
                    },
                    child: const Text('Edit Material'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showUpdateStockModal(preselectedMaterialId: (item['id'] ?? item['_id'])?.toString());
                    },
                    child: const Text('Update Stock'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}