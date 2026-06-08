import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/models/color_type_quiz_answers.dart';
import '../../../core/models/seasonal_color_type.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/color_type_calculator.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../data/color_type_quiz_questions.dart';
import '../widgets/quiz_option_card.dart';
import '../widgets/quiz_progress_bar.dart';
import '../widgets/onboarding_funnel_header.dart';
import '../data/onboarding_funnel.dart';
import '../widgets/color_type_palette_card.dart';
import '../widgets/quiz_visual_registry.dart';
import '../widgets/quiz_visual_theme.dart';

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

  List<ColorTypeQuizQuestion> get _questions => ColorTypeQuizQuestions.questions;

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
    context.go(RouteNames.bodyTypeQuiz);
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
                  Expanded(
                    child: Text(
                      AppLocale.pick(
                        ru: 'Твой цветотип',
                        en: 'Your color type',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppBrandColors.title,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      AppLocale.pick(ru: 'Позже', en: 'Later'),
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
              if (!widget.fromProfile)
                OnboardingFunnelHeader(
                  step: OnboardingFunnel.stepColorQuiz,
                  title: AppLocale.pick(
                    ru: 'Определение цветотипа',
                    en: 'Color type analysis',
                  ),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  widget.fromProfile ? 8 : 4,
                  24,
                  0,
                ),
                child: QuizProgressBar(
                  progress: (_currentIndex + 1) / _questions.length,
                  label: AppLocale.pick(
                    ru: 'Вопрос ${_currentIndex + 1} из ${_questions.length}',
                    en: 'Question ${_currentIndex + 1} of ${_questions.length}',
                  ),
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
                    _showResult
                        ? AppLocale.pick(
                            ru: 'Сохранить и продолжить',
                            en: 'Save and continue',
                          )
                        : AppLocale.pick(ru: 'Далее', en: 'Next'),
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
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        8 + MediaQuery.viewInsetsOf(context).bottom,
      ),
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
              padding: const EdgeInsets.only(bottom: QuizVisualTheme.optionCardGap),
              child: QuizOptionCard(
                label: option.label,
                hint: option.subtitle,
                selected: selectedId == option.id,
                onTap: () => onSelect(option.id),
                leading: QuizVisualRegistry.forColorOption(
                  option.id,
                  emphasized: selectedId == option.id,
                ),
              ),
            ),
          ),
        ],
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
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppBrandColors.pink.withValues(alpha: 0.12),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppBrandColors.pink.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ColorTypePaletteCard.fromColorType(
                  type: type,
                  emphasized: true,
                  swatchSize: QuizVisualTheme.resultPreviewSize,
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
                  AppLocale.pick(
                    ru: 'Стилист будет подбирать образы с учётом этой палитры — '
                        'без фото и сложного анализа, только твои ответы.',
                    en: 'The stylist will use this palette for outfits — '
                        'no photos or complex analysis, just your answers.',
                  ),
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
