import 'package:flutter/material.dart';

/// Asks for confirmation only when the card already has review history,
/// since archiving discards its progress. Returns true to proceed.
Future<bool> confirmArchiveFlashcard(
  BuildContext context, {
  required bool hasHistory,
}) async {
  if (!hasHistory) return true;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Archive this flashcard?'),
      content: const Text(
        'Its review progress will be lost. You can restore it later from '
        'the archived cards list, starting again from D+0.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: const Text('Archive'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
