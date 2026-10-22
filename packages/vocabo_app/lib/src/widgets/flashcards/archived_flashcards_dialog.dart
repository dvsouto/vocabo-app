import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';

Future<void> showArchivedFlashcardsDialog(BuildContext context) {
  return showVocaboModal<void>(
    context: context,
    builder: (_) => const _ArchivedFlashcardsDialog(),
  );
}

class _ArchivedFlashcardsDialog extends ConsumerStatefulWidget {
  const _ArchivedFlashcardsDialog();

  @override
  ConsumerState<_ArchivedFlashcardsDialog> createState() =>
      _ArchivedFlashcardsDialogState();
}

class _ArchivedFlashcardsDialogState
    extends ConsumerState<_ArchivedFlashcardsDialog> {
  final Set<String> _restoring = {};

  Future<void> _restore(Flashcard flashcard) async {
    setState(() => _restoring.add(flashcard.id));

    try {
      await ref.read(flashcardWriterProvider).restore(flashcard);
      ref.invalidate(archivedFlashcardsProvider);
      ref.invalidate(flashcardStatusProvider);
    } catch (e, st) {
      appLogger.handle(e, st, 'Archived flashcards restore() error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.flashcardsRestoreFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _restoring.remove(flashcard.id));
    }
  }

  String _formatDate(DateTime date) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale).format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final archived = ref.watch(archivedFlashcardsProvider);
    final l10n = context.l10n;

    return VocaboDialog(
      backgroundColor: VocaboColors.surface,
      shape: RoundedRectangleBorder(borderRadius: VocaboRadius.lg),
      child: SizedBox(
        width: context.dialogWidth(480),
        child: Padding(
          padding: const EdgeInsets.all(VocaboSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.flashcardsArchivedTitle,
                    style: VocaboTypography.titleLg,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: VocaboColors.neutral,
                    onPressed: () => Navigator.of(context).pop(),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    style: const ButtonStyle(
                      mouseCursor: WidgetStatePropertyAll(
                        SystemMouseCursors.click,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VocaboSpacing.xs),
              Text(
                l10n.flashcardsArchivedRestoreHint,
                style: VocaboTypography.bodySm.copyWith(
                  color: VocaboColors.neutral,
                ),
              ),
              const SizedBox(height: VocaboSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 420),
                child: archived.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(VocaboSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => Padding(
                    padding: const EdgeInsets.all(VocaboSpacing.lg),
                    child: Text(
                      l10n.flashcardsArchivedLoadFailed,
                      style: VocaboTypography.bodyMd.copyWith(
                        color: VocaboColors.neutral,
                      ),
                    ),
                  ),
                  data: (cards) => cards.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: VocaboSpacing.lg,
                          ),
                          child: Text(
                            l10n.flashcardsArchivedEmpty,
                            style: VocaboTypography.bodyMd.copyWith(
                              color: VocaboColors.neutral,
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: cards.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: VocaboSpacing.sm),
                          itemBuilder: (context, index) {
                            final card = cards[index];
                            return _ArchivedRow(
                              flashcard: card,
                              dateLabel: _formatDate(card.updatedAt),
                              isRestoring: _restoring.contains(card.id),
                              onRestore: () => _restore(card),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchivedRow extends StatelessWidget {
  const _ArchivedRow({
    required this.flashcard,
    required this.dateLabel,
    required this.isRestoring,
    required this.onRestore,
  });

  final Flashcard flashcard;
  final String dateLabel;
  final bool isRestoring;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final term = flashcard.term.isEmpty ? '—' : flashcard.term;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: VocaboSpacing.md,
        vertical: VocaboSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLow,
        borderRadius: VocaboRadius.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  term,
                  style: VocaboTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  context.l10n.flashcardsArchivedOn(dateLabel),
                  style: VocaboTypography.bodySm.copyWith(
                    color: VocaboColors.neutral,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: isRestoring ? null : onRestore,
            style: TextButton.styleFrom(
              foregroundColor: VocaboColors.primary,
              enabledMouseCursor: SystemMouseCursors.click,
              disabledMouseCursor: SystemMouseCursors.basic,
            ),
            child: isRestoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.l10n.flashcardsRestore),
          ),
        ],
      ),
    );
  }
}
