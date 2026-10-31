import 'package:flutter/material.dart';
import 'shimmer_core.dart';

/// Bespoke Shimmer Skeleton for ProductsScreen (Products Catalog)
class ProductsCatalogShimmer extends StatelessWidget {
  const ProductsCatalogShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Search Bar + Add Product Button
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 42, borderRadius: 10)),
              SizedBox(width: 10),
              ShimmerBox(width: 110, height: 42, borderRadius: 10),
            ],
          ),
          const SizedBox(height: 12),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: List.generate(
                4,
                (i) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: const ShimmerBox(width: 90, height: 32, borderRadius: 20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Product Cards
          ...List.generate(5, (_) => Container(
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
                    Row(
                      children: [
                        ShimmerBox(width: 80, height: 16, borderRadius: 4),
                        SizedBox(width: 8),
                        ShimmerBox(width: 70, height: 16, borderRadius: 12),
                      ],
                    ),
                    ShimmerBox(width: 24, height: 24, borderRadius: 12),
                  ],
                ),
                SizedBox(height: 8),
                ShimmerBox(width: 210, height: 17, borderRadius: 5),
                SizedBox(height: 6),
                ShimmerBox(width: 160, height: 12, borderRadius: 4),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ShimmerBox(width: 90, height: 14, borderRadius: 4),
                    ShimmerBox(width: 115, height: 32, borderRadius: 8),
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

/// Bespoke Shimmer Skeleton for ProductBomScreen (Bill of Materials)
class ProductBomShimmer extends StatelessWidget {
  const ProductBomShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // Product Selector Dropdown Skeleton
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 80, height: 11, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 180, height: 16, borderRadius: 4),
                  ],
                ),
                ShimmerBox(width: 20, height: 20, borderRadius: 10),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Total Formula Summary Row
          const Row(
            children: [
              Expanded(child: ShimmerBox(height: 64, borderRadius: 8)),
              SizedBox(width: 8),
              Expanded(child: ShimmerBox(height: 64, borderRadius: 8)),
              SizedBox(width: 8),
              Expanded(child: ShimmerBox(height: 64, borderRadius: 8)),
            ],
          ),
          const SizedBox(height: 18),

          const ShimmerBox(width: 140, height: 16, borderRadius: 4),
          const SizedBox(height: 10),

          // BOM Component Rows
          ...List.generate(5, (_) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 75, height: 14, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 160, height: 15, borderRadius: 4),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ShimmerBox(width: 65, height: 18, borderRadius: 6),
                    SizedBox(height: 6),
                    ShimmerBox(width: 50, height: 11, borderRadius: 4),
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
