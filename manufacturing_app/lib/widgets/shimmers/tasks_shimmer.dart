import 'package:flutter/material.dart';
import 'shimmer_core.dart';

/// Bespoke Shimmer Skeleton for TasksScreen (Tasks & Activity Feed)
class TasksScreenShimmer extends StatelessWidget {
  const TasksScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Segment Switcher (Actionable Tasks vs Activity History)
          const ShimmerBox(height: 40, borderRadius: 10),
          const SizedBox(height: 14),

          // Search + Add Task row
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 40, borderRadius: 8)),
              SizedBox(width: 8),
              ShimmerBox(width: 95, height: 40, borderRadius: 8),
            ],
          ),
          const SizedBox(height: 12),

          // Priority Filter Chips
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

          // Task Item Cards
          ...List.generate(5, (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                ShimmerBox(width: 22, height: 22, borderRadius: 6),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerBox(width: 170, height: 15, borderRadius: 4),
                          ShimmerBox(width: 55, height: 16, borderRadius: 10),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          ShimmerBox(width: 80, height: 12, borderRadius: 4),
                          SizedBox(width: 10),
                          ShimmerBox(width: 70, height: 12, borderRadius: 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
