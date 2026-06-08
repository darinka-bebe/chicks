/// Splits AI stylist reply into main text and «Почему подходит» bullets.
abstract final class OutfitWhySectionParser {
  static final _headerPattern = RegExp(
    r'(?:\*\*)?\s*(?:'
    r'Почему(?:\s+этот\s+образ)?\s+(?:подходит|работает)'
    r'|Why(?:\s+this\s+(?:look|outfit))?\s+(?:works|fits)'
    r')\s*:?\s*(?:\*\*)?',
    caseSensitive: false,
  );

  static ParsedStylistMessage parse(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return const ParsedStylistMessage(body: '');
    }

    final match = _headerPattern.firstMatch(trimmed);
    if (match == null) {
      return ParsedStylistMessage(body: trimmed);
    }

    final body = trimmed.substring(0, match.start).trim();
    var whyRaw = trimmed.substring(match.end).trim();
    if (whyRaw.startsWith('\n')) {
      whyRaw = whyRaw.trimLeft();
    }

    final bullets = _extractBullets(whyRaw);
    if (bullets.isEmpty) {
      return ParsedStylistMessage(body: trimmed);
    }

    return ParsedStylistMessage(
      body: body.isEmpty ? trimmed.substring(0, match.start).trim() : body,
      whyBullets: bullets,
    );
  }

  static List<String> _extractBullets(String section) {
    final lines = section.split('\n');
    final bullets = <String>[];

    for (final line in lines) {
      final cleaned = line
          .replaceFirst(RegExp(r'^[\s•\-\*]+'), '')
          .replaceFirst(RegExp(r'^\d+[\.\)]\s*'), '')
          .trim();
      if (cleaned.isEmpty) continue;
      if (cleaned.startsWith('**') && cleaned.endsWith('**')) continue;
      bullets.add(cleaned);
      if (bullets.length >= 3) break;
    }

    return bullets;
  }

  static final _compositionHeader = RegExp(
    r'(?:\*\*)?\s*(?:Состав\s+образа|Outfit\s+(?:items|composition))\b',
    caseSensitive: false,
  );

  /// Drops outfit composition prose when photo cards already show the items.
  static String compactBodyWhenOutfitCardsShown(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return trimmed;

    final composition = _compositionHeader.firstMatch(trimmed);
    if (composition != null) {
      final intro = trimmed.substring(0, composition.start).trim();
      return intro;
    }

    return _truncateToSentences(trimmed, maxSentences: 2);
  }

  /// Removes outfit-card sections when no wardrobe items were recommended.
  static String stripOutfitOnlySections(String content) {
    var text = content.trim();
    if (text.isEmpty) return text;

    final composition = _compositionHeader.firstMatch(text);
    if (composition != null) {
      text = text.substring(0, composition.start).trim();
    }

    final why = _headerPattern.firstMatch(text);
    if (why != null) {
      text = text.substring(0, why.start).trim();
    }

    final lines = text.split('\n');
    final kept = <String>[];
    for (final line in lines) {
      if (RegExp(r'«[^»]+»').hasMatch(line)) continue;
      kept.add(line);
    }

    return kept.join('\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  static String _truncateToSentences(String text, {required int maxSentences}) {
    final matches = RegExp(r'[^.!?…]+[.!?…]?').allMatches(text);
    final parts = <String>[];
    for (final match in matches) {
      final sentence = match.group(0)?.trim() ?? '';
      if (sentence.isEmpty) continue;
      parts.add(sentence);
      if (parts.length >= maxSentences) break;
    }
    if (parts.isEmpty) return text;
    return parts.join(' ');
  }
}

class ParsedStylistMessage {
  const ParsedStylistMessage({
    required this.body,
    this.whyBullets = const [],
  });

  final String body;
  final List<String> whyBullets;

  bool get hasWhySection => whyBullets.isNotEmpty;
}
