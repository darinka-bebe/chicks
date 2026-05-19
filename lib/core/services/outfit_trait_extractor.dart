import '../../data/models/wardrobe_item.dart';
import '../models/stylist_request_context.dart';
import 'outfit_content_hasher.dart';
import 'stylist_context_parser.dart';

/// Normalizes outfit traits for preference learning (rule-based, no ML).
abstract final class OutfitTraitExtractor {
  static const _styleRules = <_TagRule>[
    _TagRule('oversized', ['oversized', 'оверсайз', 'свободн', 'baggy']),
    _TagRule('sporty', ['спорт', 'sport', 'athletic', 'трениров']),
    _TagRule('streetwear', ['street', 'стрит', 'urban', 'худи', 'hoodie']),
    _TagRule('romantic', ['романт', 'romantic', 'кружев', 'lace']),
    _TagRule('elegant', ['элегант', 'elegant', 'классик', 'classic']),
    _TagRule('casual', ['casual', 'повседн', 'кэжуал', 'кежуал']),
    _TagRule('minimal', ['минимал', 'minimal', 'базов']),
    _TagRule('feminine', ['женствен', 'feminine', 'нежн']),
    _TagRule('office', ['офис', 'office', 'делов', 'business']),
    _TagRule('party', ['вечер', 'party', 'клуб']),
  ];

  static const _colorRules = <_TagRule>[
    _TagRule('pink', ['розов', 'pink', 'фукси']),
    _TagRule('black', ['чёрн', 'черн', 'black']),
    _TagRule('white', ['бел', 'white', 'молоч', 'айвори']),
    _TagRule('beige', ['беж', 'beige', 'крем', 'песоч']),
    _TagRule('red', ['красн', 'red', 'бордо', 'вишн']),
    _TagRule('blue', ['син', 'blue', 'голуб', 'navy', 'джинс']),
    _TagRule('green', ['зел', 'green', 'олив', 'хаки']),
    _TagRule('bright', ['неон', 'ярк', 'кислот', 'салат']),
    _TagRule('neutral', ['сер', 'grey', 'gray', 'нейтрал']),
  ];

  static const _silhouetteRules = <_TagRule>[
    _TagRule('wide_hips', ['широк', 'wide', 'клёш', 'клеш', 'flare']),
    _TagRule('fitted', ['притал', 'fitted', 'slim', 'облег']),
    _TagRule('relaxed', ['relaxed', 'свобод', 'oversized']),
    _TagRule('structured', ['пиджак', 'blazer', 'жакет', 'костюм']),
    _TagRule('layered', ['свитер', 'кардиган', 'жилет', 'layer']),
  ];

  static OutfitTraits extract({
    required List<WardrobeItem> items,
    required String recommendationText,
    String? userPrompt,
  }) {
    final context = _mergeContext(recommendationText, userPrompt);
    final corpus = _buildCorpus(items, recommendationText, context);

    final styles = <String>{
      ..._matchRules(corpus, _styleRules),
      ...items.expand((i) => i.styles.map(_normalizeTag)),
      ...items.expand((i) => i.vibes.map(_normalizeTag)),
    }..removeWhere((e) => e.isEmpty);

    final colors = <String>{
      ..._matchRules(corpus, _colorRules),
      ...items.map((i) => _normalizeTag(i.color)),
    }..removeWhere((e) => e.isEmpty);

    final silhouettes = <String>{
      ..._matchRules(corpus, _silhouetteRules),
      ...items.map((i) => _normalizeTag(i.fit)).where((f) => f.isNotEmpty),
      ...items.map((i) => _slotTag(i.category)),
    }..removeWhere((e) => e.isEmpty);

    final combinationKey = combinationKeyFrom(
      itemIds: items.map((i) => i.id).toList(),
      styles: styles,
    );

    return OutfitTraits(
      styles: styles.toList(),
      colors: colors.toList(),
      silhouettes: silhouettes.toList(),
      combinationKey: combinationKey,
      moods: context.moods,
      occasions: context.occasions,
    );
  }

  static StylistRequestContext _mergeContext(
    String recommendationText,
    String? userPrompt,
  ) {
    final fromReply = StylistContextParser.parse(recommendationText);
    if (userPrompt == null || userPrompt.trim().isEmpty) {
      return fromReply;
    }
    return StylistContextParser.parse(userPrompt).merge(fromReply);
  }

  static String _buildCorpus(
    List<WardrobeItem> items,
    String recommendationText,
    StylistRequestContext context,
  ) {
    final parts = <String>[
      recommendationText.toLowerCase(),
      ...context.moods,
      ...context.occasions,
      ...context.weather,
      for (final item in items) ...[
        item.title,
        item.category,
        item.color,
        item.fit,
        ...item.styles,
        ...item.vibes,
        ...item.occasions,
      ],
    ];
    return parts.join(' ').toLowerCase();
  }

  static Set<String> _matchRules(String corpus, List<_TagRule> rules) {
    final hits = <String>{};
    for (final rule in rules) {
      if (rule.matches(corpus)) hits.add(rule.id);
    }
    return hits;
  }

  static String _normalizeTag(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  static String _slotTag(String category) {
    final c = category.toLowerCase();
    if (c.contains('плать')) return 'dress';
    if (c.contains('верх')) return 'top';
    if (c.contains('низ')) return 'bottom';
    if (c.contains('обув')) return 'shoes';
    if (c.contains('верхняя')) return 'outerwear';
    return _normalizeTag(category);
  }

  static String combinationKeyFrom({
    required List<String> itemIds,
    required Iterable<String> styles,
  }) {
    final ids = itemIds.map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
      ..sort();
    final stylePart = styles.map(_normalizeTag).toList()..sort();
    final raw = '${ids.join('|')}:${stylePart.join('|')}';
    return OutfitContentHasher.hash(raw);
  }
}

class OutfitTraits {
  const OutfitTraits({
    this.styles = const [],
    this.colors = const [],
    this.silhouettes = const [],
    this.combinationKey = '',
    this.moods = const [],
    this.occasions = const [],
  });

  final List<String> styles;
  final List<String> colors;
  final List<String> silhouettes;
  final String combinationKey;
  final List<String> moods;
  final List<String> occasions;
}

class _TagRule {
  const _TagRule(this.id, this.keywords);

  final String id;
  final List<String> keywords;

  bool matches(String corpus) {
    for (final keyword in keywords) {
      if (corpus.contains(keyword)) return true;
    }
    return false;
  }
}
