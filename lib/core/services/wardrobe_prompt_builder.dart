import '../../core/utils/logger.dart';
import '../../data/models/wardrobe_item.dart';
import '../models/stylist_request_context.dart';
import '../models/wardrobe_outfit_slot.dart';
import 'stylist_pipeline_safety.dart';
import 'wardrobe_slot_classifier.dart';

/// Builds readable wardrobe and styling context for the AI stylist system prompt.
abstract final class WardrobePromptBuilder {
  /// Logs wardrobe payload attached to the next AI request.
  static void logPromptWardrobe({
    required int revision,
    required List<WardrobeItem> items,
  }) {
    AppLogger.info(
      'WardrobePromptBuilder: building prompt rev=$revision count=${items.length}',
    );
    if (items.isEmpty) {
      AppLogger.debug('WardrobePromptBuilder: titles in prompt=(empty)');
      return;
    }
    final grouped = StylistPipelineSafety.safeGroup(items);
    final summary = WardrobeOutfitSlotX.outfitOrder
        .where(
          (slot) => StylistPipelineSafety.itemsForSlot(grouped, slot).isNotEmpty,
        )
        .map(
          (slot) =>
              '${slot.name}=${StylistPipelineSafety.itemsForSlot(grouped, slot).length}',
        )
        .join(', ');
    AppLogger.debug('WardrobePromptBuilder: slots → $summary');
  }

  /// Tells the model to ignore wardrobe names from older chat turns.
  static String buildFreshnessGuard({
    required int revision,
    required List<WardrobeItem> items,
  }) {
    if (items.isEmpty) {
      return '''
АКТУАЛЬНОСТЬ ГАРДЕРОБА (ревизия $revision):
Гардероб пуст. Не ссылайся на вещи из прошлых сообщений в этом чате — их больше нет в данных приложения.''';
    }

    final titles = items.map((item) => '«${item.title}»').join(', ');

    return '''
АКТУАЛЬНОСТЬ ГАРДЕРОБА (ревизия $revision):
Список вещей в системных сообщениях — единственный источник правды.
Игнорируй любые названия вещей из прошлых реплик user/assistant, которых НЕТ в гардеробе сейчас.
Допустимые названия: $titles.
Не предлагай и не упоминай удалённые вещи.''';
  }

