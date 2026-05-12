import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/logger.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../features/app/bloc/app_bloc.dart';
import '../../../features/app/bloc/app_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/google_sign_in_button.dart';

/// Экран входа с анимацией появления элементов.
///
/// Слушает [AppBloc] через [BlocListener]:
/// - Когда статус меняется на `authenticated` → плавный переход на Home.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late final AnimationController _controller;
  late final List<Animation<double>> _itemAnims;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Последовательная анимация для 3 элементов (лого, заголовок, кнопка)
    _itemAnims = List.generate(3, (i) {
      final start = i * 0.2;
      final end = start + 0.6;
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onSignInPressed() async {
    setState(() => _isLoading = true);
    try {
      await AuthRepository.instance.signInWithGoogle();
    } catch (error) {
      AppLogger.error('LoginScreen: ошибка входа', error: error);
      if (!mounted) return;
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.signInError),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _animated(int index, Widget child) {
    return FadeTransition(
      opacity: _itemAnims[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(_itemAnims[index]),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<AppBloc, AppState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status == AppStatus.authenticated) {
          context.go(RouteNames.main);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF0F5),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.largePadding,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Лого
                  _animated(
                    0,
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4FA0),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4FA0).withOpacity(0.3),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Заголовок и подзаголовок
                  _animated(
                    1,
                    Column(
                      children: [
                        Text(
                          loc.loginTitle,
                          style: textTheme.headlineLarge?.copyWith(
                            color: const Color(0xFFFF4FA0),
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        Text(
                          loc.loginSubtitle,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.largePadding * 2),

                  // Кнопка входа
                  _animated(
                    2,
                    GoogleSignInButton(
                      onPressed: _onSignInPressed,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
