import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/color_type_quiz_answers.dart';
import '../../../core/models/seasonal_color_type.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/color_type_calculator.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../data/color_type_quiz_questions.dart';

/// Lightweight appearance quiz → seasonal color type (no camera / Vision).
class ColorTypeQuizScreen extends StatefulWidget {
  const ColorTypeQuizScreen({super.key, this.fromProfile = false});

  /// When true, returns to profile after save instead of login/main.
  final bool fromProfile;

  @override
  State<ColorTypeQuizScreen> createState() => _ColorTypeQuizScreenState();
}

class _ColorTypeQuizScreenState extends State<ColorTypeQuizScreen> {
  final _pageController = PageController();
  final _selections = <String, String>{};

  int _currentIndex = 0;
  bool _showResult = false;
  SeasonalColorType? _resultType;

  static const _questions = ColorTypeQuizQuestions.questions;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String? _selectedFor(String questionId) => _selections[questionId];

  ColorTypeQuizAnswers get _answers => ColorTypeQuizAnswers(
        eyeColorId: _selections['eye_color'] ?? '',
        hairColorId: _selections['hair_color'] ?? '',
        skinUndertoneId: _selections['skin_undertone'] ?? '',
        contrastLevelId: _selections['contrast_level'] ?? '',
        skinDepthId: _selections['skin_depth'] ?? '',
      );

  void _selectOption(ColorTypeQuizQuestion question, String optionId) {
    setState(() {
      _selections[question.id] = optionId;
      _showResult = false;
      _resultType = null;
    });
  }

  void _onNext() {
    final question = _questions[_currentIndex];
    if (_selectedFor(question.id) == null) return;

    if (_currentIndex >= _questions.length - 1) {
      final type = ColorTypeCalculator.determine(_answers);
      setState(() {
        _resultType = type;
        _showResult = true;
      });
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _onBack() {
    if (_showResult) {
      setState(() => _showResult = false);
      return;
    }
    if (_currentIndex == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skip() async {
    await UserProfileRepository.instance.setColorTypeQuizCompleted(
      completed: true,
    );
    if (!mounted) return;
    _goNext();
  }

  Future<void> _saveAndContinue() async {
    final type = _resultType;
    if (type == null) return;

    await UserProfileRepository.instance.saveColorType(type);
    await UserProfileRepository.instance.setColorTypeQuizCompleted(
      completed: true,
    );
    if (!mounted) return;
    _goNext();
  }

  void _goNext() {
    if (widget.fromProfile) {
      context.pop(true);
      return;
    }
    final destination = AuthRepository.instance.isLoggedIn
        ? RouteNames.main
        : RouteNames.login;
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppBrandColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 0),
              child: Row(
                children: [
                  if (_currentIndex > 0 || _showResult)
                    IconButton(
                      onPressed: _onBack,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppBrandColors.title,
                    )
                  else
                    const SizedBox(width: 48),
                  const Expanded(
                    child: Text(
                      'Твой цветотип',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppBrandColors.title,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Позже',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_showResult) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: _QuizProgressBar(
                  progress: (_currentIndex + 1) / _questions.length,
                  label: 'Вопрос ${_currentIndex + 1} из ${_questions.length}',
                ),
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: _showResult
                    ? _ResultPanel(type: _resultType!)
                    : PageView.builder(
                        key: const ValueKey('quiz'),
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(),
                        onPageChanged: (index) =>
                            setState(() => _currentIndex = index),
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          final question = _questions[index];
                          return _QuestionPage(
                            question: question,
                            selectedId: _selectedFor(question.id),
                            onSelect: (id) => _selectOption(question, id),
                          );
                        },
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _showResult
                      ? _saveAndContinue
                      : (_selectedFor(_questions[_currentIndex].id) != null
                          ? _onNext
                          : null),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppBrandColors.pink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppBrandColors.pink.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _showResult ? 'Сохранить и продолжить' : 'Далее',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizProgressBar extends StatelessWidget {
  const _QuizProgressBar({
    required this.progress,
    required this.label,
  });

  final double progress;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: AppBrandColors.pink.withValues(alpha: 0.15),
            color: AppBrandColors.pink,
          ),
        ),
      ],
    );
  }
}

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({
    required this.question,
    required this.selectedId,
    required this.onSelect,
  });

  final ColorTypeQuizQuestion question;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppBrandColors.title,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            question.subtitle,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          ...question.options.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OptionCard(
                option: option,
                selected: selectedId == option.id,
                onTap: () => onSelect(option.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final ColorTypeQuizOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppBrandColors.pink
                  : AppBrandColors.pink.withValues(alpha: 0.12),
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppBrandColors.pink.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (option.icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppBrandColors.pink.withValues(alpha: 0.12)
                        : AppBrandColors.iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    option.icon,
                    color: AppBrandColors.pink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w600,
                        color: AppBrandColors.title,
                      ),
                    ),
                    if (option.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        option.subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.circle_outlined,
                color: selected ? AppBrandColors.pink : Colors.grey[400],
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.type});

  final SeasonalColorType type;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppBrandColors.pink.withValues(alpha: 0.22),
                  AppBrandColors.iconBackground,
                ],
              ),
            ),
            child: const Icon(
              Icons.palette_outlined,
              size: 56,
              color: AppBrandColors.pink,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Твой цветотип',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppBrandColors.pink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            type.displayNameRu,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppBrandColors.title,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            type.englishLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppBrandColors.pink.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.shortDescriptionRu,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Стилист будет подбирать образы с учётом этой палитры — '
                  'без фото и сложного анализа, только твои ответы.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
