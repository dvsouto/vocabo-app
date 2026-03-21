import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/data/mock_data.dart';
import 'package:vocabo_desktop/src/providers/window_mode_provider.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/dashboard_sidebar.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/stats_section.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/vocabulary_list.dart';
import 'package:vocabo_desktop/src/widgets/tray_panel/tray_panel.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedNavIndex = 0;

  void _dismissTrayPanel() {
    ref.read(trayPanelVisibleProvider.notifier).state = false;
  }

  @override
  Widget build(BuildContext context) {
    final isTrayPanelVisible = ref.watch(trayPanelVisibleProvider);

    return Scaffold(
      backgroundColor: VocaboColors.surface,
      body: Stack(
        children: [
          // Main dashboard content
          Row(
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
                            child: VocaboSearchField(
                              hint: 'Quick search words...',
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

          // Tray panel overlay
          if (isTrayPanelVisible) ...[
            // Dismiss barrier
            Positioned.fill(
              child: GestureDetector(
                onTap: _dismissTrayPanel,
                behavior: HitTestBehavior.opaque,
                child: const ColoredBox(color: Colors.transparent),
              ),
            ),
            // Panel positioned top-right
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 340,
                  constraints: const BoxConstraints(maxHeight: 500),
                  decoration: BoxDecoration(
                    color: VocaboColors.surfaceContainerLowest,
                    borderRadius: VocaboRadius.lg,
                    boxShadow: [
                      BoxShadow(
                        color: VocaboColors.onSurface.withValues(alpha: 0.08),
                        blurRadius: 40,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: TrayPanel(onOpenDashboard: _dismissTrayPanel),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
