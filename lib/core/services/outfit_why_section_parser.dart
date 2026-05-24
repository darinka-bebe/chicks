/// Splits AI stylist reply into main text and «Почему подходит» bullets.
abstract final class OutfitWhySectionParser {
  static final _headerPattern = RegExp(
    r'(?:\*\*)?\s*Почему(?:\s+этот\s+образ)?\s+(?:подходит|работает)\s*:?\s*(?:\*\*)?',
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
      if (bullets.length >= 5) break;
    }

    return bullets;
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
