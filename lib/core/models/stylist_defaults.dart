import 'stylist_request_context.dart';

/// Learned stylist context — moods, occasions, weather from chat usage.
class StylistDefaults {
  const StylistDefaults({
    this.moodCounts = const {},
    this.occasionCounts = const {},
    this.weatherCounts = const {},
    this.recentMoods = const [],
    this.recentOccasions = const [],
    this.recentWeather = const [],
    this.styleNotes = '',
    this.updatedAt,
  });

  static const empty = StylistDefaults();

  final Map<String, int> moodCounts;
  final Map<String, int> occasionCounts;
  final Map<String, int> weatherCounts;
  final List<String> recentMoods;
  final List<String> recentOccasions;
  final List<String> recentWeather;
  final String styleNotes;
  final DateTime? updatedAt;

  bool get hasSignals =>
      moodCounts.isNotEmpty ||
      occasionCounts.isNotEmpty ||
      weatherCounts.isNotEmpty ||
      styleNotes.trim().isNotEmpty;

  List<String> topMoods({int limit = 3}) => _topKeys(moodCounts, limit);

  List<String> topOccasions({int limit = 3}) => _topKeys(occasionCounts, limit);

  List<String> topWeather({int limit = 2}) => _topKeys(weatherCounts, limit);

  static List<String> _topKeys(Map<String, int> map, int limit) {
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => e.key).toList();
  }

  StylistDefaults mergeInteraction(StylistRequestContext context) {
    final now = DateTime.now();
    return StylistDefaults(
      moodCounts: _increment(moodCounts, context.moods),
      occasionCounts: _increment(occasionCounts, context.occasions),
      weatherCounts: _increment(weatherCounts, context.weather),
      recentMoods: _prependUnique(recentMoods, context.moods, 5),
      recentOccasions: _prependUnique(recentOccasions, context.occasions, 5),
      recentWeather: _prependUnique(recentWeather, context.weather, 3),
      styleNotes: styleNotes,
      updatedAt: now,
    );
  }

  StylistDefaults copyWith({
    String? styleNotes,
    DateTime? updatedAt,
  }) {
    return StylistDefaults(
      moodCounts: moodCounts,
      occasionCounts: occasionCounts,
      weatherCounts: weatherCounts,
      recentMoods: recentMoods,
      recentOccasions: recentOccasions,
      recentWeather: recentWeather,
      styleNotes: styleNotes ?? this.styleNotes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static Map<String, int> _increment(Map<String, int> base, List<String> keys) {
    final next = Map<String, int>.from(base);
    for (final key in keys) {
      next[key] = (next[key] ?? 0) + 1;
    }
    return next;
  }

  static List<String> _prependUnique(
    List<String> current,
    List<String> added,
    int max,
  ) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in [...added, ...current]) {
      if (seen.add(value)) result.add(value);
      if (result.length >= max) break;
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
        'moodCounts': moodCounts,
        'occasionCounts': occasionCounts,
        'weatherCounts': weatherCounts,
        'recentMoods': recentMoods,
        'recentOccasions': recentOccasions,
        'recentWeather': recentWeather,
        'styleNotes': styleNotes,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory StylistDefaults.fromJson(Map<String, dynamic>? json) {
    if (json == null) return StylistDefaults.empty;
    return StylistDefaults(
      moodCounts: _intMap(json['moodCounts']),
      occasionCounts: _intMap(json['occasionCounts']),
      weatherCounts: _intMap(json['weatherCounts']),
      recentMoods: _stringList(json['recentMoods']),
      recentOccasions: _stringList(json['recentOccasions']),
      recentWeather: _stringList(json['recentWeather']),
      styleNotes: json['styleNotes'] as String? ?? '',
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static Map<String, int> _intMap(dynamic raw) {
    if (raw is! Map) return {};
    return raw.map(
      (key, value) => MapEntry(
        '$key',
        value is int ? value : int.tryParse('$value') ?? 0,
      ),
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return [];
    return raw.map((e) => '$e').where((e) => e.isNotEmpty).toList();
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is! String || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}
