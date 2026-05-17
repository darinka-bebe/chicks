import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/weather_snapshot.dart';
import '../../utils/logger.dart';
import 'weather_code_mapper.dart';
import 'weather_service.dart';

/// Free weather API — no API key (https://open-meteo.com).
class OpenMeteoWeatherService implements WeatherService {
  OpenMeteoWeatherService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  @override
  Future<WeatherSnapshot> fetchCurrent({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,weather_code,wind_speed_10m,is_day',
        'timezone': 'auto',
        'forecast_days': '1',
      },
    );

    AppLogger.debug('OpenMeteoWeatherService: GET $uri');

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      AppLogger.warning(
        'OpenMeteoWeatherService: HTTP ${response.statusCode}',
      );
      return WeatherSnapshot.unavailable;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final current = body['current'] as Map<String, dynamic>?;
    if (current == null) {
      return WeatherSnapshot.unavailable;
    }

    final temp = (current['temperature_2m'] as num?)?.toDouble();
    final code = (current['weather_code'] as num?)?.toInt();
    final wind = (current['wind_speed_10m'] as num?)?.toDouble();
    final isDay = (current['is_day'] as num?)?.toInt() ?? 1;

    if (temp == null || code == null || wind == null) {
      return WeatherSnapshot.unavailable;
    }

    final snapshot = WeatherCodeMapper.fromOpenMeteo(
      latitude: latitude,
      longitude: longitude,
      temperatureCelsius: temp,
      weatherCode: code,
      windSpeedKmh: wind,
      isDay: isDay,
      fetchedAt: DateTime.now(),
    );

    AppLogger.info(
      'OpenMeteoWeatherService: ${snapshot.compactUiLabel}',
    );
    return snapshot;
  }
}
