import 'package:flutter/material.dart';
import 'shimmer_core.dart';

/// Bespoke Shimmer Skeleton for ReportsScreen (Reports & Analytics)
class ReportsScreenShimmer extends StatelessWidget {
  const ReportsScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Report Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: const ShimmerBox(width: 90, height: 34, borderRadius: 18),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Date Range Filter Bar
          const ShimmerBox(height: 44, borderRadius: 10),
          const SizedBox(height: 16),

          // 4 Summary Metrics Cards
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 72, borderRadius: 10)),
              SizedBox(width: 8),
              Expanded(child: ShimmerBox(height: 72, borderRadius: 10)),
              SizedBox(width: 8),
              Expanded(child: ShimmerBox(height: 72, borderRadius: 10)),
              SizedBox(width: 8),
              Expanded(child: ShimmerBox(height: 72, borderRadius: 10)),
            ],
          ),
          const SizedBox(height: 18),

          // Big Analytics Chart Placeholder
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 140, height: 16, borderRadius: 4),
                    ShimmerBox(width: 60, height: 14, borderRadius: 4),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ShimmerBox(width: 28, height: 60, borderRadius: 4),
                    ShimmerBox(width: 28, height: 110, borderRadius: 4),
                    ShimmerBox(width: 28, height: 80, borderRadius: 4),
                    ShimmerBox(width: 28, height: 130, borderRadius: 4),
                    ShimmerBox(width: 28, height: 95, borderRadius: 4),
                    ShimmerBox(width: 28, height: 140, borderRadius: 4),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ShimmerBox(width: 25, height: 10, borderRadius: 2),
                    ShimmerBox(width: 25, height: 10, borderRadius: 2),
                    ShimmerBox(width: 25, height: 10, borderRadius: 2),
                    ShimmerBox(width: 25, height: 10, borderRadius: 2),
                    ShimmerBox(width: 25, height: 10, borderRadius: 2),
                    ShimmerBox(width: 25, height: 10, borderRadius: 2),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Data Breakdown Table Skeleton
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerBox(width: 120, height: 16, borderRadius: 4),
                const SizedBox(height: 12),
                ...List.generate(3, (_) => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBox(width: 110, height: 13, borderRadius: 4),
                      ShimmerBox(width: 60, height: 13, borderRadius: 4),
                      ShimmerBox(width: 50, height: 13, borderRadius: 4),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shimmer Skeleton specifically for Reports Table View
class ReportTableShimmer extends StatelessWidget {
  final int rowCount;
  const ReportTableShimmer({super.key, this.rowCount = 5});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: List.generate(
            rowCount,
            (_) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(flex: 3, child: ShimmerBox(height: 20, borderRadius: 4)),
                  SizedBox(width: 12),
                  Expanded(flex: 2, child: ShimmerBox(height: 20, borderRadius: 4)),
                  SizedBox(width: 12),
                  Expanded(flex: 2, child: ShimmerBox(height: 20, borderRadius: 4)),
                  SizedBox(width: 12),
                  Expanded(flex: 2, child: ShimmerBox(height: 20, borderRadius: 4)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
