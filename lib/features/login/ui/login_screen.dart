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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _onSignInPressed() async {
    setState(() => _isLoading = true);

    try {
      await AuthRepository.instance.signInWithGoogle();
    } catch (error) {
      AppLogger.error('Ошибка входа', error: error);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка входа через Google'),
        ),
         );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openRegistration() {
    context.go(RouteNames.registration);
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.largePadding,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  loc.loginTitle,
                  style: textTheme.headlineLarge,
                ),
                const SizedBox(height: 12),

                Text(
                  loc.loginSubtitle,
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                GoogleSignInButton(
                  onPressed: _onSignInPressed,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: _openRegistration,
                  child: const Text('Создать аккаунт'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}