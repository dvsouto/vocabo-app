enum CollectionDifficulty {
  easy('easy'),
  medium('medium'),
  hard('hard');

  const CollectionDifficulty(this.value);
  final String value;

  static CollectionDifficulty fromValue(String? value) {
    for (final difficulty in values) {
      if (difficulty.value == value) return difficulty;
    }
    return CollectionDifficulty.easy;
  }
}
