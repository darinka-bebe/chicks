/// Merges multiple system messages into fewer blocks (token savings).
abstract final class StylistSystemPromptMerger {
  static List<Map<String, String>> compact(
    List<Map<String, String>> messages,
  ) {
  if (messages.length <= 3) return messages;

    final system = <Map<String, String>>[];
    final rest = <Map<String, String>>[];

    for (final message in messages) {
      if (message['role'] == 'system') {
        system.add(message);
      } else {
        rest.add(message);
      }
    }

    if (system.length <= 2) return messages;

    final persona = system.first['content']?.trim() ?? '';
    final mergedContext = system
        .skip(1)
        .map((m) => m['content']?.trim() ?? '')
        .where((text) => text.isNotEmpty)
        .join('\n\n');

    return [
      {'role': 'system', 'content': persona},
      if (mergedContext.isNotEmpty)
        {'role': 'system', 'content': mergedContext},
      ...rest,
    ];
  }
}
