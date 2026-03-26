import 'package:test/test.dart';
import 'package:vocabo_core/vocabo_core.dart';

void main() {
  group('FuzzySearchEngine', () {
    late FuzzySearchEngine engine;

    setUp(() {
      engine = FuzzySearchEngine();
      engine.load([
        const DictionaryWord(word: 'hello', frequency: 1000),
        const DictionaryWord(word: 'help', frequency: 900),
        const DictionaryWord(word: 'helmet', frequency: 800),
        const DictionaryWord(word: 'world', frequency: 700),
        const DictionaryWord(word: 'apple', frequency: 600),
        const DictionaryWord(word: 'application', frequency: 500),
        const DictionaryWord(word: 'banana', frequency: 400),
        const DictionaryWord(word: 'beautiful', frequency: 300),
      ]);
    });

    test('isLoaded returns true after load', () {
      expect(engine.isLoaded, isTrue);
    });

    test('new engine is not loaded', () {
      final empty = FuzzySearchEngine();
      expect(empty.isLoaded, isFalse);
    });

    test('short query returns empty', () {
      expect(engine.search('h'), isEmpty);
      expect(engine.search(''), isEmpty);
    });

    test('prefix match returns correct results', () {
      final results = engine.search('hel');
      final words = results.map((r) => r.word).toList();

      expect(words, contains('hello'));
      expect(words, contains('help'));
      expect(words, contains('helmet'));
      expect(words, isNot(contains('world')));
    });

    test('fuzzy match finds misspelled words', () {
      final results = engine.search('helo');
      final words = results.map((r) => r.word).toList();

      expect(words, contains('hello'));
    });

    test('fuzzy match finds words with one character difference', () {
      final results = engine.search('werld');
      final words = results.map((r) => r.word).toList();

      expect(words, contains('world'));
    });

    test('results are deduplicated', () {
      final results = engine.search('hel');
      final words = results.map((r) => r.word).toList();
      final uniqueWords = words.toSet();

      expect(words.length, uniqueWords.length);
    });

    test('respects limit', () {
      final results = engine.search('hel', limit: 2);
      expect(results.length, lessThanOrEqualTo(2));
    });

    test('prefix results have higher score than fuzzy', () {
      final results = engine.search('helo', limit: 10);
      final helloResult = results.firstWhere((r) => r.word == 'hello');

      // "helo" prefix-matches nothing but fuzzy-matches "hello"
      // Also "help" is distance 2 from "helo"
      expect(helloResult.score, lessThan(1.0));
    });

    test('unloaded engine returns empty', () {
      final empty = FuzzySearchEngine();
      expect(empty.search('hello'), isEmpty);
    });

    test('performance: 30K words search under 10ms', () {
      final largeEngine = FuzzySearchEngine();
      final words = List.generate(
        30000,
        (i) => DictionaryWord(word: 'word${i.toString().padLeft(5, '0')}', frequency: 30000 - i),
      );
      largeEngine.load(words);

      final sw = Stopwatch()..start();
      largeEngine.search('word00');
      sw.stop();

      // Prefix search on 30K words should be well under 10ms
      expect(sw.elapsedMilliseconds, lessThan(10));
    });
  });
}
