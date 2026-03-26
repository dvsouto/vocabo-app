class SearchResult {
  final String word;
  final int frequency;
  final double score;

  const SearchResult({
    required this.word,
    required this.frequency,
    required this.score,
  });

  @override
  String toString() => 'SearchResult(word: $word, freq: $frequency, score: $score)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          word == other.word &&
          frequency == other.frequency;

  @override
  int get hashCode => word.hashCode ^ frequency.hashCode;
}
