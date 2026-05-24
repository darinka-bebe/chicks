import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../core/sync/sync_scope.dart';
import '../../features/favorites/favorites_controller.dart';
import '../../features/outfit_history/outfit_history_controller.dart';
import '../../features/sync/sync_state_controller.dart';
import '../../features/wardrobe/wardrobe_controller.dart';

/// Wires cloud sync refresh events to local UI controllers.
class SyncRefreshBinder extends StatefulWidget {
  const SyncRefreshBinder({super.key, required this.child});

  final Widget child;

  @override
  State<SyncRefreshBinder> createState() => _SyncRefreshBinderState();
}

class _SyncRefreshBinderState extends State<SyncRefreshBinder> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bindRefreshHandlers());
  }

  void _bindRefreshHandlers() {
    if (!mounted) return;

    final sync = context.read<SyncStateController>();
    final wardrobe = context.read<WardrobeController>();
    final favorites = context.read<FavoritesController>();
    final history = context.read<OutfitHistoryController>();

    sync.registerRefreshHandler(
      SyncScope.wardrobe,
      wardrobe.reloadFromStorage,
    );
    sync.registerRefreshHandler(
      SyncScope.favorites,
      favorites.refresh,
    );
    sync.registerRefreshHandler(
      SyncScope.outfitHistory,
      history.refresh,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
