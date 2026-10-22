import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_app/src/data/local_store.dart';
import 'package:vocabo_app/src/pro/plan_providers.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/src/l10n/locale_providers.dart';
import 'package:vocabo_app/src/providers/api_client_provider.dart';
import 'package:vocabo_app/src/providers/audio_player_providers.dart';
import 'package:vocabo_app/src/providers/discover_providers.dart';
import 'package:vocabo_app/src/sync/sync_engine.dart';

/// Every flashcard on this device (both decks, all statuses).
final localFlashcardsProvider = StreamProvider<List<Flashcard>>((ref) {
  return ref.watch(localStoreProvider).watchFlashcards().map((rows) {
    final cards = <Flashcard>[];
    for (final row in rows) {
      try {
        cards.add(Flashcard.fromJson(row));
      } catch (e, st) {
        appLogger.handle(e, st, 'Skipping unreadable flashcard row');
      }
    }
    return cards;
  });
});

/// Stage intervals and reverse stages shared by the API. Falls back to the
/// API defaults while loading or offline so the UI never blocks on it.
final flashcardConfigProvider = FutureProvider<FlashcardConfig>((ref) async {
  try {
    return await ref.watch(apiClientProvider).flashcards.getConfig();
  } catch (e, st) {
    appLogger.handle(e, st, 'FlashcardConfig load error');
    return FlashcardConfig.fallback;
  }
});

String _sessionKey(FlashcardDeck deck) => 'flashcards.session.${deck.value}';
String _lastHardKey(FlashcardDeck deck) => 'flashcards.last_hard.${deck.value}';

/// Due counts and the next review, computed from the local cards so the
/// sidebar badge and the home screen work offline.
final flashcardDeckStatusProvider =
    FutureProvider.family<FlashcardStatusSummary, FlashcardDeck>((
      ref,
      deck,
    ) async {
      final cards = await ref.watch(localFlashcardsProvider.future);
      final config = ref.watch(flashcardConfigProvider).valueOrNull;
      final stages = config?.stages ?? flashcardStages;
      final now = DateTime.now().toUtc();
      final inDeck = cards.where((card) => card.deck == deck).toList();
      final active = inDeck
          .where((card) => card.status == FlashcardStatus.active)
          .toList();
      final due = selectDueCards(inDeck, now: now, deck: deck);
      int dueIn(StageBand band) => due
          .where(
            (card) => stageBand(card.currentStageIndex, stages: stages) == band,
          )
          .length;

      DateTime? next;
      for (final card in active) {
        final at = card.nextReviewAt;
        if (at != null && (next == null || at.isBefore(next))) next = at;
      }
      final session = await ref
          .read(localStoreProvider)
          .read(_sessionKey(deck));

      return FlashcardStatusSummary(
        totalActive: active.length,
        dueCount: due.length,
        dueNew: dueIn(StageBand.newCard),
        dueReturning: dueIn(StageBand.returning),
        dueLongTerm: dueIn(StageBand.longTerm),
        completedCount: inDeck
            .where((card) => card.status == FlashcardStatus.completed)
            .length,
        archivedCount: inDeck
            .where((card) => card.status == FlashcardStatus.archived)
            .length,
        hasActiveSession: session != null,
        nextReviewAt: next,
      );
    });

/// The status of the library deck.
final flashcardStatusProvider = flashcardDeckStatusProvider(
  FlashcardDeck.library,
);

/// The deck shown by the flashcards widgets below it. The collections tab
/// overrides it in a nested [ProviderScope].
final currentFlashcardDeckProvider = Provider<FlashcardDeck>(
  (_) => FlashcardDeck.library,
);

final archivedFlashcardsProvider = FutureProvider.autoDispose<List<Flashcard>>((
  ref,
) async {
  final cards = await ref.watch(localFlashcardsProvider.future);
  return cards.where((card) => card.isArchived).toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
});

final flashcardByVocabularyProvider = FutureProvider.autoDispose
    .family<Flashcard?, String>((ref, userVocabularyId) async {
      final cards = await ref.watch(localFlashcardsProvider.future);
      for (final card in cards) {
        if (card.userVocabularyId == userVocabularyId) return card;
      }
      return null;
    });

