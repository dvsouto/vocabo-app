import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

class NativeLanguageField extends StatelessWidget {
  const NativeLanguageField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
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
        for (final language in nativeLanguages)
          DropdownMenuItem(
            value: language.code,
            child: Text(language.displayName, style: VocaboTypography.bodyMd),
          ),
      ],
    );
  }
}
