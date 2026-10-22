import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';

/// New collection words that enter the flashcards each day; mirrors the API.
const collectionNewWordsPerDay = 10;

/// A collection's words in a grid where longer terms span more columns.
class CollectionDetailView extends ConsumerWidget {
  const CollectionDetailView({super.key, required this.collectionId});

  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final detail = ref.watch(collectionDetailProvider(collectionId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VocaboTextButton(
          label: l10n.collectionsBack,
          leading: const Icon(Icons.arrow_back, size: 18),
          onPressed: () =>
              ref.read(openCollectionIdProvider.notifier).state = null,
        ),
        const SizedBox(height: VocaboSpacing.sm),
        Expanded(
          child: detail.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => OfflineNotice.orElse(
              error,
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.collectionsLoadFailed,
                      style: VocaboTypography.bodyMd.copyWith(
                        color: VocaboColors.neutral,
                      ),
                    ),
                    const SizedBox(height: VocaboSpacing.sm),
                    VocaboTextButton(
                      label: l10n.commonTryAgain,
                      onPressed: () => ref.invalidate(
                        collectionDetailProvider(collectionId),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            data: (detail) => _DetailBody(detail: detail),
          ),
        ),
      ],
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final CollectionDetail detail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnsForWidth(constraints.maxWidth);
        final items = detail.items;
        final rows = packSpanRows([
          for (final item in items) spanForTerm(item.term, columns),
        ], columns);

        return ListView.builder(
          itemCount: rows.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: VocaboSpacing.lg),
                child: _Header(collection: detail.collection),
              );
            }
            final row = rows[index - 1];
            final used = row.fold<int>(0, (sum, cell) => sum + cell.span);
            return Padding(
              padding: const EdgeInsets.only(bottom: VocaboSpacing.sm),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, cell) in row.indexed) ...[
                      if (i > 0) const SizedBox(width: VocaboSpacing.sm),
                      Expanded(
                        flex: cell.span,
                        child: CollectionWordCard(
                          key: ValueKey(items[cell.index].id),
                          item: items[cell.index],
                        ),
                      ),
                    ],
                    if (used < columns) ...[
                      const SizedBox(width: VocaboSpacing.sm),
                      Spacer(flex: columns - used),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Header extends ConsumerStatefulWidget {
  const _Header({required this.collection});

  final WordCollection collection;

  @override
  ConsumerState<_Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<_Header> {
  bool _adding = false;

  Future<void> _add() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _adding = true);
    try {
      await ref
          .read(apiClientProvider)
          .discover
          .addCollection(widget.collection.id);
      ref.invalidate(collectionDetailProvider(widget.collection.id));
      ref.invalidate(collectionsProvider);
      ref.invalidate(flashcardDeckStatusProvider(FlashcardDeck.collections));
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.collectionsAddedNotice(collectionNewWordsPerDay)),
        ),
      );
    } on ConflictException {
      ref.invalidate(collectionDetailProvider(widget.collection.id));
    } catch (e) {
      if (upgradeReasonFor(e) case final reason?) {
        ref.read(upgradePromptProvider.notifier).state = reason;
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.commonSomethingWrong)),
        );
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  void _study() {
    ref.read(flashcardsDeckTabProvider.notifier).state =
        FlashcardDeck.collections;
    ref.read(dashboardSectionProvider.notifier).state =
        DashboardSection.flashcards;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final collection = widget.collection;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CollectionIcon(collection, size: 40),
            const SizedBox(width: VocaboSpacing.md),
            Expanded(
              child: Text(collection.title, style: VocaboTypography.titleLg),
            ),
          ],
        ),
        const SizedBox(height: VocaboSpacing.sm),
        Text(
          collection.description,
          style: VocaboTypography.bodyMd.copyWith(
            color: VocaboColors.neutral600,
          ),
        ),
        const SizedBox(height: VocaboSpacing.sm),
        Wrap(
          spacing: VocaboSpacing.sm,
          runSpacing: VocaboSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DifficultyBadge(collection.difficulty),
            Text(
              l10n.collectionsItemCount(collection.itemCount),
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
            if (collection.isAdded)
              Text(
                l10n.collectionsProgress(
                  collection.started,
                  collection.itemCount,
                ),
                style: VocaboTypography.bodySm.copyWith(
                  color: VocaboColors.neutral,
                ),
              ),
          ],
        ),
        const SizedBox(height: VocaboSpacing.sm),
        Text(
          l10n.collectionsTapToTranslate,
          style: VocaboTypography.bodySm.copyWith(color: VocaboColors.neutral),
        ),
      ],
    );

    final action = collection.isAdded
        ? VocaboPrimaryButton(
            label: l10n.collectionsStudyNow,
            onPressed: _study,
          )
        : VocaboPrimaryButton(
            label: l10n.collectionsAddToFlashcards,
            isLoading: _adding,
            onPressed: _adding ? null : _add,
          );

    return Container(
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLow,
        borderRadius: VocaboRadius.lg,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 560
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  info,
                  const SizedBox(height: VocaboSpacing.md),
                  action,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: info),
                  const SizedBox(width: VocaboSpacing.lg),
                  action,
                ],
              ),
      ),
    );
  }
}
