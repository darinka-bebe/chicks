import '../../core/utils/logger.dart';
import '../../data/models/wardrobe_item.dart';
import '../localization/app_locale.dart';
import '../models/stylist_request_context.dart';
import '../models/wardrobe_outfit_slot.dart';
import 'stylist_pipeline_safety.dart';
import 'wardrobe_prompt_selector.dart';
import 'wardrobe_slot_classifier.dart';

/// Builds readable wardrobe and styling context for the AI stylist system prompt.
abstract final class WardrobePromptBuilder {
  /// Logs wardrobe payload attached to the next AI request.
  static void logPromptWardrobe({
    required int revision,
    required WardrobePromptSelection selection,
  }) {
    AppLogger.info(
      'WardrobePromptBuilder: prompt rev=$revision '
      'items=${selection.promptCount}/${selection.totalCount} '
      'omitted=${selection.omittedCount}',
    );
    if (selection.items.isEmpty) {
      AppLogger.debug('WardrobePromptBuilder: prompt wardrobe=(empty)');
      return;
    }
    final grouped = StylistPipelineSafety.safeGroup(selection.items);
    final summary = WardrobeOutfitSlotX.outfitOrder
        .where(
          (slot) => StylistPipelineSafety.itemsForSlot(grouped, slot).isNotEmpty,
        )
        .map(
          (slot) =>
              '${slot.name}=${StylistPipelineSafety.itemsForSlot(grouped, slot).length}',
        )
        .join(', ');
    AppLogger.debug('WardrobePromptBuilder: prompt slots → $summary');
  }

  /// Tells the model to ignore wardrobe names from older chat turns.
  static String buildFreshnessGuard({
    required int revision,
    required WardrobePromptSelection selection,
  }) {
    if (selection.totalCount == 0) {
      if (AppLocale.isRussian()) {
        return '''
АКТУАЛЬНОСТЬ ГАРДЕРОБА (ревизия $revision):
Гардероб пуст. Не ссылайся на вещи из прошлых сообщений в этом чате.
recommendedItemIds: [] — карточки вещей не показывай.''';
      }
      return '''
WARDROBE FRESHNESS (revision $revision):
Wardrobe is empty. Do not reference items from older chat turns.
recommendedItemIds: [] — do not show outfit item cards.''';
    }

    final truncation = selection.wasTruncated
        ? '\nВ промпте ${selection.promptCount} из ${selection.totalCount} вещей (релевантные слоты). '
            'recommendedItemIds — только id из блока ГАРДЕРОБ ниже.'
        : '';

    return '''
АКТУАЛЬНОСТЬ ГАРДЕРОБА (ревизия $revision):
Блок «ГАРДЕРОБ» ниже — единственный источник id для recommendedItemIds.
Игнорируй названия вещей из старых реплик чата, если их id нет в этом списке.$truncation''';
  }

