import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/vocabulary_list_item.dart';

class VocabularyList extends StatelessWidget {
  const VocabularyList({
    super.key,
    required this.userVocabularies,
    this.onLoadMore,
    this.hasMore = false,
  });

  final List<UserVocabulary> userVocabularies;
  final VoidCallback? onLoadMore;
  final bool hasMore;

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
        itemCount: userVocabularies.length + 1 + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Header row
          if (index == 0) {
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
                      'WORD',
                      style: VocaboTypography.labelSm.copyWith(
                        color: VocaboColors.neutral,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'MEANING & USAGE',
                      style: VocaboTypography.labelSm.copyWith(
                        color: VocaboColors.neutral,
                      ),
                    ),
                  ),
                  Text(
                    'ADDED',
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
            child: VocabularyListItem(
              userVocabulary: uv,
            ),
          );
        },
      ),
    );
  }
}
