import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/data/mock_data.dart';
import 'package:vocabo_desktop/src/providers/dictionary_providers.dart';
import 'package:vocabo_desktop/src/providers/search_providers.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/dashboard_sidebar.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/stats_section.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/vocabulary_list.dart';
import 'package:vocabo_desktop/src/widgets/search/search_autocomplete_dropdown.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedNavIndex = 0;
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
    // Trigger dictionary initialization
    ref.watch(dictionaryInitProvider);

    final searchResults = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: VocaboColors.surface,
      body: Row(
        children: [
          DashboardSidebar(
            selectedIndex: _selectedNavIndex,
            onNavTap: (i) => setState(() => _selectedNavIndex = i),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(VocaboSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
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
                  const SizedBox(height: VocaboSpacing.xl),

                  // Stats
                  const StatsSection(),
                  const SizedBox(height: VocaboSpacing.xl),

                  // Vocabulary list
                  VocabularyList(
                    vocabularies: MockDashboardData.vocabularies,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
