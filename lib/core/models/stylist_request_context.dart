/// Mood, weather, and occasion signals parsed from a stylist chat request.
class StylistRequestContext {
  const StylistRequestContext({
    this.moods = const [],
    this.weather = const [],
    this.occasions = const [],
  });

  static const empty = StylistRequestContext();

  final List<String> moods;
  final List<String> weather;
  final List<String> occasions;

  bool get isEmpty =>
      moods.isEmpty && weather.isEmpty && occasions.isEmpty;

  bool get isNotEmpty => !isEmpty;

  StylistRequestContext merge(StylistRequestContext other) {
    return StylistRequestContext(
      moods: _unique([...moods, ...other.moods]),
      weather: _unique([...weather, ...other.weather]),
      occasions: _unique([...occasions, ...other.occasions]),
    );
  }

  static List<String> _unique(List<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      if (seen.add(value)) result.add(value);
    }
    return result;
  }
}