/// Writes a flashcard change locally and queues it for the API, so reviews
/// work offline. Returns the updated card.
class FlashcardWriter {
  FlashcardWriter(this._ref);

  final Ref _ref;

  LocalStore get _store => _ref.read(localStoreProvider);

  Future<Flashcard?> _write(
    String id,
    Map<String, dynamic> Function(Map<String, dynamic> json) change,
  ) async {
    final json = await _store.readFlashcard(id);
    if (json == null) return null;
    final updated = change(Map<String, dynamic>.of(json))
      ..['version'] = ((json['version'] as num?)?.toInt() ?? 1) + 1
      ..['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await _store.putFlashcard(updated);
    return Flashcard.fromJson(updated);
  }

  Future<Flashcard?> evaluate(
    Flashcard card,
    FlashcardEvaluation evaluation, {
    required String sessionId,
  }) async {
    final config = _ref.read(flashcardConfigProvider).valueOrNull;
    final stages = config?.stages ?? flashcardStages;
    final reverse =
        config?.reverseStageIntervals ?? defaultReverseStageIntervals;
    final now = DateTime.now().toUtc();
    final baseJson = await _store.readFlashcard(card.id);
    final baseVersion = (baseJson?['version'] as num?)?.toInt() ?? 1;

    final next = applyStateToFlashcard(
      card,
      applyEvaluation(
        SpacedRepetitionState.fromFlashcard(card),
        evaluation,
        now,
        stages,
      ),
      now: now,
      stages: stages,
      reverseIntervals: reverse,
    );
    final updated = await _write(
      card.id,
      (json) => json
        ..['status'] = next.status.value
        ..['current_stage_index'] = next.currentStageIndex
        ..['stage_label'] = next.stageLabel
        ..['direction'] = next.direction.name
        ..['next_review_at'] = next.nextReviewAt?.toIso8601String()
        ..['has_regressed'] = next.hasRegressed
        ..['stages_history'] = [
          for (final h in next.stagesHistory) stageHistoryToJson(h),
        ]
        ..['last_evaluated_at'] = now.toIso8601String(),
    );

    await _store.enqueue('flashcard.evaluate', {
      'flashcard_id': card.id,
      'evaluation': evaluation.value,
      'evaluated_at': now.toIso8601String(),
      'base_version': baseVersion,
      'session_id': sessionId,
      'deck': card.deck.value,
    });
    _ref.read(syncEngineProvider.notifier).scheduleFlush();
    return updated;
  }

  Future<void> archive(Flashcard card) async {
    await _write(
      card.id,
      (json) => json..['status'] = FlashcardStatus.archived.value,
    );
    await _store.enqueue('flashcard.archive', {'flashcard_id': card.id});
    _ref.read(syncEngineProvider.notifier).scheduleFlush();
  }

  /// Back to the first stage, due now, like the API's restore.
  Future<void> restore(Flashcard card) async {
    final config = _ref.read(flashcardConfigProvider).valueOrNull;
    final stages = config?.stages ?? flashcardStages;
    final now = DateTime.now().toUtc();
    final initial = buildInitialState(now, stages);
    await _write(
      card.id,
      (json) => json
        ..['status'] = FlashcardStatus.active.value
        ..['current_stage_index'] = 0
        ..['stage_label'] = flashcardStageLabel(0, stages)
        ..['direction'] = FlashcardDirection.forward.name
        ..['next_review_at'] = now.toIso8601String()
        ..['has_regressed'] = false
        ..['stages_history'] = [
          for (final h in initial.stagesHistory) stageHistoryToJson(h),
        ],
    );
    await _store.enqueue('flashcard.restore', {'flashcard_id': card.id});
    _ref.read(syncEngineProvider.notifier).scheduleFlush();
  }
}

final flashcardWriterProvider = Provider<FlashcardWriter>(FlashcardWriter.new);

enum FlashcardsPhase { home, loading, session, completion }

class FlashcardSessionState {
  final FlashcardsPhase phase;
  final FlashcardSession? session;
  final int currentIndex;
  final bool isFlipped;
  final bool isExpanded;
  final FlashcardEvaluation? selectedEvaluation;
  final bool isSubmitting;
  final String? notice;
  final int noticeNonce;

