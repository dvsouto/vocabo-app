import 'package:test/test.dart';
import 'package:vocabo_core/vocabo_core.dart';

void main() {
  group('levenshteinDistance', () {
    test('identical strings return 0', () {
      expect(levenshteinDistance('hello', 'hello'), 0);
    });

    test('empty strings return 0', () {
      expect(levenshteinDistance('', ''), 0);
    });

    test('one empty string returns length of the other', () {
      expect(levenshteinDistance('', 'hello'), 5);
      expect(levenshteinDistance('hello', ''), 5);
    });

    test('kitten -> sitting = 3', () {
      expect(levenshteinDistance('kitten', 'sitting'), 3);
    });

    test('single character difference', () {
      expect(levenshteinDistance('cat', 'bat'), 1);
    });

    test('insertion', () {
      expect(levenshteinDistance('helo', 'hello'), 1);
    });

    test('deletion', () {
      expect(levenshteinDistance('hello', 'helo'), 1);
    });

    test('is symmetric', () {
      expect(
        levenshteinDistance('abc', 'xyz'),
        levenshteinDistance('xyz', 'abc'),
      );
    });
  });

  group('normalizedSimilarity', () {
    test('identical strings return 1.0', () {
      expect(normalizedSimilarity('hello', 'hello'), 1.0);
    });

    test('completely different strings return low similarity', () {
      final result = normalizedSimilarity('abc', 'xyz');
      expect(result, closeTo(0.0, 0.01));
    });

    test('both empty strings return 1.0', () {
      expect(normalizedSimilarity('', ''), 1.0);
    });

    test('similar strings return high similarity', () {
      final result = normalizedSimilarity('hello', 'helo');
      expect(result, greaterThan(0.7));
    });
  });
}
