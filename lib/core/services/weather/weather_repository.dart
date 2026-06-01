import '../../models/weather_snapshot.dart';
import '../../utils/logger.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/profile_preferences_repository.dart';
import 'open_meteo_weather_service.dart';
import 'open_meteo_geocoding_service.dart';
import 'weather_location_resolver.dart';
import 'weather_service.dart';

/// Cached access to live weather for chat and AI prompts.
class WeatherRepository {
  WeatherRepository({
    WeatherService? service,
    WeatherLocationResolver? locationResolver,
    OpenMeteoGeocodingService? geocoding,
  })  : _service = service ?? OpenMeteoWeatherService(),
        _locationResolver = locationResolver ?? WeatherLocationResolver(),
        _geocoding = geocoding ?? OpenMeteoGeocodingService.instance;

  static final WeatherRepository instance = WeatherRepository();

  final WeatherService _service;
  final WeatherLocationResolver _locationResolver;
  final OpenMeteoGeocodingService _geocoding;

  WeatherSnapshot? _cache;
  DateTime? _cacheTime;
  String? _cacheCityKey;
  static const _cacheTtl = Duration(minutes: 30);

  WeatherSnapshot? get cached => _cache;

  /// Returns cached weather when fresh; otherwise fetches (never throws).
  Future<WeatherSnapshot> getCurrent({bool forceRefresh = false}) async {
    final city = await _readProfileCity();
    final cacheKey = city.isEmpty ? '__gps__' : city.toLowerCase();

    if (!forceRefresh &&
        _isCacheValid &&
        _cacheCityKey == cacheKey &&
        _cache!.isAvailable) {
      return _cache!;
    }

    WeatherSnapshot? snapshot;

    if (city.isNotEmpty) {
      snapshot = await _fetchByCity(city);
    }

    snapshot ??= await _fetchByDeviceLocation(cityName: city.isNotEmpty ? city : null);

    if (snapshot != null && snapshot.isAvailable) {
      _cache = snapshot;
      _cacheTime = DateTime.now();
      _cacheCityKey = cacheKey;
      AppLogger.info(
        'WeatherRepository: cached ${snapshot.compactUiLabel}',
      );
      return snapshot;
    }

    return WeatherSnapshot.unavailable;
  }

  Future<String> _readProfileCity() async {
    final uid = AuthRepository.instance.currentUser.uid;
    if (uid.isEmpty) return '';
    return ProfilePreferencesRepository.instance.getCity(uid);
  }

  Future<WeatherSnapshot?> _fetchByCity(String city) async {
    try {
      final geocoded = await _geocoding.resolve(city);
      if (geocoded == null) return null;

      final snapshot = await _service.fetchCurrent(
        latitude: geocoded.latitude,
        longitude: geocoded.longitude,
      );

      if (!snapshot.isAvailable) return null;

      return WeatherSnapshot(
        isAvailable: true,
        temperatureCelsius: snapshot.temperatureCelsius,
        conditions: snapshot.conditions,
        dayPhase: snapshot.dayPhase,
        windSpeedKmh: snapshot.windSpeedKmh,
        fetchedAt: snapshot.fetchedAt,
        latitude: geocoded.latitude,
        longitude: geocoded.longitude,
        cityName: geocoded.displayName,
      );
    } catch (e) {
      AppLogger.warning(
        'WeatherRepository: city fetch failed ($city) — $e',
      );
      return null;
    }
  }

  Future<WeatherSnapshot?> _fetchByDeviceLocation({String? cityName}) async {
    try {
      final coords = await _locationResolver.resolve();
      final snapshot = await _service.fetchCurrent(
        latitude: coords.latitude,
        longitude: coords.longitude,
      );

      if (!snapshot.isAvailable) return null;

      if (cityName != null && cityName.trim().isNotEmpty && coords.usedFallback) {
        return WeatherSnapshot(
          isAvailable: true,
          temperatureCelsius: snapshot.temperatureCelsius,
          conditions: snapshot.conditions,
          dayPhase: snapshot.dayPhase,
          windSpeedKmh: snapshot.windSpeedKmh,
          fetchedAt: snapshot.fetchedAt,
          latitude: coords.latitude,
          longitude: coords.longitude,
          cityName: cityName.trim(),
        );
      }

      return snapshot;
    } catch (e) {
      AppLogger.warning(
        'WeatherRepository: GPS fetch failed ($e) — stylist works without weather',
      );
      return null;
    }
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
    _cacheCityKey = null;
  }
}