  /// Full wardrobe block grouped by outfit slots for the OpenAI system message.
  static String buildWardrobeSection(List<WardrobeItem> items) {
    try {
      final safeItems = StylistPipelineSafety.sanitizeWardrobe(items);
      if (safeItems.isEmpty) {
        return _emptyWardrobePrompt;
      }

      final grouped = StylistPipelineSafety.safeGroup(safeItems);
      final buffer = StringBuffer()
        ..writeln(
          'ГАРДЕРОБ ПОЛЬЗОВАТЕЛЯ (${safeItems.length} вещей, по слотам образа)',
        )
        ..writeln()
        ..writeln(_outfitSlotRules)
        ..writeln();

      var slotsWithItems = 0;
      for (final slot in WardrobeOutfitSlotX.outfitOrder) {
        final slotItems = StylistPipelineSafety.itemsForSlot(grouped, slot);
        if (slotItems.isEmpty) continue;
        slotsWithItems++;

        buffer
          ..writeln('── ${slot.sectionTitleRu} (${slotItems.length}) ──')
          ..writeln('Слот: ${slot.promptLabelRu}');

        for (final item in slotItems) {
          buffer.writeln('• ${formatItemLine(item)}');
        }
        buffer.writeln();
      }

      if (slotsWithItems == 0) {
        buffer.writeln(
          'В гардеробе нет вещей с распознанными слотами — используй список ID ниже.',
        );
      }

      final unknown =
          StylistPipelineSafety.itemsForSlot(grouped, WardrobeOutfitSlot.unknown);
      if (unknown.isNotEmpty) {
        buffer
          ..writeln('── ${WardrobeOutfitSlot.unknown.sectionTitleRu} ──')
          ..writeln(
            'Классифицируй по смыслу в один из слотов образа; не дублируй категории.',
          );
        for (final item in unknown) {
          final hint = WardrobeSlotClassifier.classify(item);
          buffer.writeln(
            '• ${formatItemLine(item)} (вероятный слот: ${hint.name})',
          );
        }
        buffer.writeln();
      }

      buffer.writeln('ID для recommendedItemIds (только эти строки):');
      for (final item in safeItems) {
        buffer.writeln(
          '- "${item.id}" → «${item.title}» [${item.category}]',
        );
      }

      buffer.writeln(_stylistCompositionGuide);
      buffer.writeln(_wardrobeRecommendationRules);
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
    final colorTypeHint = hasColorType
        ? '- 1 пункт: цветотип — почему палитра образа подходит пользователю.\n'
        : '';
    final bodyTypeHint = hasBodyType
        ? '- 1 пункт: тип фигуры — почему силуэт/пропорции образа подходят '
            '(например: «оверсайз-худи балансирует грушу»).\n'
        : '';

    return '''
ФОРМАТ ОТВЕТА (строго JSON, без markdown-обёртки):
{
  "message": "текст ответа пользователю на русском",
  "recommendedItemIds": ["id1", "id2", "id3"]
}

Правила JSON:
- "message" — ответ профессионального стилиста: связный ОБРАЗ, не случайный набор вещей.
- Структура message (рекомендуется):
  1) «Состав образа» — перечисли вещи «…» по слотам (верх/низ или платье, верхняя одежда, обувь, аксессуар).
  2) «Почему это работает» — 3–5 коротких пунктов: запрос, погода, цвета, силуэт, повод.
$colorTypeHint$bodyTypeHint  3) При необходимости — 1 практичный совет (слой, обувь, аксессуар).
- "recommendedItemIds" — id из гардероба в порядке сборки образа.
- СТРОГО не более ОДНОЙ вещи на слот:
  • максимум 1 верх ИЛИ 1 платье (платье заменяет верх+низ)
  • максимум 1 низ (только если нет платья)
  • максимум 1 верхняя одежда
  • максимум 1 обувь
  • максимум 1 аксессуар
- НИКОГДА не указывай два худи, две рубашки, две пары обуви и т.п.
- Если в слоте нет подходящей вещи — пропусти слот, не дублируй другую категорию.
- Только существующие id; не выдумывай. Без дубликатов id. Обычно 3–5 вещей в образе.''';
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

  /// Single-line wardrobe entry for the prompt.
  static String formatItemLine(WardrobeItem item) {
    final slot = WardrobeSlotClassifier.classify(item);
    final parts = <String>[
      'id="${item.id.trim()}"',
      '«${item.title.trim()}»',
      'слот: ${slot.name}',
      'категория: ${item.category.trim().isEmpty ? "—" : item.category.trim()}',
      'цвет: ${item.color.trim().isEmpty ? "—" : item.color.trim()}',
      'сезон: ${item.season.trim().isEmpty ? "—" : item.season.trim()}',
    ];

    if (item.fit.isNotEmpty) {
      parts.add('посадка: ${item.fit}');
    }
    if (item.styles.isNotEmpty) {
      parts.add('стиль: ${item.styles.join(', ')}');
    }
    if (item.occasions.isNotEmpty) {
      parts.add('повод: ${item.occasions.join(', ')}');
    }
    if (item.vibes.isNotEmpty) {
      parts.add('вайб: ${item.vibes.join(', ')}');
    }

    return parts.join(' | ');
  }

  static const _emptyWardrobePrompt = '''
ГАРДЕРОБ ПОЛЬЗОВАТЕЛЯ:
Список вещей пуст. Дай универсальные советы по стилю и мягко предложи добавить вещи в раздел «Твой гардероб».
Не называй конкретные вещи пользователя. recommendedItemIds: [].''';

  static const _outfitSlotRules = '''
ПРАВИЛА СБОРКИ ОБРАЗА (критично — как у профессионального стилиста):
Собирай ЦЕЛОСТНЫЙ лук из гардероба, а не случайный список.
• 1 слот = максимум 1 вещь. Запрещено: 2 верха, 2 низа, 2 пары обуви.
• Платье = самостоятельная база (не добавляй отдельный верх и низ к платью).
• Если слота нет в гардеробе — пропусти, не заменяй другой категорией.
• Сочетай цвета осознанно: нейтральная база + 1 акцент ИЛИ тон-в-тон.
• Не смешивай конфликтующие стили (например sporty + romantic) без явного запроса.
• Учитывай сезон и посадку: slim низ + oversized верх — баланс; не дублируй объём.''';

  static const _stylistCompositionGuide = '''

КАК ДУМАТЬ КАК СТИЛИСТ (перед выбором id):
1) Пойми запрос: повод, настроение, погода, dress code.
2) Выбери БАЗУ: платье ИЛИ (верх + низ) — одна логичная пара по цвету и силуэту.
3) Добавь верхнюю одежду только если холод / дождь / ветер.
4) Подбери ОДНУ обувь под повод и погоду.
5) Один аксессуар — если усиливает образ, не перегружай.
6) В message объясни ПОЧЕМУ: (а) под запрос, (б) под погоду, (в) почему цвета/стили сочетаются.''';

  static const _wardrobeRecommendationRules = '''

Персональные рекомендации:
- Только вещи из гардероба выше; названия в кавычках «…» точно как в списке.
- Приоритет: запрос пользователя → живая погода → теги вещей (стиль, повод, сезон, вайб).
- Не предлагай визуально конфликтующие вещи (спортивные кроссовки + вечернее платье без запроса).
- Докупку упоминай только если критичного слота нет в гардеробе.
- Русский язык, тепло и уверенно, без канцелярита.''';

  static const _contextMatchingGuide = '''

Сопоставление контекста с гардеробом:
- comfy / cozy → мягкие фактуры, relaxed/oversized, уютные вайбы, слои.
- romantic / feminine / soft girl → нежные оттенки, аккуратный силуэт, минимум грубого sport.
- confident / streetwear → чёткий силуэт, streetwear/casual в стилях, уместная обувь.
- elegant / dark academia → сдержанная палитра, структурные вещи.
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
