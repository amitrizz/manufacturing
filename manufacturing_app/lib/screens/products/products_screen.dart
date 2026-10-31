import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../widgets/shimmers/index.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _searchQuery = '';
  String _unitFilter = 'all';

  final _prodCodeController = TextEditingController();
  final _prodNameController = TextEditingController();
  final _prodDescController = TextEditingController();
  String _prodUnit = 'pcs';

  @override
  void dispose() {
    _prodCodeController.dispose();
    _prodNameController.dispose();
    _prodDescController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(productsProvider);
    ref.invalidate(bomItemsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsAsync = ref.watch(productsProvider(const {'limit': 100}));
    final bomItemsAsync = ref.watch(bomItemsProvider(const {'limit': 200}));

    final allProducts = productsAsync.valueOrNull?.data ?? [];
    final allBomItems = bomItemsAsync.valueOrNull?.data ?? [];

    // Calculate quick stats
    final totalProducts = allProducts.length;
    final uniqueUnits = allProducts.map((p) => p['unit']?.toString() ?? 'pcs').toSet().length;
    final productsWithBom = allProducts.where((p) {
      final pId = (p['id'] ?? p['_id'])?.toString();
      return allBomItems.any((bi) => (bi['product_id'] ?? bi['bom_id'])?.toString() == pId);
    }).length;
    final bomCoveragePct = totalProducts > 0 ? ((productsWithBom / totalProducts) * 100).toInt() : 0;

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
              'Products Master Catalog',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white),
            ),
            Text(
              'Finished goods, models & specifications',
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
              backgroundColor: const Color(0xFF7B1FA2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => _showAddEditProductModal(),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Product', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // Top 4 KPI Metrics Bar
            _buildKpiSummaryBar(
              totalProducts: totalProducts,
              uniqueUnits: uniqueUnits,
              productsWithBom: productsWithBom,
              bomCoveragePct: bomCoveragePct,
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            // Search and Unit Filters
            _buildSearchAndFilterBar(isDark),
            const SizedBox(height: 12),

            // Products Catalog Content
            productsAsync.when(
              data: (paginated) {
                var items = paginated.data;

                // Search Filter
                if (_searchQuery.isNotEmpty) {
                  items = items.where((p) {
                    final name = (p['name']?.toString() ?? '').toLowerCase();
                    final code = (p['code']?.toString() ?? '').toLowerCase();
                    final desc = (p['description']?.toString() ?? '').toLowerCase();
                    return name.contains(_searchQuery) || code.contains(_searchQuery) || desc.contains(_searchQuery);
                  }).toList();
                }

                // Unit Filter
                if (_unitFilter != 'all') {
                  items = items.where((p) {
                    final u = (p['unit']?.toString() ?? 'pcs').toLowerCase();
                    return u == _unitFilter.toLowerCase();
                  }).toList();
                }

                if (items.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                      child: Text(
                        'CATALOG ITEMS (${items.length} ${items.length == 1 ? 'PRODUCT' : 'PRODUCTS'})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...items.map((p) => _buildProductCard(p, allBomItems, isDark)),
                  ],
                );
              },
              loading: () => AppShimmer(
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
                            Row(
                              children: [
                                ShimmerBox(width: 80, height: 16, borderRadius: 4),
                                SizedBox(width: 8),
                                ShimmerBox(width: 70, height: 16, borderRadius: 12),
                              ],
                            ),
                            ShimmerBox(width: 24, height: 24, borderRadius: 12),
                          ],
                        ),
                        SizedBox(height: 8),
                        ShimmerBox(width: 210, height: 17, borderRadius: 5),
                        SizedBox(height: 6),
                        ShimmerBox(width: 160, height: 12, borderRadius: 4),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerBox(width: 90, height: 14, borderRadius: 4),
                            ShimmerBox(width: 115, height: 32, borderRadius: 8),
                          ],
                        ),
                      ],
                    ),
                  )),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Text('Error loading products: $e', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF7B1FA2),
        foregroundColor: Colors.white,
        onPressed: () => _showAddEditProductModal(),
        icon: const Icon(Icons.add),
        label: const Text('New Product', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  // 1. Top 4 KPI Metrics Bar
  Widget _buildKpiSummaryBar({
    required int totalProducts,
    required int uniqueUnits,
    required int productsWithBom,
    required int bomCoveragePct,
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
          _buildKpiItem('TOTAL SKUS', totalProducts.toString(), const Color(0xFF7B1FA2)),
          _buildDivider(isDark),
          _buildKpiItem('ACTIVE UNITS', uniqueUnits.toString(), const Color(0xFF0284C7)),
          _buildDivider(isDark),
          _buildKpiItem('ON BOM', productsWithBom.toString(), const Color(0xFF16A34A)),
          _buildDivider(isDark),
          _buildKpiItem('BOM COVERAGE', '$bomCoveragePct%', const Color(0xFFEA580C)),
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
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color),
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

  // 2. Search and Filter Bar
  Widget _buildSearchAndFilterBar(bool isDark) {
    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search products by code, name or description…',
            prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All Units', 'all'),
              const SizedBox(width: 6),
              _buildFilterChip('Pieces (pcs)', 'pcs'),
              const SizedBox(width: 6),
              _buildFilterChip('Sets / Assemblies', 'set'),
              const SizedBox(width: 6),
              _buildFilterChip('Box', 'box'),
              const SizedBox(width: 6),
              _buildFilterChip('Unit', 'unit'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _unitFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF7B1FA2),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? const Color(0xFF7B1FA2) : const Color(0xFFCBD5E1)),
      onSelected: (val) {
        if (val) setState(() => _unitFilter = value);
      },
    );
  }

  // 3. Product Card
  Widget _buildProductCard(Map<String, dynamic> p, List<Map<String, dynamic>> allBomItems, bool isDark) {
    final pId = (p['id'] ?? p['_id'])?.toString() ?? '';
    final code = p['code']?.toString() ?? 'PRD';
    final name = p['name']?.toString() ?? 'Product';
    final unit = p['unit']?.toString() ?? 'pcs';
    final desc = p['description']?.toString() ?? '';

    // Check BOM items linked to this product
    final linkedBomItems = allBomItems.where((bi) {
      final relId = (bi['product_id'] ?? bi['bom_id'])?.toString();
      return relId == pId;
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.category_outlined, size: 22, color: Color(0xFF7B1FA2)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E5F5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              code,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF7B1FA2)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Unit: $unit',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: linkedBomItems.isNotEmpty ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  linkedBomItems.isNotEmpty ? Icons.check_circle : Icons.warning_amber_rounded,
                                  size: 12,
                                  color: linkedBomItems.isNotEmpty ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  linkedBomItems.isNotEmpty ? '${linkedBomItems.length} BOM Items' : 'No BOM',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: linkedBomItems.isNotEmpty ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0A1E38),
                        ),
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          desc,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  onPressed: () => _showAddEditProductModal(existing: p),
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
                InkWell(
                  onTap: () {
                    context.push('/inventory/bom?productId=$pId');
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.hub_outlined, size: 14, color: Color(0xFF0284C7)),
                        SizedBox(width: 5),
                        Text(
                          'View BOM Recipe →',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFDC2626)),
                  tooltip: 'Delete product',
                  onPressed: () => _confirmDeleteProduct(p),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 4. Empty State
  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Color(0xFFF3E5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.category_outlined, size: 38, color: Color(0xFF7B1FA2)),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Products in Catalog',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your finished goods models or seed standard industrial products to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
                onPressed: () => _showAddEditProductModal(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Product'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF7B1FA2))),
                onPressed: () => _seedDefaultProducts(),
                icon: const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF7B1FA2)),
                label: const Text('Seed Sample Catalog', style: TextStyle(color: Color(0xFF7B1FA2))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Add / Edit Product Modal
  void _showAddEditProductModal({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    if (isEdit) {
      _prodCodeController.text = existing['code']?.toString() ?? '';
      _prodNameController.text = existing['name']?.toString() ?? '';
      _prodDescController.text = existing['description']?.toString() ?? '';
      _prodUnit = existing['unit']?.toString() ?? 'pcs';
    } else {
      _prodCodeController.text = 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
      _prodNameController.clear();
      _prodDescController.clear();
      _prodUnit = 'pcs';
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
                  Row(
                    children: [
                      Icon(isEdit ? Icons.edit_outlined : Icons.add_box_outlined, size: 20, color: const Color(0xFF7B1FA2)),
                      const SizedBox(width: 8),
                      Text(isEdit ? 'Edit Product Item' : 'New Product Item', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _prodCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Product Code *',
                        hintText: 'e.g. PRD-101',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _prodUnit,
                      decoration: InputDecoration(
                        labelText: 'Unit *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                        DropdownMenuItem(value: 'set', child: Text('set')),
                        DropdownMenuItem(value: 'box', child: Text('box')),
                        DropdownMenuItem(value: 'unit', child: Text('unit')),
                        DropdownMenuItem(value: 'meter', child: Text('meter')),
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => _prodUnit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _prodNameController,
                decoration: InputDecoration(
                  labelText: 'Product Name *',
                  hintText: 'e.g. High Pressure Hydraulic Valve Block',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _prodDescController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description & Technical Specs',
                  hintText: 'Material, dimensions, pressure rating, application...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                  const SizedBox(width: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7B1FA2)),
                    onPressed: () async {
                      final code = _prodCodeController.text.trim().toUpperCase();
                      final name = _prodNameController.text.trim();
                      if (code.isEmpty || name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product code and name are required.')),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      try {
                        final apiService = ref.read(apiServiceProvider);
                        if (isEdit) {
                          final id = (existing['id'] ?? existing['_id'])?.toString() ?? '';
                          await apiService.updateCollectionItem('products', id, {
                            'code': code,
                            'name': name,
                            'unit': _prodUnit,
                            'description': _prodDescController.text.trim(),
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Updated product "$name".'), backgroundColor: const Color(0xFF16A34A)),
                            );
                          }
                        } else {
                          await apiService.createCollectionItem('products', {
                            'code': code,
                            'name': name,
                            'unit': _prodUnit,
                            'description': _prodDescController.text.trim(),
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Created product "$name".'), backgroundColor: const Color(0xFF16A34A)),
                            );
                          }
                        }
                        ref.invalidate(productsProvider);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    child: Text(isEdit ? 'Save Changes' : 'Create Product', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 6. Delete Product Confirmation
  void _confirmDeleteProduct(Map<String, dynamic> product) {
    final id = (product['id'] ?? product['_id'])?.toString() ?? '';
    final name = product['name']?.toString() ?? 'Product';
    final code = product['code']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to delete "$name" ($code)?\n\nThis will remove the product from the catalog.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final apiService = ref.read(apiServiceProvider);
                await apiService.deleteCollectionItem('products', id);
                ref.invalidate(productsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted product "$name".')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not delete product: $e'), backgroundColor: Colors.red),
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

  // 7. Seed Sample Products
  Future<void> _seedDefaultProducts() async {
    final apiService = ref.read(apiServiceProvider);
    try {
      await apiService.createCollectionItem('products', {
        'code': 'PRD-101',
        'name': 'Hydraulic Valve Block',
        'unit': 'pcs',
        'description': 'High-pressure precision hydraulic valve block for fluid power systems',
      });
      await apiService.createCollectionItem('products', {
        'code': 'PRD-102',
        'name': 'Centrifugal Pump Impeller',
        'unit': 'pcs',
        'description': 'Cast alloy impeller for multi-stage industrial water pumps',
      });
      await apiService.createCollectionItem('products', {
        'code': 'PRD-103',
        'name': 'Gearbox Housing DN80',
        'unit': 'set',
        'description': 'Ductile iron industrial reduction gearbox casing assembly',
      });
      await apiService.createCollectionItem('products', {
        'code': 'PRD-104',
        'name': 'Flange Adapter DN50',
        'unit': 'pcs',
        'description': 'PN16 carbon steel piping adapter flange with counterbores',
      });

      ref.invalidate(productsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sample industrial products seeded successfully!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error seeding products: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
