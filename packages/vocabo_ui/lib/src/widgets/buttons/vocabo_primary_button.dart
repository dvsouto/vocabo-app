import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_radius.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

class VocaboPrimaryButton extends StatelessWidget {
  const VocaboPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.trailing,
    this.isLoading = false,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? trailing;
  final bool isLoading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        mouseCursor: isLoading || onPressed == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        borderRadius: VocaboRadius.md,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [VocaboColors.primary, VocaboColors.primaryContainer],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: VocaboRadius.md,
          ),
          child: Row(
            mainAxisSize:
                isExpanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: VocaboColors.onPrimary,
                  ),
                )
              else ...[
                Text(
                  label,
                  style: VocaboTypography.bodyMd.copyWith(
                    color: VocaboColors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
