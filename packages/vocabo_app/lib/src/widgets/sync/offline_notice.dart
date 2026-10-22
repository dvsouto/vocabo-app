import 'package:flutter/material.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_app/src/sync/connectivity.dart';

/// Shown where content was never saved on this device and there is no
/// connection to fetch it.
class OfflineNotice extends StatelessWidget {
  const OfflineNotice({super.key, this.compact = false});

  final bool compact;

  /// [OfflineNotice] when [error] is a lost connection, [fallback] otherwise.
  static Widget orElse(Object error, Widget fallback, {bool compact = false}) =>
      isOfflineError(error) ? OfflineNotice(compact: compact) : fallback;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body = Text(
      l10n.offlineNoticeBody,
      textAlign: compact ? TextAlign.start : TextAlign.center,
      style: VocaboTypography.bodyMd.copyWith(color: VocaboColors.neutral600),
    );

    if (compact) {
      return Row(
        children: [
          const Icon(Icons.wifi_off, size: 18, color: VocaboColors.neutral),
          const SizedBox(width: VocaboSpacing.sm),
          Expanded(child: body),
        ],
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VocaboSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: VocaboColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off, color: VocaboColors.neutral),
            ),
            const SizedBox(height: VocaboSpacing.md),
            Text(l10n.offlineNoticeTitle, style: VocaboTypography.titleLg),
            const SizedBox(height: VocaboSpacing.xs),
            body,
          ],
        ),
      ),
    );
  }
}
