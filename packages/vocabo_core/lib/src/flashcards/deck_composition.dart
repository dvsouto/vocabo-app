import 'package:equatable/equatable.dart';

import 'package:vocabo_core/src/enums/flashcard_deck.dart';
import 'package:vocabo_core/src/enums/flashcard_evaluation.dart';
import 'package:vocabo_core/src/enums/flashcard_status.dart';
import 'package:vocabo_core/src/flashcards/flashcard_stages.dart';
import 'package:vocabo_core/src/models/flashcard.dart';
import 'package:vocabo_core/src/models/flashcard_session.dart';

class DeckCandidate extends Equatable {
  final String id;
  final int stageIndex;
  final DateTime createdAt;

  const DeckCandidate({
    required this.id,
    required this.stageIndex,
    required this.createdAt,
  });

  factory DeckCandidate.fromFlashcard(Flashcard card) => DeckCandidate(
    id: card.id,
    stageIndex: card.currentStageIndex,
    createdAt: card.createdAt,
  );

  @override
  List<Object?> get props => [id, stageIndex, createdAt];
}

int _byAge(DeckCandidate a, DeckCandidate b) {
  final byTime = a.createdAt.millisecondsSinceEpoch.compareTo(
    b.createdAt.millisecondsSinceEpoch,
  );
  return byTime != 0 ? byTime : a.id.compareTo(b.id);
}

/// `Math.round` semantics: halves round towards positive infinity.
int _jsRound(double value) {
  final floor = value.floor();
  return value - floor >= 0.5 ? floor + 1 : floor;
}

class _CandidatePool {
  final Map<int, List<DeckCandidate>> _byStage = {};
  final Set<String> _taken = {};

  _CandidatePool(List<DeckCandidate> cards) {
    final sorted = [...cards]..sort(_byAge);
    for (final card in sorted) {
      _byStage.putIfAbsent(card.stageIndex, () => []).add(card);
    }
  }

  List<DeckCandidate> take(int stageIndex, int limit) {
    if (limit <= 0) return [];

    final picked = <DeckCandidate>[];
    for (final card in _byStage[stageIndex] ?? const <DeckCandidate>[]) {
      if (picked.length >= limit) break;
      if (!_taken.add(card.id)) continue;
      picked.add(card);
    }
    return picked;
  }

  List<DeckCandidate> takeByIds(Set<String> ids) {
    final all = [for (final bucket in _byStage.values) ...bucket]..sort(_byAge);

    final picked = <DeckCandidate>[];
    for (final card in all) {
      if (!ids.contains(card.id) || _taken.contains(card.id)) continue;
      _taken.add(card.id);
      picked.add(card);
    }
    return picked;
  }
}

List<DeckCandidate> _takeDistributed(
  _CandidatePool pool,
  int limit,
  Map<int, double> distribution,
  FlashcardDeckConfig config,
) {
  if (limit <= 0) return [];

  // JS iterates integer object keys in ascending order, whatever the
  // insertion order, so the distribution is walked by sorted interval.
  final intervals = distribution.keys.toList()..sort();
  final picked = <DeckCandidate>[];

  for (final interval in intervals) {
    final stageIndex = stageIndexByInterval(interval, config.stages);
    if (stageIndex == null) continue;

    final rounded = _jsRound(limit * distribution[interval]!);
    picked.addAll(pool.take(stageIndex, rounded < 1 ? 1 : rounded));
  }

  return picked.length > limit ? picked.sublist(0, limit) : picked;
}

List<DeckCandidate> _fillGaps(
  _CandidatePool pool,
  int gaps,
  FlashcardDeckConfig config,
) {
  final extras = <DeckCandidate>[];

  for (final interval in config.redistributionPriority) {
    if (extras.length >= gaps) break;

    final stageIndex = stageIndexByInterval(interval, config.stages);
    if (stageIndex == null) continue;

    extras.addAll(pool.take(stageIndex, gaps - extras.length));
  }

  return extras.length > gaps ? extras.sublist(0, gaps) : extras;
}

