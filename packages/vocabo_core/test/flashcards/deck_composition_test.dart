import 'package:test/test.dart';
import 'package:vocabo_core/vocabo_core.dart';

var _counter = 0;

List<DeckCandidate> _cards(int stageInterval, int count) {
  final stageIndex = flashcardStages.indexOf(stageInterval);
  return List.generate(count, (_) {
    _counter += 1;
    return DeckCandidate(
      id: 'd$stageInterval-$_counter',
      stageIndex: stageIndex,
      createdAt: DateTime.utc(2026, 1, 1, 0, 0, _counter),
    );
  });
}

Map<int, int> _countByInterval(List<DeckCandidate> deck) {
  final result = <int, int>{};
  for (final card in deck) {
    final interval = flashcardStages[card.stageIndex];
    result[interval] = (result[interval] ?? 0) + 1;
  }
  return result;
}

Flashcard _flashcard(
  String id, {
  int stage = 0,
  FlashcardStatus status = FlashcardStatus.active,
  FlashcardDeck deck = FlashcardDeck.library,
  DateTime? nextReviewAt,
  DateTime? createdAt,
}) => Flashcard(
  id: id,
  deck: deck,
  status: status,
  currentStageIndex: stage,
  stageLabel: flashcardStageLabel(stage),
  hasRegressed: false,
  nextReviewAt: nextReviewAt,
  createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
  updatedAt: DateTime.utc(2026, 1, 1),
);

