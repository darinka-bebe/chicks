import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../../../data/repositories/tutorial_repository.dart';
import '../data/tutorial_pages.dart';
import '../../../core/widgets/chicks_hint_chip.dart';
import '../widgets/tutorial_illustration.dart';
import '../widgets/tutorial_progress_indicator.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, this.fromProfile = false});

  final bool fromProfile;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _pages = TutorialPages.slides;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await TutorialRepository.instance.setCompleted();
    if (!mounted) return;

    if (widget.fromProfile && context.canPop()) {
      context.pop();
      return;
    }
    context.go(RouteNames.main);
  }

  void _onNext() {
    if (_currentPage >= _pages.length - 1) {
      _finish();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppBrandColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  if (widget.fromProfile)
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppBrandColors.title,
                    )
                  else
                    const SizedBox(width: 8),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Пропустить',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                children: [
                  Text(
                    '${_currentPage + 1} / ${_pages.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Знакомство с Chicks',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppBrandColors.pink.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return _TutorialSlide(
                    data: _pages[index],
                    pageIndex: index,
                    isActive: index == _currentPage,
                  );
                },
              ),
            ),
            TutorialProgressIndicator(
              count: _pages.length,
              index: _currentPage,
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppBrandColors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    isLastPage ? 'Начать стиль ✨' : 'Далее',
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

class _TutorialSlide extends StatelessWidget {
  const _TutorialSlide({
    required this.data,
    required this.pageIndex,
    required this.isActive,
  });

  final TutorialPageData data;
  final int pageIndex;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isActive ? 1 : 0.92,
      duration: const Duration(milliseconds: 280),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          children: [
            TutorialIllustration(data: data, pageIndex: pageIndex),
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: Column(
                key: ValueKey<int>(pageIndex),
                children: [
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppBrandColors.title,
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            if (data.hint != null) ...[
              const SizedBox(height: 24),
              ChicksHintChip(text: data.hint!),
            ],
          ],
        ),
      ),
    );
  }
}
