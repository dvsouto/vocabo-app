import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/providers/audio_player_providers.dart';
import 'package:vocabo_desktop/src/providers/dictionary_providers.dart';
import 'package:vocabo_desktop/src/providers/search_providers.dart';
import 'package:vocabo_desktop/src/providers/user_preferences_provider.dart';
import 'package:vocabo_desktop/src/providers/user_vocabulary_providers.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/stats_section.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/vocabulary_list.dart';
import 'package:vocabo_desktop/src/widgets/search/search_autocomplete_dropdown.dart';

class LibraryContent extends ConsumerStatefulWidget {
  const LibraryContent({super.key});

  @override
  ConsumerState<LibraryContent> createState() => _LibraryContentState();
}

class _LibraryContentState extends ConsumerState<LibraryContent> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      setState(() {
        _showDropdown = _searchFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dictionaryInitProvider);

    ref.listen(userVocabularyListProvider, (prev, next) {
      next.whenData((vocabularies) {
        ref.read(audioPrefetchServiceProvider).prefetch(vocabularies);
      });
    });

    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final vocabList = ref.watch(userVocabularyListProvider);
    final showTranslations = ref.watch(showTranslationsProvider);
    final l10n = context.l10n;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(VocaboSpacing.xl).copyWith(bottom: 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.libraryTitle, style: VocaboTypography.headlineSm),
                    const SizedBox(height: VocaboSpacing.xs),
                    Text(
                      l10n.librarySubtitle,
                      style: VocaboTypography.bodyMd.copyWith(
                        color: VocaboColors.neutral,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VocaboSearchField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      hint: l10n.librarySearchHint,
                      onChanged: (v) =>
                          ref.read(searchQueryProvider.notifier).state = v,
                      suffixActions: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: showTranslations
                                ? l10n.libraryHideMeanings
                                : l10n.libraryShowMeanings,
                            icon: Icon(
                              showTranslations
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                              color: showTranslations
                                  ? VocaboColors.neutral
                                  : VocaboColors.primary,
                            ),
                            onPressed: () => ref
                                .read(userPreferencesProvider.notifier)
                                .toggleShowTranslations(),
                            style: const ButtonStyle(
                              mouseCursor: WidgetStatePropertyAll(
                                SystemMouseCursors.click,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_showDropdown &&
                        query.isNotEmpty &&
                        searchResults.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      SearchAutocompleteDropdown(
                        results: searchResults.take(8).toList(),
                        onSelected: (result) {
                          _searchController.text = result.word;
                          ref.read(searchQueryProvider.notifier).state =
                              result.word;
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VocaboSpacing.xl),

        // Vocabulary list with infinite scroll
        Expanded(
          child: vocabList.when(
            data: (vocabularies) => VocabularyList(
              userVocabularies: vocabularies,
              leading: const Padding(
                padding: EdgeInsets.only(bottom: VocaboSpacing.xl),
                child: StatsSection(),
              ),
              onLoadMore: () =>
                  ref.read(userVocabularyListProvider.notifier).loadMore(),
              hasMore: ref.read(userVocabularyListProvider.notifier).hasMore,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                l10n.libraryLoadFailed,
                style: VocaboTypography.bodyMd.copyWith(
                  color: VocaboColors.neutral,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
