import 'package:flutter/material.dart';

import '../../../core/theme/app_brand_colors.dart';
import '../../../l10n/generated/app_localizations.dart';

class ChatEmptyState extends StatelessWidget {
  const ChatEmptyState({super.key, required this.onSuggestionTap});

  final ValueChanged<String> onSuggestionTap;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final suggestions = [
      _Suggestion(
        emoji: '🏫',
        title: loc.chatSuggestionSchoolTitle,
        prompt: loc.chatSuggestionSchoolPrompt,
      ),
      _Suggestion(
        emoji: '🌧',
        title: loc.chatSuggestionRainTitle,
        prompt: loc.chatSuggestionRainPrompt,
      ),
      _Suggestion(
        emoji: '💖',
        title: loc.chatSuggestionDateTitle,
        prompt: loc.chatSuggestionDatePrompt,
      ),
      _Suggestion(
        emoji: '✨',
        title: loc.chatSuggestionCasualTitle,
        prompt: loc.chatSuggestionCasualPrompt,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppBrandColors.iconBackground,
                  AppBrandColors.pink.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppBrandColors.pink.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppBrandColors.pink,
              size: 40,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            loc.chatEmptyGreeting,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppBrandColors.title,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            loc.chatEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              loc.chatEmptyTryAsking,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SuggestionTile(
                suggestion: suggestion,
                onTap: () => onSuggestionTap(suggestion.prompt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Suggestion {
  const _Suggestion({
    required this.emoji,
    required this.title,
    required this.prompt,
  });

  final String emoji;
  final String title;
  final String prompt;
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.suggestion,
    required this.onTap,
  });

  final _Suggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppBrandColors.pink.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Text(suggestion.emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  suggestion.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppBrandColors.title,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppBrandColors.pink.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
