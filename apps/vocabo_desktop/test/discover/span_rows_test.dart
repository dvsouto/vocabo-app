import 'package:flutter_test/flutter_test.dart';
import 'package:vocabo_desktop/src/widgets/discover/span_rows.dart';

void main() {
  test('spans grow with the term length and fit the columns', () {
    expect(spanForTerm('cat', 6), 1);
    expect(spanForTerm('break the ice', 6), 2);
    expect(spanForTerm('the ball is in your court now', 6), 3);
    expect(spanForTerm('the ball is in your court now', 2), 2);
  });

  test('rows keep order and fill every row but the last', () {
    final rows = packSpanRows([1, 2, 3, 1, 1], 4);

    expect(rows.map((row) => row.map((cell) => cell.index).toList()), [
      [0, 1],
      [2, 3],
      [4],
    ]);
    for (final row in rows.take(rows.length - 1)) {
      expect(row.fold<int>(0, (sum, cell) => sum + cell.span), 4);
    }
    expect(rows.last.single.span, 1);
  });

  test('a span wider than the grid is clamped', () {
    final rows = packSpanRows([3], 2);
    expect(rows.single.single.span, 2);
  });
}
