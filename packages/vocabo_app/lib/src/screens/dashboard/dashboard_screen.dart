import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_app/vocabo_app.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Widget _buildContent(DashboardSection section) {
    return switch (section) {
      DashboardSection.flashcards => const FlashcardsContent(),
      DashboardSection.progress => const ProgressContent(),
      DashboardSection.settings => const SettingsContent(),
      DashboardSection.library => const LibraryContent(),
    };
  }

  Widget _buildModalOverlay(VoidCallback onClose) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onClose,
        mouseCursor: SystemMouseCursors.basic,
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(color: Colors.black54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dailyReminderServiceProvider);
    final section = ref.watch(dashboardSectionProvider);
    final showAddWordModal = ref.watch(showAddWordModalProvider);
    final initialTerm = ref.watch(addWordInitialTermProvider);
    final showWordDetail = ref.watch(showWordDetailModalProvider);
    final selectedWord = ref.watch(selectedWordProvider);

    return Scaffold(
      backgroundColor: VocaboColors.surface,
      body: Stack(
        children: [
          Row(
            children: [
              DashboardSidebar(
                selectedIndex: section.index,
                onNavTap: (i) =>
                    ref.read(dashboardSectionProvider.notifier).state =
                        DashboardSection.values[i],
              ),
              Expanded(child: _buildContent(section)),
            ],
          ),

          // Word detail modal overlay
          if (showWordDetail && selectedWord != null) ...[
            _buildModalOverlay(() {
              ref.read(showWordDetailModalProvider.notifier).state = false;
              ref.read(selectedWordProvider.notifier).state = null;
            }),
            WordDetailModal(userVocabulary: selectedWord),
          ],

          // Add word modal overlay
          if (showAddWordModal) ...[
            _buildModalOverlay(() {
              ref.read(addWordNotifierProvider.notifier).reset();
              ref.read(showAddWordModalProvider.notifier).state = false;
            }),
            AddWordModal(
              initialTerm: initialTerm.isNotEmpty ? initialTerm : null,
            ),
          ],
        ],
      ),
    );
  }
}
