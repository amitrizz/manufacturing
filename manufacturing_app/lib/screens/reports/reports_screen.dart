import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/dashboard.dart';
import '../../providers/app_providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const ReportsScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

enum DateRangePreset { today, yesterday, last7Days, last30Days, thisMonth, allTime }

class _ReportsScreenState extends ConsumerState<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateRangePreset _selectedPreset = DateRangePreset.thisMonth;
  int _selectedMonths = 6;

  // Report counts cache
  final Map<String, int> _reportCounts = {};
  bool _loadingCounts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _loadReportCounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  (int start, int end) _computeRange() {
    final now = DateTime.now();
    switch (_selectedPreset) {
      case DateRangePreset.today:
        final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).millisecondsSinceEpoch;
        return (start, end);
      case DateRangePreset.yesterday:
        final y = now.subtract(const Duration(days: 1));
        final start = DateTime(y.year, y.month, y.day).millisecondsSinceEpoch;
        final end = DateTime(y.year, y.month, y.day, 23, 59, 59, 999).millisecondsSinceEpoch;
        return (start, end);
      case DateRangePreset.last7Days:
        final start = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
        return (start, now.millisecondsSinceEpoch);
      case DateRangePreset.last30Days:
        final start = now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
        return (start, now.millisecondsSinceEpoch);
      case DateRangePreset.thisMonth:
        final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
        return (start, now.millisecondsSinceEpoch);
      case DateRangePreset.allTime:
        return (0, now.millisecondsSinceEpoch + 86400000);
    }
  }

  String _presetLabel(DateRangePreset preset) {
    switch (preset) {
      case DateRangePreset.today:
        return 'Today';
      case DateRangePreset.yesterday:
        return 'Yesterday';
      case DateRangePreset.last7Days:
        return 'Last 7 Days';
      case DateRangePreset.last30Days:
        return 'Last 30 Days';
      case DateRangePreset.thisMonth:
        return 'This Month';
      case DateRangePreset.allTime:
        return 'All Time';
    }
  }

  Future<void> _loadReportCounts() async {
    if (!mounted) return;
    setState(() => _loadingCounts = true);

    try {
      final api = ref.read(apiServiceProvider);
      final collections = [
        ('production', 'production_orders'),
        ('quality', 'quality_inspections'),
        ('downtime', 'machine_downtime'),
        ('maintenance', 'maintenance_orders'),
        ('materials', 'materials'),
        ('finished_goods', 'finished_goods'),
        ('dispatch', 'dispatch_orders'),
        ('machines', 'machines'),
        ('attendance', 'staff_attendance'),
      ];

      final counts = <String, int>{};
      await Future.wait(
        collections.map((col) async {
          try {
            final res = await api.getCollection(col.$2, queryParams: const {'limit': 500});
            counts[col.$1] = res.data.length;
          } catch (_) {
            counts[col.$1] = 0;
          }
        }),
      );

      if (mounted) {
        setState(() {
          _reportCounts.addAll(counts);
          _loadingCounts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCounts = false);
    }
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
    final dashboardAsync = ref.watch(dashboardProvider);

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
          'Reports & Analytics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          // Date Range Preset Selector
          PopupMenuButton<DateRangePreset>(
            initialValue: _selectedPreset,
            tooltip: 'Filter Range',
            onSelected: (preset) {
              setState(() => _selectedPreset = preset);
              _loadReportCounts();
            },
            itemBuilder: (context) => DateRangePreset.values.map((p) {
              return PopupMenuItem(
                value: p,
                child: Row(
                  children: [
                    Icon(
                      _selectedPreset == p ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      size: 16,
                      color: _selectedPreset == p ? const Color(0xFF0284C7) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _presetLabel(p),
                      style: TextStyle(
                        fontWeight: _selectedPreset == p ? FontWeight.w700 : FontWeight.w500,
                        color: _selectedPreset == p ? const Color(0xFF0A1E38) : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    _presetLabel(_selectedPreset),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 22),
            tooltip: 'Refresh Reports',
            onPressed: () {
              ref.invalidate(dashboardProvider);
              _loadReportCounts();
            },
          ),
          const SizedBox(width: 6),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Operational Trends'),
            Tab(text: 'Reports Center (9)'),
            Tab(text: 'OEE Telemetry'),
            Tab(text: 'Audit Activity Log'),
          ],
        ),
      ),
      body: dashboardAsync.when(
        data: (dashboard) => TabBarView(
          controller: _tabController,
          children: [
            _buildTrendsTab(dashboard),
            _buildReportsCenterTab(),
            _buildOeeTelemetryTab(dashboard),
            _buildActivityLogTab(dashboard),
          ],
        ),
        loading: () => const ReportsScreenShimmer(),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
                const SizedBox(height: 12),
                const Text('Failed to load analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(err.toString(), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(dashboardProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 0: Operational Trends & Overview
  // ---------------------------------------------------------------------------
  Widget _buildTrendsTab(DashboardResponse dashboard) {
    final kpis = dashboard.kpis;
    final monthlyData = dashboard.monthlyData;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardProvider);
        await _loadReportCounts();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            _buildHeaderBanner(),
            const SizedBox(height: 14),

            // Top 4 KPI Metric Cards
            _buildKpisGrid(kpis),
            const SizedBox(height: 16),

            // Monthly Production Trend Bar Chart
            _buildMonthlyChartCard(monthlyData),
            const SizedBox(height: 16),

            // Machine Status Pie Chart & Line Progress
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 700;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildMachineStatusCard(kpis.machineStatusCounts)),
                      const SizedBox(width: 14),
                      Expanded(child: _buildLineProgressCard(kpis.lineProgress)),
                    ],
                  );
                }
                return Column(
                  children: [
                    _buildMachineStatusCard(kpis.machineStatusCounts),
                    const SizedBox(height: 14),
                    _buildLineProgressCard(kpis.lineProgress),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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
            child: const Icon(Icons.insights_rounded, color: Color(0xFF2563EB), size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plant Analytics & Operational Reports',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 2),
                Text(
                  'Real-time KPIs, equipment effectiveness (OEE), monthly trends & exportable reports',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpisGrid(DashboardKpis kpis) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        final items = [
          _buildKpiBox(
            title: 'OUTPUT ACHIEVEMENT',
            value: '${kpis.achievement}%',
            sub: '${Formatters.formatNumber(kpis.produced.toInt())} / ${Formatters.formatNumber(kpis.target.toInt())} pcs',
            icon: Icons.track_changes_rounded,
            color: const Color(0xFF2563EB),
          ),
          _buildKpiBox(
            title: 'QUALITY PASS RATE',
            value: '${kpis.qualityRate}%',
            sub: 'Zero defect tolerance',
            icon: Icons.verified_user_rounded,
            color: const Color(0xFF16A34A),
          ),
          _buildKpiBox(
            title: 'MACHINE AVAILABILITY',
            value: '${kpis.machineAvailability}%',
            sub: '${kpis.downtimeHours}h total downtime',
            icon: Icons.precision_manufacturing_rounded,
            color: const Color(0xFF0284C7),
          ),
          _buildKpiBox(
            title: 'MAINTENANCE HEALTH',
            value: '${kpis.downtimeHours}h',
            sub: 'Equipment uptime healthy',
            icon: Icons.build_circle_rounded,
            color: const Color(0xFF7C3AED),
          ),
        ];

        if (isWide) {
          return Row(
            children: items.map((i) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: i))).toList(),
          );
        }

        return Column(
          children: [
            Row(children: [Expanded(child: items[0]), const SizedBox(width: 8), Expanded(child: items[1])]),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: items[2]), const SizedBox(width: 8), Expanded(child: items[3])]),
          ],
        );
      },
    );
  }

  Widget _buildKpiBox({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.4),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color),
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
    );
  }

  Widget _buildMonthlyChartCard(List<MonthlyData> monthlyData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Production Trend',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 2),
                  Text('Target vs Actual Good Output (pcs)', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                ],
              ),
              // Period chips (3M / 6M / 12M)
              Row(
                children: [3, 6, 12].map((m) {
                  final isSelected = _selectedMonths == m;
                  return InkWell(
                    onTap: () => setState(() => _selectedMonths = m),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0A1E38) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${m}M',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            children: [
              Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFFBFDBFE), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 5),
              const Text('Target Output', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(width: 14),
              Container(width: 10, height: 10, decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 5),
              const Text('Produced Output', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 16),

          // Bar Chart
          SizedBox(
            height: 260,
            child: _buildBarChartWidget(monthlyData),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartWidget(List<MonthlyData> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No historical data available', style: TextStyle(color: Color(0xFF94A3B8))));
    }

    // Take last N months
    final sliced = data.length > _selectedMonths ? data.sublist(data.length - _selectedMonths) : data;

    final maxVal = sliced.fold<double>(
      100.0,
      (max, d) => d.produced > max ? d.produced.toDouble() : (d.target > max ? d.target.toDouble() : max),
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.25,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final month = sliced[group.x.toInt()].month;
              final isProduced = rodIndex == 1;
              return BarTooltipItem(
                '$month\n${isProduced ? "Produced" : "Target"}: ${Formatters.formatNumber(rod.toY.toInt())} pcs',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx >= 0 && idx < sliced.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      sliced[idx].month,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (val, meta) => Text(
                Formatters.formatNumber(val.toInt()),
                style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(sliced.length, (idx) {
          final d = sliced[idx];
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: d.target.toDouble(),
                width: 14,
                color: const Color(0xFFBFDBFE),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: d.produced.toDouble(),
                width: 14,
                color: const Color(0xFF2563EB),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
            barsSpace: 4,
          );
        }),
      ),
    );
  }

  Widget _buildMachineStatusCard(Map<String, int> statusCounts) {
    final total = statusCounts.values.fold(0, (a, b) => a + b);

    final colorsMap = {
      'RUNNING': const Color(0xFF16A34A),
      'IDLE': const Color(0xFF64748B),
      'BREAKDOWN': const Color(0xFFDC2626),
      'MAINTENANCE': const Color(0xFFF59E0B),
      'OFFLINE': const Color(0xFF94A3B8),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Machine Fleet Distribution', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('Current operational telemetry status', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          const SizedBox(height: 14),

          if (total == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No machines assigned yet', style: TextStyle(color: Color(0xFF94A3B8)))),
            )
          else ...[
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sections: statusCounts.entries.where((e) => e.value > 0).map((entry) {
                    final pct = (entry.value / total) * 100;
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${pct.toStringAsFixed(0)}%',
                      color: colorsMap[entry.key] ?? const Color(0xFF0284C7),
                      radius: 44,
                      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                    );
                  }).toList(),
                  centerSpaceRadius: 28,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: statusCounts.entries.map((entry) {
                final col = colorsMap[entry.key] ?? const Color(0xFF0284C7);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('${entry.key}: ${entry.value}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLineProgressCard(List<LineProgress> lineProgress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Production Lines Progress', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('Throughput contribution per line', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          const SizedBox(height: 14),

          if (lineProgress.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No line entries recorded', style: TextStyle(color: Color(0xFF94A3B8)))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lineProgress.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final l = lineProgress[idx];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.lineName ?? 'Line ${l.lineCode}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${l.pct}% (${Formatters.formatNumber(l.produced.toInt())} pcs)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (l.pct / 100).clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: Reports Center (9 Functional Reports matching frontend)
  // ---------------------------------------------------------------------------
  Widget _buildReportsCenterTab() {
    final reports = [
      (
        type: 'production',
        title: 'Production Orders Report',
        sub: 'Work orders, planned quantities, produced output, status and schedules',
        icon: Icons.assignment_outlined,
        color: const Color(0xFF0284C7),
      ),
      (
        type: 'quality',
        title: 'Quality & Inspections Audit',
        sub: 'QA pass/fail logs, batch numbers, inspectors, and defect rejection logs',
        icon: Icons.verified_outlined,
        color: const Color(0xFF16A34A),
      ),
      (
        type: 'downtime',
        title: 'Machine Downtime & Stoppages',
        sub: 'Machine outage logs, breakdown reasons, and duration analysis',
        icon: Icons.timer_off_outlined,
        color: const Color(0xFFDC2626),
      ),
      (
        type: 'maintenance',
        title: 'Machine Maintenance Logs',
        sub: 'Preventive service, corrective work orders, and technician logs',
        icon: Icons.build_outlined,
        color: const Color(0xFF5D4037),
      ),
      (
        type: 'materials',
        title: 'Raw Materials Inventory',
        sub: 'Stock on hand, safety stock levels, consumption, and replenishment status',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFFD97706),
      ),
      (
        type: 'finished_goods',
        title: 'Finished Goods Inventory',
        sub: 'Produced units, quality-cleared goods, and dispatch-ready inventory',
        icon: Icons.archive_outlined,
        color: const Color(0xFF7C3AED),
      ),
      (
        type: 'dispatch',
        title: 'Dispatch & Customer Shipments',
        sub: 'Outward deliveries, customer orders, quantities, and logistics status',
        icon: Icons.local_shipping_outlined,
        color: const Color(0xFF0284C7),
      ),
      (
        type: 'oee_summary',
        title: 'OEE Operational Summary',
        sub: 'Overall equipment effectiveness, availability, speed performance & quality',
        icon: Icons.speed_rounded,
        color: const Color(0xFF2563EB),
      ),
      (
        type: 'attendance',
        title: 'Staff Shift Attendance',
        sub: 'Worker presence, shifts, clock-in records, and overtime tracking',
        icon: Icons.badge_outlined,
        color: const Color(0xFF0D9488),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operational Reports Repository',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  SizedBox(height: 2),
                  Text('Preview live datasets or export directly to CSV / JSON', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              if (_loadingCounts)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 14),

          // 9 Report Cards
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final r = reports[idx];
              final count = _reportCounts[r.type];

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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: r.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(r.icon, color: r.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                r.title,
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              if (count != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$count rows',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.sub,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Actions: Preview, CSV, JSON
                    Wrap(
                      spacing: 6,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _openReportPreviewModal(r.type, r.title),
                          icon: const Icon(Icons.table_chart_outlined, size: 14),
                          label: const Text('Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0A1E38),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _exportReportData(r.type, r.title, 'csv'),
                          icon: const Icon(Icons.download_rounded, size: 14),
                          label: const Text('CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0284C7),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: OEE Telemetry Breakdown
  // ---------------------------------------------------------------------------
  Widget _buildOeeTelemetryTab(DashboardResponse dashboard) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchOeeTelemetry(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ReportsScreenShimmer();
        }

        final oeeList = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Equipment Effectiveness (OEE)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'OEE = Availability (%) × Performance (%) × Quality (%)',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (oeeList.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.precision_manufacturing_outlined, size: 48, color: Color(0xFF94A3B8)),
                      SizedBox(height: 12),
                      Text('No machine telemetry recorded yet', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 4),
                      Text('Record production entries and telemetry to calculate live OEE.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: oeeList.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final item = oeeList[idx];
                    return _buildOeeCard(item);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOeeCard(Map<String, dynamic> item) {
    final code = item['machine_code']?.toString() ?? 'Machine';
    final avail = (item['availability'] as num?)?.toInt() ?? 100;
    final perf = (item['performance'] as num?)?.toInt() ?? 100;
    final qual = (item['quality'] as num?)?.toInt() ?? 100;
    final oee = (item['oee'] as num?)?.toInt() ?? 100;

    Color oeeColor = const Color(0xFF16A34A);
    if (oee < 70) {
      oeeColor = const Color(0xFFDC2626);
    } else if (oee < 85) {
      oeeColor = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.precision_manufacturing_rounded, size: 18, color: Color(0xFF0A1E38)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    code,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: oeeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'OEE: $oee%',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: oeeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 3 Component Progress Bars
          _buildOeeProgressRow('Availability', avail, const Color(0xFF0284C7)),
          const SizedBox(height: 8),
          _buildOeeProgressRow('Performance', perf, const Color(0xFF7C3AED)),
          const SizedBox(height: 8),
          _buildOeeProgressRow('Quality Rate', qual, const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _buildOeeProgressRow(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 38,
          child: Text(
            '$value%',
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchOeeTelemetry() async {
    try {
      final api = ref.read(apiServiceProvider);
      List<Map<String, dynamic>> machines = [];
      List<Map<String, dynamic>> entries = [];

      try {
        final res = await api.getCollection('machines', queryParams: const {'limit': 100});
        machines = res.data;
      } catch (_) {}

      try {
        final res = await api.getCollection('production_entries', queryParams: const {'limit': 200});
        entries = res.data;
      } catch (_) {}

      final entriesByMachine = <String, (int good, int reject)>{};
      for (final e in entries) {
        final mId = e['machine_id']?.toString() ?? '';
        final cur = entriesByMachine[mId] ?? (0, 0);
        final g = (e['good_quantity'] as num?)?.toInt() ?? 0;
        final r = (e['rejected_quantity'] as num?)?.toInt() ?? 0;
        entriesByMachine[mId] = (cur.$1 + g, cur.$2 + r);
      }

      final list = <Map<String, dynamic>>[];
      for (final m in machines) {
        final mId = m['id']?.toString() ?? m['_id']?.toString() ?? '';
        final counts = entriesByMachine[mId] ?? (0, 0);
        final runtime = (m['runtime_seconds'] as num?)?.toDouble() ?? 3600.0;
        final downtime = (m['downtime_seconds'] as num?)?.toDouble() ?? 0.0;

        final avail = (runtime + downtime) > 0 ? ((runtime / (runtime + downtime)) * 100).round() : 100;
        final good = counts.$1;
        final reject = counts.$2;
        final totalUnits = good + reject;
        final qual = totalUnits > 0 ? ((good / totalUnits) * 100).round() : 100;
        const perf = 95; // default benchmark
        final oee = ((avail * perf * qual) / 10000).round();

        list.add({
          'machine_code': m['code'] ?? m['name'] ?? 'Machine',
          'availability': avail,
          'performance': perf,
          'quality': qual,
          'oee': oee,
        });
      }

      return list;
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // TAB 3: Activity Audit Log
  // ---------------------------------------------------------------------------
  Widget _buildActivityLogTab(DashboardResponse dashboard) {
    final activities = dashboard.recentActivities;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Operations Audit History',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 2),
                Text('Immutable audit trail of plant events & operator inputs', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (activities.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text('No activity records logged', style: TextStyle(color: Color(0xFF94A3B8))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final act = activities[idx];
                final timeStr = DateTime.fromMillisecondsSinceEpoch(act.timestamp).toLocal().toString().substring(0, 16);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(color: act.dotColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  act.title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                ),
                                Text(
                                  timeStr,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                ),
                              ],
                            ),
                            if (act.description != null && act.description!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                act.description!,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                act.eventType,
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // REPORT DATA PREVIEW & EXPORT HELPERS
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> _fetchReportData(String type) async {
    final api = ref.read(apiServiceProvider);
    final (start, end) = _computeRange();

    switch (type) {
      case 'production': {
        final res = await api.getCollection('production_orders', queryParams: const {'limit': 200});
        return res.data
            .where((o) {
              final ts = (o['start_date'] ?? o['created_at'] ?? 0) as num;
              return ts >= start && ts <= end;
            })
            .map((o) => {
                  'Order Number': o['order_number'] ?? '',
                  'Product': o['product_name'] ?? o['product_code'] ?? '',
                  'Line': o['line_code'] ?? 'Line A',
                  'Target Qty': o['target_quantity'] ?? 0,
                  'Produced Qty': o['produced_quantity'] ?? 0,
                  'Status': o['status'] ?? 'PENDING',
                  'QC Status': o['qc_status'] ?? 'PENDING',
                })
            .toList();
      }

      case 'quality': {
        final res = await api.getCollection('quality_inspections', queryParams: const {'limit': 200});
        return res.data
            .where((i) {
              final ts = (i['inspected_at'] ?? i['created_at'] ?? 0) as num;
              return ts >= start && ts <= end;
            })
            .map((i) => {
                  'Batch Number': i['batch_number'] ?? i['inspection_number'] ?? '',
                  'Overall Result': i['overall_result'] ?? i['result'] ?? 'PASS',
                  'Sample Qty': i['quantity'] ?? 1,
                  'Rejected Qty': i['rejected_quantity'] ?? 0,
                  'Inspector': i['inspector'] ?? 'QA Inspector',
                  'Date': i['inspected_at'] != null ? Formatters.formatDateTime(DateTime.fromMillisecondsSinceEpoch((i['inspected_at'] as num).toInt())) : '',
                })
            .toList();
      }

      case 'downtime': {
        final res = await api.getCollection('machine_downtime', queryParams: const {'limit': 200});
        return res.data.map((d) => {
              'Machine': d['machine_id'] ?? 'M-01',
              'Reason': d['reason'] ?? 'Maintenance',
              'Duration (min)': d['duration_minutes'] ?? 0,
              'Description': d['description'] ?? '',
            }).toList();
      }

      case 'maintenance': {
        final res = await api.getCollection('maintenance_orders', queryParams: const {'limit': 200});
        return res.data.map((m) => {
              'Order Number': m['order_number'] ?? '',
              'Machine': m['machine_id'] ?? '',
              'Type': m['type'] ?? 'BREAKDOWN',
              'Status': m['status'] ?? 'OPEN',
              'Priority': m['priority'] ?? 'MEDIUM',
            }).toList();
      }

      case 'materials': {
        final res = await api.getCollection('materials', queryParams: const {'limit': 200});
        return res.data.map((m) => {
              'Code': m['code'] ?? '',
              'Name': m['name'] ?? '',
              'Category': m['category'] ?? 'Raw Material',
              'Current Stock': m['current_stock'] ?? 0,
              'Min Stock': m['minimum_stock'] ?? 0,
              'Max Stock': m['maximum_stock'] ?? 0,
            }).toList();
      }

      case 'finished_goods': {
        final res = await api.getCollection('finished_goods', queryParams: const {'limit': 200});
        return res.data.map((fg) => {
              'Product Code': fg['product_code'] ?? fg['product_id'] ?? '',
              'Produced': fg['produced_quantity'] ?? 0,
              'Quality Cleared': fg['quality_passed_quantity'] ?? 0,
              'Available Stock': fg['available_quantity'] ?? 0,
            }).toList();
      }

      case 'dispatch': {
        final res = await api.getCollection('dispatch_orders', queryParams: const {'limit': 200});
        return res.data.map((d) => {
              'Dispatch Number': d['dispatch_number'] ?? '',
              'Customer': d['customer_name'] ?? '',
              'Quantity': d['quantity'] ?? 0,
              'Status': d['status'] ?? 'DRAFT',
            }).toList();
      }

      case 'oee_summary': {
        final oee = await _fetchOeeTelemetry();
        return oee.map((o) => {
              'Machine': o['machine_code'],
              'Availability (%)': o['availability'],
              'Performance (%)': o['performance'],
              'Quality (%)': o['quality'],
              'OEE (%)': o['oee'],
            }).toList();
      }

      case 'attendance': {
        final res = await api.getCollection('staff_attendance', queryParams: const {'limit': 200});
        return res.data.map((a) => {
              'Date': a['date'] ?? '',
              'Staff ID': a['staff_id'] ?? '',
              'Shift': a['shift'] ?? 'Morning',
              'Status': a['status'] ?? 'PRESENT',
              'Overtime (h)': a['overtime_hours'] ?? 0,
            }).toList();
      }

      default:
        return [];
    }
  }

  void _openReportPreviewModal(String type, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ReportPreviewSheet(
          type: type,
          title: title,
          onFetch: () => _fetchReportData(type),
        );
      },
    );
  }

  Future<void> _exportReportData(String type, String title, String format) async {
    try {
      final rows = await _fetchReportData(type);
      if (rows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No data available to export for selected range.')),
          );
        }
        return;
      }

      String content;
      if (format == 'json') {
        content = const JsonEncoder.withIndent('  ').convert(rows);
      } else {
        final headers = rows.first.keys.toList();
        final lines = [headers.join(',')];
        for (final r in rows) {
          lines.add(headers.map((h) {
            final v = r[h]?.toString() ?? '';
            return v.contains(',') ? '"${v.replaceAll('"', '""')}"' : v;
          }).join(','));
        }
        content = lines.join('\n');
      }

      await Clipboard.setData(ClipboardData(text: content));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text('$title copied to clipboard in ${format.toUpperCase()} format! (${rows.length} rows)'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: const Color(0xFFDC2626), content: Text('Export error: $e')),
        );
      }
    }
  }
}

// -----------------------------------------------------------------------------
// Interactive Data Table Preview Sheet
// -----------------------------------------------------------------------------
class _ReportPreviewSheet extends StatefulWidget {
  final String type;
  final String title;
  final Future<List<Map<String, dynamic>>> Function() onFetch;

  const _ReportPreviewSheet({
    required this.type,
    required this.title,
    required this.onFetch,
  });

  @override
  State<_ReportPreviewSheet> createState() => _ReportPreviewSheetState();
}

class _ReportPreviewSheetState extends State<_ReportPreviewSheet> {
  List<Map<String, dynamic>> _allRows = [];
  String _searchFilter = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.onFetch().then((data) {
      if (mounted) {
        setState(() {
          _allRows = data;
          _loading = false;
        });
      }
    });
  }

  List<Map<String, dynamic>> get _filteredRows {
    if (_searchFilter.trim().isEmpty) return _allRows;
    final q = _searchFilter.trim().toLowerCase();
    return _allRows.where((r) {
      return r.values.any((v) => v.toString().toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _copyCsv() async {
    if (_allRows.isEmpty) return;
    final headers = _allRows.first.keys.toList();
    final lines = [headers.join(',')];
    for (final r in _allRows) {
      lines.add(headers.map((h) {
        final v = r[h]?.toString() ?? '';
        return v.contains(',') ? '"${v.replaceAll('"', '""')}"' : v;
      }).join(','));
    }
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF16A34A),
          content: Text('${widget.title} CSV copied to clipboard (${_allRows.length} rows)'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        '${_allRows.length} total records',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _allRows.isNotEmpty ? _copyCsv : null,
                  icon: const Icon(Icons.copy, size: 14),
                  label: const Text('Copy CSV', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Color(0xFF64748B)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search Field
          if (_allRows.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 16, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _searchFilter = v),
                        style: const TextStyle(fontSize: 12.5),
                        decoration: const InputDecoration(
                          hintText: 'Filter in table...',
                          hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Table Content
          Expanded(
            child: _loading
                ? const ReportTableShimmer(rowCount: 6)
                : _filteredRows.isEmpty
                    ? const Center(
                        child: Text(
                          'No records found for this period',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                            dataRowMinHeight: 38,
                            dataRowMaxHeight: 44,
                            columns: _filteredRows.first.keys.map((k) {
                              return DataColumn(
                                label: Text(
                                  k,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF0F172A)),
                                ),
                              );
                            }).toList(),
                            rows: _filteredRows.map((r) {
                              return DataRow(
                                cells: r.values.map((v) {
                                  return DataCell(
                                    Text(
                                      v?.toString() ?? '',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                                    ),
                                  );
                                }).toList(),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}