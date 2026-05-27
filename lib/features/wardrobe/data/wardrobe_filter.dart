import '../../../core/constants/wardrobe_catalog.dart';
import '../../../core/utils/logger.dart';
import '../../../data/models/wardrobe_item.dart';

/// Client-side wardrobe search and filter criteria.
class WardrobeFilterCriteria {
  const WardrobeFilterCriteria({
    this.query = '',
    this.category,
    this.season,
    this.color,
    this.style,
    this.favoritesOnly = false,
    this.favoriteIds = const {},
  });

  final String query;
  final String? category;
  final String? season;
  final String? color;
  final String? style;
  final bool favoritesOnly;
  final Set<String> favoriteIds;

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      (category != null && category!.isNotEmpty) ||
      (season != null && season!.isNotEmpty) ||
      (color != null && color!.isNotEmpty) ||
      (style != null && style!.isNotEmpty) ||
      favoritesOnly;

  WardrobeFilterCriteria cleared() => WardrobeFilterCriteria(
        favoriteIds: favoriteIds,
      );

  WardrobeFilterCriteria copyWith({
    String? query,
    String? category,
    String? season,
    String? color,
    String? style,
    bool? favoritesOnly,
    Set<String>? favoriteIds,
    bool clearCategory = false,
    bool clearSeason = false,
    bool clearColor = false,
    bool clearStyle = false,
  }) {
    return WardrobeFilterCriteria(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      season: clearSeason ? null : (season ?? this.season),
      color: clearColor ? null : (color ?? this.color),
      style: clearStyle ? null : (style ?? this.style),
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      favoriteIds: favoriteIds ?? this.favoriteIds,
    );
  }
}

enum WardrobeEmptyFilterReason {
  none,
  search,
  filters,
  favorites,
}

/// Pure filter engine — operates on in-memory items from Hive / sync cache.
abstract final class WardrobeFilterEngine {
  static List<WardrobeItem> apply({
    required List<WardrobeItem> items,
    required WardrobeFilterCriteria criteria,
  }) {
    final needle = criteria.query.trim().toLowerCase();
    final result = items.where((item) {
      if (criteria.favoritesOnly &&
          !criteria.favoriteIds.contains(item.id.trim())) {
        return false;
      }
      if (criteria.category != null &&
          criteria.category!.isNotEmpty &&
          item.category != criteria.category) {
        return false;
      }
      if (criteria.season != null &&
          criteria.season!.isNotEmpty &&
          item.season != criteria.season) {
        return false;
      }
      if (criteria.color != null && criteria.color!.isNotEmpty) {
        if (!_containsIgnoreCase(item.color, criteria.color!)) return false;
      }
      if (criteria.style != null && criteria.style!.isNotEmpty) {
        final styleNeedle = criteria.style!.toLowerCase();
        final styleHit = item.styles.any(
              (tag) => tag.toLowerCase().contains(styleNeedle),
            ) ||
            item.vibes.any(
              (tag) => tag.toLowerCase().contains(styleNeedle),
            ) ||
            item.occasions.any(
              (tag) => tag.toLowerCase().contains(styleNeedle),
            ) ||
            item.fit.toLowerCase().contains(styleNeedle);
        if (!styleHit) return false;
      }
      if (needle.isEmpty) return true;
      return _matchesSearch(item, needle);
    }).toList();

    if (criteria.hasActiveFilters || needle.isNotEmpty) {
      AppLogger.debug(
        'WardrobeFilter: search="${criteria.query}" '
        'category=${criteria.category ?? '—'} '
        'season=${criteria.season ?? '—'} '
        'color=${criteria.color ?? '—'} '
        'style=${criteria.style ?? '—'} '
        'favoritesOnly=${criteria.favoritesOnly} '
        'total=${items.length} filtered=${result.length}',
      );
    }

    return result;
  }

  static WardrobeEmptyFilterReason emptyReason({
    required WardrobeFilterCriteria criteria,
    required int totalCount,
    required int filteredCount,
  }) {
    if (totalCount == 0) return WardrobeEmptyFilterReason.none;
    if (filteredCount > 0) return WardrobeEmptyFilterReason.none;
    if (criteria.favoritesOnly) return WardrobeEmptyFilterReason.favorites;
    if (criteria.query.trim().isNotEmpty) {
      return WardrobeEmptyFilterReason.search;
    }
    return WardrobeEmptyFilterReason.filters;
  }

  static Set<String> uniqueColors(Iterable<WardrobeItem> items) {
    final colors = <String>{};
    for (final item in items) {
      final value = item.color.trim();
      if (value.isNotEmpty && value != 'Не указан') colors.add(value);
    }
    final list = colors.toList()..sort();
    return list.toSet();
  }

  static Set<String> uniqueStyles(Iterable<WardrobeItem> items) {
    final styles = <String>{...WardrobeCatalog.styles, ...WardrobeCatalog.vibes};
    for (final item in items) {
      styles.addAll(item.styles);
      styles.addAll(item.vibes);
    }
    final list = styles.toList()..sort();
    return list.toSet();
  }

  static bool _matchesSearch(WardrobeItem item, String needle) {
    if (_containsIgnoreCase(item.title, needle)) return true;
    if (_containsIgnoreCase(item.category, needle)) return true;
    if (_containsIgnoreCase(item.color, needle)) return true;
    if (_containsIgnoreCase(item.season, needle)) return true;
    if (_containsIgnoreCase(item.fit, needle)) return true;
    for (final tag in [...item.styles, ...item.vibes, ...item.occasions]) {
      if (_containsIgnoreCase(tag, needle)) return true;
    }
    return false;
  }

  static bool _containsIgnoreCase(String haystack, String needle) {
    return haystack.toLowerCase().contains(needle.toLowerCase());
  }
}
