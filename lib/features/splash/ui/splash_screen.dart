import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/route_names.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/onboarding_repository.dart';
import '../../../data/repositories/user_profile_repository.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Сплэш-экран с логотипом-анимацией и плавным исчезновением.
///
/// Что происходит:
/// 1. Показываем логотип с анимацией scale + fade.
/// 2. Ждём минимальное время (splashDelaySeconds).
/// 3. Проверяем авторизацию.
/// 4. Переходим на Home или Login через _fadeSlideUp из роутера.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _textFadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) => _navigateAfterDelay());
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(
      Duration(seconds: AppConstants.splashDelaySeconds),
    );
    if (!mounted) return;

    final onboardingDone = await OnboardingRepository.instance.isCompleted();
    if (!mounted) return;

    if (!onboardingDone) {
      context.go(RouteNames.onboarding);
      return;
    }

    final colorQuizDone =
        await UserProfileRepository.instance.isColorTypeQuizCompleted();
    if (!mounted) return;

    if (!colorQuizDone) {
      context.go(RouteNames.colorTypeQuiz);
      return;
    }

    final isLoggedIn = AuthRepository.instance.isLoggedIn;
    if (isLoggedIn) {
      context.go(RouteNames.main);
    } else {
      context.go(RouteNames.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Анимированный логотип
            ScaleTransition(
              scale: _scaleAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4FA0),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4FA0).withOpacity(0.35),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Название
            FadeTransition(
              opacity: _textFadeAnim,
              child: Text(
                loc.appName,
                style: textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFFFF4FA0),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Подпись
            FadeTransition(
              opacity: _textFadeAnim,
              child: Text(
                loc.splashLoading,
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey[400],
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Индикатор загрузки
            FadeTransition(
              opacity: _textFadeAnim,
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: const Color(0xFFFF4FA0).withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
