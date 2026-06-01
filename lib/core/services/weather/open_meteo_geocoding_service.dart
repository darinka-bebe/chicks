import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utils/logger.dart';

/// Resolves a city name to coordinates via Open-Meteo Geocoding (no API key).
class OpenMeteoGeocodingService {
  OpenMeteoGeocodingService({http.Client? client}) : _client = client ?? http.Client();

  static final OpenMeteoGeocodingService instance = OpenMeteoGeocodingService();

  final http.Client _client;

  static const _baseUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  Future<GeocodedCity?> resolve(String cityName) async {
    final query = cityName.trim();
    if (query.length < 2) return null;

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'name': query,
        'count': '1',
        'language': 'ru',
        'format': 'json',
      },
    );

    AppLogger.debug('OpenMeteoGeocodingService: GET $uri');

    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      AppLogger.warning(
        'OpenMeteoGeocodingService: HTTP ${response.statusCode}',
      );
      return null;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      AppLogger.warning('OpenMeteoGeocodingService: no results for "$query"');
      return null;
    }

    final first = results.first as Map<String, dynamic>;
    final lat = (first['latitude'] as num?)?.toDouble();
    final lon = (first['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    final name = first['name'] as String? ?? query;
    final country = first['country'] as String? ?? '';
    final label = country.isEmpty ? name : '$name, $country';

    AppLogger.info(
      'OpenMeteoGeocodingService: "$query" → $label ($lat, $lon)',
    );

    return GeocodedCity(
      latitude: lat,
      longitude: lon,
      displayName: label,
    );
  }
}

class GeocodedCity {
  const GeocodedCity({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });

  final double latitude;
  final double longitude;
  final String displayName;
}
