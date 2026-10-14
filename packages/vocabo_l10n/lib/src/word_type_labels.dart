import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';

/// Display name of a word type, such as "Noun".
String wordTypeLabel(AppLocalizations l10n, WordType type) => switch (type) {
  WordType.noun => l10n.wordTypeNoun,
  WordType.verb => l10n.wordTypeVerb,
  WordType.adjective => l10n.wordTypeAdjective,
  WordType.adverb => l10n.wordTypeAdverb,
};

/// Abbreviated word type for compact chips, such as "ADJ".
String wordTypeShortLabel(AppLocalizations l10n, WordType type) =>
    switch (type) {
      WordType.noun => l10n.wordTypeNounShort,
      WordType.verb => l10n.wordTypeVerbShort,
      WordType.adjective => l10n.wordTypeAdjectiveShort,
      WordType.adverb => l10n.wordTypeAdverbShort,
    };
