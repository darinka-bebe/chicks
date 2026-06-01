import 'package:equatable/equatable.dart';

import 'weather_condition.dart';

/// Current weather used by the AI stylist and chat UI.
class WeatherSnapshot extends Equatable {
  const WeatherSnapshot({
    required this.isAvailable,
    this.temperatureCelsius,
    this.conditions = const [],
    this.dayPhase,
    this.windSpeedKmh,
    this.fetchedAt,
    this.latitude,
    this.longitude,
    this.cityName,
  });

  final bool isAvailable;
  final double? temperatureCelsius;
  final List<WeatherCondition> conditions;
  final DayPhase? dayPhase;
  final double? windSpeedKmh;
  final DateTime? fetchedAt;
  final double? latitude;
  final double? longitude;
  final String? cityName;

  static const unavailable = WeatherSnapshot(isAvailable: false);

  bool get isCold =>
      temperatureCelsius != null && temperatureCelsius! < 12;

  bool get isHot =>
      temperatureCelsius != null && temperatureCelsius! > 22;

  /// Compact label for chat UI, e.g. «☁️ +12°C • Дождь».
  String get compactUiLabel {
    if (!isAvailable) return '';

    final parts = <String>[];
    final city = cityName?.trim() ?? '';
    if (city.isNotEmpty) {
      parts.add(city);
    }

    final emoji = _primaryEmoji;
    final temp = temperatureCelsius;
    if (temp != null) {
      final rounded = temp.round();
      final sign = rounded > 0 ? '+' : '';
      parts.add('$emoji $sign$rounded°C');
    } else if (emoji.isNotEmpty) {
      parts.add(emoji);
    }

    final summary = _conditionsSummaryRu;
    if (summary.isNotEmpty) {
      parts.add(summary);
    }

    return parts.join(' • ');
  }

  String get _primaryEmoji {
    if (conditions.contains(WeatherCondition.snowy)) return '❄️';
    if (conditions.contains(WeatherCondition.rainy)) return '🌧️';
    if (conditions.contains(WeatherCondition.sunny)) return '☀️';
    if (conditions.contains(WeatherCondition.windy)) return '💨';
    if (conditions.contains(WeatherCondition.foggy)) return '🌫️';
    if (conditions.contains(WeatherCondition.cloudy)) return '☁️';
    return '🌤️';
  }

  String get _conditionsSummaryRu {
    if (conditions.isEmpty) return '';

    final labels = <String>[];
    for (final condition in conditions) {
      labels.add(_labelRu(condition));
    }
    return labels.take(2).join(', ');
  }

  static String _labelRu(WeatherCondition condition) {
    return switch (condition) {
      WeatherCondition.sunny => 'Солнечно',
      WeatherCondition.cloudy => 'Облачно',
      WeatherCondition.rainy => 'Дождь',
      WeatherCondition.snowy => 'Снег',
      WeatherCondition.windy => 'Ветер',
      WeatherCondition.foggy => 'Туман',
    };
  }

  static String dayPhaseRu(DayPhase? phase) {
    return switch (phase) {
      DayPhase.morning => 'утро',
      DayPhase.afternoon => 'день',
      DayPhase.evening => 'вечер',
      DayPhase.night => 'ночь',
      null => '',
    };
  }

  @override
  List<Object?> get props => [
        isAvailable,
        temperatureCelsius,
        conditions,
        dayPhase,
        windSpeedKmh,
        fetchedAt,
        latitude,
        longitude,
        cityName,
      ];
}
