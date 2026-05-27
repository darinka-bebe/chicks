import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../data/repositories/tutorial_repository.dart';
import '../../data/repositories/user_profile_repository.dart';
import 'route_names.dart';

/// Prevents navigation loops (e.g. reopening finished onboarding).
abstract final class AppNavigationGuard {
  static Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final path = state.uri.path;
    if (path == RouteNames.splash) return null;

    final fromProfile = state.uri.queryParameters['from'] == 'profile';
    if (fromProfile) return null;

    final onboardingDone = await OnboardingRepository.instance.isCompleted();
    final colorDone =
        await UserProfileRepository.instance.isColorTypeQuizCompleted();
    final bodyDone =
        await UserProfileRepository.instance.isBodyTypeQuizCompleted();
    final loggedIn = AuthRepository.instance.isLoggedIn;

    if (loggedIn &&
        (path == RouteNames.login || path == RouteNames.registration)) {
      return RouteNames.main;
    }

    if (onboardingDone && path == RouteNames.onboarding) {
      return loggedIn ? RouteNames.main : RouteNames.login;
    }

    if (colorDone && path == RouteNames.colorTypeQuiz) {
      if (bodyDone) {
        return loggedIn ? RouteNames.main : RouteNames.login;
      }
      return RouteNames.bodyTypeQuiz;
    }

    if (bodyDone && path == RouteNames.bodyTypeQuiz) {
      return loggedIn ? RouteNames.main : RouteNames.login;
    }

    if (path == RouteNames.tutorial && !fromProfile) {
      final tutorialDone = await TutorialRepository.instance.isCompleted();
      if (tutorialDone) {
        return loggedIn ? RouteNames.main : RouteNames.login;
      }
    }

    return null;
  }
}
