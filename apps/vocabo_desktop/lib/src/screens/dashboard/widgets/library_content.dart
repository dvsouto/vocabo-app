import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/pro/plan_providers.dart';
import 'package:vocabo_desktop/src/pro/pro_feature_gate.dart';
import 'package:vocabo_desktop/src/providers/audio_player_providers.dart';
import 'package:vocabo_desktop/src/providers/discover_providers.dart';
import 'package:vocabo_desktop/src/providers/dictionary_providers.dart';
import 'package:vocabo_desktop/src/providers/search_providers.dart';
import 'package:vocabo_desktop/src/providers/user_preferences_provider.dart';
import 'package:vocabo_desktop/src/providers/user_vocabulary_providers.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/stats_section.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/vocabulary_list.dart';
import 'package:vocabo_desktop/src/widgets/discover/collections_catalog.dart';
import 'package:vocabo_desktop/src/widgets/discover/for_you_view.dart';
import 'package:vocabo_desktop/src/widgets/search/search_autocomplete_dropdown.dart';
import 'package:vocabo_desktop/src/widgets/section_tabs.dart';

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

    final tab = ref.watch(libraryTabProvider);
    final isPro = ref.watch(planStatusProvider).valueOrNull?.isPro ?? false;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.libraryTitle, style: VocaboTypography.headlineSm),
        const SizedBox(height: VocaboSpacing.xs),
        Text(
          l10n.librarySubtitle,
          style: VocaboTypography.bodyMd.copyWith(color: VocaboColors.neutral),
        ),
      ],
    );

    final search = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VocaboSearchField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          hint: l10n.librarySearchHint,
          onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
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
                  mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
                ),
              ),
            ],
          ),
        ),
        if (_showDropdown && query.isNotEmpty && searchResults.isNotEmpty) ...[
          const SizedBox(height: 4),
          SearchAutocompleteDropdown(
            results: searchResults.take(8).toList(),
            onSelected: (result) {
              _searchController.text = result.word;
              ref.read(searchQueryProvider.notifier).state = result.word;
            },
          ),
        ],
      ],
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(VocaboSpacing.xl).copyWith(bottom: 0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (tab != LibraryTab.myWords) {
                return SizedBox(width: double.infinity, child: titleBlock);
              }
              if (constraints.maxWidth < 720) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: VocaboSpacing.md),
                    search,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: VocaboSpacing.lg),
                  SizedBox(width: 320, child: search),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VocaboSpacing.xl - VocaboSpacing.md,
          ).copyWith(top: VocaboSpacing.md),
          child: Align(
            alignment: Alignment.centerLeft,
            child: SectionTabs(
              labels: [
                l10n.libraryTabMyWords,
                l10n.libraryTabForYou,
                l10n.libraryTabCollections,
              ],
              selectedIndex: tab.index,
              trailing: isPro ? const {} : const {1: ProBadge(), 2: ProBadge()},
              onSelected: (index) {
                final selected = LibraryTab.values[index];
                if (selected == LibraryTab.collections && tab == selected) {
                  ref.read(openCollectionIdProvider.notifier).state = null;
                }
                ref.read(libraryTabProvider.notifier).state = selected;
              },
            ),
          ),
        ),
        const SizedBox(height: VocaboSpacing.lg),
        Expanded(
          child: switch (tab) {
            LibraryTab.myWords => vocabList.when(
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
            LibraryTab.forYou => const Padding(
              padding: EdgeInsets.symmetric(horizontal: VocaboSpacing.xl),
              child: ForYouTab(),
            ),
            LibraryTab.collections => const Padding(
              padding: EdgeInsets.symmetric(horizontal: VocaboSpacing.xl),
              child: CollectionsTab(),
            ),
          },
        ),
      ],
    );
  }
}
