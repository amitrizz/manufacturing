import 'package:flutter/material.dart';
import 'shimmer_core.dart';

/// Bespoke Shimmer Skeleton for StaffScreen (Staff & Shifts)
class StaffScreenShimmer extends StatelessWidget {
  const StaffScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 4 Attendance Metric Cards
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

          // Search + Add Staff Row
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 42, borderRadius: 10)),
              SizedBox(width: 10),
              ShimmerBox(width: 100, height: 42, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 12),

          // Department Chips
          Row(
            children: List.generate(
              4,
              (i) => Container(
                margin: const EdgeInsets.only(right: 8),
                child: const ShimmerBox(width: 75, height: 30, borderRadius: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Staff Operator Cards
          ...List.generate(5, (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                ShimmerBox(width: 44, height: 44, borderRadius: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShimmerBox(width: 120, height: 16, borderRadius: 4),
                          SizedBox(width: 8),
                          ShimmerBox(width: 60, height: 16, borderRadius: 10),
                        ],
                      ),
                      SizedBox(height: 6),
                      ShimmerBox(width: 160, height: 12, borderRadius: 4),
                      SizedBox(height: 4),
                      ShimmerBox(width: 90, height: 11, borderRadius: 4),
                    ],
                  ),
                ),
                ShimmerBox(width: 65, height: 26, borderRadius: 8),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
