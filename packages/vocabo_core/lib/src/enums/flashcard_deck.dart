/// Library words and collection words are reviewed in separate decks.
enum FlashcardDeck {
  library('library'),
  collections('collections');

  const FlashcardDeck(this.value);
  final String value;

  static FlashcardDeck fromValue(String? value) {
    for (final deck in values) {
      if (deck.value == value) return deck;
    }
    return FlashcardDeck.library;
  }
}
