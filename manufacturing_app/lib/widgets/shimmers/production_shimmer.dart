import 'package:flutter/material.dart';
import 'shimmer_core.dart';

/// Bespoke Shimmer Skeleton for ProductionOrdersScreen
class ProductionOrdersShimmer extends StatelessWidget {
  const ProductionOrdersShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 4 Top KPI Cards
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
          const SizedBox(height: 14),

          // Search bar + + New Order button row
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 42, borderRadius: 10)),
              SizedBox(width: 10),
              ShimmerBox(width: 110, height: 42, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 12),

          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: List.generate(
                5,
                (i) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: const ShimmerBox(width: 85, height: 32, borderRadius: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Production Order Cards Skeletons
          ...List.generate(4, (_) => Container(
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
        ],
      ),
    );
  }
}

/// Bespoke Shimmer Skeleton for ProductionPlansScreen
class ProductionPlansShimmer extends StatelessWidget {
  const ProductionPlansShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 4 Top KPI Cards
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
          const SizedBox(height: 14),

          // Search bar
          const ShimmerBox(height: 42, borderRadius: 10),
          const SizedBox(height: 12),

          // Filter chips
          Row(
            children: List.generate(
              4,
              (i) => Container(
                margin: const EdgeInsets.only(right: 8),
                child: const ShimmerBox(width: 80, height: 30, borderRadius: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Plan Cards Skeletons
          ...List.generate(3, (_) => Container(
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
        ],
      ),
    );
  }
}

/// Bespoke Shimmer Skeleton for ProductionFloorScreen
class ProductionFloorShimmer extends StatelessWidget {
  const ProductionFloorShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 4 Top KPI Cards
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
          const SizedBox(height: 14),

          // Period toggle segmented bar
          const ShimmerBox(height: 38, borderRadius: 10),
          const SizedBox(height: 14),

          // Quick Action Bar
          const ShimmerBox(height: 48, borderRadius: 10),
          const SizedBox(height: 16),

          // Floor Line Cards Skeletons
          ...List.generate(3, (_) => Container(
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
                const ShimmerBox(width: double.infinity, height: 50, borderRadius: 8),
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
        ],
      ),
    );
  }
}
