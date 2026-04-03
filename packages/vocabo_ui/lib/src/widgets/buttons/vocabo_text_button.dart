import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

class VocaboTextButton extends StatefulWidget {
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
  State<VocaboTextButton> createState() => _VocaboTextButtonState();
}

class _VocaboTextButtonState extends State<VocaboTextButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final color = isDisabled
        ? VocaboColors.neutral
        : _isHovered
            ? VocaboColors.primary800
            : VocaboColors.primary700;
    final displayLabel =
        widget.uppercase ? widget.label.toUpperCase() : widget.label;

    return MouseRegion(
      cursor:
          isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.leading != null) ...[
                IconTheme(
                  data: IconThemeData(color: color, size: 18),
                  child: widget.leading!,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                displayLabel,
                style: VocaboTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
