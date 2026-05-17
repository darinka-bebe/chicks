import '../../models/weather_snapshot.dart';
import '../../utils/logger.dart';
import 'open_meteo_weather_service.dart';
import 'weather_location_resolver.dart';
import 'weather_service.dart';

/// Cached access to live weather for chat and AI prompts.
class WeatherRepository {
  WeatherRepository({
    WeatherService? service,
    WeatherLocationResolver? locationResolver,
  })  : _service = service ?? OpenMeteoWeatherService(),
        _locationResolver = locationResolver ?? WeatherLocationResolver();

  static final WeatherRepository instance = WeatherRepository();

  final WeatherService _service;
  final WeatherLocationResolver _locationResolver;

  WeatherSnapshot? _cache;
  DateTime? _cacheTime;
  static const _cacheTtl = Duration(minutes: 30);

  WeatherSnapshot? get cached => _cache;

  /// Returns cached weather when fresh; otherwise fetches (never throws).
  Future<WeatherSnapshot> getCurrent({bool forceRefresh = false}) async {
    if (!forceRefresh && _isCacheValid) {
      return _cache!;
    }

    try {
      final coords = await _locationResolver.resolve();
      final snapshot = await _service.fetchCurrent(
        latitude: coords.latitude,
        longitude: coords.longitude,
      );

      if (snapshot.isAvailable) {
        _cache = snapshot;
        _cacheTime = DateTime.now();
        AppLogger.info(
          'WeatherRepository: cached ${snapshot.compactUiLabel}',
        );
        return snapshot;
      }
    } catch (e) {
      AppLogger.warning(
        'WeatherRepository: fetch failed ($e) — stylist works without weather',
      );
    }

    return WeatherSnapshot.unavailable;
  }

  bool get _isCacheValid {
    if (_cache == null || _cacheTime == null || !_cache!.isAvailable) {
      return false;
    }
    return DateTime.now().difference(_cacheTime!) < _cacheTtl;
  }

  void clearCache() {
    _cache = null;
    _cacheTime = null;
  }
}
