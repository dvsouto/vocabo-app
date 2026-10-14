import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

/// Dropdown of native languages, or of interface languages with
/// [NativeLanguageField.interface], each written in its own language so it
/// reads the same whatever the interface language.
class NativeLanguageField extends StatelessWidget {
  const NativeLanguageField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  }) : languages = nativeLanguages;

  const NativeLanguageField.interface({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  }) : languages = interfaceLanguages;

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final List<NativeLanguage> languages;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      borderRadius: VocaboRadius.sm,
      dropdownColor: VocaboColors.surfaceContainerLowest,
      onChanged: enabled
          ? (code) {
              if (code != null) onChanged(code);
            }
          : null,
      decoration: InputDecoration(
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
      ),
      items: [
        for (final language in languages)
          DropdownMenuItem(
            value: language.code,
            child: Text(language.nativeName, style: VocaboTypography.bodyMd),
          ),
      ],
    );
  }
}
