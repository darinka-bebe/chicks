import 'package:flutter/material.dart';

import '../../../core/models/weather_snapshot.dart';
import '../../../core/theme/app_brand_colors.dart';

/// Live weather chip for chat header or above stylist replies.
class ChatWeatherBanner extends StatelessWidget {
  const ChatWeatherBanner({
    super.key,
    this.weather,
    this.label,
    this.compact = false,
  }) : assert(weather != null || label != null);

  final WeatherSnapshot? weather;
  final String? label;
  final bool compact;

  String get _displayLabel {
    if (label != null && label!.isNotEmpty) return label!;
    return weather?.compactUiLabel ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final text = _displayLabel;
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppBrandColors.pink.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: AppBrandColors.pink.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_outlined,
                  size: 15,
                  color: AppBrandColors.pink.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11.5 : 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppBrandColors.title.withValues(alpha: 0.8),
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
