import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/post_auth_navigation.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/logger.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../features/app/bloc/app_bloc.dart';
import '../../../features/app/bloc/auth_state.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/google_sign_in_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _onGoogleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await AuthRepository.instance.signInWithGoogle();
      // Success: AppBloc navigates via BlocListener — no snackbar.
    } on AuthException catch (e) {
      if (!mounted || e.isCancelled) return;
      _showError(e.message);
    } catch (error, stack) {
      AppLogger.error('LoginScreen: Google sign-in failed', error: error, stackTrace: stack);
      if (!mounted) return;
      _showError('Не удалось войти через Google. Проверьте интернет и настройки Firebase.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
  }

  void _openRegistration() {
    context.push(RouteNames.registration);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<AppBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == AppStatus.authenticated,
      listener: (context, state) async {
        final destination = await PostAuthNavigation.destinationAfterAuth();
        if (!context.mounted) return;
        context.go(destination);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF0F5),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.largePadding,
                vertical: 24,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    loc.loginTitle,
                    style: textTheme.headlineLarge?.copyWith(
                      color: const Color(0xFFFF4FA0),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  GoogleSignInButton(
                    onPressed: _isLoading ? null : _onGoogleSignIn,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _isLoading ? null : _openRegistration,
                    child: const Text('Создать аккаунт по email'),
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
