import 'dart:math' as math;

int levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  // Ensure a is the shorter string for space optimization
  if (a.length > b.length) {
    final temp = a;
    a = b;
    b = temp;
  }

  final aLen = a.length;
  final bLen = b.length;

  // Single-row DP optimization: O(min(m,n)) space
  var previousRow = List<int>.generate(aLen + 1, (i) => i);
  var currentRow = List<int>.filled(aLen + 1, 0);

  for (var j = 1; j <= bLen; j++) {
    currentRow[0] = j;

    for (var i = 1; i <= aLen; i++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;

      currentRow[i] = math.min(
        math.min(
          currentRow[i - 1] + 1, // insertion
          previousRow[i] + 1, // deletion
        ),
        previousRow[i - 1] + cost, // substitution
      );
    }

    final temp = previousRow;
    previousRow = currentRow;
    currentRow = temp;
  }

  return previousRow[aLen];
}

double normalizedSimilarity(String a, String b) {
  if (a.isEmpty && b.isEmpty) return 1.0;
  final maxLen = math.max(a.length, b.length);
  return 1.0 - (levenshteinDistance(a, b) / maxLen);
}
