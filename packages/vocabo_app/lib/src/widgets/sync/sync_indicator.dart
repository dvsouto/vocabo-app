import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_app/src/sync/connectivity.dart';
import 'package:vocabo_app/src/sync/sync_engine.dart';

/// Small status mark: a spinning sync icon while changes download, a
/// "no connection" icon offline, nothing otherwise.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key, this.color, this.showLabel = false});

  final Color? color;

  /// Writes "No connection" next to the icon (phones, where there is no
  /// hover tooltip).
  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);
    final status = ref.watch(syncEngineProvider);
    final l10n = context.l10n;
    final tint = color ?? VocaboColors.neutral;

    if (!online) {
      final message = status.pending > 0
          ? '${l10n.syncOffline} · ${l10n.syncOfflinePending(status.pending)}'
          : l10n.syncOffline;
      return Tooltip(
        message: message,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 16, color: tint),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                l10n.syncOffline,
                style: VocaboTypography.labelSm.copyWith(color: tint),
              ),
            ],
          ],
        ),
      );
    }
    if (!status.downloading) return const SizedBox.shrink();
    return Tooltip(
      message: l10n.syncDownloading,
      child: SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: tint),
      ),
    );
  }
}
