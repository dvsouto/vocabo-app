import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_app/vocabo_app.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/providers/spotlight_providers.dart';

/// The global shortcut toggle, a desktop-only settings card.
class SpotlightSettingsCard extends ConsumerWidget {
  const SpotlightSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(spotlightEnabledProvider).valueOrNull ?? true;
    final l10n = context.l10n;

    return SettingsCard(
      icon: Icons.translate,
      iconColor: VocaboColors.primary,
      title: l10n.settingsShortcutsTitle,
      child: SettingsToggleRow(
        title: l10n.settingsSpotlightTitle,
        subtitle: l10n.settingsSpotlightSubtitle,
        value: enabled,
        onChanged: (value) =>
            ref.read(spotlightEnabledProvider.notifier).setEnabled(value),
      ),
    );
  }
}
