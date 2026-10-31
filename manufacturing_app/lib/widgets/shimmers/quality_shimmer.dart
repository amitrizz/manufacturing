import 'package:flutter/material.dart';
import 'shimmer_core.dart';

/// Bespoke Shimmer Skeleton for QualityScreen (Quality Control)
class QualityScreenShimmer extends StatelessWidget {
  const QualityScreenShimmer({super.key});

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

          // Search + New Inspection Row
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 42, borderRadius: 10)),
              SizedBox(width: 10),
              ShimmerBox(width: 110, height: 42, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 12),

          // Filter Chips (All, Passed, Failed, Pending)
          Row(
            children: List.generate(
              4,
              (i) => Container(
                margin: const EdgeInsets.only(right: 8),
                child: const ShimmerBox(width: 75, height: 32, borderRadius: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quality Inspection Cards
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
                    ShimmerBox(width: 100, height: 16, borderRadius: 4),
                    ShimmerBox(width: 70, height: 20, borderRadius: 10),
                  ],
                ),
                SizedBox(height: 8),
                ShimmerBox(width: 200, height: 17, borderRadius: 4),
                SizedBox(height: 6),
                Row(
                  children: [
                    ShimmerBox(width: 90, height: 12, borderRadius: 4),
                    SizedBox(width: 8),
                    ShimmerBox(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 110, height: 14, borderRadius: 4),
                    ShimmerBox(width: 80, height: 14, borderRadius: 4),
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
