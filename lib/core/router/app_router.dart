import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/ui/chat_screen.dart';
import '../../features/home/ui/home_shell.dart';
import '../../features/home/ui/main_tab.dart';
import '../../features/profile/ui/profile.dart';
import '../../features/app/ui/registration_screen.dart';
import '../../features/login/ui/login_screen.dart';
import '../../features/splash/ui/splash_screen.dart';
import 'route_names.dart';

/// Конфигурация навигации (GoRouter).
class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GlobalKey<NavigatorState> shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  /// Единый экземпляр роутера (не создавать заново в build).
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RouteNames.splash,
    routes: [
      GoRoute(
        name: RouteNames.splashName,
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: RouteNames.loginName,
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: RouteNames.registrationName,
        path: RouteNames.registration,
        builder: (context, state) => const RegistrationScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            name: RouteNames.mainName,
            path: RouteNames.main,
            builder: (context, state) => const MainTab(),
          ),
          GoRoute(
            name: RouteNames.profileName,
            path: RouteNames.profile,
            builder: (context, state) => const ProfileTab(),
          ),
        ],
      ),
      GoRoute(
        name: RouteNames.chatName,
        path: RouteNames.chat,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ChatScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Страница не найдена: ${state.uri}',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    ),
  );

  @Deprecated('Use AppRouter.router')
  static GoRouter create() => router;
}