  const FlashcardSessionState({
    this.phase = FlashcardsPhase.home,
    this.session,
    this.currentIndex = 0,
    this.isFlipped = false,
    this.isExpanded = false,
    this.selectedEvaluation,
    this.isSubmitting = false,
    this.notice,
    this.noticeNonce = 0,
  });

  FlashcardSessionCard? get currentCard {
    final cards = session?.cards;
    if (cards == null || currentIndex < 0 || currentIndex >= cards.length) {
      return null;
    }
    return cards[currentIndex];
  }

  int get evaluatedCount => session?.evaluatedCount ?? 0;
  int get totalCards => session?.cards.length ?? 0;

  int countOf(FlashcardEvaluation evaluation) =>
      session?.cards.where((card) => card.evaluation == evaluation).length ?? 0;

  FlashcardSessionState copyWith({
    FlashcardsPhase? phase,
    FlashcardSession? Function()? session,
    int? currentIndex,
    bool? isFlipped,
    bool? isExpanded,
    FlashcardEvaluation? Function()? selectedEvaluation,
    bool? isSubmitting,
    String? Function()? notice,
    int? noticeNonce,
  }) {
    return FlashcardSessionState(
      phase: phase ?? this.phase,
      session: session != null ? session() : this.session,
      currentIndex: currentIndex ?? this.currentIndex,
      isFlipped: isFlipped ?? this.isFlipped,
      isExpanded: isExpanded ?? this.isExpanded,
      selectedEvaluation: selectedEvaluation != null
          ? selectedEvaluation()
          : this.selectedEvaluation,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      notice: notice != null ? notice() : this.notice,
      noticeNonce: noticeNonce ?? this.noticeNonce,
    );
  }
}

class FlashcardSessionNotifier
    extends FamilyNotifier<FlashcardSessionState, FlashcardDeck> {
  /// Time the chosen evaluation stays highlighted before the next card.
  static const evaluationHold = Duration(milliseconds: 375);

  @override
  FlashcardSessionState build(FlashcardDeck deck) =>
      const FlashcardSessionState();

  AppLocalizations get _l10n => ref.read(appLocalizationsProvider);

  LocalStore get _store => ref.read(localStoreProvider);

  /// Resumes this device's session of the deck or composes a new one from
  /// the local cards. [size] limits a new deck (menu bar quick sessions).
  Future<void> startSession({int? size}) async {
    state = state.copyWith(
      phase: FlashcardsPhase.loading,
      session: () => null,
      currentIndex: 0,
      isFlipped: false,
      isExpanded: false,
      selectedEvaluation: () => null,
      isSubmitting: false,
    );

    try {
      final cards = await ref.read(localFlashcardsProvider.future);
      final byId = {for (final card in cards) card.id: card};
      final saved =
          await _store.read(_sessionKey(arg)) as Map<String, dynamic>?;

      FlashcardSession? session;
      if (saved != null) {
        session = _restore(saved, byId);
      }
      if (session == null || session.cards.isEmpty) {
        final config = ref.read(flashcardConfigProvider).valueOrNull;
        final lastHard =
            (await _store.read(_lastHardKey(arg)) as List?)?.cast<String>() ??
            const <String>[];
        final deck = composeSessionDeck(
          cards,
          now: DateTime.now().toUtc(),
          deck: arg,
          previousHardIds: lastHard,
          size: size,
          config: config == null
              ? FlashcardDeckConfig.defaults
              : FlashcardDeckConfig.fromConfig(config),
        );
        if (deck.isEmpty) {
          _goHome(notice: _l10n.flashcardsNothingToReview);
          return;
        }
        session = FlashcardSession(
          id: newLocalId(),
          deck: arg,
          status: FlashcardSessionStatus.inProgress,
          startedAt: DateTime.now().toUtc(),
          flashcardIds: [for (final card in deck) card.id],
          cards: [
            for (var i = 0; i < deck.length; i++)
              FlashcardSessionCard(
                id: deck[i].id,
                position: i,
                flashcard: deck[i],
              ),
          ],
        );
        await _save(session);
      }

      if (session.isComplete) {
        await _complete(session);
        return;
      }

      final pending = session.firstPendingIndex;
      state = state.copyWith(
        phase: FlashcardsPhase.session,
        session: () => session,
        currentIndex: pending < 0 ? 0 : pending,
      );

      ref
          .read(audioPrefetchServiceProvider)
          .prefetchFlashcards(
            session.cards.map((card) => card.flashcard).toList(),
          );
    } catch (e, st) {
      appLogger.handle(e, st, 'FlashcardSession startSession() error');
      _goHome(notice: _l10n.flashcardsSessionLoadFailed);
    }
  }

  /// The session saved on this device, with the cards still present.
  FlashcardSession? _restore(
    Map<String, dynamic> saved,
    Map<String, Flashcard> byId,
  ) {
    final evaluations =
        (saved['evaluations'] as Map?)?.cast<String, String>() ?? {};
    final ids = (saved['flashcard_ids'] as List).cast<String>();
    final cards = <FlashcardSessionCard>[];
    for (final id in ids) {
      final card = byId[id];
      if (card == null || card.isArchived) continue;
      cards.add(
        FlashcardSessionCard(
          id: id,
          position: cards.length,
          flashcard: card,
          evaluation: FlashcardEvaluation.fromValue(evaluations[id]),
        ),
      );
    }
    return FlashcardSession(
      id: saved['id'] as String,
      deck: arg,
      status: FlashcardSessionStatus.inProgress,
      startedAt: DateTime.tryParse(saved['started_at'] as String? ?? ''),
      flashcardIds: [for (final card in cards) card.id],
      cards: cards,
    );
  }

  Future<void> _save(FlashcardSession session) => _store.write(
    _sessionKey(arg),
    {
      'id': session.id,
      'started_at': session.startedAt?.toIso8601String(),
      'flashcard_ids': session.flashcardIds,
      'evaluations': {
        for (final card in session.cards)
          if (card.evaluation case final evaluation?) card.id: evaluation.value,
      },
    },
  );

  void flip() {
    final card = state.currentCard;
    if (card == null || card.isEvaluated || state.isSubmitting) return;

    if (state.isFlipped) {
      state = state.copyWith(isFlipped: false, isExpanded: false);
    } else {
      state = state.copyWith(isFlipped: true);
    }
  }

  void toggleMeaning() {
    final card = state.currentCard;
    if (card == null || card.isEvaluated || state.isSubmitting) return;

    if (!state.isFlipped) {
      state = state.copyWith(isFlipped: true, isExpanded: true);
    } else {
      state = state.copyWith(isExpanded: !state.isExpanded);
    }
  }

  Future<void> evaluate(FlashcardEvaluation evaluation) async {
    final session = state.session;
    final card = state.currentCard;
    if (session == null ||
        card == null ||
        card.isEvaluated ||
        !state.isFlipped ||
        state.isSubmitting) {
      return;
    }

    state = state.copyWith(
      selectedEvaluation: () => evaluation,
      isSubmitting: true,
    );
    final hold = Future<void>.delayed(evaluationHold);

    try {
      final updatedCard = await ref
          .read(flashcardWriterProvider)
          .evaluate(card.flashcard, evaluation, sessionId: session.id!);
      final updated = session.copyWith(
        cards: [
          for (final item in session.cards)
            item.id == card.id
                ? item.copyWith(
                    evaluation: () => evaluation,
                    evaluatedAt: () => DateTime.now(),
                    flashcard: updatedCard ?? item.flashcard,
                  )
                : item,
        ],
      );
      await _save(updated);
      await hold;
      await _advance(updated);
    } catch (e, st) {
      appLogger.handle(e, st, 'FlashcardSession evaluate() error');
      state = state.copyWith(
        selectedEvaluation: () => null,
        isSubmitting: false,
      );
      _notify(_l10n.flashcardsAnswerSaveFailed);
    }
  }

  Future<void> archiveCurrent() async {
    final session = state.session;
    final card = state.currentCard;
    if (session == null || card == null || state.isSubmitting) return;

    final plan = ref.read(planStatusProvider).valueOrNull;
    if (plan != null && !plan.limits.archive) {
      ref.read(upgradePromptProvider.notifier).state = const UpgradeReason(
        UpgradeTrigger.feature,
      );
      return;
    }

    state = state.copyWith(isSubmitting: true);
    try {
      await ref.read(flashcardWriterProvider).archive(card.flashcard);
      final remaining = session.copyWith(
        cards: session.cards.where((item) => item.id != card.id).toList(),
        flashcardIds: session.flashcardIds
            .where((id) => id != card.flashcard.id)
            .toList(),
      );
      if (remaining.cards.isEmpty) {
        await _store.remove(_sessionKey(arg));
        _goHome(notice: _l10n.flashcardsSessionEmpty);
        return;
      }
      await _save(remaining);
      if (remaining.firstPendingIndex < 0) {
        await _complete(remaining);
        return;
      }
      _notify(_l10n.flashcardsWordSetAside);
      await _advance(remaining);
    } catch (e, st) {
      state = state.copyWith(isSubmitting: false);
      appLogger.handle(e, st, 'FlashcardSession archiveCurrent() error');
      _notify(_l10n.flashcardsSetAsideFailed);
    }
  }

  void leaveSession() => _goHome();

  void finishCompletion() => _goHome();

  Future<void> _advance(FlashcardSession session) async {
    if (session.firstPendingIndex < 0) {
      await _complete(session);
      return;
    }

    var next = session.cards.indexWhere(
      (card) => !card.isEvaluated,
      state.currentIndex.clamp(0, session.cards.length - 1),
    );
    if (next < 0) next = session.firstPendingIndex;

    state = state.copyWith(
      phase: FlashcardsPhase.session,
      session: () => session,
      currentIndex: next,
      isFlipped: false,
      isExpanded: false,
      selectedEvaluation: () => null,
      isSubmitting: false,
    );
  }

  /// Records the finished session (stats and streak) and remembers its hard
  /// cards for the next deck.
  Future<void> _complete(FlashcardSession session) async {
    int count(FlashcardEvaluation evaluation) =>
        session.cards.where((card) => card.evaluation == evaluation).length;

    await _store.remove(_sessionKey(arg));
    await _store.write(_lastHardKey(arg), [
      for (final card in session.cards)
        if (card.evaluation == FlashcardEvaluation.hard) card.id,
    ]);
    await _store.enqueue('session.complete', {
      'session_id': session.id,
      'deck': arg.value,
      'started_at': (session.startedAt ?? DateTime.now().toUtc())
          .toIso8601String(),
      'completed_at': DateTime.now().toUtc().toIso8601String(),
      'cards_hard': count(FlashcardEvaluation.hard),
      'cards_medium': count(FlashcardEvaluation.medium),
      'cards_easy': count(FlashcardEvaluation.easy),
    });
    ref.read(syncEngineProvider.notifier).scheduleFlush();

    ref.invalidate(flashcardDeckStatusProvider(arg));
    if (arg == FlashcardDeck.collections) ref.invalidate(collectionsProvider);
    state = state.copyWith(
      phase: FlashcardsPhase.completion,
      session: () => session,
      selectedEvaluation: () => null,
      isSubmitting: false,
    );
  }

  void _goHome({String? notice}) {
    ref.invalidate(flashcardDeckStatusProvider(arg));
    state = FlashcardSessionState(
      notice: notice,
      noticeNonce: notice == null ? state.noticeNonce : state.noticeNonce + 1,
    );
  }

  void _notify(String message) {
    state = state.copyWith(
      notice: () => message,
      noticeNonce: state.noticeNonce + 1,
    );
  }
}

final flashcardDeckSessionProvider =
    NotifierProvider.family<
      FlashcardSessionNotifier,
      FlashcardSessionState,
      FlashcardDeck
    >(FlashcardSessionNotifier.new);

/// The session of the library deck.
final flashcardSessionProvider = flashcardDeckSessionProvider(
  FlashcardDeck.library,
);

/// The deck tab open in Flashcards.
final flashcardsDeckTabProvider = StateProvider<FlashcardDeck>(
  (_) => FlashcardDeck.library,
);
