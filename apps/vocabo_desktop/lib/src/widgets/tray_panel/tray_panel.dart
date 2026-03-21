import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/data/mock_data.dart';
import 'package:vocabo_desktop/src/widgets/tray_panel/tray_word_item.dart';

class TrayPanel extends StatefulWidget {
  const TrayPanel({super.key});

  @override
  State<TrayPanel> createState() => _TrayPanelState();
}

class _TrayPanelState extends State<TrayPanel> {
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allWords = MockDashboardData.trayWords;
    final matchedWord = _searchText.isNotEmpty
        ? allWords
            .where(
              (v) =>
                  v.term.toLowerCase().startsWith(_searchText.toLowerCase()),
            )
            .firstOrNull
        : null;

    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 480),
      padding: const EdgeInsets.all(VocaboSpacing.md),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLowest,
        borderRadius: VocaboRadius.lg,
        boxShadow: [VocaboShadows.whisper],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Text('Vocabo', style: VocaboTypography.titleLg),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.history, size: 20),
                  color: VocaboColors.neutral,
                  onPressed: () {},
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 20),
                  color: VocaboColors.neutral,
                  onPressed: () {},
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
              onChanged: (v) => setState(() => _searchText = v),
            ),

            // Autocomplete suggestion
            if (matchedWord != null && _searchText.isNotEmpty) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: VocaboColors.surfaceContainerLow,
                  borderRadius: VocaboRadius.sm,
                ),
                child: Row(
                  children: [
                    Text(
                      matchedWord.term,
                      style: VocaboTypography.bodyMd,
                    ),
                    const Spacer(),
                    Text(
                      matchedWord.wordType.value.substring(0, 3).toUpperCase(),
                      style: VocaboTypography.labelSm.copyWith(
                        color: VocaboColors.neutral,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: VocaboSpacing.sm),

            // Recent words
            ...allWords
                .where((v) => v.id != matchedWord?.id || _searchText.isEmpty)
                .take(3)
                .map((vocab) => TrayWordItem(vocabulary: vocab)),

            const SizedBox(height: VocaboSpacing.md),

            // Add new word button
            VocaboPrimaryButton(
              label: 'Add New Word',
              isExpanded: true,
              trailing: const Icon(
                Icons.add_circle_outline,
                color: VocaboColors.onPrimary,
                size: 18,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
