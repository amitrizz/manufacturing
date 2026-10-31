import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/app_providers.dart';
import '../../models/production.dart';
import '../../models/machine.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

class ProductionFloorScreen extends ConsumerStatefulWidget {
  const ProductionFloorScreen({super.key});

  @override
  ConsumerState<ProductionFloorScreen> createState() => _ProductionFloorScreenState();
}

class _ProductionFloorScreenState extends ConsumerState<ProductionFloorScreen> {
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
  void dispose() {
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

    final linesAsync = ref.watch(productionLinesProvider);
    final machinesAsync = ref.watch(machinesProvider(const {'limit': 100}));
    final ordersAsync = ref.watch(productionOrdersProvider('IN_PROGRESS'));
    final staffAsync = ref.watch(staffProvider(const {'limit': 100}));

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
          'Production Floor & Assembly Lines',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            tooltip: 'Add Production Line',
            onPressed: () => _showAddLineDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Floor',
            onPressed: () {
              ref.invalidate(productionLinesProvider);
              ref.invalidate(machinesProvider);
              ref.invalidate(productionOrdersProvider);
              ref.invalidate(staffProvider);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productionLinesProvider);
          ref.invalidate(machinesProvider);
          ref.invalidate(productionOrdersProvider);
          ref.invalidate(staffProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // KPI Summary Cards Strip
            machinesAsync.when(
              data: (paginated) {
                final machines = paginated.data;
                final orders = ordersAsync.valueOrNull?.data ?? [];
                final totalProduced = orders.fold<double>(0, (sum, o) => sum + o.producedQuantity).toInt();
                final runningCount = machines.where((m) => m.status == 'RUNNING').length;
                final workersCount = machines.where((m) => m.currentOperator != null && m.currentOperator!.isNotEmpty).length;
                final linesCount = linesAsync.valueOrNull?.length ?? 0;

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
                      _buildKpiItem('TOTAL OUTPUT', '${Formatters.formatNumber(totalProduced)} pcs', const Color(0xFF16A34A)),
                      _buildDivider(isDark),
                      _buildKpiItem('RUNNING', '$runningCount / ${machines.length}', const Color(0xFF0284C7)),
                      _buildDivider(isDark),
                      _buildKpiItem('ACTIVE LINES', '$linesCount Lines', const Color(0xFF0D9488)),
                      _buildDivider(isDark),
                      _buildKpiItem('WORKERS', '$workersCount Active', const Color(0xFF7C3AED)),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 60),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 12),

            // Period Segmented Tabs
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
            const SizedBox(height: 12),

            // Search Field & Quick Add Line Action
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search machine, line, worker or product…',
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                      isDense: true,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                  onPressed: () => _showAddLineDialog(),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('+ Add Line', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Record Action Bar
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
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
                                ? '${ordersAsync.valueOrNull!.data.length} active order running • Tap to record pieces & shift'
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
            const SizedBox(height: 16),

            // Lines and Machines Grouped View
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
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFECFDF5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.alt_route_rounded, size: 40, color: Color(0xFF16A34A)),
                        ),
                        const SizedBox(height: 14),
                        const Text('No Production Lines Configured', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        const Text(
                          'Configure assembly lines, map workstation machines, and monitor shift output.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                          onPressed: () => _showAddLineDialog(),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('+ Add Production Line'),
                        ),
                      ],
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
                          // Line Header Card
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
              loading: () => AppShimmer(
                child: Column(
                  children: List.generate(3, (_) => Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ShimmerBox(width: 140, height: 18, borderRadius: 6),
                            ShimmerBox(width: 70, height: 20, borderRadius: 12),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const ShimmerBox(width: double.infinity, height: 48, borderRadius: 8),
                        const SizedBox(height: 12),
                        Row(
                          children: List.generate(
                            3,
                            (i) => Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
                                child: const ShimmerBox(height: 44, borderRadius: 8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                ShimmerBox(width: 28, height: 28, borderRadius: 14),
                                SizedBox(width: 6),
                                ShimmerBox(width: 28, height: 28, borderRadius: 14),
                              ],
                            ),
                            ShimmerBox(width: 100, height: 32, borderRadius: 8),
                          ],
                        ),
                      ],
                    ),
                  )),
                ),
              ),
              error: (e, _) => Center(child: Text('Error loading lines: $e')),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
        onPressed: () {
          final orders = ordersAsync.valueOrNull?.data ?? [];
          if (orders.isNotEmpty) {
            _showRecordOutputDialog(orders.first);
          } else {
            _showRecordOutputDialogDirect('Production Floor');
          }
        },
        icon: const Icon(Icons.create_outlined),
        label: const Text('Log Output', style: TextStyle(fontWeight: FontWeight.w700)),
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
            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: color),
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

  // Machine Card in Floor
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
              _buildMachineStatusBadge(m.status),
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

          // Shift & Worker Breakdown Table
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
    );
  }

  Widget _buildMachineStatusBadge(String status) {
    Color color;
    switch (status.toUpperCase()) {
      case 'RUNNING':
        color = const Color(0xFF16A34A);
        break;
      case 'IDLE':
        color = const Color(0xFFD97706);
        break;
      case 'BREAKDOWN':
      case 'MAINTENANCE':
        color = const Color(0xFFDC2626);
        break;
      default:
        color = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
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

          InkWell(
            onTap: onAssign,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                worker != null ? Icons.edit_outlined : Icons.add_circle_outline,
                size: 15,
                color: const Color(0xFF0284C7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add Production Line Dialog
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
                  hintText: 'e.g. Final Packaging & Assembly Line',
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
                          });
                          ref.invalidate(productionLinesProvider);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Line $code created successfully!'), backgroundColor: const Color(0xFF10B981)),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
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

  // Assign Worker Dialog
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

                    const Text('Staff Member', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    if (staffList.isNotEmpty)
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                        hint: const Text('Pick from active staff roster'),
                        items: staffList.map((s) {
                          final name = s['name']?.toString() ?? s['full_name']?.toString() ?? 'Staff';
                          final role = s['role']?.toString() ?? s['job_title']?.toString() ?? 'Operator';
                          return DropdownMenuItem(value: name, child: Text('$name ($role)'));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              _assignWorkerNameController.text = val;
                            });
                          }
                        },
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _assignWorkerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Or enter Operator Name manually',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _assignNotesController,
                      decoration: const InputDecoration(
                        labelText: 'Shift notes / instructions (optional)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 18),

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
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter or select a worker.')));
                                return;
                              }

                              Navigator.pop(modalCtx);
                              try {
                                final api = ref.read(apiServiceProvider);
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
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not assign: $e'), backgroundColor: Colors.red));
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

  // Record Output Dialogs
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
                    'scrap_quantity': scrap,
                    'timestamp': DateTime.now().millisecondsSinceEpoch,
                  });
                }
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
}
