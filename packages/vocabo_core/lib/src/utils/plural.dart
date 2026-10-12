/// Formats a count with the singular or plural noun, e.g. `1 day`, `3 days`.
String countLabel(int count, String singular, {String? plural}) =>
    '$count ${count == 1 ? singular : (plural ?? '${singular}s')}';
