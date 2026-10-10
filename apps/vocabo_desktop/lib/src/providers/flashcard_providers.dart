import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/audio_player_providers.dart';

final flashcardStatusProvider = FutureProvider<FlashcardStatusSummary>((
  ref,
) async {
  final api = ref.watch(apiClientProvider);
  return api.flashcards.getStatus();
});

final archivedFlashcardsProvider = FutureProvider.autoDispose<List<Flashcard>>((
  ref,
) async {
  final api = ref.watch(apiClientProvider);
  return api.flashcards.getArchived();
});

final flashcardByVocabularyProvider = FutureProvider.autoDispose
    .family<Flashcard?, String>((ref, userVocabularyId) async {
      final api = ref.watch(apiClientProvider);
      return api.flashcards.getByVocabulary(userVocabularyId);
    });

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

class FlashcardSessionNotifier extends Notifier<FlashcardSessionState> {
  /// Time the chosen evaluation stays highlighted before the next card.
  static const evaluationHold = Duration(milliseconds: 375);

  @override
  FlashcardSessionState build() => const FlashcardSessionState();

  Future<void> startSession() async {
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
      final api = ref.read(apiClientProvider);
      final session = await api.flashcards.getSession();

      if (session == null || session.isEmpty) {
        _goHome(notice: 'Nothing to review right now.');
        return;
      }

      if (session.isComplete) {
        _complete(session);
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
      _goHome(notice: 'Could not load your review session.');
    }
  }

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
      final api = ref.read(apiClientProvider);
      final FlashcardEvaluationResult result;

      if (session.isVirtual) {
        result = await api.flashcards.startSession(
          flashcardIds: session.flashcardIds,
          firstFlashcardId: card.flashcard.id,
          evaluation: evaluation,
        );
      } else {
        result = await api.flashcards.evaluateCard(
          sessionCardId: card.id,
          evaluation: evaluation,
        );
      }

      await hold;

      final updated =
          result.session ??
          _withEvaluation(session, card.id, evaluation, result.flashcard);

      _advance(updated, completed: result.sessionCompleted);
    } on ConflictException {
      _notify('Your session changed on another device. Reloading…');
      await startSession();
    } catch (e, st) {
      appLogger.handle(e, st, 'FlashcardSession evaluate() error');
      state = state.copyWith(
        selectedEvaluation: () => null,
        isSubmitting: false,
      );
      _notify('Could not save your answer. Please try again.');
    }
  }

  Future<void> archiveCurrent() async {
    final session = state.session;
    final card = state.currentCard;
    if (session == null || card == null || state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true);

    try {
      final api = ref.read(apiClientProvider);
      final result = await api.flashcards.archive(card.flashcard.id);

      ref.invalidate(archivedFlashcardsProvider);

      final remaining = session.copyWith(
        cards: session.cards.where((item) => item.id != card.id).toList(),
        flashcardIds: session.flashcardIds
            .where((id) => id != card.flashcard.id)
            .toList(),
      );

      if (remaining.cards.isEmpty) {
        if (result.sessionCompleted) {
          _complete(remaining);
        } else {
          _goHome(notice: 'This session is empty.');
        }
        return;
      }

      if (result.sessionCompleted || remaining.firstPendingIndex < 0) {
        _complete(remaining);
        return;
      }

      _notify('Flashcard archived.');
      _advance(remaining, completed: false);
    } catch (e, st) {
      appLogger.handle(e, st, 'FlashcardSession archiveCurrent() error');
      state = state.copyWith(isSubmitting: false);
      _notify('Could not archive this flashcard. Please try again.');
    }
  }

  void leaveSession() => _goHome();

  void finishCompletion() => _goHome();

  FlashcardSession _withEvaluation(
    FlashcardSession session,
    String cardId,
    FlashcardEvaluation evaluation,
    Flashcard flashcard,
  ) {
    // The evaluate response only carries scheduling fields, so merge them
    // into the hydrated card instead of replacing it.
    return session.copyWith(
      cards: session.cards
          .map(
            (card) => card.id == cardId
                ? card.copyWith(
                    evaluation: () => evaluation,
                    evaluatedAt: () => DateTime.now(),
                    flashcard: card.flashcard.copyWith(
                      status: flashcard.status,
                      currentStageIndex: flashcard.currentStageIndex,
                      stageLabel: flashcard.stageLabel,
                      nextReviewAt: () => flashcard.nextReviewAt,
                      hasRegressed: flashcard.hasRegressed,
                    ),
                  )
                : card,
          )
          .toList(),
    );
  }

  void _advance(FlashcardSession session, {required bool completed}) {
    if (completed || session.firstPendingIndex < 0) {
      _complete(session);
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

  void _complete(FlashcardSession session) {
    ref.invalidate(flashcardStatusProvider);
    state = state.copyWith(
      phase: FlashcardsPhase.completion,
      session: () => session,
      selectedEvaluation: () => null,
      isSubmitting: false,
    );
  }

  void _goHome({String? notice}) {
    ref.invalidate(flashcardStatusProvider);
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

final flashcardSessionProvider =
    NotifierProvider<FlashcardSessionNotifier, FlashcardSessionState>(
      FlashcardSessionNotifier.new,
    );
