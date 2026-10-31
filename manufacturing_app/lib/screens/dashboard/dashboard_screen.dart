import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../providers/app_providers.dart';
import '../../models/dashboard.dart';
import '../../utils/formatters.dart';
import '../../widgets/shimmers/index.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedMonthIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);
    final dashboardAsync = ref.watch(dashboardProvider);

    final companyName = authState.userName != null && authState.userName!.isNotEmpty
        ? authState.userName!
        : 'Apex Manufacturing Ltd';
    final effectiveUser = ref.watch(effectiveUserProvider);
    final userName = effectiveUser.name;
    final userRole = effectiveUser.role;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. App Header (Deep Obsidian Navy #0F172A)
              SliverToBoxAdapter(
                child: _buildAppHeader(
                  context: context,
                  companyName: companyName,
                  userName: userName,
                  userRole: userRole,
                ),
              ),

              // 2. Dashboard Content Body
              SliverToBoxAdapter(
                child: dashboardAsync.when(
                  data: (dashboard) => _buildDashboardBody(
                    context: context,
                    dashboard: dashboard,
                    isDark: isDark,
                    userName: userName,
                  ),
                  loading: () => _buildLoadingState(isDark),
                  error: (error, _) => _buildErrorState(error, isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGuardedRoute(BuildContext context, String route, String moduleName) {
    final effectiveUser = ref.read(effectiveUserProvider);
    if (effectiveUser.canAccessRoute(route)) {
      context.push(route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access to $moduleName is restricted for role "${effectiveUser.role}".'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ===========================================================================
  // 1. App Header (Identical to React Native AppHeader.tsx)
  // ===========================================================================
  Widget _buildAppHeader({
    required BuildContext context,
    required String companyName,
    required String userName,
    required String userRole,
  }) {
    final topInset = MediaQuery.of(context).padding.top;
    final initialLetter = (companyName.isNotEmpty ? companyName[0] : 'A').toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.headerNavy,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Company Brand Title & Role Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.shield_rounded,
                      size: 11,
                      color: Color(0xFF93C5FD),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        '$userName ($userRole)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right: Action Buttons (Search, Notifications, Avatar)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Button
              _buildHeaderGlassButton(
                icon: Icons.search_rounded,
                onTap: () => _showQuickSearchModal(context),
              ),
              const SizedBox(width: 8),

              // Notifications Button
              _buildHeaderGlassButton(
                icon: Icons.notifications_none_rounded,
                onTap: () => context.push('/settings/notifications'),
              ),
              const SizedBox(width: 10),

              // User Avatar Button -> Profile
              InkWell(
                onTap: () => context.go('/profile'),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initialLetter,
                    style: const TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderGlassButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 19, color: Colors.white),
      ),
    );
  }

  // ===========================================================================
  // 2. Dashboard Body (Identical layout to DashboardScreen.tsx)
  // ===========================================================================
  Widget _buildDashboardBody({
    required BuildContext context,
    required DashboardResponse dashboard,
    required bool isDark,
    required String userName,
  }) {
    final kpis = dashboard.kpis;
    final machines = dashboard.machines;
    final attendance = dashboard.attendance;
    final monthlyData = dashboard.monthlyData;
    final activities = dashboard.recentActivities;

    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final openAlerts = (kpis.machineStatusCounts['BREAKDOWN'] ?? machines.breakdown) +
        (kpis.machineStatusCounts['MAINTENANCE'] ?? machines.maintenance);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2. Greeting Header with Factory Watermark
          _buildGreetingContainer(
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            userName: userName,
          ),
          const SizedBox(height: 16),

          // 3. Top 4 KPI Metric Cards in a Horizontal Row
          _buildKpiScrollRow(
            context: context,
            kpis: kpis,
            machines: machines,
            openAlerts: openAlerts,
            isDark: isDark,
          ),
          const SizedBox(height: 16),

          // 4. Production Progress Card
          _buildProductionProgressSection(
            context: context,
            kpis: kpis,
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 16),

          // 5. Machine Status (Full Width 4-Cell Row)
          _buildMachineStatusSection(
            context: context,
            machines: machines,
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 16),

          // 6. Today's Activity (Full Width Row-Wise)
          _buildTodayActivitySection(
            context: context,
            activities: activities,
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 16),

          // 7. Monthly Production Trend (Interactive Bar Graph & Modal)
          _buildMonthlyTrendSection(
            context: context,
            monthlyData: monthlyData,
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          const SizedBox(height: 16),

          // 8. Bottom Two Wide Cards: Attendance Overview & Pending Tasks
          _buildBottomWideCards(
            context: context,
            attendance: attendance,
            pendingTasksCount: dashboard.pendingTasksCount,
            isDark: isDark,
            surfaceColor: surfaceColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Greeting Header with Factory Watermark
  // ===========================================================================
  Widget _buildGreetingContainer({
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
    required String userName,
  }) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    final dateFormatted = DateFormat('EEE, d MMM y').format(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Factory Skyline Silhouette Watermark (Custom Painted)
            Positioned(
              right: 0,
              bottom: -5,
              child: CustomPaint(
                size: const Size(130, 80),
                painter: FactorySkylinePainter(
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('👋', style: TextStyle(fontSize: 22)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Here's today's plant summary",
                          style: TextStyle(
                            fontSize: 12.5,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Date Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 13,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          dateFormatted,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Top 4 KPI Metric Cards in a Horizontal Scrollable Row
  // ===========================================================================
  Widget _buildKpiScrollRow({
    required BuildContext context,
    required DashboardKpis kpis,
    required MachineStats machines,
    required int openAlerts,
    required bool isDark,
  }) {
    final produced = kpis.produced.round();
    final target = kpis.target.round();
    final achievementPct = target > 0 ? ((produced / target) * 100).round() : 0;
    final qualityRate = kpis.qualityRate.round();
    final runningMachines = machines.running;
    final totalMachines = machines.total;
    final breakdownMachines = machines.breakdown;

    final cards = [
      // Card 1: Today's Output
      _buildSingleKpiCard(
        bgColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4),
        borderColor: isDark ? const Color(0xFF14532D) : const Color(0xFFBBF7D0),
        iconBg: isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7),
        icon: Icons.business_rounded,
        iconColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
        label: "Today's Output",
        labelColor: isDark ? const Color(0xFF86EFAC) : const Color(0xFF64748B),
        valueText: '$produced',
        valueSubText: ' / $target',
        footText: '$achievementPct% Achieved',
        footColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
        progressFraction: (achievementPct / 100.0).clamp(0.0, 1.0),
        progressFillColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
        textColor: isDark ? const Color(0xFFF0FDF4) : const Color(0xFF0F172A),
        subTextColor: isDark ? const Color(0xFFBBF7D0) : const Color(0xFF64748B),
        onTap: () => _navigateToGuardedRoute(context, '/production/floor', 'Production Floor'),
      ),

      // Card 2: Quality Rate
      _buildSingleKpiCard(
        bgColor: isDark ? const Color(0xFF172554) : const Color(0xFFF0F9FF),
        borderColor: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBAE6FD),
        iconBg: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFE0F2FE),
        icon: Icons.disc_full_rounded,
        iconColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        label: 'Quality Rate',
        labelColor: isDark ? const Color(0xFF93C5FD) : const Color(0xFF64748B),
        valueText: '$qualityRate%',
        valueSubText: '',
        footText: 'Good',
        footColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        progressFraction: (qualityRate / 100.0).clamp(0.0, 1.0),
        progressFillColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
        textColor: isDark ? const Color(0xFFF0F9FF) : const Color(0xFF0F172A),
        subTextColor: isDark ? const Color(0xFFBAE6FD) : const Color(0xFF64748B),
        onTap: () => _navigateToGuardedRoute(context, '/quality', 'Quality Control'),
      ),

      // Card 3: Active Machines
      _buildSingleKpiCard(
        bgColor: isDark ? const Color(0xFF3B0764) : const Color(0xFFFAF5FF),
        borderColor: isDark ? const Color(0xFF581C87) : const Color(0xFFE9D5FF),
        iconBg: isDark ? const Color(0xFF2E1065) : const Color(0xFFF3E8FF),
        icon: Icons.memory_rounded,
        iconColor: isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED),
        label: 'Active Machines',
        labelColor: isDark ? const Color(0xFFD8B4FE) : const Color(0xFF64748B),
        valueText: '$runningMachines',
        valueSubText: ' / $totalMachines',
        footText: '$breakdownMachines Breakdown',
        footColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
        progressFraction: totalMachines > 0 ? (runningMachines / totalMachines).clamp(0.0, 1.0) : 0.0,
        progressFillColor: isDark ? const Color(0xFFC084FC) : const Color(0xFF7C3AED),
        textColor: isDark ? const Color(0xFFFAF5FF) : const Color(0xFF0F172A),
        subTextColor: isDark ? const Color(0xFFE9D5FF) : const Color(0xFF64748B),
        onTap: () => _navigateToGuardedRoute(context, '/machines', 'Machines Telemetry'),
      ),

      // Card 4: Open Alerts
      _buildSingleKpiCard(
        bgColor: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
        borderColor: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
        iconBg: isDark ? const Color(0xFF300808) : const Color(0xFFFEE2E2),
        icon: Icons.notifications_active_rounded,
        iconColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
        label: 'Open Alerts',
        labelColor: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF64748B),
        valueText: '$openAlerts',
        valueSubText: '',
        footText: 'Need Attention',
        footColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
        progressFraction: (openAlerts * 0.25).clamp(0.0, 1.0),
        progressFillColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
        textColor: isDark ? const Color(0xFFFEF2F2) : const Color(0xFF0F172A),
        subTextColor: isDark ? const Color(0xFFFECACA) : const Color(0xFF64748B),
        onTap: () => context.push('/tasks'),
      ),
    ];

    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) => cards[index],
      ),
    );
  }

  Widget _buildSingleKpiCard({
    required Color bgColor,
    required Color borderColor,
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required String valueText,
    required String valueSubText,
    required String footText,
    required Color footColor,
    required double progressFraction,
    required Color progressFillColor,
    required Color textColor,
    required Color subTextColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor),
      ),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.03),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 130,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 17, color: iconColor),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: valueText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (valueSubText.isNotEmpty)
                          TextSpan(
                            text: valueSubText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: subTextColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    footText,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: footColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      height: 4,
                      color: Colors.black.withValues(alpha: 0.06),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progressFraction,
                        child: Container(color: progressFillColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. Production Progress Section (Gauge + Meta + Delta Pill)
  // ===========================================================================
  Widget _buildProductionProgressSection({
    required BuildContext context,
    required DashboardKpis kpis,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final produced = kpis.produced.round();
    final target = kpis.target.round();
    final achievementPct = target > 0 ? ((produced / target) * 100).round() : 0;
    final qualityRate = kpis.qualityRate.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Production Progress',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.1,
              ),
            ),
            InkWell(
              onTap: () => _navigateToGuardedRoute(context, '/production/floor', 'Production Floor'),
              child: const Row(
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Circular Ring Gauge (Identical to CircularProgress.tsx)
              CircularProgressGauge(
                percent: achievementPct.toDouble(),
                size: 68,
                strokeWidth: 6.5,
                isDark: isDark,
                textColor: textColor,
              ),
              const SizedBox(width: 14),

              // Middle Meta Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Target',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target: $target pcs   |   Produced: $produced pcs',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quality Rate: $qualityRate%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),

              // Delta Pill
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: achievementPct >= 100
                          ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                          : achievementPct > 0
                              ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF))
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$achievementPct%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: achievementPct >= 100
                            ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF10B981))
                            : achievementPct > 0
                                ? (isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB))
                                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Achieved',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. Machine Status (Full Width 4-Cell Row)
  // ===========================================================================
  Widget _buildMachineStatusSection({
    required BuildContext context,
    required MachineStats machines,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Machine Status',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.1,
              ),
            ),
            InkWell(
              onTap: () => _navigateToGuardedRoute(context, '/machines', 'Machines Telemetry'),
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Running
              _buildMachineCell(
                icon: Icons.play_circle_filled_rounded,
                iconColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                count: machines.running,
                countColor: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                label: 'Running',
                labelColor: isDark ? const Color(0xFFA7F3D0) : const Color(0xFF64748B),
                bgColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4),
                borderColor: isDark ? const Color(0xFF14532D) : const Color(0xFFBBF7D0),
                onTap: () => context.push('/machines'),
              ),
              const SizedBox(width: 8),

              // Breakdown
              _buildMachineCell(
                icon: Icons.error_rounded,
                iconColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                count: machines.breakdown,
                countColor: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
                label: 'Breakdown',
                labelColor: isDark ? const Color(0xFFFECACA) : const Color(0xFF64748B),
                bgColor: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                borderColor: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECACA),
                onTap: () => context.push('/machines'),
              ),
              const SizedBox(width: 8),

              // Maintenance
              _buildMachineCell(
                icon: Icons.build_rounded,
                iconColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                count: machines.maintenance,
                countColor: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
                label: 'Maintenance',
                labelColor: isDark ? const Color(0xFFFDE68A) : const Color(0xFF64748B),
                bgColor: isDark ? const Color(0xFF78350F) : const Color(0xFFFFFBEB),
                borderColor: isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A),
                onTap: () => context.push('/machines'),
              ),
              const SizedBox(width: 8),

              // Total
              _buildMachineCell(
                icon: Icons.power_settings_new_rounded,
                iconColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                count: machines.total,
                countColor: textColor,
                label: 'Total',
                labelColor: secondaryTextColor,
                bgColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                onTap: () => context.push('/machines'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMachineCell({
    required IconData icon,
    required Color iconColor,
    required int count,
    required Color countColor,
    required String label,
    required Color labelColor,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: countColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 6. Today's Activity (Full Width Row-Wise)
  // ===========================================================================
  Widget _buildTodayActivitySection({
    required BuildContext context,
    required List<Activity> activities,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's Activity",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.1,
              ),
            ),
            InkWell(
              onTap: () => context.push('/tasks'),
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: activities.isNotEmpty
              ? Column(
                  children: activities.take(4).map((act) {
                    final isLast = act == activities.take(4).last;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                ),
                              ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: act.dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              act.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            act.displayTime,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.access_time_rounded, size: 24, color: secondaryTextColor),
                        const SizedBox(height: 6),
                        Text(
                          'No recent activity',
                          style: TextStyle(fontSize: 13, color: secondaryTextColor),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 7. Monthly Production Trend (Interactive Bar Graph & Modal)
  // ===========================================================================
  Widget _buildMonthlyTrendSection({
    required BuildContext context,
    required List<MonthlyData> monthlyData,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final maxVal = monthlyData.isNotEmpty
        ? monthlyData.map((m) => m.produced).reduce((a, b) => a > b ? a : b).toDouble()
        : 100.0;
    final graphMax = maxVal > 0 ? maxVal * 1.15 : 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Monthly Production Trend',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textColor,
                letterSpacing: -0.1,
              ),
            ),
            InkWell(
              onTap: () => _showMachineOutputModal(context, monthlyData, isDark, surfaceColor, borderColor, textColor, secondaryTextColor),
              child: const Row(
                children: [
                  Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: SizedBox(
            height: 125,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthlyData.asMap().entries.map((entry) {
                final idx = entry.key;
                final m = entry.value;
                final isSelected = idx == _selectedMonthIndex;
                final heightFraction = m.produced > 0
                    ? (m.produced / graphMax).clamp(0.08, 1.0)
                    : 0.0;

                final displayVal = m.produced >= 1000
                    ? '${(m.produced / 1000).round()}k'
                    : '${m.produced}';

                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedMonthIndex = idx),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          displayVal,
                          style: TextStyle(
                            fontSize: isSelected ? 11 : 10,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? textColor : secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 28,
                          height: 70,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: heightFraction,
                            widthFactor: 1.0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBAE6FD)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m.month,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? const Color(0xFF2563EB) : secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 8. Bottom Two Wide Cards (Attendance Overview & Pending Tasks)
  // ===========================================================================
  Widget _buildBottomWideCards({
    required BuildContext context,
    required AttendanceStats attendance,
    required int pendingTasksCount,
    required bool isDark,
    required Color surfaceColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Row(
      children: [
        // Attendance Overview
        Expanded(
          child: Material(
            color: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: borderColor),
            ),
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.03),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _navigateToGuardedRoute(context, '/staff', 'Staff & Attendance Roster'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x337C3AED) : AppColors.moduleStaffBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.people_rounded, size: 18, color: AppColors.moduleStaff),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Attendance',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${attendance.rate}%',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF16A34A),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${attendance.present} / ${attendance.total} Staff Present',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Pending Tasks
        Expanded(
          child: Material(
            color: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: borderColor),
            ),
            elevation: 1,
            shadowColor: Colors.black.withValues(alpha: 0.03),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.push('/tasks'),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.check_box_rounded, size: 18, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending Tasks',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 1),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$pendingTasksCount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10.5,
                                    color: textColor,
                                  ),
                                ),
                                TextSpan(
                                  text: ' items to handle',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Machine Output Details Modal
  // ===========================================================================
  void _showMachineOutputModal(
    BuildContext context,
    List<MonthlyData> monthlyData,
    bool isDark,
    Color surfaceColor,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    if (monthlyData.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final curMonth = monthlyData[_selectedMonthIndex.clamp(0, monthlyData.length - 1)];

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.memory_rounded, color: Color(0xFF0284C7), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Machine Output Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                            Text(
                              'Production volume for ${curMonth.month} ${curMonth.year}',
                              style: TextStyle(fontSize: 12, color: secondaryTextColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Month Switcher Chips
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: monthlyData.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, idx) {
                      final active = idx == _selectedMonthIndex;
                      return InkWell(
                        onTap: () {
                          setModalState(() => _selectedMonthIndex = idx);
                          setState(() => _selectedMonthIndex = idx);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF2563EB)
                                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            monthlyData[idx].month,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                              color: active
                                  ? Colors.white
                                  : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Total Summary Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3B82F6) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Items Created in ${curMonth.month} ${curMonth.year}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${Formatters.formatNumber(curMonth.produced)} pcs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFFEFF6FF) : const Color(0xFF1D4ED8),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${curMonth.pct}% Target',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // Quick Search Dialog
  // ===========================================================================
  void _showQuickSearchModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quick Navigation', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.precision_manufacturing_rounded, color: Color(0xFF2563EB)),
              title: const Text('Production Orders'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/production/orders');
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_rounded, color: Color(0xFF059669)),
              title: const Text('Inventory & Stock'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/inventory');
              },
            ),
            ListTile(
              leading: const Icon(Icons.hardware_rounded, color: Color(0xFF7C3AED)),
              title: const Text('Machine Fleet'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/machines');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_rounded, color: Color(0xFFD97706)),
              title: const Text('Staff & Attendance'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/staff');
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Loading & Error States
  // ===========================================================================
  Widget _buildLoadingState(bool isDark) {
    return const DashboardShimmer();
  }

  Widget _buildErrorState(Object error, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 54, color: Color(0xFFDC2626)),
            const SizedBox(height: 14),
            Text(
              'Unable to load live dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              onPressed: () => ref.invalidate(dashboardProvider),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry Connection'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Circular Ring Gauge (Faithfully replicates CircularProgress in DashboardScreen.tsx)
// =============================================================================
class CircularProgressGauge extends StatelessWidget {
  final double percent;
  final double size;
  final double strokeWidth;
  final bool isDark;
  final Color textColor;

  const CircularProgressGauge({
    super.key,
    required this.percent,
    this.size = 68,
    this.strokeWidth = 6.5,
    this.isDark = false,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final intPercent = percent.round().clamp(0, 100);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: intPercent / 100.0,
              strokeWidth: strokeWidth,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
            ),
          ),
          Text(
            '$intPercent%',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Factory Skyline Watermark Custom Painter
// =============================================================================
class FactorySkylinePainter extends CustomPainter {
  final Color color;

  FactorySkylinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final path1 = Path()
      ..moveTo(size.width * 0.08, size.height)
      ..lineTo(size.width * 0.08, size.height * 0.56)
      ..lineTo(size.width * 0.25, size.height * 0.69)
      ..lineTo(size.width * 0.25, size.height * 0.56)
      ..lineTo(size.width * 0.42, size.height * 0.69)
      ..lineTo(size.width * 0.42, size.height * 0.44)
      ..lineTo(size.width * 0.58, size.height * 0.44)
      ..lineTo(size.width * 0.58, size.height)
      ..close();
    canvas.drawPath(path1, paint1);

    final paint2 = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(size.width * 0.58, size.height)
      ..lineTo(size.width * 0.58, size.height * 0.31)
      ..lineTo(size.width * 0.70, size.height * 0.31)
      ..lineTo(size.width * 0.70, size.height)
      ..close();
    canvas.drawPath(path2, paint2);

    final path3 = Path()
      ..moveTo(size.width * 0.74, size.height)
      ..lineTo(size.width * 0.74, size.height * 0.5)
      ..lineTo(size.width * 0.88, size.height * 0.62)
      ..lineTo(size.width * 0.88, size.height * 0.38)
      ..lineTo(size.width * 1.0, size.height * 0.38)
      ..lineTo(size.width * 1.0, size.height)
      ..close();
    canvas.drawPath(path3, paint1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}