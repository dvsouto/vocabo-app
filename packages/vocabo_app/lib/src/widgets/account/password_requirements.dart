import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';

/// Checklist of the password rules, ticked as the user types.
class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: VocaboSpacing.md,
      runSpacing: VocaboSpacing.xs,
      children: [
        for (final rule in PasswordRequirement.values)
          _Rule(
            label: context.l10n.passwordRequirementLabel(rule),
            met: rule.isMetBy(password),
          ),
      ],
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.label, required this.met});

  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final color = met ? VocaboColors.tertiary : VocaboColors.neutral;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: color,
        ),
        const SizedBox(width: VocaboSpacing.xs),
        Text(label, style: VocaboTypography.bodySm.copyWith(color: color)),
      ],
    );
  }
}
