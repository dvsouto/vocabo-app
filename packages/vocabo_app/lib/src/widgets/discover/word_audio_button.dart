import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_app/src/widgets/audio/pronunciation_button.dart';

/// Plays the pronunciation of a system vocabulary entry.
class WordAudioButton extends StatelessWidget {
  const WordAudioButton({super.key, required this.vocabulary, this.size = 32});

  final Vocabulary vocabulary;
  final double size;

  @override
  Widget build(BuildContext context) {
    return PronunciationButton(
      vocabularyId: vocabulary.id,
      type: VocabularyType.system.value,
      contentHash: vocabulary.contentHash,
      size: size,
      iconSize: size * 0.5,
    );
  }
}
