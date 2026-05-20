import 'package:flutter/widgets.dart';

import '../../data/repositories/auth_repository.dart';
import '../services/wardrobe_ai_context.dart';
import '../utils/logger.dart';

/// Refreshes local profile/wardrobe state when the app returns from background.
class AppLifecycleCoordinator extends StatefulWidget {
  const AppLifecycleCoordinator({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppLifecycleCoordinator> createState() => _AppLifecycleCoordinatorState();
}

class _AppLifecycleCoordinatorState extends State<AppLifecycleCoordinator>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResumed();
    }
  }

  Future<void> _onResumed() async {
    AppLogger.debug('AppLifecycleCoordinator: resumed');
    try {
      await AuthRepository.instance.repairStoredSession();
      WardrobeAiContext.instance.invalidate(reason: 'app_resumed');
    } catch (e, stack) {
      AppLogger.error(
        'AppLifecycleCoordinator: resume refresh failed',
        error: e,
        stackTrace: stack,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
