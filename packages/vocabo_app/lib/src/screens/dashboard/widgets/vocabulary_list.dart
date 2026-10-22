import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/src/screens/dashboard/widgets/vocabulary_list_item.dart';

class VocabularyList extends StatelessWidget {
  const VocabularyList({
    super.key,
    required this.userVocabularies,
    this.onLoadMore,
    this.hasMore = false,
    this.leading,
  });

  final List<UserVocabulary> userVocabularies;
  final VoidCallback? onLoadMore;
  final bool hasMore;

  /// Scrolls together with the list, above the column titles.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200 &&
            hasMore) {
          onLoadMore?.call();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: VocaboSpacing.xl),
        itemCount:
            (leading == null ? 0 : 1) +
            1 +
            (userVocabularies.isEmpty ? 1 : userVocabularies.length) +
            (hasMore ? 1 : 0),
        itemBuilder: (context, position) {
          if (leading != null && position == 0) return leading!;
          final index = leading == null ? position : position - 1;

          if (userVocabularies.isEmpty) {
            return index == 0 ? const SizedBox.shrink() : const _EmptyLibrary();
          }

          // Header row, only where the columns have room
          if (index == 0) {
            if (context.isCompact) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VocaboSpacing.lg,
                vertical: VocaboSpacing.sm,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: Text(
                      context.l10n.libraryColumnWord,
                      style: VocaboTypography.labelSm.copyWith(
                        color: VocaboColors.neutral,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      context.l10n.libraryColumnMeaning,
                      style: VocaboTypography.labelSm.copyWith(
                        color: VocaboColors.neutral,
                      ),
                    ),
                  ),
                  Text(
                    context.l10n.libraryColumnAdded,
                    style: VocaboTypography.labelSm.copyWith(
                      color: VocaboColors.neutral,
                    ),
                  ),
                ],
              ),
            );
          }

          // Loading indicator at the bottom
          if (index == userVocabularies.length + 1) {
            return const Padding(
              padding: EdgeInsets.all(VocaboSpacing.lg),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          final uv = userVocabularies[index - 1];
          if (uv.vocabulary == null) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.only(bottom: VocaboSpacing.md),
            child: VocabularyListItem(userVocabulary: uv),
          );
        },
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(VocaboSpacing.xxl),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLow,
        borderRadius: VocaboRadius.lg,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_stories_outlined,
            size: 32,
            color: VocaboColors.primary,
          ),
          const SizedBox(height: VocaboSpacing.md),
          Text(l10n.libraryEmptyTitle, style: VocaboTypography.titleLg),
          const SizedBox(height: VocaboSpacing.xs),
          Text(
            l10n.libraryEmptyBody(l10n.addWordTitle),
            textAlign: TextAlign.center,
            style: VocaboTypography.bodyMd.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
        ],
      ),
    );
  }
}
