import '../../data/models/wardrobe_item.dart';
import '../models/stylist_request_context.dart';
import '../models/wardrobe_outfit_slot.dart';
import 'stylist_pipeline_safety.dart';

/// Result of trimming wardrobe for the AI system prompt.
class WardrobePromptSelection {
  const WardrobePromptSelection({
    required this.items,
    required this.totalCount,
  });

  final List<WardrobeItem> items;
  final int totalCount;

  int get promptCount => items.length;

  int get omittedCount => (totalCount - promptCount).clamp(0, totalCount);

  bool get wasTruncated => omittedCount > 0;
}

/// Picks a bounded, request-aware subset of wardrobe items for OpenAI prompts.
abstract final class WardrobePromptSelector {
  static const int maxItemsInPrompt = 40;
  static const int maxItemsPerSlot = 8;

  static WardrobePromptSelection select(
    List<WardrobeItem> wardrobe, {
    StylistRequestContext context = StylistRequestContext.empty,
  }) {
    final safe = StylistPipelineSafety.sanitizeWardrobe(wardrobe);
    if (safe.isEmpty) {
      return const WardrobePromptSelection(items: [], totalCount: 0);
    }

    if (safe.length <= maxItemsInPrompt) {
      return WardrobePromptSelection(items: safe, totalCount: safe.length);
    }

    final keywords = _contextKeywords(context);
    final grouped = StylistPipelineSafety.safeGroup(safe);
    final scored = <_ScoredItem>[];

    for (final slot in [...WardrobeOutfitSlotX.outfitOrder, WardrobeOutfitSlot.unknown]) {
      final slotItems = StylistPipelineSafety.itemsForSlot(grouped, slot);
      if (slotItems.isEmpty) continue;

      final ranked = slotItems
          .map(
            (item) => _ScoredItem(
              item: item,
              slot: slot,
              score: _scoreItem(item, keywords),
            ),
          )
          .toList()
        ..sort((a, b) => b.score.compareTo(a.score));

      final take = ranked.take(maxItemsPerSlot).toList();
      scored.addAll(take);
    }

    if (scored.length <= maxItemsInPrompt) {
      return WardrobePromptSelection(
        items: scored.map((e) => e.item).toList(),
        totalCount: safe.length,
      );
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final picked = scored.take(maxItemsInPrompt).toList();
    final pickedIds = picked.map((e) => e.item.id).toSet();

    // Ensure at least one item per slot that had candidates in the per-slot pass.
    final slotsInPool = scored.map((e) => e.slot).toSet();
    for (final slot in slotsInPool) {
      if (picked.any((e) => e.slot == slot)) continue;

      final replacement = scored.firstWhere(
        (e) => e.slot == slot && !pickedIds.contains(e.item.id),
        orElse: () => scored.firstWhere((e) => e.slot == slot),
      );

      if (pickedIds.contains(replacement.item.id)) continue;

      final weakest = picked.reduce(
        (a, b) => a.score <= b.score ? a : b,
      );
      if (replacement.score <= weakest.score) continue;

      pickedIds.remove(weakest.item.id);
      picked.remove(weakest);
      picked.add(replacement);
      pickedIds.add(replacement.item.id);
    }

    return WardrobePromptSelection(
      items: picked.map((e) => e.item).toList(),
      totalCount: safe.length,
    );
  }

  static Set<String> _contextKeywords(StylistRequestContext context) {
    final raw = [
      ...context.moods,
      ...context.weather,
      ...context.occasions,
    ];
    return raw
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();
  }

  static int _scoreItem(WardrobeItem item, Set<String> keywords) {
    if (keywords.isEmpty) return 0;

    final haystack = [
      item.title,
      item.category,
      item.color,
      item.season,
      item.fit,
      ...item.styles,
      ...item.occasions,
      ...item.vibes,
    ].join(' ').toLowerCase();

    var score = 0;
    for (final key in keywords) {
      if (haystack.contains(key)) score += 3;
      for (final part in key.split(RegExp(r'[\s_]+'))) {
        if (part.length >= 3 && haystack.contains(part)) score += 1;
      }
    }
    return score;
  }
}

class _ScoredItem {
  const _ScoredItem({
    required this.item,
    required this.slot,
    required this.score,
  });

  final WardrobeItem item;
  final WardrobeOutfitSlot slot;
  final int score;
}
