import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';
import 'package:vocabo_core/vocabo_core.dart';

class DashboardSidebar extends ConsumerWidget {
  const DashboardSidebar({
    super.key,
    required this.selectedIndex,
    required this.onNavTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onNavTap;

  static const _sidebarBackground = Color(0xFF1A1B2E);

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
    final navItems = [
      (icon: Icons.auto_stories, label: l10n.sidebarLibrary),
      (icon: Icons.style_outlined, label: l10n.sidebarFlashcards),
      (icon: Icons.trending_up, label: l10n.sidebarProgress),
      (icon: Icons.settings_outlined, label: l10n.sidebarSettings),
    ];

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
          Row(
            children: [
              Image.asset(
                'assets/tray_icon@2x.png',
                width: 24,
                height: 24,
                color: Colors.white,
              ),
              const SizedBox(width: VocaboSpacing.sm),
              Text(
                'Vocabo',
                style: VocaboTypography.headlineSm.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: VocaboSpacing.xl),
          Text(
            l10n.sidebarPersonalWorkspace,
            style: VocaboTypography.labelSm.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: VocaboSpacing.md),
          ...List.generate(navItems.length, (i) {
            final item = navItems[i];
            final isFlashcards = i == DashboardSection.flashcards.index;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: VocaboNavItem(
                icon: item.icon,
                label: item.label,
                isActive: i == selectedIndex,
                badge: isFlashcards && dueCount > 0 ? '$dueCount' : null,
                onTap: () => onNavTap(i),
              ),
            );
          }),
          const Spacer(),
          VocaboPrimaryButton(
            label: l10n.sidebarAddNewWord,
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
