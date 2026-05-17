import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';

import '../../utils/logger.dart';

/// Resolves coordinates for weather (device GPS with .env fallback).
class WeatherLocationResolver {
  WeatherLocationResolver({
    double? fallbackLatitude,
    double? fallbackLongitude,
  })  : _fallbackLat = fallbackLatitude ?? _readEnvDouble('WEATHER_LATITUDE', 55.7558),
        _fallbackLon = fallbackLongitude ?? _readEnvDouble('WEATHER_LONGITUDE', 37.6173);

  final double _fallbackLat;
  final double _fallbackLon;

  static double _readEnvDouble(String key, double defaultValue) {
    final raw = dotenv.env[key];
    if (raw == null) return defaultValue;
    return double.tryParse(raw.trim()) ?? defaultValue;
  }

  Future<({double latitude, double longitude, bool usedFallback})> resolve() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        AppLogger.debug('WeatherLocationResolver: location services off — fallback');
        return _fallback(usedFallback: true);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppLogger.debug('WeatherLocationResolver: permission denied — fallback');
        return _fallback(usedFallback: true);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      ).timeout(const Duration(seconds: 10));

      AppLogger.debug(
        'WeatherLocationResolver: GPS ${position.latitude}, ${position.longitude}',
      );

      return (
        latitude: position.latitude,
        longitude: position.longitude,
        usedFallback: false,
      );
    } catch (e) {
      AppLogger.warning('WeatherLocationResolver: GPS failed ($e) — fallback');
      return _fallback(usedFallback: true);
    }
  }

  ({double latitude, double longitude, bool usedFallback}) _fallback({
    required bool usedFallback,
  }) {
    return (
      latitude: _fallbackLat,
      longitude: _fallbackLon,
      usedFallback: usedFallback,
    );
  }
}
