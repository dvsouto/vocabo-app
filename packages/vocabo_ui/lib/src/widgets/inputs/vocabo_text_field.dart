import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.readOnly = false,
    this.errorText,
    this.onChanged,
    this.focusNode,
    this.autofillHints,
    this.inputFormatters,
    this.textInputAction,
    this.prefix,
    this.suffix,
  });

  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  /// Shown before the text, e.g. a country picker.
  final Widget? prefix;

  /// Shown after the text, e.g. a show password toggle.
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      autofocus: autofocus,
      enabled: enabled,
      readOnly: readOnly,
      focusNode: focusNode,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefix,
        suffixIcon: suffix,
        errorText: errorText,
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
