import 'package:test/test.dart';
import 'package:vocabo_core/vocabo_core.dart';

void main() {
  group('Trie', () {
    late Trie trie;

    setUp(() {
      trie = Trie();
    });

    test('insert and size', () {
      trie.insert('hello', 100);
      trie.insert('help', 200);
      trie.insert('world', 50);
      expect(trie.size, 3);
    });

    test('duplicate insert does not increase size', () {
      trie.insert('hello', 100);
      trie.insert('hello', 200);
      expect(trie.size, 1);
    });

    test('prefixSearch returns matching words', () {
      trie.insert('hello', 100);
      trie.insert('help', 200);
      trie.insert('helmet', 150);
      trie.insert('world', 50);

      final results = trie.prefixSearch('hel');
      final words = results.map((r) => r.word).toSet();

      expect(words, contains('hello'));
      expect(words, contains('help'));
      expect(words, contains('helmet'));
      expect(words, isNot(contains('world')));
    });

    test('prefixSearch returns empty for non-existent prefix', () {
      trie.insert('hello', 100);
      final results = trie.prefixSearch('xyz');
      expect(results, isEmpty);
    });

    test('prefixSearch respects limit', () {
      for (var i = 0; i < 20; i++) {
        trie.insert('word$i', i * 10);
      }
      final results = trie.prefixSearch('word', limit: 5);
      expect(results.length, 5);
    });

    test('prefixSearch results sorted by frequency descending', () {
      trie.insert('help', 200);
      trie.insert('hello', 100);
      trie.insert('helmet', 300);

      final results = trie.prefixSearch('hel');
      expect(results.first.word, 'helmet');
      expect(results.last.word, 'hello');
    });

    test('build inserts multiple words', () {
      trie.build([
        (word: 'apple', frequency: 100),
        (word: 'banana', frequency: 200),
        (word: 'cherry', frequency: 50),
      ]);
      expect(trie.size, 3);
    });

    test('empty trie returns empty results', () {
      final results = trie.prefixSearch('anything');
      expect(results, isEmpty);
    });
  });
}