  /// Wardrobe block for the OpenAI system message (bounded subset).
  static String buildWardrobeSection(
    List<WardrobeItem> items, {
    StylistRequestContext context = StylistRequestContext.empty,
    WardrobePromptSelection? selection,
  }) {
    try {
      final resolved = selection ??
          WardrobePromptSelector.select(items, context: context);
      if (resolved.totalCount == 0) {
        return StylistPipelineSafety.emptyWardrobeSection;
      }

      final promptItems = resolved.items;
      final grouped = StylistPipelineSafety.safeGroup(promptItems);
      final header = resolved.wasTruncated
          ? 'ГАРДЕРОБ (${resolved.promptCount} из ${resolved.totalCount} вещей в промпте, по слотам)'
          : 'ГАРДЕРОБ (${resolved.totalCount} вещей, по слотам образа)';

      final buffer = StringBuffer()
        ..writeln(header)
        ..writeln()
        ..writeln(_compactWardrobeRules)
        ..writeln();

      var slotsWithItems = 0;
      for (final slot in WardrobeOutfitSlotX.outfitOrder) {
        final slotItems = StylistPipelineSafety.itemsForSlot(grouped, slot);
        if (slotItems.isEmpty) continue;
        slotsWithItems++;

        buffer.writeln('── ${slot.sectionTitleRu} ──');

        for (final item in slotItems) {
          buffer.writeln('• ${formatCompactItemLine(item, context: context)}');
        }
        buffer.writeln();
      }

      if (slotsWithItems == 0) {
        buffer.writeln(
          'Слоты не распознаны — используй id из списка «Прочее».',
        );
      }

      final unknown =
          StylistPipelineSafety.itemsForSlot(grouped, WardrobeOutfitSlot.unknown);
      if (unknown.isNotEmpty) {
        buffer.writeln('── ${WardrobeOutfitSlot.unknown.sectionTitleRu} ──');
        for (final item in unknown) {
          buffer.writeln('• ${formatCompactItemLine(item, context: context)}');
        }
        buffer.writeln();
      }

      return buffer.toString().trim();
    } catch (e, stack) {
      AppLogger.error(
        'WardrobePromptBuilder.buildWardrobeSection failed — using fallback',
        error: e,
        stackTrace: stack,
      );
      return StylistPipelineSafety.emptyWardrobeSection;
    }
  }

  /// JSON output contract for OpenAI structured replies.
  static String buildResponseFormatSection({
    bool hasColorType = false,
    bool hasBodyType = false,
  }) {
    return AppLocale.isRussian()
        ? _buildResponseFormatSectionRu(
            hasColorType: hasColorType,
            hasBodyType: hasBodyType,
          )
        : _buildResponseFormatSectionEn(
            hasColorType: hasColorType,
            hasBodyType: hasBodyType,
          );
  }

  static String _buildResponseFormatSectionRu({
    required bool hasColorType,
    required bool hasBodyType,
  }) {
    final colorTypeHint = hasColorType
        ? '- 1 пункт: цветотип — почему палитра образа подходит пользователю.\n'
        : '';
    final bodyTypeHint = hasBodyType
        ? '- 1 пункт: тип фигуры — почему силуэт/пропорции образа подходят.\n'
        : '';

    return '''
ФОРМАТ ОТВЕТА (строго JSON, без markdown-обёртки):
{
  "message": "текст ответа на русском",
  "recommendedItemIds": ["id1", "id2", "id3"]
}

Правила JSON:
- "message" — короткий текст; вещи пользователь увидит на фото в карточках приложения.
- Лимит message: до 450 символов. Без воды и повторов.
- Если recommendedItemIds НЕ пуст (есть цельный образ из гардероба):
  • 1–2 предложения вступления, БЕЗ «Состав образа» и БЕЗ списка вещей.
  • затем «Почему это работает» — 2–3 пункта (до 12 слов каждый).
$colorTypeHint$bodyTypeHint- Если из гардероба НЕЛЬЗЯ собрать подходящий образ (пустой гардероб, мало вещей, нет слотов, не подходит под повод/погоду):
  • recommendedItemIds: [] — обязательно пустой массив, карточки не показывай.
  • Честно скажи, что из твоих вещей сейчас нечего надеть / образ собрать не получается.
  • Дай прямой совет по запросу: что надеть в целом (типы вещей, цвета, слои) — без названий вещей из гардероба.
  • Без блока «Почему это работает» и без «Состав образа».
- Не называй вещи, которых нет в recommendedItemIds.
- "recommendedItemIds" — только id из гардероба. Не заполняй «для галочки».
- СТРОГО не более ОДНОЙ вещи на слот (верх/платье, низ, верхняя одежда, обувь, аксессуар).
- Если цельный образ собрать нельзя — recommendedItemIds: [], а не частичный набор.
- Только существующие id; не выдумывай. Обычно 3–5 вещей в образе.''';
  }

