import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';

class PartOfSpeechSelector extends StatelessWidget {
  const PartOfSpeechSelector({
    super.key,
    this.selected,
    this.onSelected,
    this.enabled = true,
  });

  final WordType? selected;
  final ValueChanged<WordType>? onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WordType.values.map((type) {
        return VocaboSelectableChip(
          label: wordTypeShortLabel(l10n, type),
          isSelected: selected == type,
          enabled: enabled,
          onTap: () => onSelected?.call(type),
        );
      }).toList(),
    );
  }
}
