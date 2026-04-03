import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

class VocaboTextButton extends StatelessWidget {
  const VocaboTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.uppercase = false,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool uppercase;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: VocaboColors.primary,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: VocaboTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
        overlayColor: Colors.transparent,
      ).copyWith(
        mouseCursor: WidgetStatePropertyAll(
          onPressed != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            IconTheme(
              data: const IconThemeData(
                color: VocaboColors.primary,
                size: 16,
              ),
              child: leading!,
            ),
            const SizedBox(width: 6),
          ],
          Text(uppercase ? label.toUpperCase() : label),
        ],
      ),
    );
  }
}
