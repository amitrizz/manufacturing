import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

class ProductionPlansScreen extends ConsumerStatefulWidget {
  const ProductionPlansScreen({super.key});

  @override
  ConsumerState<ProductionPlansScreen> createState() => _ProductionPlansScreenState();
}

class _ProductionPlansScreenState extends ConsumerState<ProductionPlansScreen> {
  String _planSearch = '';
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final plansAsync = ref.watch(productionPlansProvider(const {'limit': 100}));

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
          'Production Plans & Targets',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Plans',
            onPressed: () => ref.invalidate(productionPlansProvider),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(productionPlansProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // Top 4 KPI Metrics
            plansAsync.when(
              data: (paginated) => _buildKpiBar(paginated.data, isDark),
              loading: () => const ShimmerKpiRow(padding: EdgeInsets.zero),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),

            // Search Bar & Action Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search plans by number, product, or line…',
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
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
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                  onPressed: () => _showCreatePlanDialog(),
                  icon: const Icon(Icons.add_chart_rounded, size: 18),
                  label: const Text('+ New Plan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All Plans', _statusFilter == null, () {
                    setState(() => _statusFilter = null);
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Active', _statusFilter == 'ACTIVE', () {
                    setState(() => _statusFilter = _statusFilter == 'ACTIVE' ? null : 'ACTIVE');
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Planned', _statusFilter == 'PLANNED', () {
                    setState(() => _statusFilter = _statusFilter == 'PLANNED' ? null : 'PLANNED');
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Completed', _statusFilter == 'COMPLETED', () {
                    setState(() => _statusFilter = _statusFilter == 'COMPLETED' ? null : 'COMPLETED');
                  }),
                ],
              ),
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

                if (_statusFilter != null) {
                  plans = plans.where((p) {
                    final st = (p['status'] ?? 'PLANNED').toString().toUpperCase();
                    return st == _statusFilter;
                  }).toList();
                }

                if (plans.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0FDFA),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.calendar_month_outlined, size: 40, color: Color(0xFF0D9488)),
                        ),
                        const SizedBox(height: 16),
                        const Text('No production plans found', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text(
                          'Configure monthly production schedules, volume targets and shift allocations.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                          onPressed: () => _showCreatePlanDialog(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Create Production Plan'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: plans.map((plan) {
                    return _buildPlanCard(plan, isDark);
                  }).toList(),
                );
              },
              loading: () => AppShimmer(
                child: Column(
                  children: List.generate(3, (_) => Container(
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
                            ShimmerBox(width: 120, height: 16, borderRadius: 6),
                            ShimmerBox(width: 60, height: 18, borderRadius: 6),
                          ],
                        ),
                        SizedBox(height: 10),
                        ShimmerBox(width: 200, height: 18, borderRadius: 5),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerBox(width: 110, height: 14, borderRadius: 4),
                            ShimmerBox(width: 90, height: 14, borderRadius: 4),
                          ],
                        ),
                        SizedBox(height: 12),
                        ShimmerBox(width: double.infinity, height: 36, borderRadius: 8),
                      ],
                    ),
                  )),
                ),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 40, color: Colors.red),
                      const SizedBox(height: 8),
                      Text('Error loading plans: $error'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(productionPlansProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0D9488),
        foregroundColor: Colors.white,
        onPressed: () => _showCreatePlanDialog(),
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text('New Plan', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  // Top 4 KPI Metrics Bar
  Widget _buildKpiBar(List<Map<String, dynamic>> plans, bool isDark) {
    final total = plans.length;
    final totalTarget = plans.fold<num>(0, (sum, p) => sum + ((p['target_quantity'] ?? p['planned_quantity'] ?? 0) as num)).toInt();
    final uniqueLines = plans.map((p) => p['line_id']?.toString() ?? p['line_code']?.toString()).where((id) => id != null && id.isNotEmpty).toSet().length;
    final completed = plans.where((p) => (p['status'] ?? '').toString().toUpperCase() == 'COMPLETED').length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildKpiItem('ACTIVE PLANS', '$total', const Color(0xFF0D9488)),
          _buildDivider(isDark),
          _buildKpiItem('TARGET UNITS', Formatters.formatNumber(totalTarget), const Color(0xFF0284C7)),
          _buildDivider(isDark),
          _buildKpiItem('LINES SCHEDULED', '$uniqueLines Lines', const Color(0xFF7C3AED)),
          _buildDivider(isDark),
          _buildKpiItem('COMPLETED', '$completed', const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _buildKpiItem(String title, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.3),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 26,
      width: 1,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF0D9488) : const Color(0xFFE2E8F0)),
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

  // Plan Card Widget
  Widget _buildPlanCard(Map<String, dynamic> plan, bool isDark) {
    final planNumber = plan['plan_number'] ?? plan['planNumber'] ?? 'PLN-001';
    final productCode = plan['product_code'] ?? plan['productCode'] ?? 'PRD';
    final productName = plan['product_name'] ?? plan['productName'] ?? 'Product';
    final lineCode = plan['line_code'] ?? plan['lineCode'] ?? 'Line 1';
    final status = (plan['status'] ?? 'PLANNED').toString().toUpperCase();
    final priority = (plan['priority'] ?? 'MEDIUM').toString().toUpperCase();
    final targetQty = ((plan['target_quantity'] ?? plan['planned_quantity'] ?? 0) as num).toInt();
    final notes = plan['notes']?.toString();

    Color statusColor;
    switch (status) {
      case 'COMPLETED':
        statusColor = const Color(0xFF16A34A);
        break;
      case 'IN_PROGRESS':
        statusColor = const Color(0xFF0284C7);
        break;
      default:
        statusColor = const Color(0xFFD97706);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
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
            // Top Row: Plan Number & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF99F6E4)),
                  ),
                  child: Text(
                    planNumber,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0D9488)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Product & Line details
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '$productCode · Line $lineCode',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 8),
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
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('TARGET', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                      Text(
                        '${Formatters.formatNumber(targetQty)} pcs',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0D9488)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                notes,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),

            // Action Button: Create Order from Plan
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE0F2FE),
                    foregroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () => _createOrderFromPlan(plan),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                  label: const Text('Create Work Order from Plan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Create Order from Plan Modal
  void _createOrderFromPlan(Map<String, dynamic> plan) {
    final orderNumController = TextEditingController(
      text: 'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    final qtyController = TextEditingController(
      text: (plan['target_quantity'] ?? plan['planned_quantity'] ?? 100).toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Launch Order for ${plan['plan_number'] ?? 'Plan'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${plan['product_code'] ?? ''} - ${plan['product_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Text('Target Line: Line ${plan['line_code'] ?? '1'}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: orderNumController,
              decoration: const InputDecoration(labelText: 'Order Number', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qtyController,
              decoration: const InputDecoration(labelText: 'Batch Target Qty (pcs)', border: OutlineInputBorder(), isDense: true),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
            onPressed: () async {
              final num = orderNumController.text.trim();
              final target = double.tryParse(qtyController.text) ?? 100;
              Navigator.pop(ctx);

              try {
                final api = ref.read(apiServiceProvider);
                final planId = (plan['id'] ?? plan['_id'])?.toString();

                await api.createCollectionItem('production_orders', {
                  'order_number': num,
                  'product_id': plan['product_id'],
                  'product_code': plan['product_code'],
                  'product_name': plan['product_name'],
                  'line_id': plan['line_id'],
                  'line_code': plan['line_code'],
                  'target_quantity': target,
                  'produced_quantity': 0,
                  'rejected_quantity': 0,
                  'status': 'PENDING',
                  'priority': plan['priority'] ?? 'MEDIUM',
                  'production_plan_id': planId,
                  'created_at': DateTime.now().millisecondsSinceEpoch,
                });

                ref.invalidate(productionOrdersProvider);
                ref.invalidate(dashboardProvider);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Launched Production Order $num from plan!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to launch order: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Create Order'),
          ),
        ],
      ),
    );
  }

  // Create Plan Dialog
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
                    const Divider(),
                    const SizedBox(height: 8),

                    // Plan Number
                    TextField(
                      controller: planNumController,
                      decoration: const InputDecoration(labelText: 'Plan Number', border: OutlineInputBorder(), isDense: true),
                    ),
                    const SizedBox(height: 12),

                    // Product Selector
                    const Text('Finished Product *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedProductId,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      items: products.map((p) {
                        final id = p['id']?.toString() ?? p['_id']?.toString() ?? '';
                        return DropdownMenuItem(
                          value: id,
                          child: Text('${p['code'] ?? 'PRD'} - ${p['name'] ?? 'Product'} (${p['unit'] ?? 'pcs'})'),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedProductId = val),
                    ),
                    const SizedBox(height: 12),

                    // Target Quantity
                    TextField(
                      controller: targetController,
                      decoration: const InputDecoration(labelText: 'Planned Target Quantity (pcs) *', border: OutlineInputBorder(), isDense: true),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // Production Line Selector
                    const Text('Assigned Line *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedLineId,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      items: lines.map((l) {
                        final id = l['id']?.toString() ?? l['_id']?.toString() ?? '';
                        return DropdownMenuItem(
                          value: id,
                          child: Text('${l['code'] ?? 'L1'} - ${l['name'] ?? 'Line'}'),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedLineId = val),
                    ),
                    const SizedBox(height: 12),

                    // Priority
                    const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPriority,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'LOW', child: Text('LOW')),
                        DropdownMenuItem(value: 'MEDIUM', child: Text('MEDIUM')),
                        DropdownMenuItem(value: 'HIGH', child: Text('HIGH')),
                      ],
                      onChanged: (val) => setModalState(() => selectedPriority = val ?? 'MEDIUM'),
                    ),
                    const SizedBox(height: 12),

                    // Notes
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes / Scheduling Remarks (Optional)', border: OutlineInputBorder(), isDense: true),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                        onPressed: () async {
                          final num = planNumController.text.trim();
                          final target = double.tryParse(targetController.text) ?? 500;
                          if (num.isEmpty || selectedProductId == null || selectedLineId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select Product and Line.')),
                            );
                            return;
                          }

                          Navigator.pop(modalCtx);
                          try {
                            final api = ref.read(apiServiceProvider);
                            final targetProd = products.firstWhere((p) => (p['id'] ?? p['_id'])?.toString() == selectedProductId);
                            final targetLine = lines.firstWhere((l) => (l['id'] ?? l['_id'])?.toString() == selectedLineId);

                            await api.createCollectionItem('production_plans', {
                              'plan_number': num,
                              'product_id': selectedProductId,
                              'product_code': targetProd['code'],
                              'product_name': targetProd['name'],
                              'line_id': selectedLineId,
                              'line_code': targetLine['code'],
                              'line_name': targetLine['name'],
                              'target_quantity': target,
                              'status': 'PLANNED',
                              'priority': selectedPriority,
                              'notes': notesController.text.trim(),
                              'created_at': DateTime.now().millisecondsSinceEpoch,
                            });

                            ref.invalidate(productionPlansProvider);

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Production Plan $num created successfully!'), backgroundColor: const Color(0xFF10B981)),
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
}
