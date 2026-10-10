import 'package:flutter/material.dart';

/// Asks for confirmation only when the card already has review history,
/// since setting it aside discards its progress. Returns true to proceed.
Future<bool> confirmArchiveFlashcard(
  BuildContext context, {
  required bool hasHistory,
}) async {
  if (!hasHistory) return true;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Set this word aside?'),
      content: const Text(
        'It leaves your reviews and its progress is reset. The word stays in '
        'your library, and you can bring it back anytime from Archived.',
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
          child: const Text('Set aside'),
        ),
      ],
    ),
  );

  return confirmed ?? false;
}
