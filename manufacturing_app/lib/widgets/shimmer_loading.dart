import 'package:flutter/material.dart';

/// Core animated gradient shimmer effect
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;

  const AppShimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1400),
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = widget.baseColor ?? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));
    final highlight = widget.highlightColor ?? (isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2.6 - 0.8), 0, 0);
  }
}

/// Generic rounded skeleton box
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
    this.margin,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = color ?? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer card skeleton
class ShimmerCard extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry margin;
  final bool hasProgressBar;

  const ShimmerCard({
    super.key,
    this.height = 110,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.hasProgressBar = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: height,
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 90, height: 16, borderRadius: 6),
              ShimmerBox(width: 65, height: 16, borderRadius: 6),
            ],
          ),
          const SizedBox(height: 8),
          const ShimmerBox(width: 200, height: 18, borderRadius: 6),
          const SizedBox(height: 6),
          if (hasProgressBar) ...[
            const ShimmerBox(width: double.infinity, height: 6, borderRadius: 3),
            const SizedBox(height: 6),
          ],
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShimmerBox(width: 80, height: 12, borderRadius: 4),
              ShimmerBox(width: 100, height: 12, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

/// List of ShimmerCards
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double cardHeight;
  final EdgeInsetsGeometry padding;
  final bool hasProgressBar;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    this.cardHeight = 110,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.hasProgressBar = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        itemBuilder: (context, index) => ShimmerCard(
          height: cardHeight,
          hasProgressBar: hasProgressBar,
        ),
      ),
    );
  }
}

/// Row of 4 KPI Metric Cards Skeleton
class ShimmerKpiRow extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;

  const ShimmerKpiRow({
    super.key,
    this.count = 4,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppShimmer(
      child: Padding(
        padding: padding,
        child: Row(
          children: List.generate(count, (index) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == count - 1 ? 0 : 8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 35, height: 10, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: 55, height: 18, borderRadius: 5),
                    SizedBox(height: 6),
                    ShimmerBox(width: 45, height: 8, borderRadius: 4),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Grid of shimmer cards (for machines, floor lines, or modules)
class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  const ShimmerGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.3,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppShimmer(
      child: GridView.builder(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: childAspectRatio,
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
                    ShimmerBox(width: 34, height: 34, borderRadius: 8),
                    ShimmerBox(width: 52, height: 16, borderRadius: 6),
                  ],
                ),
                ShimmerBox(width: 110, height: 14, borderRadius: 4),
                ShimmerBox(width: 70, height: 12, borderRadius: 4),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Full dashboard page shimmer skeleton
class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Welcome / Target Hero Banner
            Container(
              height: 120,
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
                      ShimmerBox(width: 130, height: 16, borderRadius: 6),
                      ShimmerBox(width: 65, height: 20, borderRadius: 6),
                    ],
                  ),
                  ShimmerBox(width: double.infinity, height: 8, borderRadius: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerBox(width: 90, height: 12, borderRadius: 4),
                      ShimmerBox(width: 80, height: 12, borderRadius: 4),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4 KPI Metric Cards
            const Row(
              children: [
                Expanded(child: ShimmerBox(height: 80, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 80, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 80, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 80, borderRadius: 10)),
              ],
            ),
            const SizedBox(height: 18),

            // Production Line Progress Card
            Container(
              height: 150,
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
                  ShimmerBox(width: 140, height: 16, borderRadius: 6),
                  ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                  ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                  ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Machines Fleet Summary
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerBox(width: 120, height: 18, borderRadius: 6),
                ShimmerBox(width: 60, height: 14, borderRadius: 4),
              ],
            ),
            const SizedBox(height: 10),
            const Row(
              children: [
                Expanded(child: ShimmerBox(height: 70, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 70, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 70, borderRadius: 10)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 70, borderRadius: 10)),
              ],
            ),
            const SizedBox(height: 18),

            // Recent Activity Skeletons
            const ShimmerBox(width: 130, height: 18, borderRadius: 6),
            const SizedBox(height: 10),
            ...List.generate(3, (_) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: ShimmerBox(height: 60, borderRadius: 10),
            )),
          ],
        ),
      ),
    );
  }
}

/// Detail page shimmer skeleton (e.g., machine details, maintenance details)
class ShimmerDetail extends StatelessWidget {
  const ShimmerDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Header Card
          Container(
            height: 130,
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
                    ShimmerBox(width: 110, height: 18, borderRadius: 6),
                    ShimmerBox(width: 70, height: 20, borderRadius: 6),
                  ],
                ),
                ShimmerBox(width: 190, height: 14, borderRadius: 4),
                ShimmerBox(width: 140, height: 12, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Specs Grid Skeletons
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

          // Details List
          const ShimmerBox(width: 120, height: 16, borderRadius: 6),
          const SizedBox(height: 10),
          ...List.generate(4, (_) => const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: ShimmerBox(height: 52, borderRadius: 8),
          )),
        ],
      ),
    );
  }
}
