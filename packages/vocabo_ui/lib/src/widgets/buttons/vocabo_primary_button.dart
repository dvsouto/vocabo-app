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
    final isDisabled = isLoading || onPressed == null;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: isDisabled
              ? null
              : const LinearGradient(
                  colors: [VocaboColors.primary, VocaboColors.primaryContainer],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
          color: isDisabled ? VocaboColors.surfaceContainerHigh : null,
          borderRadius: VocaboRadius.md,
        ),
        child: InkWell(
          onTap: isDisabled ? null : onPressed,
          mouseCursor: isDisabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          borderRadius: VocaboRadius.md,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                      color: VocaboColors.neutral,
                    ),
                  )
                else ...[
                  Text(
                    label,
                    style: VocaboTypography.bodyMd.copyWith(
                      color: isDisabled
                          ? VocaboColors.neutral
                          : VocaboColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    IconTheme(
                      data: IconThemeData(
                        color: isDisabled
                            ? VocaboColors.neutral
                            : VocaboColors.onPrimary,
                      ),
                      child: trailing!,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
