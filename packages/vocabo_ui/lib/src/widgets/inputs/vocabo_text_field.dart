import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_radius.dart';

class VocaboTextField extends StatelessWidget {
  const VocaboTextField({
    super.key,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: VocaboColors.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: VocaboRadius.sm,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: VocaboRadius.sm,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: VocaboRadius.sm,
          borderSide: BorderSide(
            color: VocaboColors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
      ),
    );
  }
}
