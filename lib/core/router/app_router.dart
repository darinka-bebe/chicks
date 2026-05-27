import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/debug/ui/test_image_screen.dart';
import '../../features/chat/ui/chat_screen.dart';
import '../../features/chat/widgets/wardrobe_snapshot_scope.dart';
import '../../data/models/favorite_outfit.dart';
import '../../data/models/outfit_history_entry.dart';
import '../../data/models/wardrobe_item.dart';
import '../../features/favorites/ui/favorite_outfit_details_screen.dart';
import '../../features/favorites/ui/favorites_screen.dart';
import '../../features/outfit_history/ui/outfit_history_details_screen.dart';
import '../../features/outfit_history/ui/outfit_history_screen.dart';
import '../../features/wardrobe/ui/add_wardrobe_item_screen.dart';
import '../../features/wardrobe/ui/wardrobe_item_details_screen.dart';
import '../../features/wardrobe/ui/wardrobe_insights_screen.dart';
import '../../features/wardrobe/ui/wardrobe_screen.dart';
import '../../features/home/ui/home_shell.dart';
import '../../features/home/ui/main_tab.dart';
import '../../features/profile/ui/profile.dart';
import '../../features/app/ui/registration_screen.dart';
import '../../features/login/ui/login_screen.dart';
import '../../features/onboarding/ui/body_type_quiz_screen.dart';
import '../../features/onboarding/ui/color_type_quiz_screen.dart';
import '../../features/onboarding/ui/onboarding_screen.dart';
import '../../features/splash/ui/splash_screen.dart';
import '../../features/tutorial/ui/tutorial_screen.dart';
import 'app_navigation_guard.dart';
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
    redirect: AppNavigationGuard.redirect,
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
        name: RouteNames.colorTypeQuizName,
        path: RouteNames.colorTypeQuiz,
        builder: (context, state) {
          final fromProfile = state.uri.queryParameters['from'] == 'profile';
          return ColorTypeQuizScreen(fromProfile: fromProfile);
        },
      ),
      GoRoute(
        name: RouteNames.bodyTypeQuizName,
        path: RouteNames.bodyTypeQuiz,
        builder: (context, state) {
          final fromProfile = state.uri.queryParameters['from'] == 'profile';
          return BodyTypeQuizScreen(fromProfile: fromProfile);
        },
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
      GoRoute(
        name: RouteNames.tutorialName,
        path: RouteNames.tutorial,
        pageBuilder: (context, state) {
          final fromProfile = state.uri.queryParameters['from'] == 'profile';
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: TutorialScreen(fromProfile: fromProfile),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.04),
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
        builder: (context, state) {
          final extra = state.extra;
          final restoreEntry = extra is OutfitHistoryEntry ? extra : null;
          final initialPrompt = extra is String ? extra : null;
          return ChatScreen(
            restoreEntry: restoreEntry,
            initialPrompt: initialPrompt,
          );
        },
      ),
      GoRoute(
        name: RouteNames.outfitHistoryName,
        path: RouteNames.outfitHistory,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OutfitHistoryScreen(),
        routes: [
          GoRoute(
            name: RouteNames.outfitHistoryDetailsName,
            path: 'item',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final entry = state.extra as OutfitHistoryEntry?;
              if (entry == null) {
                return const Scaffold(
                  body: Center(child: Text('Образ не найден')),
                );
              }
              return WardrobeSnapshotLoader(
                child: OutfitHistoryDetailsScreen(entry: entry),
              );
            },
          ),
        ],
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
            builder: (context, state) {
              final editItem = state.extra as WardrobeItem?;
              return AddWardrobeItemScreen(editItem: editItem);
            },
          ),
          GoRoute(
            name: RouteNames.wardrobeInsightsName,
            path: 'insights',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) => const WardrobeInsightsScreen(),
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
