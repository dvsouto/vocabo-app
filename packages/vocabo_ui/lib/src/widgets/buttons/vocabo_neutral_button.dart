import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_radius.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

class VocaboNeutralButton extends StatelessWidget {
  const VocaboNeutralButton({
    super.key,
    required this.label,
    this.onPressed,
    this.leading,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    final contentColor =
        isDisabled ? VocaboColors.neutral : VocaboColors.onSurface;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: isDisabled ? VocaboColors.neutral50 : VocaboColors.neutral100,
          borderRadius: VocaboRadius.md,
        ),
        child: InkWell(
          onTap: onPressed,
          mouseCursor:
              isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
          borderRadius: VocaboRadius.md,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize:
                  isExpanded ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  IconTheme(
                    data: IconThemeData(color: contentColor, size: 16),
                    child: leading!,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: VocaboTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: contentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
