import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

class VocaboTextButton extends StatelessWidget {
  const VocaboTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.uppercase = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: VocaboColors.primary,
        minimumSize: const Size(44, 44),
        textStyle: uppercase
            ? VocaboTypography.labelSm
            : VocaboTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
      ).copyWith(
        mouseCursor: WidgetStatePropertyAll(
          onPressed != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
        ),
      ),
      child: Text(uppercase ? label.toUpperCase() : label),
    );
  }
}
