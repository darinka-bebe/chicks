import '../../models/weather_snapshot.dart';

/// Fetches live weather for outfit recommendations (implementation-agnostic).
abstract interface class WeatherService {
  Future<WeatherSnapshot> fetchCurrent({
    required double latitude,
    required double longitude,
  });
}
