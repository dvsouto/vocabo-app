const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', //
  'ç': 'c', 'ñ': 'n',
};

/// Lowercases, trims and strips common Latin accents so "cafe" finds "café".
String normalizeForMatch(String value) {
  final lower = value.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final char in lower.split('')) {
    buffer.write(_accents[char] ?? char);
  }
  return buffer.toString();
}

/// How well [query] matches a word or its translation, from 0 (no match)
/// to 1 (exact). Matching the translation lets the user search in either
/// language.
double translationMatchScore({
  required String query,
  required String term,
  String? translation,
}) {
  final q = normalizeForMatch(query);
  if (q.isEmpty) return 0;

  double score(String candidate) {
    final c = normalizeForMatch(candidate);
    if (c.isEmpty) return 0;
    if (c == q) return 1;
    if (c.startsWith(q)) return 0.8;
    if (c.split(RegExp(r'[\s,;/]+')).any((word) => word.startsWith(q))) {
      return 0.6;
    }
    if (c.contains(q)) return 0.4;
    return 0;
  }

  final termScore = score(term);
  final translationScore = translation == null
      ? 0.0
      : score(translation) * 0.95;
  return termScore >= translationScore ? termScore : translationScore;
}
