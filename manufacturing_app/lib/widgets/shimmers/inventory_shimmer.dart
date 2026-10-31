import 'package:flutter/material.dart';
import 'shimmer_core.dart';

/// Bespoke Shimmer Skeleton for Stock Inventory (InventoryScreen)
class StockInventoryShimmer extends StatelessWidget {
  const StockInventoryShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Segment Switcher (Raw & Components vs Ledger)
          const ShimmerBox(height: 40, borderRadius: 10),
          const SizedBox(height: 12),

          // Search + Add Item + Update Buttons Row
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 40, borderRadius: 8)),
              SizedBox(width: 8),
              ShimmerBox(width: 75, height: 40, borderRadius: 8),
              SizedBox(width: 6),
              ShimmerBox(width: 80, height: 40, borderRadius: 8),
            ],
          ),
          const SizedBox(height: 16),

          // Material Item Skeletons
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ShimmerBox(width: 70, height: 14, borderRadius: 4),
                          SizedBox(width: 8),
                          ShimmerBox(width: 65, height: 14, borderRadius: 4),
                        ],
                      ),
                      SizedBox(height: 6),
                      ShimmerBox(width: 170, height: 16, borderRadius: 4),
                      SizedBox(height: 6),
                      ShimmerBox(width: 130, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShimmerBox(width: 65, height: 20, borderRadius: 6),
                    SizedBox(height: 6),
                    ShimmerBox(width: 45, height: 12, borderRadius: 4),
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

/// Bespoke Shimmer Skeleton for FinishedGoodsScreen
class FinishedGoodsShimmer extends StatelessWidget {
  const FinishedGoodsShimmer({super.key});

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

          // Quick Filter Chips
          Row(
            children: List.generate(
              3,
              (i) => Container(
                margin: const EdgeInsets.only(right: 8),
                child: const ShimmerBox(width: 85, height: 30, borderRadius: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Finished Goods Cards
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
                    ShimmerBox(width: 80, height: 18, borderRadius: 12),
                  ],
                ),
                SizedBox(height: 8),
                ShimmerBox(width: 200, height: 18, borderRadius: 5),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 120, height: 14, borderRadius: 4),
                    ShimmerBox(width: 70, height: 14, borderRadius: 4),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 100, height: 14, borderRadius: 4),
                    ShimmerBox(width: 110, height: 32, borderRadius: 8),
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
