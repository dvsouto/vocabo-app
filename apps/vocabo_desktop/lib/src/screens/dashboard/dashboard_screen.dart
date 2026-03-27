import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/providers/add_word_providers.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/dashboard_sidebar.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/library_content.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/progress_content.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/settings_content.dart';
import 'package:vocabo_desktop/src/widgets/add_word_modal/add_word_modal.dart';

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

  @override
  Widget build(BuildContext context) {
    final showModal = ref.watch(showAddWordModalProvider);
    final initialTerm = ref.watch(addWordInitialTermProvider);

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

          // Modal overlay
          if (showModal) ...[
            GestureDetector(
              onTap: () {
                ref.read(addWordNotifierProvider.notifier).reset();
                ref.read(showAddWordModalProvider.notifier).state = false;
              },
              child: Container(
                color: Colors.black54,
              ),
            ),
            AddWordModal(
              initialTerm: initialTerm.isNotEmpty ? initialTerm : null,
            ),
          ],
        ],
      ),
    );
  }
}
