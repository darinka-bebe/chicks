import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'features/app/bloc/app_bloc.dart';
import 'features/favorites/favorites_controller.dart';
import 'features/wardrobe/wardrobe_controller.dart';
import 'l10n/generated/app_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(
          create: (_) => AppBloc(authRepository: AuthRepository.instance),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesController()..ensureLoaded(),
        ),
        ChangeNotifierProvider(
          create: (_) => WardrobeController(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Chicks',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }
}
