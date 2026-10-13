/// How many grid columns a word card spans, from its length.
int spanForTerm(String term, int columns) {
  final span = term.length <= 12
      ? 1
      : term.length <= 26
      ? 2
      : 3;
  return span.clamp(1, columns);
}

/// Grid columns for the available width.
int columnsForWidth(double width) {
  if (width >= 960) return 6;
  if (width >= 640) return 4;
  if (width >= 420) return 3;
  return 2;
}

/// Packs items into rows of [columns] keeping their order. Every row but
/// the last is stretched to the full width by widening its cards.
List<List<({int index, int span})>> packSpanRows(List<int> spans, int columns) {
  final rows = <List<({int index, int span})>>[];
  var current = <({int index, int span})>[];
  var used = 0;

  for (var index = 0; index < spans.length; index++) {
    final span = spans[index].clamp(1, columns);
    if (used + span > columns) {
      rows.add(_stretch(current, columns - used));
      current = [];
      used = 0;
    }
    current.add((index: index, span: span));
    used += span;
  }
  if (current.isNotEmpty) rows.add(current);
  return rows;
}

List<({int index, int span})> _stretch(
  List<({int index, int span})> row,
  int leftover,
) {
  final result = [...row];
  for (var i = 0; leftover > 0; i = (i + 1) % result.length, leftover--) {
    result[i] = (index: result[i].index, span: result[i].span + 1);
  }
  return result;
}
