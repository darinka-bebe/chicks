import 'package:flutter/material.dart';

import '../app.dart';
import '../core/localization/localized_app_shell.dart';
import '../core/bootstrap/env_bootstrap.dart';
import '../core/platform/app_platform_bootstrap.dart';
import '../core/services/firebase_bootstrap.dart';
import '../core/services/profile_bootstrap_service.dart';
import '../core/services/sync_coordinator.dart';
import '../core/storage/local_hive_storage.dart';
import '../core/theme/app_brand_colors.dart';
import '../l10n/generated/app_localizations.dart';
import '../core/utils/logger.dart';

/// Runs async startup AFTER [runApp] so Android plugins are registered on the engine.
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({super.key});

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate> {
  late final Future<void> _startup = _runStartup();

  static Future<void> _runStartup() async {
    await EnvBootstrap.load();

    AppLogger.info('AppStartupGate: begin startup');
    await FirebaseBootstrap.ensureInitialized();
    AppLogger.info('AppStartupGate: firebase ready');
    await LocalHiveStorage.initialize();
    AppLogger.info('AppStartupGate: hive ready');
    SyncCoordinator.instance.initialize();
    await ProfileBootstrapService.restoreOnStartup();
    AppLogger.info('AppStartupGate: startup complete (sync runs in background)');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return LocalizedAppShell.wrap(
            _StartupErrorScreen(error: snapshot.error),
          );
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return LocalizedAppShell.wrap(
            const _StartupLoadingScreen(),
          );
        }

        return AppPlatformBootstrap.wrapApp(const App());
      },
    );
  }
}

class _StartupLoadingScreen extends StatelessWidget {
  const _StartupLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppBrandColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppBrandColors.pink),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppBrandColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Text(
                loc.startupFirebaseError,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppBrandColors.title,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              Text(
                loc.startupRetryHint,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
