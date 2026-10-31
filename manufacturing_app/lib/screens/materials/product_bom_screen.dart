import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../widgets/shimmers/index.dart';
import '../../utils/formatters.dart';

class ProductBomScreen extends ConsumerStatefulWidget {
  final String? initialProductId;

  const ProductBomScreen({super.key, this.initialProductId});

  @override
  ConsumerState<ProductBomScreen> createState() => _ProductBomScreenState();
}

class _ProductBomScreenState extends ConsumerState<ProductBomScreen> {
  String? _selectedProductId;
  String _searchQuery = '';

  final _bomQtyController = TextEditingController(text: '1.0');
  String _bomUnit = 'pcs';
  String? _bomSelectedMaterialId;

  @override
  void initState() {
    super.initState();
    _selectedProductId = widget.initialProductId;
  }

  @override
  void dispose() {
    _bomQtyController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(bomItemsProvider);
    ref.invalidate(bomProvider);
    ref.invalidate(productsProvider);
    ref.invalidate(materialsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsAsync = ref.watch(productsProvider(const {'limit': 100}));
    final bomItemsAsync = ref.watch(bomItemsProvider(const {'limit': 200}));
    final materialsAsync = ref.watch(materialsProvider(const {'limit': 200}));

    final allProducts = productsAsync.valueOrNull?.data ?? [];
    final allBomItems = bomItemsAsync.valueOrNull?.data ?? [];
    final allMaterials = materialsAsync.valueOrNull?.data ?? [];

    // Ensure selected product is valid
    if (_selectedProductId == null && allProducts.isNotEmpty) {
      _selectedProductId = (allProducts.first['id'] ?? allProducts.first['_id'])?.toString();
    }

    final productsWithBom = allProducts.where((p) {
      final pId = (p['id'] ?? p['_id'])?.toString();
      return allBomItems.any((bi) => (bi['product_id'] ?? bi['bom_id'])?.toString() == pId);
    }).length;

    final inStockMaterials = allMaterials.where((m) {
      final cur = (m['current_stock'] as num?)?.toDouble() ?? 0.0;
      return cur > 0;
    }).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1E38),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: 'Back to Management',
          onPressed: () => context.canPop() ? context.pop() : context.go('/management'),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bill of Materials (BOM)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white),
            ),
            Text(
              'Formulas, raw component ratios & unit recipes',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => _showAddBomItemModal(),
            icon: const Icon(Icons.add_link, size: 16),
            label: const Text('Add Component', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: (productsAsync.isLoading && !productsAsync.hasValue)
          ? const ProductBomShimmer()
          : RefreshIndicator(
              onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // Top 4 KPI Metrics Bar
            _buildKpiSummaryBar(
              productsCount: allProducts.length,
              productsWithBom: productsWithBom,
              totalBomItems: allBomItems.length,
              inStockMaterials: inStockMaterials,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // Formula Guidance Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 20, color: Color(0xFF0284C7)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Formula Standard: Raw Material Per 1 Unit Output',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0369A1)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Quantities listed represent the exact raw material needed to manufacture 1 unit of the finished good. In production orders, materials scale automatically by order quantity.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF0C4A6E), height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Products & BOM Content
            if (allProducts.isEmpty)
              _buildNoProductsState(isDark)
            else
              _buildBomContent(allProducts, allBomItems, allMaterials, isDark),

            const SizedBox(height: 60),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        onPressed: () => _showAddBomItemModal(),
        icon: const Icon(Icons.add_link),
        label: const Text('Add Component', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  // 1. Top KPI Summary Bar
  Widget _buildKpiSummaryBar({
    required int productsCount,
    required int productsWithBom,
    required int totalBomItems,
    required int inStockMaterials,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildKpiItem('CONFIGURED', '$productsWithBom / $productsCount', const Color(0xFF0284C7)),
          _buildDivider(isDark),
          _buildKpiItem('TOTAL LINES', totalBomItems.toString(), const Color(0xFF7B1FA2)),
          _buildDivider(isDark),
          _buildKpiItem('BASE OUTPUT', '1 Unit', const Color(0xFF16A34A)),
          _buildDivider(isDark),
          _buildKpiItem('IN-STOCK MATS', inStockMaterials.toString(), const Color(0xFFEA580C)),
        ],
      ),
    );
  }

  Widget _buildKpiItem(String title, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 30,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }

  // 2. Main BOM Content with Quick Pick Chips & Focused Product Card
  Widget _buildBomContent(
    List<Map<String, dynamic>> products,
    List<Map<String, dynamic>> allBomItems,
    List<Map<String, dynamic>> allMaterials,
    bool isDark,
  ) {
    final activeProduct = products.firstWhere(
      (p) => (p['id'] ?? p['_id'])?.toString() == _selectedProductId,
      orElse: () => products.first,
    );
    final activePId = (activeProduct['id'] ?? activeProduct['_id'])?.toString() ?? '';

    // Filter BOM items for active product
    final activeBomItems = allBomItems.where((bi) {
      final relId = (bi['product_id'] ?? bi['bom_id'])?.toString();
      return relId == activePId;
    }).toList();

    // Material Map for rapid lookup
    final matMap = {
      for (var m in allMaterials) (m['id'] ?? m['_id'])?.toString(): m
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Pick Section Header
        const Text(
          'SELECT FINISHED PRODUCT',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.6),
        ),
        const SizedBox(height: 8),

        // Product Horizontal Selector Chips
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final p = products[index];
              final pId = (p['id'] ?? p['_id'])?.toString() ?? '';
              final isSel = pId == _selectedProductId;

              return ChoiceChip(
                label: Text(
                  '${p['code']} • ${p['name']}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF1E293B)),
                  ),
                ),
                selected: isSel,
                selectedColor: const Color(0xFF0284C7),
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                side: BorderSide(color: isSel ? const Color(0xFF0284C7) : const Color(0xFFCBD5E1)),
                onSelected: (val) {
                  if (val) setState(() => _selectedProductId = pId);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Focused Product BOM Recipe Card
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0284C7).withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.hub_outlined, color: Color(0xFF0284C7), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              activeProduct['code']?.toString() ?? 'PRD',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Per 1 ${activeProduct['unit'] ?? 'unit'} output',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeProduct['name']?.toString() ?? 'Product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0A1E38),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _showAddBomItemModal(preselectedProductId: activePId),
                    icon: const Icon(Icons.add, size: 15),
                    label: const Text('Add Component', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const Divider(height: 24),

              // BOM Components List
              if (activeBomItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 8),
                      const Text(
                        'No materials mapped to this recipe yet',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF0284C7))),
                        onPressed: () => _showAddBomItemModal(preselectedProductId: activePId),
                        icon: const Icon(Icons.add_link, size: 16, color: Color(0xFF0284C7)),
                        label: const Text('Add First Material', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text('RAW MATERIAL / COMPONENT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text('QTY / 1 UNIT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B))),
                      ),
                      SizedBox(width: 40),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                ...activeBomItems.map((bi) {
                  final biId = (bi['id'] ?? bi['_id'])?.toString() ?? '';
                  final matId = bi['material_id']?.toString() ?? '';
                  final mat = matMap[matId];
                  final matName = mat?['name']?.toString() ?? bi['material_name']?.toString() ?? 'Raw Material';
                  final matCode = mat?['code']?.toString() ?? bi['material_code']?.toString() ?? matId;
                  final qty = (bi['quantity'] as num?)?.toDouble() ?? 1.0;
                  final unit = bi['unit']?.toString() ?? mat?['unit']?.toString() ?? 'pcs';
                  final currentStock = (mat?['current_stock'] as num?)?.toDouble() ?? 0.0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                matName,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              Row(
                                children: [
                                  Text(
                                    matCode,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '• Stock: ${Formatters.formatNumber(currentStock.toInt())} $unit',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: currentStock > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${qty.toStringAsFixed(qty.truncateToDouble() == qty ? 0 : 3)} $unit',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0284C7),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                          tooltip: 'Remove from recipe',
                          onPressed: () => _deleteBomItem(biId),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Search for All Recipes
        const Text(
          'ALL PRODUCTS BOM DIRECTORY',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.6),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search recipe by product or material name…',
            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
            isDense: true,
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
          ),
          onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 10),

        // All Products Recipes Cards
        ...products.where((p) {
          if (_searchQuery.isEmpty) return true;
          final pName = (p['name']?.toString() ?? '').toLowerCase();
          final pCode = (p['code']?.toString() ?? '').toLowerCase();
          return pName.contains(_searchQuery) || pCode.contains(_searchQuery);
        }).map((p) {
          final pId = (p['id'] ?? p['_id'])?.toString() ?? '';
          final pItems = allBomItems.where((bi) {
            final relId = (bi['product_id'] ?? bi['bom_id'])?.toString();
            return relId == pId;
          }).toList();

          return Container(
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
                            p['code']?.toString() ?? 'PRD',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: pItems.isNotEmpty ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              pItems.isNotEmpty ? '${pItems.length} Materials Linked' : 'No BOM Defined',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: pItems.isNotEmpty ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p['name']?.toString() ?? 'Product',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0284C7)),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () => setState(() => _selectedProductId = pId),
                  child: const Text('Select', style: TextStyle(fontSize: 12, color: Color(0xFF0284C7))),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // 3. Empty State if no products exist
  Widget _buildNoProductsState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hub_outlined, size: 42, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text(
            'No Products in Catalog',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Define products in the Product Catalog first to configure their Bill of Materials recipe.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () => context.push('/inventory/products'),
            icon: const Icon(Icons.category_outlined, size: 16),
            label: const Text('Open Products Catalog'),
          ),
        ],
      ),
    );
  }

  // 4. Add BOM Item Modal
  void _showAddBomItemModal({String? preselectedProductId}) {
    final products = ref.read(productsProvider(const {'limit': 100})).valueOrNull?.data ?? [];
    final materials = ref.read(materialsProvider(const {'limit': 100})).valueOrNull?.data ?? [];

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product before configuring BOM recipes.')),
      );
      return;
    }

    if (materials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one raw material before configuring BOM recipes.')),
      );
      return;
    }

    String chosenProductId = preselectedProductId ??
        _selectedProductId ??
        (products.first['id'] ?? products.first['_id'])?.toString() ??
        '';

    if (!products.any((p) => (p['id'] ?? p['_id'])?.toString() == chosenProductId)) {
      chosenProductId = (products.first['id'] ?? products.first['_id'])?.toString() ?? '';
    }

    String chosenMaterialId = _bomSelectedMaterialId ?? (materials.first['id'] ?? materials.first['_id'])?.toString() ?? '';
    if (!materials.any((m) => (m['id'] ?? m['_id'])?.toString() == chosenMaterialId)) {
      chosenMaterialId = (materials.first['id'] ?? materials.first['_id'])?.toString() ?? '';
    }

    final initialMat = materials.firstWhere(
      (m) => (m['id'] ?? m['_id'])?.toString() == chosenMaterialId,
      orElse: () => materials.first,
    );
    _bomUnit = initialMat['unit']?.toString() ?? 'pcs';
    _bomQtyController.text = '1.0';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final selMat = materials.firstWhere(
            (m) => (m['id'] ?? m['_id'])?.toString() == chosenMaterialId,
            orElse: () => materials.first,
          );
          final currentStock = (selMat['current_stock'] as num?)?.toDouble() ?? 0.0;

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
                          Icon(Icons.hub_outlined, size: 20, color: Color(0xFF0284C7)),
                          SizedBox(width: 8),
                          Text('Add Component to BOM Recipe', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Product Selector
                  const Text('Finished Product *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: chosenProductId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    items: products.map((p) {
                      final id = (p['id'] ?? p['_id'])?.toString() ?? '';
                      return DropdownMenuItem(
                        value: id,
                        child: Text('${p['code']} - ${p['name']} (${p['unit'] ?? 'pcs'})', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setModalState(() => chosenProductId = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Material Selector
                  const Text('Raw Material / Component *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    initialValue: chosenMaterialId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    ),
                    items: materials.map((m) {
                      final id = (m['id'] ?? m['_id'])?.toString() ?? '';
                      final stock = (m['current_stock'] as num?)?.toDouble() ?? 0.0;
                      return DropdownMenuItem(
                        value: id,
                        child: Text(
                          '${m['code']} - ${m['name']} (${stock.toInt()} ${m['unit']} available)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          chosenMaterialId = val;
                          final m = materials.firstWhere((item) => (item['id'] ?? item['_id'])?.toString() == val);
                          _bomUnit = m['unit']?.toString() ?? 'pcs';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Quantity per 1 unit & Unit
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quantity Per 1 Unit Output *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _bomQtyController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: 'e.g. 2.5',
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
                              initialValue: _bomUnit,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                                DropdownMenuItem(value: 'kg', child: Text('kg')),
                                DropdownMenuItem(value: 'meter', child: Text('meter')),
                                DropdownMenuItem(value: 'ltr', child: Text('ltr')),
                                DropdownMenuItem(value: 'box', child: Text('box')),
                                DropdownMenuItem(value: 'set', child: Text('set')),
                              ],
                              onChanged: (val) {
                                if (val != null) setModalState(() => _bomUnit = val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stock Summary Insight
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
                        Text('Current Warehouse Stock: ${Formatters.formatNumber(currentStock.toInt())} $_bomUnit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                        const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF16A34A)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                        onPressed: () async {
                          final qty = double.tryParse(_bomQtyController.text) ?? 1.0;
                          if (qty <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a valid quantity greater than 0.')),
                            );
                            return;
                          }

                          Navigator.pop(ctx);
                          try {
                            final apiService = ref.read(apiServiceProvider);
                            final targetProd = products.firstWhere((p) => (p['id'] ?? p['_id'])?.toString() == chosenProductId);
                            final targetMat = materials.firstWhere((m) => (m['id'] ?? m['_id'])?.toString() == chosenMaterialId);

                            await apiService.createCollectionItem('bom_items', {
                              'product_id': chosenProductId,
                              'bom_id': chosenProductId,
                              'material_id': chosenMaterialId,
                              'material_code': targetMat['code'],
                              'material_name': targetMat['name'],
                              'quantity': qty,
                              'unit': _bomUnit,
                              'created_at': DateTime.now().millisecondsSinceEpoch,
                            });

                            // Ensure active BOM record exists
                            final existingBoms = await apiService.getCollection('bom', queryParams: {'product_id': chosenProductId, 'limit': 1});
                            if (existingBoms.data.isEmpty) {
                              await apiService.createCollectionItem('bom', {
                                'product_id': chosenProductId,
                                'version': '1.0',
                                'is_active': 1,
                                'created_at': DateTime.now().millisecondsSinceEpoch,
                              });
                            }

                            // Log to activity_history
                            await apiService.createCollectionItem('activity_history', {
                              'event_type': 'BOM_UPDATE',
                              'title': 'BOM component added for ${targetProd['name']}',
                              'description': 'Added $qty $_bomUnit of ${targetMat['name']} to 1 unit output formula',
                              'reference_type': 'bom_items',
                              'timestamp': DateTime.now().millisecondsSinceEpoch,
                            });

                            ref.invalidate(bomItemsProvider);
                            ref.invalidate(bomProvider);

                            if (mounted) {
                              setState(() => _selectedProductId = chosenProductId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added "${targetMat['name']}" ($qty $_bomUnit) to BOM recipe.'),
                                  backgroundColor: const Color(0xFF16A34A),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error adding to BOM: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.add_link, size: 16),
                        label: const Text('Add Component', style: TextStyle(fontWeight: FontWeight.w700)),
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

  // 5. Delete BOM Item
  void _deleteBomItem(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from BOM Recipe', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to remove this raw material component from the product formula?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final apiService = ref.read(apiServiceProvider);
                await apiService.deleteCollectionItem('bom_items', id);
                ref.invalidate(bomItemsProvider);
                ref.invalidate(bomProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Removed material from BOM recipe.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not remove BOM item: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
