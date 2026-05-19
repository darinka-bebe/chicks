import '../../data/models/wardrobe_item.dart';
import '../models/body_profile.dart';
import '../models/body_shape_type.dart';
import '../models/wardrobe_outfit_slot.dart';
import 'wardrobe_slot_classifier.dart';

/// Outfit-level silhouette rules (combinations, not single items).
abstract final class SilhouetteBalancer {
  static bool isOversized(WardrobeItem item) {
    final text = '${item.fit} ${item.title} ${item.styles.join(" ")}'
        .toLowerCase();
    return text.contains('oversized') ||
        text.contains('oversize') ||
        text.contains('baggy') ||
        text.contains('мешков');
  }

  static bool isFitted(WardrobeItem item) {
    final text = '${item.fit} ${item.title}'.toLowerCase();
    return text.contains('slim') ||
        text.contains('fitted') ||
        text.contains('притал') ||
        text.contains('облег');
  }

  /// Bonus/penalty when picking an item given slots already chosen.
  static double combinationDelta({
    required WardrobeItem candidate,
    required WardrobeOutfitSlot slot,
    required Map<WardrobeOutfitSlot, WardrobeItem> selected,
    BodyProfile? profile,
  }) {
    if (profile == null) return 0;

    final trial = Map<WardrobeOutfitSlot, WardrobeItem>.from(selected)
      ..[slot] = candidate;

    return outfitHarmonyScore(trial, profile) - 0.5;
  }

  /// 0..1 — higher is better balanced for body shape.
  static double outfitHarmonyScore(
    Map<WardrobeOutfitSlot, WardrobeItem> outfit,
    BodyProfile profile,
  ) {
    var score = 0.65;

    final top = outfit[WardrobeOutfitSlot.top] ?? outfit[WardrobeOutfitSlot.dress];
    final bottom = outfit[WardrobeOutfitSlot.bottom];
    final topOver = top != null && isOversized(top);
    final bottomOver = bottom != null && isOversized(bottom);

    if (topOver && bottomOver) {
      score -= switch (profile.shape) {
        BodyShapeType.pear => 0.35,
        BodyShapeType.apple => 0.3,
        BodyShapeType.rectangle => 0.25,
        _ => 0.2,
      };
    }

    if (profile.prefersFitted && topOver && bottomOver) {
      score -= 0.15;
    }

    if (profile.prefersOversized && !topOver && bottom != null && !bottomOver) {
      score -= 0.05;
    }

    score += _shapeSpecificBonus(profile.shape, outfit, top, bottom);

    return score.clamp(0.0, 1.0);
  }

  static double _shapeSpecificBonus(
    BodyShapeType shape,
    Map<WardrobeOutfitSlot, WardrobeItem> outfit,
    WardrobeItem? top,
    WardrobeItem? bottom,
  ) {
    return switch (shape) {
      BodyShapeType.pear => _pearBonus(top, bottom),
      BodyShapeType.invertedTriangle => _invertedBonus(top, bottom),
      BodyShapeType.hourglass => _hourglassBonus(top, bottom),
      BodyShapeType.apple => _appleBonus(top, bottom),
      BodyShapeType.rectangle => _rectangleBonus(top, bottom),
    };
  }

  static double _pearBonus(WardrobeItem? top, WardrobeItem? bottom) {
    var b = 0.0;
    if (top != null && (isFitted(top) || _hasStructure(top))) b += 0.12;
    if (bottom != null &&
        top != null &&
        isOversized(bottom) &&
        isOversized(top)) {
      b -= 0.2;
    }
    if (bottom != null && !isOversized(bottom)) b += 0.06;
    return b;
  }

  static double _invertedBonus(WardrobeItem? top, WardrobeItem? bottom) {
    var b = 0.0;
    if (top != null && isOversized(top)) b -= 0.1;
    if (bottom != null && isOversized(bottom)) b += 0.08;
    return b;
  }

  static double _hourglassBonus(WardrobeItem? top, WardrobeItem? bottom) {
    if (top != null && bottom != null && isFitted(top) && isFitted(bottom)) {
      return 0.1;
    }
    if (top != null && isOversized(top) && bottom != null && isOversized(bottom)) {
      return -0.15;
    }
    return 0.0;
  }

  static double _appleBonus(WardrobeItem? top, WardrobeItem? bottom) {
    var b = 0.0;
    if (top != null && _hasStructure(top)) b += 0.08;
    if (bottom != null &&
        top != null &&
        isFitted(bottom) &&
        isOversized(top)) {
      b += 0.05;
    }
    return b;
  }

  static double _rectangleBonus(WardrobeItem? top, WardrobeItem? bottom) {
    if (top != null && bottom != null) {
      if (isFitted(top) || isFitted(bottom)) return 0.08;
    }
    return 0.0;
  }

  static bool _hasStructure(WardrobeItem item) {
    final t = item.title.toLowerCase();
    return t.contains('пиджак') ||
        t.contains('жакет') ||
        t.contains('рубаш') ||
        t.contains('blazer');
  }

  static double scoreItemForBody({
    required WardrobeItem item,
    required BodyProfile profile,
  }) {
    final slot = WardrobeSlotClassifier.classify(item);
    final text = '${item.fit} ${item.title} ${item.category}'.toLowerCase();
    var score = 0.5;

    switch (profile.shape) {
      case BodyShapeType.pear:
        if (slot == WardrobeOutfitSlot.top &&
            (_hasStructure(item) || isFitted(item))) {
          score += 0.25;
        }
        if (slot == WardrobeOutfitSlot.bottom && isOversized(item)) {
          score -= 0.1;
        }
      case BodyShapeType.invertedTriangle:
        if (slot == WardrobeOutfitSlot.bottom && isOversized(item)) {
          score += 0.15;
        }
        if (slot == WardrobeOutfitSlot.top && isOversized(item)) {
          score -= 0.12;
        }
      case BodyShapeType.hourglass:
        if (isFitted(item) || text.contains('пояс') || text.contains('wrap')) {
          score += 0.2;
        }
      case BodyShapeType.apple:
        if (slot == WardrobeOutfitSlot.top && _hasStructure(item)) {
          score += 0.15;
        }
        if (text.contains('притал') && slot == WardrobeOutfitSlot.top) {
          score -= 0.08;
        }
      case BodyShapeType.rectangle:
        if (text.contains('пояс') || text.contains('peplum')) score += 0.15;
    }

    if (profile.prefersFitted && isFitted(item)) score += 0.1;
    if (profile.prefersOversized && isOversized(item)) score += 0.1;

    return score.clamp(0.0, 1.0);
  }
}
