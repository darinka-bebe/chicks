import 'package:flutter/material.dart';

import '../theme/app_brand_colors.dart';
import '../theme/app_spacing.dart';

/// Soft pulsing placeholder — no external shimmer package.
class ChicksSkeleton extends StatefulWidget {
  const ChicksSkeleton({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  State<ChicksSkeleton> createState() => _ChicksSkeletonState();
}

class _ChicksSkeletonState extends State<ChicksSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.2 + t * 2.4, 0),
              end: Alignment(-0.2 + t * 2.4, 0),
              colors: const [
                Color(0xFFF0E8EC),
                Color(0xFFFCEEF4),
                Color(0xFFF0E8EC),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Two-column wardrobe grid skeleton.
class ChicksWardrobeGridSkeleton extends StatelessWidget {
  const ChicksWardrobeGridSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenHorizontal,
        0,
        AppSpacing.screenHorizontal,
        88,
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => const _WardrobeCardSkeleton(),
    );
  }
}

class _WardrobeCardSkeleton extends StatelessWidget {
  const _WardrobeCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppBrandColors.pink.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ChicksSkeleton(
                height: double.infinity,
                borderRadius: 14,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ChicksSkeleton(width: 80, height: 12, borderRadius: 6),
                SizedBox(height: 8),
                ChicksSkeleton(width: 56, height: 10, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal stat cards skeleton for profile.
class ChicksStatsRowSkeleton extends StatelessWidget {
  const ChicksStatsRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (index) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: AppBrandColors.pink.withValues(alpha: 0.08),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                child: Column(
                  children: [
                    ChicksSkeleton(width: 36, height: 36, borderRadius: 12),
                    SizedBox(height: 10),
                    ChicksSkeleton(width: 32, height: 14, borderRadius: 6),
                    SizedBox(height: 6),
                    ChicksSkeleton(width: 64, height: 10, borderRadius: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// List card skeleton (favorites / history).
class ChicksListCardSkeleton extends StatelessWidget {
  const ChicksListCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppBrandColors.pink.withValues(alpha: 0.08)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            ChicksSkeleton(width: 72, height: 72, borderRadius: 14),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChicksSkeleton(width: double.infinity, height: 14, borderRadius: 6),
                  SizedBox(height: 8),
                  ChicksSkeleton(width: 120, height: 11, borderRadius: 6),
                  SizedBox(height: 8),
                  ChicksSkeleton(width: 80, height: 10, borderRadius: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
