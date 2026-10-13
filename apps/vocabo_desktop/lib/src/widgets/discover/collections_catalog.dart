import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/pro/paywall_dialog.dart';
import 'package:vocabo_desktop/src/pro/plan_providers.dart';
import 'package:vocabo_desktop/src/pro/pro_feature_gate.dart';
import 'package:vocabo_desktop/src/providers/discover_providers.dart';
import 'package:vocabo_desktop/src/widgets/discover/collection_detail_view.dart';
import 'package:vocabo_desktop/src/widgets/discover/collection_visuals.dart';

/// The Collections tab: the catalog, or the open collection.
class CollectionsTab extends ConsumerWidget {
  const CollectionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openId = ref.watch(openCollectionIdProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.expand,
        children: [...previous, ?current],
      ),
      child: openId == null
          ? const CollectionsCatalog(key: ValueKey('catalog'))
          : CollectionDetailView(key: ValueKey(openId), collectionId: openId),
    );
  }
}

/// Every collection, filterable by difficulty. Free accounts see it locked.
class CollectionsCatalog extends ConsumerStatefulWidget {
  const CollectionsCatalog({super.key});

  @override
  ConsumerState<CollectionsCatalog> createState() => _CollectionsCatalogState();
}

class _CollectionsCatalogState extends ConsumerState<CollectionsCatalog> {
  CollectionDifficulty? _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final collections = ref.watch(collectionsProvider);
    final included =
        ref.watch(planStatusProvider).valueOrNull?.limits.collections ?? false;

    return collections.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
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
              onPressed: () => ref.invalidate(collectionsProvider),
            ),
          ],
        ),
      ),
      data: (all) {
        final visible = _filter == null
            ? all
            : all.where((c) => c.difficulty == _filter).toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            const gap = VocaboSpacing.md;
            final width = constraints.maxWidth;
            final columns = width >= 1000
                ? 3
                : width >= 620
                ? 2
                : 1;
            final cardWidth = (width - gap * (columns - 1)) / columns;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.collectionsSubtitle,
                    style: VocaboTypography.bodyMd.copyWith(
                      color: VocaboColors.neutral600,
                    ),
                  ),
                  if (!included) ...[
                    const SizedBox(height: VocaboSpacing.md),
                    ProLockedPanel(
                      icon: Icons.collections_bookmark_outlined,
                      title: l10n.collectionsLockedTitle,
                      body: l10n.collectionsLockedBody,
                      compact: true,
                    ),
                  ],
                  const SizedBox(height: VocaboSpacing.md),
                  Wrap(
                    spacing: VocaboSpacing.sm,
                    runSpacing: VocaboSpacing.sm,
                    children: [
                      VocaboSelectableChip(
                        label: l10n.collectionsFilterAll,
                        isSelected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                      ),
                      for (final difficulty in CollectionDifficulty.values)
                        VocaboSelectableChip(
                          label: difficultyLabel(l10n, difficulty),
                          isSelected: _filter == difficulty,
                          onTap: () => setState(() => _filter = difficulty),
                        ),
                    ],
                  ),
                  const SizedBox(height: VocaboSpacing.lg),
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final collection in visible)
                        SizedBox(
                          width: cardWidth,
                          child: CollectionCard(
                            collection: collection,
                            locked: !included,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: VocaboSpacing.xl),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// A collection in the catalog or in the recommendations.
class CollectionCard extends ConsumerWidget {
  const CollectionCard({
    super.key,
    required this.collection,
    this.locked = false,
    this.reason,
  });

  final WordCollection collection;
  final bool locked;

  /// Why it was recommended, shown instead of the description.
  final String? reason;

  void _open(BuildContext context, WidgetRef ref) {
    if (locked) {
      showPaywall(context, const UpgradeReason(UpgradeTrigger.feature));
      return;
    }
    ref.read(libraryTabProvider.notifier).state = LibraryTab.collections;
    ref.read(openCollectionIdProvider.notifier).state = collection.id;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLowest,
        borderRadius: VocaboRadius.lg,
        boxShadow: [VocaboShadows.whisper],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => _open(context, ref),
          mouseCursor: SystemMouseCursors.click,
          borderRadius: VocaboRadius.lg,
          child: Container(
            height: 188,
            padding: const EdgeInsets.all(VocaboSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CollectionIcon(collection),
                    const Spacer(),
                    if (locked)
                      const Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: VocaboColors.neutral,
                      )
                    else if (collection.isAdded)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: VocaboColors.tertiary,
                          ),
                          const SizedBox(width: VocaboSpacing.xs),
                          Text(
                            l10n.collectionsAdded,
                            style: VocaboTypography.labelSm.copyWith(
                              color: VocaboColors.neutral600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: VocaboSpacing.sm),
                Text(
                  collection.title,
                  style: VocaboTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: VocaboSpacing.xs),
                Expanded(
                  child: Text(
                    reason ?? collection.description,
                    style: VocaboTypography.bodySm.copyWith(
                      color: VocaboColors.neutral600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    DifficultyBadge(collection.difficulty),
                    const SizedBox(width: VocaboSpacing.sm),
                    Flexible(
                      child: Text(
                        collection.isAdded
                            ? l10n.collectionsProgress(
                                collection.started,
                                collection.itemCount,
                              )
                            : l10n.collectionsItemCount(collection.itemCount),
                        style: VocaboTypography.bodySm.copyWith(
                          color: VocaboColors.neutral,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
