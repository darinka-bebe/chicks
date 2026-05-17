import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/debug/ui/test_image_screen.dart';
import '../../features/chat/ui/chat_screen.dart';
import '../../data/models/favorite_outfit.dart';
import '../../data/models/wardrobe_item.dart';
import '../../features/favorites/ui/favorite_outfit_details_screen.dart';
import '../../features/favorites/ui/favorites_screen.dart';
import '../../features/wardrobe/ui/add_wardrobe_item_screen.dart';
import '../../features/wardrobe/ui/wardrobe_item_details_screen.dart';
import '../../features/wardrobe/ui/wardrobe_screen.dart';
import '../../features/home/ui/home_shell.dart';
import '../../features/home/ui/main_tab.dart';
import '../../features/profile/ui/profile.dart';
import '../../features/app/ui/registration_screen.dart';
import '../../features/login/ui/login_screen.dart';
import '../../features/onboarding/ui/onboarding_screen.dart';
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
        name: RouteNames.onboardingName,
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
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
      GoRoute(
        name: RouteNames.favoritesName,
        path: RouteNames.favorites,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FavoritesScreen(),
        routes: [
          GoRoute(
            name: RouteNames.favoriteOutfitDetailsName,
            path: 'item',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final outfit = state.extra as FavoriteOutfit?;
              if (outfit == null) {
                return const Scaffold(
                  body: Center(child: Text('Образ не найден')),
                );
              }
              return FavoriteOutfitDetailsScreen(outfit: outfit);
            },
          ),
        ],
      ),
      GoRoute(
        name: RouteNames.testImageName,
        path: RouteNames.testImage,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TestImageScreen(),
      ),
      GoRoute(
        name: RouteNames.wardrobeName,
        path: RouteNames.wardrobe,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WardrobeScreen(),
        routes: [
          GoRoute(
            name: RouteNames.addWardrobeItemName,
            path: 'add',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const AddWardrobeItemScreen(),
          ),
          GoRoute(
            name: RouteNames.wardrobeItemDetailsName,
            path: 'item',
            parentNavigatorKey: rootNavigatorKey,
            pageBuilder: (context, state) {
              final item = state.extra as WardrobeItem?;
              if (item == null) {
                return const MaterialPage(
                  child: Scaffold(
                    body: Center(child: Text('Вещь не найдена')),
                  ),
                );
              }
              return CustomTransitionPage<void>(
                key: state.pageKey,
                child: WardrobeItemDetailsScreen(item: item),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.06),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );
                  return SlideTransition(
                    position: slide,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
              );
            },
          ),
        ],
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
