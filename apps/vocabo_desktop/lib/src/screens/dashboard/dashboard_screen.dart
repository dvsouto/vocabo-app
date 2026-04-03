import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/providers/add_word_providers.dart';
import 'package:vocabo_desktop/src/providers/word_detail_providers.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/dashboard_sidebar.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/library_content.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/progress_content.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/settings_content.dart';
import 'package:vocabo_desktop/src/widgets/add_word_modal/add_word_modal.dart';
import 'package:vocabo_desktop/src/widgets/word_detail_modal/word_detail_modal.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedNavIndex = 0;

  Widget _buildContent() {
    return switch (_selectedNavIndex) {
      0 => const LibraryContent(),
      1 => const ProgressContent(),
      2 => const SettingsContent(),
      _ => const LibraryContent(),
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
                selectedIndex: _selectedNavIndex,
                onNavTap: (i) => setState(() => _selectedNavIndex = i),
              ),
              Expanded(child: _buildContent()),
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
