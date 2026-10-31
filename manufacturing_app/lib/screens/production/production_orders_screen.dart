import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../models/production.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

class ProductionOrdersScreen extends ConsumerStatefulWidget {
  const ProductionOrdersScreen({super.key});

  @override
  ConsumerState<ProductionOrdersScreen> createState() => _ProductionOrdersScreenState();
}

class _ProductionOrdersScreenState extends ConsumerState<ProductionOrdersScreen> {
  String? _selectedStatus;
  String _orderSearch = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ordersAsync = ref.watch(productionOrdersProvider(_selectedStatus));

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
          'Production Orders',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Filter by Status',
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  _selectedStatus != null ? _formatStatusName(_selectedStatus!) : 'All',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
              ],
            ),
            onSelected: (value) {
              setState(() {
                _selectedStatus = value == 'all' ? null : value;
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text('All Statuses')),
              PopupMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
              PopupMenuItem(value: 'PENDING', child: Text('Pending')),
              PopupMenuItem(value: 'COMPLETED', child: Text('Completed')),
              PopupMenuItem(value: 'DELAYED', child: Text('Delayed')),
              PopupMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Orders',
            onPressed: () => ref.invalidate(productionOrdersProvider),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(productionOrdersProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // Top 4 KPI Metrics Bar
            ordersAsync.when(
              data: (paginated) => _buildKpiBar(paginated.data, isDark),
              loading: () => const ShimmerKpiRow(padding: EdgeInsets.zero),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),

            // Search Bar & + New Order Action Button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search orders by number, product, or line…',
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
                        _orderSearch = val.trim().toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                  onPressed: () => _showCreateOrderDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('+ New Order', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusChip('All', _selectedStatus == null, () {
                    setState(() => _selectedStatus = null);
                  }),
                  const SizedBox(width: 8),
                  _buildStatusChip('In Progress', _selectedStatus == 'IN_PROGRESS', () {
                    setState(() => _selectedStatus = _selectedStatus == 'IN_PROGRESS' ? null : 'IN_PROGRESS');
                  }),
                  const SizedBox(width: 8),
                  _buildStatusChip('Pending', _selectedStatus == 'PENDING', () {
                    setState(() => _selectedStatus = _selectedStatus == 'PENDING' ? null : 'PENDING');
                  }),
                  const SizedBox(width: 8),
                  _buildStatusChip('Completed', _selectedStatus == 'COMPLETED', () {
                    setState(() => _selectedStatus = _selectedStatus == 'COMPLETED' ? null : 'COMPLETED');
                  }),
                  const SizedBox(width: 8),
                  _buildStatusChip('Delayed', _selectedStatus == 'DELAYED', () {
                    setState(() => _selectedStatus = _selectedStatus == 'DELAYED' ? null : 'DELAYED');
                  }),
                ],
              ),
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

                // Sort: IN_PROGRESS first, then PENDING, then created_at desc
                list.sort((a, b) {
                  int rank(String s) => s == 'IN_PROGRESS' ? 0 : s == 'PENDING' ? 1 : 2;
                  final rDiff = rank(a.status).compareTo(rank(b.status));
                  if (rDiff != 0) return rDiff;
                  return b.createdAt.compareTo(a.createdAt);
                });

                if (list.isEmpty) {
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
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.assignment_outlined, size: 40, color: Color(0xFF0284C7)),
                        ),
                        const SizedBox(height: 16),
                        const Text('No production orders found', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text(
                          'Create your first work order to schedule line execution.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        ),
                        const SizedBox(height: 18),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                          onPressed: () => _showCreateOrderDialog(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Create Production Order'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: list.map((order) {
                    return _buildOrderCard(order, isDark);
                  }).toList(),
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
                            ShimmerBox(width: 100, height: 16, borderRadius: 6),
                            ShimmerBox(width: 75, height: 18, borderRadius: 12),
                          ],
                        ),
                        SizedBox(height: 10),
                        ShimmerBox(width: 220, height: 17, borderRadius: 5),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            ShimmerBox(width: 80, height: 13, borderRadius: 4),
                            SizedBox(width: 8),
                            ShimmerBox(width: 70, height: 13, borderRadius: 4),
                          ],
                        ),
                        SizedBox(height: 12),
                        ShimmerBox(width: double.infinity, height: 8, borderRadius: 4),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerBox(width: 90, height: 14, borderRadius: 4),
                            ShimmerBox(width: 100, height: 32, borderRadius: 8),
                          ],
                        ),
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
                      Text('Error loading orders: $error'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(productionOrdersProvider),
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
        backgroundColor: const Color(0xFF0284C7),
        foregroundColor: Colors.white,
        onPressed: () => _showCreateOrderDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Order', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  // Top 4 KPI Metrics Card Bar
  Widget _buildKpiBar(List<ProductionOrder> orders, bool isDark) {
    final total = orders.length;
    final inProgress = orders.where((o) => o.status.toUpperCase() == 'IN_PROGRESS' || o.status.toUpperCase() == 'RUNNING').length;
    final pending = orders.where((o) => o.status.toUpperCase() == 'PENDING').length;
    final completed = orders.where((o) => o.status.toUpperCase() == 'COMPLETED').length;

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
          _buildKpiItem('TOTAL ORDERS', '$total', const Color(0xFF0284C7)),
          _buildDivider(isDark),
          _buildKpiItem('IN PROGRESS', '$inProgress', const Color(0xFF16A34A)),
          _buildDivider(isDark),
          _buildKpiItem('PENDING', '$pending', const Color(0xFFD97706)),
          _buildDivider(isDark),
          _buildKpiItem('COMPLETED', '$completed', const Color(0xFF7C3AED)),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color),
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

  Widget _buildStatusChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF0284C7) : const Color(0xFFE2E8F0)),
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

  // Order Card Widget
  Widget _buildOrderCard(ProductionOrder order, bool isDark) {
    final pct = (order.progressPercent).clamp(0.0, 100.0);

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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showOrderDetailModal(order),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Order Number Badge & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      order.orderNumber,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0284C7)),
                    ),
                  ),
                  _buildStatusBadge(order.statusDisplayName, order.statusColor),
                ],
              ),
              const SizedBox(height: 8),

              // Product Info & Line Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.productName ?? order.productCode ?? 'Finished Good Product',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Code: ${order.productCode ?? "–"}',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Line ${order.lineCode ?? "1"}',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: order.qcStatus == 'PASSED' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      order.qcStatus == 'PASSED' ? 'QC PASSED' : 'QC PENDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: order.qcStatus == 'PASSED' ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress Bar & Produced vs Target
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress: ${Formatters.formatNumber(order.producedQuantity.toInt())} / ${Formatters.formatNumber(order.targetQuantity.toInt())} pcs',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                  ),
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: order.statusColor),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              LinearProgressIndicator(
                value: pct / 100,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                valueColor: AlwaysStoppedAnimation<Color>(order.statusColor),
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              const SizedBox(height: 10),

              // Bottom Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (order.status == 'PENDING') ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF16A34A)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _startOrder(order),
                      icon: const Icon(Icons.play_arrow_rounded, size: 16, color: Color(0xFF16A34A)),
                      label: const Text('Start Run', style: TextStyle(fontSize: 11.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _showRecordOutputDialog(order),
                    icon: const Icon(Icons.create_outlined, size: 15),
                    label: const Text('Record Output', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
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

  // Start Production Order Action
  Future<void> _startOrder(ProductionOrder order) async {
    try {
      final api = ref.read(apiServiceProvider);
      await api.startProductionOrder(order.id);
      ref.invalidate(productionOrdersProvider);
      ref.invalidate(dashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order ${order.orderNumber} started successfully!'), backgroundColor: const Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start order: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Order Detail Bottom Sheet
  void _showOrderDetailModal(ProductionOrder order) {
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
                  _buildStatusBadge(order.statusDisplayName, order.statusColor),
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
                        onPressed: () {
                          Navigator.pop(ctx);
                          _startOrder(order);
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

  // Record Output Dialog
  void _showRecordOutputDialog(ProductionOrder order) {
    final qtyController = TextEditingController(text: '50');
    final scrapController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Record Production Output\n${order.orderNumber}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
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
                await api.createCollectionItem('production_entries', {
                  'production_order_id': order.id,
                  'good_quantity': good,
                  'scrap_quantity': scrap,
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                });
                ref.invalidate(productionOrdersProvider);
                ref.invalidate(dashboardProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Recorded $good pcs produced!'), backgroundColor: const Color(0xFF10B981)),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to record output: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Save Output'),
          ),
        ],
      ),
    );
  }

  // Create Order Dialog
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

    final productsAsync = ref.read(productsProvider(const {'limit': 100}));
    final linesAsync = ref.read(productionLinesProvider);
    final plansAsync = ref.read(productionPlansProvider(const {'limit': 50}));

    final products = productsAsync.valueOrNull?.data ?? [];
    final lines = linesAsync.valueOrNull ?? [];
    final plans = plansAsync.valueOrNull?.data ?? [];

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
                    TextField(
                      controller: orderNumController,
                      decoration: const InputDecoration(labelText: 'Order Number', border: OutlineInputBorder(), isDense: true),
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
                      controller: qtyController,
                      decoration: const InputDecoration(labelText: 'Target Quantity (pcs) *', border: OutlineInputBorder(), isDense: true),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),

                    // Production Line Selector
                    const Text('Production Line *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
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

                    // Priority Selector
                    const Text('Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPriority,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'LOW', child: Text('LOW')),
                        DropdownMenuItem(value: 'MEDIUM', child: Text('MEDIUM')),
                        DropdownMenuItem(value: 'HIGH', child: Text('HIGH')),
                        DropdownMenuItem(value: 'URGENT', child: Text('URGENT')),
                      ],
                      onChanged: (val) => setModalState(() => selectedPriority = val ?? 'MEDIUM'),
                    ),
                    const SizedBox(height: 12),

                    // Associated Plan (Optional)
                    if (plans.isNotEmpty) ...[
                      const Text('Associate Production Plan (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPlanId,
                        isExpanded: true,
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('None (Direct Order)')),
                          ...plans.map((pl) {
                            final id = pl['id']?.toString() ?? pl['_id']?.toString() ?? '';
                            return DropdownMenuItem(
                              value: id,
                              child: Text('${pl['plan_number'] ?? 'PLN'} · ${pl['product_code'] ?? ''}'),
                            );
                          }),
                        ],
                        onChanged: (val) => setModalState(() => selectedPlanId = val),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                        onPressed: () async {
                          final num = orderNumController.text.trim();
                          final target = double.tryParse(qtyController.text) ?? 100;
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

                            await api.createCollectionItem('production_orders', {
                              'order_number': num,
                              'product_id': selectedProductId,
                              'product_code': targetProd['code'],
                              'product_name': targetProd['name'],
                              'line_id': selectedLineId,
                              'line_code': targetLine['code'],
                              'target_quantity': target,
                              'produced_quantity': 0,
                              'rejected_quantity': 0,
                              'status': 'PENDING',
                              'priority': selectedPriority,
                              'production_plan_id': selectedPlanId,
                              'created_at': DateTime.now().millisecondsSinceEpoch,
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

  String _formatStatusName(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'PENDING':
        return 'Pending';
      case 'COMPLETED':
        return 'Completed';
      case 'DELAYED':
        return 'Delayed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
