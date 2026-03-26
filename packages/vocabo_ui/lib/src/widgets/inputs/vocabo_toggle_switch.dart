import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

class VocaboToggleSwitch extends StatelessWidget {
  const VocaboToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 24,
          width: 44,
          child: Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: VocaboColors.primary,
            activeThumbColor: VocaboColors.onPrimary,
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 8),
          Text(
            label!,
            style: VocaboTypography.bodySm.copyWith(
              color: VocaboColors.onSurface,
            ),
          ),
        ],
      ],
    );
  }
}
