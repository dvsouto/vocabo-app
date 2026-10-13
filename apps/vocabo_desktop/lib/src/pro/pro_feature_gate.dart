import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/pro/paywall_dialog.dart';
import 'package:vocabo_desktop/src/pro/plan_providers.dart';

/// Shows [child] when the plan includes the feature and [ProLockedPanel]
/// otherwise, so free accounts still see what Pro offers.
class ProFeatureGate extends ConsumerWidget {
  const ProFeatureGate({
    super.key,
    required this.isIncluded,
    required this.icon,
    required this.title,
    required this.body,
    required this.child,
    this.compact = false,
  });

  final bool Function(PlanLimits limits) isIncluded;
  final IconData icon;
  final String title;
  final String body;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(planStatusProvider);
    final limits = status.valueOrNull?.limits;

    if (limits == null) {
      return status.hasError
          ? child
          : const Center(child: CircularProgressIndicator());
    }
    if (isIncluded(limits)) return child;

    final panel = ProLockedPanel(
      icon: icon,
      title: title,
      body: body,
      compact: compact,
    );
    if (compact) return panel;
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: panel,
        ),
      ),
    );
  }
}

/// The locked state of a Pro feature with the button that opens the
/// paywall. The full variant fills an empty tab; the compact one fits a
/// card inside a page.
class ProLockedPanel extends StatelessWidget {
  const ProLockedPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool compact;

  void _upgrade(BuildContext context) =>
      showPaywall(context, const UpgradeReason(UpgradeTrigger.feature));

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompact(context) : _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VocaboSpacing.xl),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLow,
        borderRadius: VocaboRadius.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: VocaboColors.primary50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: VocaboColors.primary, size: 28),
          ),
          const SizedBox(height: VocaboSpacing.md),
          const ProBadge(),
          const SizedBox(height: VocaboSpacing.sm),
          Text(
            title,
            style: VocaboTypography.titleLg,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VocaboSpacing.xs),
          Text(
            body,
            style: VocaboTypography.bodyMd.copyWith(
              color: VocaboColors.neutral600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VocaboSpacing.lg),
          VocaboPrimaryButton(
            label: context.l10n.proGateUnlock,
            onPressed: () => _upgrade(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: VocaboColors.primary),
            const SizedBox(width: VocaboSpacing.xs),
            Flexible(
              child: Text(
                title.toUpperCase(),
                style: VocaboTypography.labelSm.copyWith(
                  color: VocaboColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: VocaboSpacing.sm),
            const ProBadge(),
          ],
        ),
        const SizedBox(height: VocaboSpacing.xs),
        Text(
          body,
          style: VocaboTypography.bodyMd.copyWith(
            color: VocaboColors.neutral700,
          ),
        ),
      ],
    );
    final button = VocaboPrimaryButton(
      label: context.l10n.proGateUnlock,
      onPressed: () => _upgrade(context),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLowest,
        borderRadius: VocaboRadius.lg,
        boxShadow: [VocaboShadows.whisper],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 520
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  text,
                  const SizedBox(height: VocaboSpacing.md),
                  button,
                ],
              )
            : Row(
                children: [
                  Expanded(child: text),
                  const SizedBox(width: VocaboSpacing.md),
                  button,
                ],
              ),
      ),
    );
  }
}

/// The small "PRO" label shown on locked features.
class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: VocaboColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'PRO',
        style: VocaboTypography.labelSm.copyWith(
          color: VocaboColors.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}
