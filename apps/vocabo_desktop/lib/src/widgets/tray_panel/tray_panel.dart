import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/providers/dictionary_providers.dart';
import 'package:vocabo_desktop/src/providers/search_providers.dart';
import 'package:vocabo_desktop/src/widgets/search/search_autocomplete_dropdown.dart';
import 'package:vocabo_desktop/src/widgets/tray_panel/tray_word_item.dart';

class TrayPanel extends ConsumerStatefulWidget {
  const TrayPanel({super.key, this.onOpenDashboard});

  final VoidCallback? onOpenDashboard;

  @override
  ConsumerState<TrayPanel> createState() => _TrayPanelState();
}

class _TrayPanelState extends ConsumerState<TrayPanel> {
  static const _channel = MethodChannel('vocabo/tray_panel_actions');

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openApp() {
    if (widget.onOpenDashboard != null) {
      widget.onOpenDashboard!();
    } else {
      _channel.invokeMethod('openApp');
    }
  }

  void _openAddWord() {
    final term = _searchController.text.trim();
    _channel.invokeMethod('openAddWord', {'term': term});
  }

  void _confirmQuit() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit Vocabo'),
        content: const Text('Are you sure you want to quit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _channel.invokeMethod('quitApp');
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dictionaryInitProvider);

    final searchResults = ref.watch(localSearchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final recentWords = ref.watch(recentCachedVocabularyProvider(query));

    final isInVocabulary = ref.watch(localIsTermInVocabularyProvider(query));
    final showAddButton = query.isNotEmpty && !isInVocabulary;

    return Padding(
      padding: const EdgeInsets.all(VocaboSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Text('Vocabo', style: VocaboTypography.titleLg),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 18),
                color: VocaboColors.neutral,
                tooltip: 'Open Dashboard',
                onPressed: _openApp,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.power_settings_new, size: 20),
                color: VocaboColors.neutral,
                tooltip: 'Quit Vocabo',
                onPressed: _confirmQuit,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: VocaboSpacing.sm),

          // Search
          VocaboSearchField(
            controller: _searchController,
            hint: 'Search words...',
            autofocus: true,
            onChanged: (v) =>
                ref.read(searchQueryProvider.notifier).state = v,
          ),

          // Autocomplete suggestions
          if (query.isNotEmpty && searchResults.isNotEmpty) ...[
            const SizedBox(height: 4),
            SearchAutocompleteDropdown(
              results: searchResults.take(5).toList(),
              onSelected: (result) {
                _searchController.text = result.word;
                ref.read(searchQueryProvider.notifier).state = result.word;
              },
            ),
          ],
          const SizedBox(height: VocaboSpacing.sm),

          // Recent words list
          Expanded(
            child: recentWords.when(
              data: (words) {
                if (words.isEmpty) {
                  return Center(
                    child: Text(
                      query.isEmpty
                          ? 'No words yet'
                          : 'No matching words',
                      style: VocaboTypography.bodySm.copyWith(
                        color: VocaboColors.neutral,
                      ),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent Words',
                      style: VocaboTypography.labelSm.copyWith(
                        color: VocaboColors.neutral,
                      ),
                    ),
                    const Divider(height: 12),
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: words.length,
                        itemBuilder: (context, index) =>
                            TrayWordItem(
                              vocabulary: words[index].vocabulary!,
                            ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => Center(
                child: Text(
                  'Failed to load words',
                  style: VocaboTypography.bodySm.copyWith(
                    color: VocaboColors.neutral,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: VocaboSpacing.sm),

          // Single conditional button
          VocaboPrimaryButton(
            label: showAddButton ? 'Add New Word' : 'Dashboard',
            isExpanded: true,
            trailing: showAddButton
                ? const Icon(
                    Icons.add_circle_outline,
                    color: VocaboColors.onPrimary,
                    size: 18,
                  )
                : null,
            onPressed: showAddButton ? _openAddWord : _openApp,
          ),
        ],
      ),
    );
  }
}
