import 'package:flutter/material.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_radius.dart';

class VocaboSearchField extends StatelessWidget {
  const VocaboSearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.hint,
    this.onChanged,
    this.suffixActions,
    this.autofocus = false,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final Widget? suffixActions;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      autofocus: autofocus,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: VocaboColors.surfaceContainerLow,
        prefixIcon: const Icon(
          Icons.search,
          color: VocaboColors.neutral,
          size: 20,
        ),
        suffixIcon: suffixActions,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: TextStyle(
          color: VocaboColors.neutral,
          fontSize: 14,
        ),
      ),
    );
  }
}
