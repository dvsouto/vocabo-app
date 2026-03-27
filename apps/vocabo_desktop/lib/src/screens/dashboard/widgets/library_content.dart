import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/providers/dictionary_providers.dart';
import 'package:vocabo_desktop/src/providers/search_providers.dart';
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

    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final vocabList = ref.watch(userVocabularyListProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding:
              const EdgeInsets.all(VocaboSpacing.xl).copyWith(bottom: 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Library',
                      style: VocaboTypography.headlineSm,
                    ),
                    const SizedBox(height: VocaboSpacing.xs),
                    Text(
                      'Curating your intellectual vocabulary.',
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
                      hint: 'Quick search words...',
                      onChanged: (v) => ref
                          .read(searchQueryProvider.notifier)
                          .state = v,
                      suffixActions: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.tune,
                              size: 20,
                              color: VocaboColors.neutral,
                            ),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.more_vert,
                              size: 20,
                              color: VocaboColors.neutral,
                            ),
                            onPressed: () {},
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
                          ref
                              .read(searchQueryProvider.notifier)
                              .state = result.word;
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

        // Stats
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: VocaboSpacing.xl,
          ),
          child: StatsSection(),
        ),
        const SizedBox(height: VocaboSpacing.xl),

        // Vocabulary list with infinite scroll
        Expanded(
          child: vocabList.when(
            data: (vocabularies) => VocabularyList(
              userVocabularies: vocabularies,
              onLoadMore: () => ref
                  .read(userVocabularyListProvider.notifier)
                  .loadMore(),
              hasMore: ref
                  .read(userVocabularyListProvider.notifier)
                  .hasMore,
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (e, _) => Center(
              child: Text(
                'Failed to load vocabulary',
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
