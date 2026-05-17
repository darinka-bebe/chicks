import '../../models/weather_condition.dart';
import '../../models/weather_snapshot.dart';

/// Maps Open-Meteo WMO codes and metrics to [WeatherSnapshot].
abstract final class WeatherCodeMapper {
  static const _windyKmh = 28.0;

  static WeatherSnapshot fromOpenMeteo({
    required double latitude,
    required double longitude,
    required double temperatureCelsius,
    required int weatherCode,
    required double windSpeedKmh,
    required int isDay,
    required DateTime fetchedAt,
  }) {
    final conditions = <WeatherCondition>{};
    conditions.addAll(_conditionsFromCode(weatherCode));

    if (windSpeedKmh >= _windyKmh) {
      conditions.add(WeatherCondition.windy);
    }

    if (temperatureCelsius < 12) {
      // Implicit cold — handled via isCold on snapshot; no enum needed.
    }

    return WeatherSnapshot(
      isAvailable: true,
      temperatureCelsius: temperatureCelsius,
      conditions: conditions.toList(),
      dayPhase: _dayPhaseFromClock(fetchedAt, isDay == 1),
      windSpeedKmh: windSpeedKmh,
      fetchedAt: fetchedAt,
      latitude: latitude,
      longitude: longitude,
    );
  }

  static List<WeatherCondition> _conditionsFromCode(int code) {
    if (code == 0) return [WeatherCondition.sunny];
    if (code <= 3) return [WeatherCondition.cloudy];
    if (code == 45 || code == 48) return [WeatherCondition.foggy, WeatherCondition.cloudy];
    if (code >= 51 && code <= 67) return [WeatherCondition.rainy, WeatherCondition.cloudy];
    if (code >= 71 && code <= 77) return [WeatherCondition.snowy, WeatherCondition.cloudy];
    if (code >= 80 && code <= 82) return [WeatherCondition.rainy];
    if (code >= 85 && code <= 86) return [WeatherCondition.snowy];
    if (code >= 95) return [WeatherCondition.rainy, WeatherCondition.windy];
    return [WeatherCondition.cloudy];
  }

  static DayPhase _dayPhaseFromClock(DateTime time, bool isDay) {
    if (!isDay) return DayPhase.night;
    final hour = time.hour;
    if (hour >= 6 && hour < 12) return DayPhase.morning;
    if (hour >= 12 && hour < 17) return DayPhase.afternoon;
    if (hour >= 17 && hour < 22) return DayPhase.evening;
    return DayPhase.night;
  }
}
