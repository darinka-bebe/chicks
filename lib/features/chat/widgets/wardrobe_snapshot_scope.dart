import 'package:flutter/widgets.dart';

import '../../../core/services/wardrobe_ai_context.dart';
import '../../../data/models/wardrobe_item.dart';

/// Single wardrobe load for the chat screen — avoids N× Hive reads while scrolling.
class WardrobeSnapshotScope extends InheritedWidget {
  const WardrobeSnapshotScope({
    super.key,
    required this.items,
    required this.revision,
    required super.child,
  });

  final List<WardrobeItem> items;
  final int revision;

  static WardrobeSnapshotScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<WardrobeSnapshotScope>();
    assert(scope != null, 'WardrobeSnapshotScope not found in widget tree');
    return scope!;
  }

  static WardrobeSnapshotScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<WardrobeSnapshotScope>();
  }

  @override
  bool updateShouldNotify(WardrobeSnapshotScope oldWidget) {
    return revision != oldWidget.revision ||
        !identical(items, oldWidget.items);
  }
}

/// Loads wardrobe once and provides [WardrobeSnapshotScope] to chat descendants.
class WardrobeSnapshotLoader extends StatefulWidget {
  const WardrobeSnapshotLoader({super.key, required this.child});

  final Widget child;

  @override
  State<WardrobeSnapshotLoader> createState() => _WardrobeSnapshotLoaderState();
}

class _WardrobeSnapshotLoaderState extends State<WardrobeSnapshotLoader> {
  List<WardrobeItem> _items = const [];
  int _revision = -1;

  @override
  void initState() {
    super.initState();
    final cached = WardrobeAiContext.instance.cachedItems;
    if (cached != null) {
      _items = cached;
      _revision = WardrobeAiContext.instance.revision;
    }
    WardrobeAiContext.instance.addListener(_onWardrobeChanged);
    if (cached == null) {
      _load();
    }
  }

  @override
  void dispose() {
    WardrobeAiContext.instance.removeListener(_onWardrobeChanged);
    super.dispose();
  }

  void _onWardrobeChanged() {
    final nextRevision = WardrobeAiContext.instance.revision;
    if (nextRevision == _revision) return;
    _load();
  }

  Future<void> _load() async {
    final revision = WardrobeAiContext.instance.revision;
    final items = await WardrobeAiContext.instance.loadForPrompt();
    if (!mounted) return;
    setState(() {
      _items = items;
      _revision = revision;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WardrobeSnapshotScope(
      revision: _revision,
      items: _items,
      child: widget.child,
    );
  }
}
