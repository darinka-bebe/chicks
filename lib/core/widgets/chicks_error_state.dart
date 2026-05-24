import 'package:flutter/material.dart';

import '../theme/app_brand_colors.dart';

/// Error state with optional retry — non-blocking, friendly copy.
class ChicksErrorState extends StatelessWidget {
  const ChicksErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 20 : 32,
          vertical: compact ? 16 : 24,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: compact ? 36 : 44,
              color: AppBrandColors.pink.withValues(alpha: 0.65),
            ),
            SizedBox(height: compact ? 12 : 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 14 : 15,
                color: Colors.grey[700],
                height: 1.45,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: compact ? 16 : 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Повторить'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppBrandColors.pink,
                  side: BorderSide(
                    color: AppBrandColors.pink.withValues(alpha: 0.45),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Wraps empty/error content so [RefreshIndicator] works on short lists.
class ChicksRefreshableScroll extends StatelessWidget {
  const ChicksRefreshableScroll({
    super.key,
    required this.onRefresh,
    required this.child,
    this.padding,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppBrandColors.pink,
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