void main() {
  group('composeDeck', () {
    test('returns an empty deck when nothing is due', () {
      expect(composeDeck(dueCards: const []), isEmpty);
    });

    test('applies the 20/40/40 base proportions when every band is full', () {
      final dueCards = [
        ..._cards(0, 10),
        ..._cards(1, 10),
        ..._cards(3, 10),
        ..._cards(5, 10),
        ..._cards(7, 10),
        ..._cards(14, 10),
        ..._cards(28, 10),
      ];

      final deck = composeDeck(dueCards: dueCards);

      expect(deck, hasLength(defaultCardsPerSession));
      expect(_countByInterval(deck), {
        0: 3,
        1: 2,
        3: 2,
        5: 1,
        7: 1,
        14: 3,
        28: 3,
      });
    });

    test(
      'puts previous hard cards first and fills the rest proportionally',
      () {
        final hard = _cards(5, 2);
        final dueCards = [
          ..._cards(0, 5),
          ..._cards(1, 5),
          ...hard,
          ..._cards(14, 5),
        ];

        final deck = composeDeck(
          dueCards: dueCards,
          virtualBandIds: hard.map((card) => card.id),
        );

        expect(
          deck.take(2).map((card) => card.id),
          hard.map((card) => card.id),
        );
        expect(deck, hasLength(defaultCardsPerSession));
        expect(deck.map((card) => card.id).toSet(), hasLength(deck.length));
      },
    );

    test('caps the virtual band at the session size', () {
      final hard = _cards(1, 20);
      final deck = composeDeck(
        dueCards: hard,
        virtualBandIds: hard.map((card) => card.id),
      );

      expect(deck, hasLength(defaultCardsPerSession));
    });

    test(
      'redistributes gaps following the priority order and never exceeds the limit',
      () {
        final dueCards = [..._cards(0, 20), ..._cards(1, 2), ..._cards(3, 3)];

        final deck = composeDeck(dueCards: dueCards);

        expect(deck, hasLength(defaultCardsPerSession));
        expect(_countByInterval(deck), {0: 10, 1: 2, 3: 3});
      },
    );

    test('returns a smaller deck when fewer cards are available', () {
      final deck = composeDeck(dueCards: [..._cards(0, 2), ..._cards(28, 1)]);

      expect(deck, hasLength(3));
    });

    test('orders cards inside a stage from oldest to newest', () {
      final pair = _cards(0, 2);
      final deck = composeDeck(dueCards: [pair[1], pair[0]]);

      expect(deck.map((card) => card.id), [pair[0].id, pair[1].id]);
    });

    test('ignores virtual band ids that are not due anymore', () {
      final deck = composeDeck(
        dueCards: _cards(0, 1),
        virtualBandIds: const ['missing-id'],
      );

      expect(deck, hasLength(1));
    });

    test('keeps the band order: virtual, A, B by interval, C, gaps', () {
      final d28 = _cards(28, 5);
      final d14 = _cards(14, 5);
      final d7 = _cards(7, 5);
      final d1 = _cards(1, 5);
      final d0 = _cards(0, 5);
      final deck = composeDeck(dueCards: [...d28, ...d14, ...d7, ...d1, ...d0]);

      expect(deck.map((card) => flashcardStages[card.stageIndex]), [
        0, 0, 0, // band A: floor(15 * 0.2)
        1, 1, // band B: round(6 / 3) at D+1
        7, // round(6 / 6) at D+7 (D+3 and D+5 are empty)
        14, 14, 14, 28, 28, 28, // band C: round(6 * 0.5) each
        1, 1, 1, // gaps: D+1 first in the redistribution priority
      ]);
    });

    test('breaks createdAt ties by id', () {
      final at = DateTime.utc(2026, 2, 1);
      final deck = composeDeck(
        dueCards: [
          DeckCandidate(id: 'b', stageIndex: 0, createdAt: at),
          DeckCandidate(id: 'a', stageIndex: 0, createdAt: at),
        ],
      );

      expect(deck.map((card) => card.id), ['a', 'b']);
    });

    test('orders the virtual band by age, not by the given ids', () {
      final hard = _cards(3, 3);
      final deck = composeDeck(
        dueCards: hard,
        virtualBandIds: hard.reversed.map((card) => card.id),
      );

      expect(deck.map((card) => card.id), hard.map((card) => card.id));
    });
  });

  group('composeDeck with a custom session size', () {
    test('caps quick sessions at the requested size', () {
      final deck = composeDeck(
        dueCards: [..._cards(0, 5), ..._cards(1, 5)],
        config: FlashcardDeckConfig.defaults.copyWith(cardsPerSession: 3),
      );

      expect(deck, hasLength(3));
    });

    test('still fills quick sessions made only of new cards', () {
      final deck = composeDeck(
        dueCards: _cards(0, 10),
        config: FlashcardDeckConfig.defaults.copyWith(cardsPerSession: 3),
      );

      expect(deck, hasLength(3));
    });

    test('rounds half-way shares up and trims each band to its size', () {
      // Size 9: band A = 1 (no D+0 due), band B = 3 and band C = 5.
      // B takes max(1, round(0.5)) at D+5 and D+7 too, then keeps the first
      // 3 (D+1, D+3, D+5). C takes round(2.5) = 3 at D+14 and D+28 and keeps
      // 5. The empty band A slot goes to D+1, first in the priority.
      final deck = composeDeck(
        dueCards: [
          ..._cards(1, 5),
          ..._cards(3, 5),
          ..._cards(5, 5),
          ..._cards(7, 5),
          ..._cards(14, 5),
          ..._cards(28, 5),
        ],
        config: FlashcardDeckConfig.defaults.copyWith(cardsPerSession: 9),
      );

      expect(_countByInterval(deck), {1: 2, 3: 1, 5: 1, 14: 3, 28: 2});
    });
  });

  group('FlashcardDeckConfig.fromConfig', () {
    test('uses the served stages and session size', () {
      const served = FlashcardConfig(stages: [0, 1, 3], cardsPerSession: 5);
      final config = FlashcardDeckConfig.fromConfig(served);

      expect(config.stages, [0, 1, 3]);
      expect(config.cardsPerSession, 5);
      expect(
        FlashcardDeckConfig.fromConfig(served, size: 2).cardsPerSession,
        2,
      );
    });
  });

  group('composeSessionDeck', () {
    final now = DateTime.utc(2026, 3, 10, 12);

    test('only uses active, due cards of the requested deck', () {
      final cards = [
        _flashcard('due', nextReviewAt: now),
        _flashcard('future', nextReviewAt: now.add(const Duration(seconds: 1))),
        _flashcard(
          'archived',
          status: FlashcardStatus.archived,
          nextReviewAt: now,
        ),
        _flashcard('done', status: FlashcardStatus.completed),
        _flashcard(
          'other-deck',
          deck: FlashcardDeck.collections,
          nextReviewAt: now,
        ),
        _flashcard(
          'earlier-local',
          nextReviewAt: DateTime.utc(2026, 3, 10, 11).toLocal(),
        ),
      ];

      final deck = composeSessionDeck(cards, now: now);

      expect(deck.map((card) => card.id).toSet(), {'due', 'earlier-local'});
      expect(
        composeSessionDeck(
          cards,
          now: now,
          deck: FlashcardDeck.collections,
        ).map((card) => card.id),
        ['other-deck'],
      );
    });

    test('puts the previous hard cards first and honours the size', () {
      final cards = [
        for (var i = 0; i < 6; i++)
          _flashcard(
            'n$i',
            nextReviewAt: now,
            createdAt: DateTime.utc(2026, 1, 1, 0, i),
          ),
        _flashcard(
          'hard',
          stage: 2,
          nextReviewAt: now,
          createdAt: DateTime.utc(2026, 2, 1),
        ),
      ];

      final deck = composeSessionDeck(
        cards,
        now: now,
        previousHardIds: const ['hard'],
        size: 3,
      );

      expect(deck.map((card) => card.id), ['hard', 'n0', 'n1']);
    });
  });

  group('previousHardCardIds', () {
    FlashcardSession session({
      required DateTime? completedAt,
      FlashcardDeck deck = FlashcardDeck.library,
      FlashcardSessionStatus status = FlashcardSessionStatus.completed,
      required Map<String, FlashcardEvaluation?> cards,
    }) {
      var position = 0;
      return FlashcardSession(
        id: 's-${completedAt?.toIso8601String()}-${deck.value}',
        deck: deck,
        status: status,
        completedAt: completedAt,
        cards: [
          for (final entry in cards.entries)
            FlashcardSessionCard(
              id: 'sc-${entry.key}',
              position: position++,
              evaluation: entry.value,
              flashcard: _flashcard(entry.key),
            ),
        ],
      );
    }

    test('reads the hard cards of the last completed session of the deck', () {
      final sessions = [
        session(
          completedAt: DateTime.utc(2026, 3, 1),
          cards: {'old': FlashcardEvaluation.hard},
        ),
        session(
          completedAt: DateTime.utc(2026, 3, 5),
          cards: {
            'a': FlashcardEvaluation.hard,
            'b': FlashcardEvaluation.easy,
            'c': FlashcardEvaluation.hard,
          },
        ),
        session(
          completedAt: DateTime.utc(2026, 3, 9),
          deck: FlashcardDeck.collections,
          cards: {'col': FlashcardEvaluation.hard},
        ),
        session(
          completedAt: null,
          status: FlashcardSessionStatus.inProgress,
          cards: {'live': FlashcardEvaluation.hard},
        ),
      ];

      expect(previousHardCardIds(sessions), ['a', 'c']);
      expect(previousHardCardIds(sessions, deck: FlashcardDeck.collections), [
        'col',
      ]);
      expect(previousHardCardIds(const []), isEmpty);
    });
  });
}
