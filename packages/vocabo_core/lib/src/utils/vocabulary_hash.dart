import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Computes a deterministic SHA-256 hash for vocabulary content.
///
/// Must produce the same hash as the backend `generateVocabularyHash` function.
/// All string values are lowercased and trimmed before hashing.
String computeVocabularyHash({
  required String term,
  required String language,
  String? translation,
  String? meaning,
  String? wordType,
  String? pronunciation,
  String? ttsPronunciation,
  dynamic usageExamples,
}) {
  final normalized = {
    'term': term.toLowerCase().trim(),
    'language': language.toLowerCase().trim(),
    'translation': translation?.toLowerCase().trim(),
    'meaning': (meaning ?? '').toLowerCase().trim(),
    'word_type': (wordType ?? '').toLowerCase().trim(),
    'pronunciation': (pronunciation ?? '').toLowerCase().trim(),
    'tts_pronunciation': (ttsPronunciation ?? '').toLowerCase().trim(),
    'usage_examples': _normalizeUsageExamples(usageExamples),
  };

  final jsonString = jsonEncode(normalized);
  final bytes = utf8.encode(jsonString);

  return sha256.convert(bytes).toString();
}

dynamic _normalizeUsageExamples(dynamic examples) {
  if (examples == null) return <String, List<String>>{};

  if (examples is List) {
    return examples
        .map((e) => e.toString().toLowerCase())
        .toList(growable: false);
  }

  if (examples is Map) {
    final result = <String, List<String>>{};
    final sortedKeys = examples.keys.map((k) => k.toString()).toList()..sort();

    for (final key in sortedKeys) {
      final values = examples[key];
      if (values is List) {
        result[key.toLowerCase()] =
            values.map((v) => v.toString().toLowerCase()).toList(growable: false);
      }
    }

    return result;
  }

  return <String, List<String>>{};
}
