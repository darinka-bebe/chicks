import '../../../core/constants/wardrobe_catalog.dart';
import '../../../data/models/wardrobe_item.dart';

/// Picks up to [max] aesthetic labels from wardrobe metadata for outfit chips.
abstract final class OutfitItemTags {
  static const int maxChips = 2;

  static List<String> aestheticLabels(WardrobeItem item) {
    final seen = <String>{};
    final labels = <String>[];

    void add(String? value) {
      final normalized = _normalize(value);
      if (normalized == null || seen.contains(normalized)) return;
      seen.add(normalized);
      labels.add(normalized);
    }

    for (final style in item.styles) {
      add(style);
      if (labels.length >= maxChips) return labels;
    }
    for (final vibe in item.vibes) {
      add(vibe);
      if (labels.length >= maxChips) return labels;
    }

    return labels;
  }

  static String? _normalize(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final label = _displayLabel(trimmed);
    if (label.length <= 18) return label;
    return '${label.substring(0, 16)}…';
  }

  static String _displayLabel(String raw) {
    if (WardrobeCatalog.vibes.contains(raw)) {
      return WardrobeCatalog.displayVibe(raw);
    }
    if (WardrobeCatalog.styles.contains(raw)) {
      return raw;
    }
    return WardrobeCatalog.displayMetadata(raw);
  }
}
