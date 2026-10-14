import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';

/// Today's Study Note; only requested for Pro accounts.
final studyNoteProvider = FutureProvider<StudyNote>((ref) {
  return ref
      .watch(apiClientProvider)
      .studyNotes
      .getToday(timezoneOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes);
});

/// The daily AI note on the user's study, or its teaser on the free plan.
class StudyNoteCard extends ConsumerWidget {
  const StudyNoteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(planStatusProvider).valueOrNull;
    if (status == null) return const SizedBox.shrink();
    if (!status.limits.studyNote) return const _StudyNoteTeaser();

    return ref
        .watch(studyNoteProvider)
        .when(
          loading: () => _Frame(
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: VocaboSpacing.sm),
                Text(
                  context.l10n.studyNoteWriting,
                  style: VocaboTypography.bodyMd.copyWith(
                    color: VocaboColors.neutral600,
                  ),
                ),
              ],
            ),
          ),
          error: (_, _) => _Frame(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.studyNoteUnavailable,
                    style: VocaboTypography.bodyMd.copyWith(
                      color: VocaboColors.neutral600,
                    ),
                  ),
                ),
                VocaboTextButton(
                  label: context.l10n.commonRetry,
                  onPressed: () => ref.invalidate(studyNoteProvider),
                ),
              ],
            ),
          ),
          data: (note) => _StudyNoteContent(note: note),
        );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLowest,
        borderRadius: VocaboRadius.lg,
        boxShadow: [VocaboShadows.whisper],
      ),
      child: child,
    );
  }
}

class _Overline extends StatelessWidget {
  const _Overline();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.auto_awesome_outlined,
          size: 16,
          color: VocaboColors.primary,
        ),
        const SizedBox(width: VocaboSpacing.xs),
        Text(
          context.l10n.studyNoteTitle.toUpperCase(),
          style: VocaboTypography.labelSm.copyWith(
            color: VocaboColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StudyNoteContent extends StatefulWidget {
  const _StudyNoteContent({required this.note});

  final StudyNote note;

  @override
  State<_StudyNoteContent> createState() => _StudyNoteContentState();
}

class _StudyNoteContentState extends State<_StudyNoteContent> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final note = widget.note;

    return _Frame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Overline(),
          const SizedBox(height: VocaboSpacing.sm),
          Text(note.headline, style: VocaboTypography.titleLg),
          const SizedBox(height: VocaboSpacing.xs),
          Text(
            note.summary,
            style: VocaboTypography.bodyMd.copyWith(
              color: VocaboColors.neutral700,
              height: 1.45,
            ),
          ),
          if (note.createdAt case final createdAt?) ...[
            const SizedBox(height: VocaboSpacing.xs),
            Text(
              updatedAtLabel(context, createdAt),
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
          ],
          if (note.unchanged) ...[
            const SizedBox(height: VocaboSpacing.xs),
            Text(
              l10n.studyNoteUnchanged,
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
          ],
          if (note.wordsAtRisk.isNotEmpty)
            _Section(title: l10n.studyNoteWordsAtRisk, tips: note.wordsAtRisk),
          if (note.watchOut.isNotEmpty)
            _Section(title: l10n.studyNoteWatchOut, tips: note.watchOut),
          if (note.planToday.isNotEmpty) ...[
            const SizedBox(height: VocaboSpacing.md),
            _SectionTitle(l10n.studyNotePlanToday),
            Text(note.planToday, style: VocaboTypography.bodyMd),
          ],
          if (note.challenge case final challenge?) ...[
            const SizedBox(height: VocaboSpacing.md),
            _SectionTitle(l10n.studyNoteChallenge),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(VocaboSpacing.md),
              decoration: BoxDecoration(
                color: VocaboColors.surfaceContainerLow,
                borderRadius: VocaboRadius.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _showAnswer
                          ? challenge.sentence.replaceFirst(
                              '____',
                              challenge.answer,
                            )
                          : challenge.sentence,
                      style: VocaboTypography.bodyMd.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  if (!_showAnswer)
                    VocaboTextButton(
                      label: l10n.studyNoteShowAnswer,
                      onPressed: () => setState(() => _showAnswer = true),
                    ),
                ],
              ),
            ),
          ],
          if (note.milestone case final milestone?) ...[
            const SizedBox(height: VocaboSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.emoji_events_outlined,
                  size: 18,
                  color: VocaboColors.tertiary,
                ),
                const SizedBox(width: VocaboSpacing.xs),
                Expanded(
                  child: Text(milestone, style: VocaboTypography.bodySm),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VocaboSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: VocaboTypography.labelSm.copyWith(color: VocaboColors.neutral),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.tips});

  final String title;
  final List<StudyNoteTip> tips;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: VocaboSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(bottom: VocaboSpacing.xs),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${tip.term}  ',
                      style: VocaboTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: tip.text, style: VocaboTypography.bodyMd),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StudyNoteTeaser extends StatelessWidget {
  const _StudyNoteTeaser();

  @override
  Widget build(BuildContext context) {
    return ProLockedPanel(
      icon: Icons.auto_awesome_outlined,
      title: context.l10n.studyNoteTitle,
      body: context.l10n.studyNoteTeaser,
      compact: true,
    );
  }
}
