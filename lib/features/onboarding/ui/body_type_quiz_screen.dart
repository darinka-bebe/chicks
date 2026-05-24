import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/body_profile.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/body_shape_calculator.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../data/body_type_quiz_questions.dart';
import '../widgets/quiz_option_card.dart';
import '../widgets/quiz_progress_bar.dart';
import '../widgets/onboarding_funnel_header.dart';
import '../data/onboarding_funnel.dart';
import '../widgets/quiz_visual_registry.dart';
import '../widgets/quiz_visual_theme.dart';

/// Body shape + fit preferences quiz (no photos).
class BodyTypeQuizScreen extends StatefulWidget {
  const BodyTypeQuizScreen({super.key, this.fromProfile = false});

  final bool fromProfile;

  @override
  State<BodyTypeQuizScreen> createState() => _BodyTypeQuizScreenState();
}

class _BodyTypeQuizScreenState extends State<BodyTypeQuizScreen> {
  final _pageController = PageController();
  final _selections = <String, String>{};

  int _currentIndex = 0;
  bool _showResult = false;
  BodyProfile? _resultProfile;

  static const _questions = BodyTypeQuizQuestions.questions;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String? _selectedFor(String questionId) => _selections[questionId];

  BodyTypeQuizAnswers get _answers => BodyTypeQuizAnswers(
        shapeId: _selections['body_shape'] ?? '',
        shoulderHipsId: _selections['shoulder_hips'] ?? '',
        waistId: _selections['waist'] ?? '',
        fitPreferenceId: _selections['fit_pref'] ?? '',
        heightId: _selections['height'] ?? '',
      );

  void _selectOption(BodyTypeQuizQuestion question, String optionId) {
    setState(() {
      _selections[question.id] = optionId;
      _showResult = false;
      _resultProfile = null;
    });
  }

  void _onNext() {
    final question = _questions[_currentIndex];
    if (_selectedFor(question.id) == null) return;

    if (_currentIndex >= _questions.length - 1) {
      setState(() {
        _resultProfile = BodyShapeCalculator.determine(_answers);
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
    await UserProfileRepository.instance.setBodyTypeQuizCompleted(
      completed: true,
    );
    if (!mounted) return;
    _goNext();
  }

  Future<void> _saveAndContinue() async {
    final profile = _resultProfile;
    if (profile == null) return;

    await UserProfileRepository.instance.saveBodyProfile(profile);
    await UserProfileRepository.instance.setBodyTypeQuizCompleted(
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
                      'Тип фигуры',
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
              if (!widget.fromProfile)
                const OnboardingFunnelHeader(
                  step: OnboardingFunnel.stepBodyQuiz,
                  title: 'Тип фигуры и посадка',
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
                  label: 'Вопрос ${_currentIndex + 1} из ${_questions.length}',
                ),
              ),
              const SizedBox(height: 8),
            ],
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                child: _showResult
                    ? _ResultPanel(profile: _resultProfile!)
                    : PageView.builder(
                        key: const ValueKey('body_quiz'),
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

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({
    required this.question,
    required this.selectedId,
    required this.onSelect,
  });

  final BodyTypeQuizQuestion question;
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
                hint: option.hint,
                selected: selectedId == option.id,
                onTap: () => onSelect(option.id),
                leading: QuizVisualRegistry.forBodyOption(
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
  const _ResultPanel({required this.profile});

  final BodyProfile profile;

  @override
  Widget build(BuildContext context) {
    final shape = profile.shape;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        children: [
          Center(
            child: QuizVisualRegistry.forBodyResult(
              shape,
              size: QuizVisualTheme.resultPreviewSize,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            shape.displayNameRu,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppBrandColors.title,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            shape.englishLabel,
            style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Text(
            shape.shortDescriptionRu,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Стилист будет балансировать силуэт и учитывать посадку: ${profile.fitPreference.isNotEmpty ? profile.fitPreference : "универсальная"}.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.45),
          ),
        ],
      ),
    );
  }
}
