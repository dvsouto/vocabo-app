import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/providers/add_word_providers.dart';

class DashboardSidebar extends ConsumerWidget {
  const DashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onNavTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onNavTap;

  static const _sidebarBackground = Color(0xFF1A1B2E);

  static const _navItems = [
    (icon: Icons.auto_stories, label: 'Library'),
    (icon: Icons.trending_up, label: 'Progress'),
    (icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 240,
      color: _sidebarBackground,
      padding: const EdgeInsets.symmetric(
        horizontal: VocaboSpacing.md,
        vertical: VocaboSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vocabo',
            style: VocaboTypography.headlineSm.copyWith(color: Colors.white),
          ),
          const SizedBox(height: VocaboSpacing.xl),
          Text(
            'PERSONAL WORKSPACE',
            style: VocaboTypography.labelSm.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: VocaboSpacing.md),
          ...List.generate(_navItems.length, (i) {
            final item = _navItems[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: VocaboNavItem(
                icon: item.icon,
                label: item.label,
                isActive: i == selectedIndex,
                onTap: () => onNavTap(i),
              ),
            );
          }),
          const Spacer(),
          VocaboPrimaryButton(
            label: '+ Add New Word',
            isExpanded: true,
            onPressed: () {
              ref.read(addWordInitialTermProvider.notifier).state = '';
              ref.read(showAddWordModalProvider.notifier).state = true;
            },
          ),
        ],
      ),
    );
  }
}
