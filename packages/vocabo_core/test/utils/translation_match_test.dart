import 'package:test/test.dart';
import 'package:vocabo_core/vocabo_core.dart';

void main() {
  group('normalizeForMatch', () {
    test('strips accents and case', () {
      expect(normalizeForMatch('  Café Ação '), 'cafe acao');
    });
  });

  group('translationMatchScore', () {
    double score(
      String query, {
      String term = 'chair',
      String? tr = 'cadeira',
    }) => translationMatchScore(query: query, term: term, translation: tr);

    test('ranks exact over prefix over contains', () {
      expect(score('chair'), 1);
      expect(score('cha'), 0.8);
      expect(score('hai'), 0.4);
      expect(score('xyz'), 0);
    });

    test('matches the translation, slightly below the term', () {
      expect(score('cadeira'), closeTo(0.95, 0.001));
      expect(score('cad'), closeTo(0.76, 0.001));
    });

    test('matches any word of a multi-word translation without accents', () {
      expect(
        translationMatchScore(
          query: 'acucar',
          term: 'sugar',
          translation: 'pó, açúcar',
        ),
        closeTo(0.57, 0.001),
      );
    });

    test('ignores empty queries and missing translations', () {
      expect(score('  '), 0);
      expect(score('cad', tr: null), 0);
    });
  });
}
