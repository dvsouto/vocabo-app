import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

/// Left-aligned underlined tabs that scroll sideways when they don't fit.
class SectionTabs extends StatelessWidget {
  const SectionTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.trailing = const {},
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Widgets shown after a tab label, such as a "PRO" badge.
  final Map<int, Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            _Tab(
              label: labels[index],
              trailing: trailing[index],
              isSelected: index == selectedIndex,
              onTap: () => onSelected(index),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: VocaboRadius.sm,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: VocaboSpacing.md),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? VocaboColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: VocaboTypography.bodyMd.copyWith(
                color: isSelected ? VocaboColors.primary : VocaboColors.neutral,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: VocaboSpacing.xs),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
