import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_app/src/pro/plan_providers.dart';
import 'package:vocabo_app/src/providers/dashboard_providers.dart';
import 'package:vocabo_app/src/providers/flashcard_providers.dart';

/// The phone counterpart of [DashboardSidebar]: the same four sections as
/// a bottom bar, with the due-card badge on Flashcards.
class DashboardBottomBar extends ConsumerWidget {
  const DashboardBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onNavTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onNavTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasCollections =
        ref.watch(planStatusProvider).valueOrNull?.limits.collections ?? false;
    final dueCount =
        (ref.watch(flashcardStatusProvider).valueOrNull?.dueCount ?? 0) +
        (hasCollections
            ? ref
                      .watch(
                        flashcardDeckStatusProvider(FlashcardDeck.collections),
                      )
                      .valueOrNull
                      ?.dueCount ??
                  0
            : 0);
    final l10n = context.l10n;
    final items = [
      (icon: Icons.auto_stories_outlined, label: l10n.sidebarLibrary),
      (icon: Icons.style_outlined, label: l10n.sidebarFlashcards),
      (icon: Icons.trending_up, label: l10n.sidebarProgress),
      (icon: Icons.settings_outlined, label: l10n.sidebarSettings),
    ];

    return Material(
      color: VocaboColors.surfaceContainerLowest,
      elevation: 8,
      shadowColor: Colors.black26,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(VocaboSpacing.sm),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _BottomBarItem(
                    icon: items[i].icon,
                    label: items[i].label,
                    selected: i == selectedIndex,
                    badge:
                        i == DashboardSection.flashcards.index && dueCount > 0
                        ? '$dueCount'
                        : null,
                    onTap: () => onNavTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One section of the bottom bar; the selected one is filled with the
/// primary color edge to edge, with white icon and label.
class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? VocaboColors.onPrimary
        : VocaboColors.onSurface;
    final iconWidget = Icon(icon, color: foreground, size: 24);

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: selected ? VocaboColors.primary : Colors.transparent,
          borderRadius: VocaboRadius.md,
          child: InkWell(
            onTap: onTap,
            borderRadius: VocaboRadius.md,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: VocaboSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  badge == null
                      ? iconWidget
                      : Badge(label: Text(badge!), child: iconWidget),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VocaboTypography.labelSm.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
