import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_spacing.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

class VocaboTabBar extends StatelessWidget {
  const VocaboTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: VocaboColors.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: _VocaboTab(
              label: tabs[index],
              isSelected: isSelected,
              onTap: () => onTabChanged(index),
            ),
          );
        }),
      ),
    );
  }
}

class _VocaboTab extends StatelessWidget {
  const _VocaboTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: VocaboSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? VocaboColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: VocaboTypography.bodyMd.copyWith(
              color: isSelected ? VocaboColors.primary : VocaboColors.neutral,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
