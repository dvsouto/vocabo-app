import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/providers/flashcard_providers.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/flashcards_completion.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/flashcards_home.dart';
import 'package:vocabo_desktop/src/widgets/flashcards/flashcards_session.dart';

class FlashcardsContent extends ConsumerStatefulWidget {
  const FlashcardsContent({super.key});

  @override
  ConsumerState<FlashcardsContent> createState() => _FlashcardsContentState();
}

class _FlashcardsContentState extends ConsumerState<FlashcardsContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshOnEnter());
  }

  /// The server is the source of truth: always reload the status when the
  /// tab opens and resume any session that was left open elsewhere.
  void _refreshOnEnter() {
    if (!mounted) return;

    ref.invalidate(flashcardStatusProvider);

    final notifier = ref.read(flashcardSessionProvider.notifier);
    switch (ref.read(flashcardSessionProvider).phase) {
      case FlashcardsPhase.session:
      case FlashcardsPhase.loading:
        notifier.startSession();
      case FlashcardsPhase.completion:
        notifier.finishCompletion();
      case FlashcardsPhase.home:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(flashcardSessionProvider.select((state) => state.noticeNonce), (
      _,
      _,
    ) {
      final notice = ref.read(flashcardSessionProvider).notice;
      if (notice == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(notice)));
    });

    final phase = ref.watch(flashcardSessionProvider.select((s) => s.phase));

    return Padding(
      padding: const EdgeInsets.all(VocaboSpacing.xl),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (phase) {
          FlashcardsPhase.home => const _HomeLayout(key: ValueKey('home')),
          FlashcardsPhase.loading => const Center(
            key: ValueKey('loading'),
            child: CircularProgressIndicator(),
          ),
          FlashcardsPhase.session => const FlashcardsSession(
            key: ValueKey('session'),
          ),
          FlashcardsPhase.completion => const FlashcardsCompletion(
            key: ValueKey('completion'),
          ),
        },
      ),
    );
  }
}

class _HomeLayout extends StatelessWidget {
  const _HomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.l10n.flashcardsTitle, style: VocaboTypography.headlineSm),
        const SizedBox(height: VocaboSpacing.xs),
        Text(
          context.l10n.flashcardsTagline,
          style: VocaboTypography.bodyMd.copyWith(color: VocaboColors.neutral),
        ),
        const SizedBox(height: VocaboSpacing.xl),
        const Expanded(child: FlashcardsHome()),
      ],
    );
  }
}
