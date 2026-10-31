import 'package:flutter/material.dart';
import 'shimmer_core.dart';

/// Bespoke Shimmer Skeleton for MachinesScreen
class MachinesScreenShimmer extends StatelessWidget {
  const MachinesScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 4 Machine Status Cards (Running, Breakdown, Maintenance, Idle)
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

          // Search + Line Filter Row
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 42, borderRadius: 10)),
              SizedBox(width: 10),
              ShimmerBox(width: 100, height: 42, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 16),

          // Machine Cards Grid (2-column)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBox(width: 32, height: 32, borderRadius: 8),
                        ShimmerBox(width: 55, height: 16, borderRadius: 10),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 80, height: 13, borderRadius: 4),
                        SizedBox(height: 4),
                        ShimmerBox(width: 110, height: 15, borderRadius: 4),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerBox(width: 50, height: 11, borderRadius: 4),
                        ShimmerBox(width: 35, height: 11, borderRadius: 4),
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
}

/// Bespoke Shimmer Skeleton for MachineDetailScreen
class MachineDetailShimmer extends StatelessWidget {
  const MachineDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Machine Profile Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 140, height: 20, borderRadius: 6),
                    ShimmerBox(width: 75, height: 22, borderRadius: 12),
                  ],
                ),
                SizedBox(height: 8),
                ShimmerBox(width: 220, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 160, height: 12, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4 Performance Metrics (OEE, Availability, Hours, MTBF)
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 72, borderRadius: 10)),
              SizedBox(width: 8),
              Expanded(child: ShimmerBox(height: 72, borderRadius: 10)),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 72, borderRadius: 10)),
              SizedBox(width: 8),
              Expanded(child: ShimmerBox(height: 72, borderRadius: 10)),
            ],
          ),
          const SizedBox(height: 20),

          // Operating Parameters Card
          const ShimmerBox(width: 150, height: 16, borderRadius: 4),
          const SizedBox(height: 10),
          ...List.generate(3, (_) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 120, height: 14, borderRadius: 4),
                ShimmerBox(width: 70, height: 14, borderRadius: 4),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

/// Bespoke Shimmer Skeleton for MaintenanceScreen
class MaintenanceScreenShimmer extends StatelessWidget {
  const MaintenanceScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 4 KPI Cards
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

          // Priority Filter Chips
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

          // Maintenance Work Order Cards
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
                    ShimmerBox(width: 90, height: 16, borderRadius: 4),
                    ShimmerBox(width: 65, height: 18, borderRadius: 10),
                  ],
                ),
                SizedBox(height: 8),
                ShimmerBox(width: 220, height: 17, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 170, height: 13, borderRadius: 4),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ShimmerBox(width: 22, height: 22, borderRadius: 11),
                        SizedBox(width: 6),
                        ShimmerBox(width: 80, height: 12, borderRadius: 4),
                      ],
                    ),
                    ShimmerBox(width: 85, height: 28, borderRadius: 6),
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

/// Bespoke Shimmer Skeleton for MaintenanceDetailScreen
class MaintenanceDetailShimmer extends StatelessWidget {
  const MaintenanceDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Ticket Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 110, height: 18, borderRadius: 4),
                    ShimmerBox(width: 70, height: 20, borderRadius: 10),
                  ],
                ),
                SizedBox(height: 10),
                ShimmerBox(width: 200, height: 18, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBox(width: 140, height: 13, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stepper Skeleton
          const ShimmerBox(height: 50, borderRadius: 10),
          const SizedBox(height: 16),

          // Parts Checklist
          const ShimmerBox(width: 140, height: 16, borderRadius: 4),
          const SizedBox(height: 10),
          ...List.generate(3, (_) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 130, height: 14, borderRadius: 4),
                ShimmerBox(width: 45, height: 14, borderRadius: 4),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
