import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/sync/sync_state.dart';
import '../../../core/theme/app_brand_colors.dart';
import '../sync_state_controller.dart';

class SyncStatusBanner extends StatelessWidget {
  const SyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<SyncStateController, SyncState>(
      selector: (_, controller) => controller.state,
      builder: (context, state, _) {
        if (state.phase == SyncPhase.idle) return const SizedBox.shrink();

        final canRetry = state.canRetry;
        final isSyncing = state.phase == SyncPhase.syncing;
        final isOffline = state.phase == SyncPhase.offline;
        final isError = state.phase == SyncPhase.error;

        final icon = isSyncing
            ? Icons.cloud_sync_rounded
            : isError
                ? Icons.cloud_off_rounded
                : isOffline
                    ? Icons.wifi_off_rounded
                    : Icons.cloud_done_rounded;

        final text = state.message ??
            (isSyncing
                ? 'Синхронизируем данные…'
                : isError
                    ? 'Не удалось синхронизировать. Попробуй снова.'
                    : isOffline
                        ? 'Нет сети. Продолжаем работать локально.'
                        : 'Синхронизация завершена');

        final background = isError || isOffline
            ? const Color(0xFFFFF1F4)
            : const Color(0xFFFFF7FA);

        final borderColor = isError || isOffline
            ? AppBrandColors.pink.withValues(alpha: 0.25)
            : AppBrandColors.pink.withValues(alpha: 0.15);

        return IgnorePointer(
          ignoring: !canRetry,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: Container(
                  key: ValueKey('${state.phase}:${state.message}'),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      if (isSyncing)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(icon, size: 18, color: AppBrandColors.pink),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppBrandColors.title,
                          ),
                        ),
                      ),
                      if (canRetry)
                        TextButton(
                          onPressed: context.read<SyncStateController>().retry,
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
