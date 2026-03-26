import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

class SearchAutocompleteDropdown extends StatelessWidget {
  const SearchAutocompleteDropdown({
    super.key,
    required this.results,
    required this.onSelected,
  });

  final List<SearchResult> results;
  final ValueChanged<SearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLow,
        borderRadius: VocaboRadius.sm,
        boxShadow: [VocaboShadows.whisper],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: results.map((result) {
          final isUserWord = result.score >= 1.0;

          return InkWell(
            onTap: () => onSelected(result),
            borderRadius: VocaboRadius.sm,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Icon(
                    isUserWord ? Icons.star_rounded : Icons.menu_book_rounded,
                    size: 16,
                    color: isUserWord
                        ? VocaboColors.primary
                        : VocaboColors.neutral,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.word,
                      style: VocaboTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (result.score < 1.0)
                    Text(
                      'fuzzy',
                      style: VocaboTypography.labelSm.copyWith(
                        color: VocaboColors.neutral,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
