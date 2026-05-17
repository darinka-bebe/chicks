import 'package:equatable/equatable.dart';

/// Parsed stylist reply: display text + wardrobe item references for UI cards.
class StylistResponse extends Equatable {
  const StylistResponse({
    required this.message,
    this.recommendedItemIds = const [],
  });

  final String message;
  final List<String> recommendedItemIds;

  bool get hasRecommendations => recommendedItemIds.isNotEmpty;

  @override
  List<Object?> get props => [message, recommendedItemIds];
}