/// Builds the ordered session deck following the band rules: virtual band
/// (cards rated hard in the previous completed session) first, then bands
/// A/B/C by stage, then leftover positions redistributed by priority.
///
/// [dueCards] are the active cards whose `next_review_at` is already due
/// (see [selectDueCards]).
List<DeckCandidate> composeDeck({
  required List<DeckCandidate> dueCards,
  Iterable<String> virtualBandIds = const [],
  FlashcardDeckConfig config = FlashcardDeckConfig.defaults,
}) {
  final pool = _CandidatePool(dueCards);
  final total = config.cardsPerSession;

  final virtualBand = pool.takeByIds(virtualBandIds.toSet());
  final remaining = total - virtualBand.length;

  if (remaining <= 0) {
    return virtualBand.sublist(0, total < 0 ? 0 : total);
  }

  final bandASize = (remaining * config.bandAPercent).floor();
  final bandBSize = (remaining * config.bandBPercent).floor();
  final bandCSize = remaining - bandASize - bandBSize;

  final stageZero = stageIndexByInterval(0, config.stages) ?? 0;
  final bandA = pool.take(stageZero, bandASize);
  final bandB = _takeDistributed(
    pool,
    bandBSize,
    config.bandBDistribution,
    config,
  );
  final bandC = _takeDistributed(
    pool,
    bandCSize,
    config.bandCDistribution,
    config,
  );

  final deck = [...virtualBand, ...bandA, ...bandB, ...bandC];

  if (deck.length < total) {
    deck.addAll(_fillGaps(pool, total - deck.length, config));
  }

  return deck.length > total ? deck.sublist(0, total) : deck;
}

/// The cards the API loads as candidates: same deck, `active`, and
/// `next_review_at <= now`.
List<Flashcard> selectDueCards(
  Iterable<Flashcard> cards, {
  required DateTime now,
  FlashcardDeck deck = FlashcardDeck.library,
}) => [
  for (final card in cards)
    if (card.deck == deck &&
        card.status == FlashcardStatus.active &&
        card.nextReviewAt != null &&
        !card.nextReviewAt!.isAfter(now))
      card,
];

/// Composes the session deck from local flashcards and returns them in deck
/// order, like `composeSessionDeckAction` in the API. [previousHardIds] are
/// the cards rated hard in the last completed session of the same [deck];
/// [size] overrides the session size (quick sessions).
List<Flashcard> composeSessionDeck(
  Iterable<Flashcard> cards, {
  required DateTime now,
  FlashcardDeck deck = FlashcardDeck.library,
  Iterable<String> previousHardIds = const [],
  int? size,
  FlashcardDeckConfig config = FlashcardDeckConfig.defaults,
}) {
  final due = selectDueCards(cards, now: now, deck: deck);
  final byId = {for (final card in due) card.id: card};

  final composed = composeDeck(
    dueCards: due.map(DeckCandidate.fromFlashcard).toList(),
    virtualBandIds: previousHardIds,
    config: size == null ? config : config.copyWith(cardsPerSession: size),
  );

  return [
    for (final candidate in composed)
      if (byId[candidate.id] case final card?) card,
  ];
}

/// Ids of the cards rated hard in the most recently completed session of
/// [deck] (the virtual band). Like the API's `ORDER BY completed_at DESC`,
/// a completed session without `completedAt` sorts first.
List<String> previousHardCardIds(
  Iterable<FlashcardSession> sessions, {
  FlashcardDeck deck = FlashcardDeck.library,
}) {
  FlashcardSession? last;
  for (final session in sessions) {
    if (session.deck != deck ||
        session.status != FlashcardSessionStatus.completed) {
      continue;
    }
    if (last == null || _completedLater(session, last)) last = session;
  }
  if (last == null) return const [];

  return [
    for (final card in last.cards)
      if (card.evaluation == FlashcardEvaluation.hard) card.flashcard.id,
  ];
}

bool _completedLater(FlashcardSession a, FlashcardSession b) {
  final aAt = a.completedAt;
  final bAt = b.completedAt;
  if (bAt == null) return false;
  if (aAt == null) return true;
  return aAt.isAfter(bAt);
}