  static String _buildResponseFormatSectionEn({
    required bool hasColorType,
    required bool hasBodyType,
  }) {
    final colorTypeHint = hasColorType
        ? '- 1 bullet: seasonal color type — why the palette fits.\n'
        : '';
    final bodyTypeHint = hasBodyType
        ? '- 1 bullet: body type — why the silhouette works.\n'
        : '';

    return '''
RESPONSE FORMAT (strict JSON, no markdown wrapper):
{
  "message": "reply text in English",
  "recommendedItemIds": ["id1", "id2", "id3"]
}

JSON rules:
- "message" — short; item photos appear in app cards when ids are set.
- Max 450 characters. No filler.
- If recommendedItemIds is NOT empty (a complete wardrobe outfit):
  • 1–2 intro sentences only — no item list.
  • then "Why this works" — 2–3 bullets (max 12 words each).
$colorTypeHint$bodyTypeHint- If you CANNOT build a suitable outfit from the wardrobe (empty, too few items, missing slots, wrong for occasion/weather):
  • recommendedItemIds: [] — required empty array, no item cards.
  • Say honestly there is nothing to wear from their wardrobe right now.
  • Give direct styling advice for the request (garment types, colors, layers) — no wardrobe item names.
  • No "Why this works" block and no outfit composition list.
- Do not name items that are not in recommendedItemIds.
- "recommendedItemIds" — wardrobe ids only. Never fill ids just to show cards.
- At most ONE item per slot (top/dress, bottom, outerwear, shoes, accessory).
- If a complete outfit is impossible — recommendedItemIds: [], not a partial pick.
- Only real ids from the list; never invent. Usually 3–5 items per outfit.''';
  }

  /// Mood / weather / occasion guidance for the current user message.
  static String buildStylingContextSection(StylistRequestContext context) {
    final buffer = StringBuffer()
      ..writeln('КОНТЕКСТ ЗАПРОСА ПОЛЬЗОВАТЕЛЯ:');

    if (context.isEmpty) {
      buffer.writeln(
        'Явные теги не распознаны — внимательно прочитай сообщение user: '
        'повод, настроение, погоду и стиль (school, romantic, comfy, rainy, streetwear и т.д.).',
      );
    } else {
      if (context.moods.isNotEmpty) {
        buffer.writeln('- Настроение / вайб: ${context.moods.join(', ')}');
      }
      if (context.weather.isNotEmpty) {
        buffer.writeln('- Погода (из запроса): ${context.weather.join(', ')}');
      }
      if (context.occasions.isNotEmpty) {
        buffer.writeln('- Повод: ${context.occasions.join(', ')}');
      }
    }

    buffer.writeln(_contextMatchingGuide);
    buffer.writeln(buildOccasionPlaybook(context));
    return buffer.toString().trim();
  }

  /// Targeted styling playbooks for common user prompts.
  static String buildOccasionPlaybook(StylistRequestContext context) {
    final keys = <String>{
      ...context.moods.map((e) => e.toLowerCase()),
      ...context.weather.map((e) => e.toLowerCase()),
      ...context.occasions.map((e) => e.toLowerCase()),
    };

    final sections = <String>[];

    if (keys.contains('school')) {
      sections.add(_playbookSchool);
    }
    if (keys.contains('romantic')) {
      sections.add(_playbookRomantic);
    }
    if (keys.contains('comfy') || keys.contains('cozy')) {
      sections.add(_playbookComfy);
    }
    if (keys.contains('rainy')) {
      sections.add(_playbookRainy);
    }
    if (_impliesStreetwear(keys)) {
      sections.add(_playbookStreetwear);
    }

    if (sections.isEmpty) return '';

    return '''

СЦЕНАРИЙ ЗАПРОСА (примени к гардеробу):
${sections.join('\n\n')}''';
  }

  static bool _impliesStreetwear(Set<String> keys) =>
      keys.contains('streetwear');

