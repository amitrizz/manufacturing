import 'package:flutter/material.dart';

/// High-performance animated gradient shimmer wrapper
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

/// Generic rounded skeleton box with configurable width, height, and radius
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

/// Reusable KPI metric card row skeleton (matches standard 4-column KPI cards)
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
                    ShimmerBox(width: 38, height: 10, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: 54, height: 18, borderRadius: 5),
                    SizedBox(height: 6),
                    ShimmerBox(width: 44, height: 8, borderRadius: 4),
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
