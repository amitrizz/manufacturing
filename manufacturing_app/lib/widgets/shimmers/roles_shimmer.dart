import 'package:flutter/material.dart';
import 'shimmer_core.dart';

/// Bespoke Shimmer Skeleton for RolesScreen (Roles & Access)
class RolesScreenShimmer extends StatelessWidget {
  const RolesScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Search + Add User Button Row
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 42, borderRadius: 10)),
              SizedBox(width: 10),
              ShimmerBox(width: 105, height: 42, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 16),

          // User Role Cards
          ...List.generate(5, (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
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
                          ShimmerBox(width: 110, height: 16, borderRadius: 4),
                          SizedBox(width: 8),
                          ShimmerBox(width: 60, height: 16, borderRadius: 10),
                        ],
                      ),
                      SizedBox(height: 6),
                      ShimmerBox(width: 170, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
                ShimmerBox(width: 24, height: 24, borderRadius: 12),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

/// Bespoke Shimmer Skeleton for NotificationsScreen (Alerts & Notifications)
class NotificationsScreenShimmer extends StatelessWidget {
  const NotificationsScreenShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Filter Chips (All, Unread, High Priority)
          Row(
            children: List.generate(
              3,
              (i) => Container(
                margin: const EdgeInsets.only(right: 8),
                child: const ShimmerBox(width: 80, height: 32, borderRadius: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notification Alert Cards
          ...List.generate(5, (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 36, height: 36, borderRadius: 18),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ShimmerBox(width: 130, height: 15, borderRadius: 4),
                          ShimmerBox(width: 50, height: 11, borderRadius: 4),
                        ],
                      ),
                      SizedBox(height: 6),
                      ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                      SizedBox(height: 4),
                      ShimmerBox(width: 160, height: 12, borderRadius: 4),
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
