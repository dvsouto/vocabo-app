import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/pro/paywall_dialog.dart';
import 'package:vocabo_desktop/src/pro/plan_providers.dart';

/// Placeholder for the Pro statistics on the free plan.
class ProLockedCard extends StatelessWidget {
  const ProLockedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VocaboSpacing.xl),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLow,
        borderRadius: VocaboRadius.lg,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.insights_outlined,
            size: 32,
            color: VocaboColors.primary,
          ),
          const SizedBox(height: VocaboSpacing.md),
          Text(
            l10n.proStatsLockedTitle,
            style: VocaboTypography.titleLg,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VocaboSpacing.xs),
          Text(
            l10n.proStatsLockedBody,
            style: VocaboTypography.bodyMd.copyWith(
              color: VocaboColors.neutral600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VocaboSpacing.lg),
          VocaboPrimaryButton(
            label: l10n.proUpgradeButton,
            onPressed: () => showPaywall(
              context,
              const UpgradeReason(UpgradeTrigger.feature),
            ),
          ),
        ],
      ),
    );
  }
}
