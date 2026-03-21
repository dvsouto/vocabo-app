import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/data/mock_data.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/dashboard_sidebar.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/stats_section.dart';
import 'package:vocabo_desktop/src/screens/dashboard/widgets/vocabulary_list.dart';
import 'package:vocabo_desktop/src/widgets/tray_panel/tray_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedNavIndex = 0;

  void _showTrayPanel() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => const Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.only(top: 40, right: 40),
          child: Material(
            color: Colors.transparent,
            child: TrayPanel(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                                onPressed: _showTrayPanel,
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
    );
  }
}
