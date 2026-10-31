import 'package:flutter/material.dart';
import 'shimmer_core.dart';

/// Pixel-perfect bespoke shimmer skeleton for DashboardScreen
class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Target Hero Banner
            Container(
              height: 125,
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
                      ShimmerBox(width: 140, height: 16, borderRadius: 6),
                      ShimmerBox(width: 70, height: 22, borderRadius: 6),
                    ],
                  ),
                  ShimmerBox(width: double.infinity, height: 8, borderRadius: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBox(width: 95, height: 12, borderRadius: 4),
                      ShimmerBox(width: 85, height: 12, borderRadius: 4),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. 4 Top KPI Cards
            const Row(
              children: [
                Expanded(child: ShimmerBox(height: 82, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 82, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 82, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 82, borderRadius: 10)),
              ],
            ),
            const SizedBox(height: 18),

            // 3. Shop Floor Line Progress Card
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
                      ShimmerBox(width: 150, height: 16, borderRadius: 6),
                      ShimmerBox(width: 60, height: 14, borderRadius: 4),
                    ],
                  ),
                  SizedBox(height: 14),
                  ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
                  SizedBox(height: 10),
                  ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
                  SizedBox(height: 10),
                  ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 4. Machine Fleet Status 4-Card Grid
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 130, height: 18, borderRadius: 6),
                ShimmerBox(width: 65, height: 14, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 20),

            // 5. Recent Activity Stream
            const ShimmerBox(width: 140, height: 18, borderRadius: 6),
            const SizedBox(height: 12),
            ...List.generate(4, (_) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  ShimmerBox(width: 10, height: 10, borderRadius: 5),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShimmerBox(width: 160, height: 14, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 210, height: 11, borderRadius: 4),
                      ],
                    ),
                  ),
                  ShimmerBox(width: 50, height: 10, borderRadius: 4),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