  /// Compact single-line wardrobe entry for the AI prompt.
  static String formatCompactItemLine(
    WardrobeItem item, {
    StylistRequestContext context = StylistRequestContext.empty,
  }) {
    final slot = WardrobeSlotClassifier.classify(item);
    final parts = <String>[
      'id="${item.id.trim()}"',
      '«${item.title.trim()}»',
      slot.name,
      item.color.trim().isEmpty ? '—' : item.color.trim(),
      item.season.trim().isEmpty ? '—' : item.season.trim(),
    ];

    final tag = _bestContextTag(item, context);
    if (tag != null) {
      parts.add(tag);
    }

    return parts.join(' | ');
  }

  static String? _bestContextTag(
    WardrobeItem item,
    StylistRequestContext context,
  ) {
    if (context.isEmpty) return null;

    final keywords = {
      ...context.moods,
      ...context.weather,
      ...context.occasions,
    }.map((e) => e.toLowerCase()).toSet();

    for (final style in item.styles) {
      if (keywords.contains(style.toLowerCase())) return style;
    }
    for (final occasion in item.occasions) {
      if (keywords.contains(occasion.toLowerCase())) return occasion;
    }
    for (final vibe in item.vibes) {
      if (keywords.contains(vibe.toLowerCase())) return vibe;
    }
    if (item.fit.isNotEmpty && keywords.contains(item.fit.toLowerCase())) {
      return item.fit;
    }
    return null;
  }

  static const _compactWardrobeRules = '''
Правила: только id из списка ниже; 1 вещь на слот; платье заменяет верх+низ.''';

  static const _contextMatchingGuide = '''

Сопоставление контекста с гардеробом:
- comfy / cozy → мягкие фактуры, relaxed/oversized, уютные вайбы, слои.
- romantic / feminine / soft girl → нежные оттенки, аккуратный силуэт, минимум грубого sport.
- confident / streetwear → чёткий силуэт, streetwear/casual в стилях, уместная обувь.
- elegant → сдержанная палитра, структурные вещи.
- hot / cold / rainy / windy — согласуй с сезоном вещи и обувью (см. блок погоды).''';

  static const _playbookSchool = '''【school / школа】
База: 1 верх + 1 низ (или платье), без party-перегруза.
Цвета: нейтральные, аккуратные; избегай слишком яркого total look.
Обувь: кроссовки/лоферы из гардероба — практично для долгого дня.
Слои: лёгкий верхний слой при холоде; не двойной верх.''';

  static const _playbookRomantic = '''【romantic / романтичный】
База: платье ИЛИ блуза/топ + юбка/брюки с мягкой линией.
Цвета: пастель, кремовый, нежно-розовый, молочный; избегай агрессивного спорт-стиля.
Обувь: изящнее (лоферы, ботильоны) — если есть в гардеробе.
Аксессуар: один деликатный (сумка, шарф) — не перегружай.''';

  static const _playbookComfy = '''【comfy / уютный】
База: мягкий верх (худи, свитер) + comfortable низ.
Посадка: relaxed / oversized сверху + straight/relaxed снизу — баланс объёма.
Ткани: тёплые, тактильные; цвета спокойные.
Обувь: кроссовки или мягкая закрытая обувь.''';

  static const _playbookRainy = '''【rainy / дождь】
Обязательно: верхняя одежда (плащ/тренч/куртка) если есть в гардеробе.
Обувь: закрытая, не открытые сандалии.
Цвета: можно чуть темнее низ, чтобы образ выглядел собранно.
Не дублируй верх — один защитный слой достаточно.''';

  static const _playbookStreetwear = '''【streetwear】
База: statement верх или худи + straight/cargo низ.
Силуэт: баланс oversized сверху и более прямого низа.
Обувь: кроссовки из гардероба — ключевой элемент.
Цвета: нейтраль + один акцент; избегай слишком romantic-вайба без запроса.''';
}
