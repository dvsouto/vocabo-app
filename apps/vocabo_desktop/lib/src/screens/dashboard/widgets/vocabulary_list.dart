import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/data/mock_data.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/vocabulary_list_item.dart';

class VocabularyList extends StatelessWidget {
  const VocabularyList({super.key, required this.vocabularies});

  final List<Vocabulary> vocabularies;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
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
                'LAST PRACTICED',
                style: VocaboTypography.labelSm.copyWith(
                  color: VocaboColors.neutral,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VocaboSpacing.sm),

        // Items
        ...vocabularies.map((vocab) {
          return Padding(
            padding: const EdgeInsets.only(bottom: VocaboSpacing.md),
            child: VocabularyListItem(
              vocabulary: vocab,
              tags: MockDashboardData.tags[vocab.id] ?? [],
              lastPracticed: MockDashboardData.lastPracticed[vocab.id] ?? '',
            ),
          );
        }),
      ],
    );
  }
}
