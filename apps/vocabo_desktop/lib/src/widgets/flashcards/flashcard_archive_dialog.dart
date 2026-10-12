import 'package:flutter/material.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';

/// Asks for confirmation only when the card already has review history,
/// since setting it aside discards its progress. Returns true to proceed.
Future<bool> confirmArchiveFlashcard(
  BuildContext context, {
  required bool hasHistory,
}) async {
  if (!hasHistory) return true;

  final l10n = context.l10n;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.flashcardsSetAsideTitle),
      content: Text(l10n.flashcardsSetAsideBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: Text(l10n.flashcardsSetAside),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
