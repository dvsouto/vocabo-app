import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

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

  static const _labels = {
    WordType.noun: 'NOUN',
    WordType.verb: 'VERB',
    WordType.adjective: 'ADJ',
    WordType.adverb: 'ADV',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: WordType.values.map((type) {
        return VocaboSelectableChip(
          label: _labels[type] ?? type.value,
          isSelected: selected == type,
          enabled: enabled,
          onTap: () => onSelected?.call(type),
        );
      }).toList(),
    );
  }
}
