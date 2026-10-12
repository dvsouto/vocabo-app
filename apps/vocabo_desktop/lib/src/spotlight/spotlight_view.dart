import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/word_type_labels.dart';
import 'package:vocabo_desktop/src/l10n/memory_strength_label.dart';
import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/l10n/locale_providers.dart';
import 'package:vocabo_desktop/src/providers/dictionary_providers.dart';
import 'package:vocabo_desktop/src/spotlight/spotlight_controller.dart';
import 'package:vocabo_desktop/src/spotlight/spotlight_host.dart';
import 'package:vocabo_desktop/src/spotlight/spotlight_items.dart';

/// Space around the card for its shadow; the native panel adds the same
/// inset to the content height reported here.
const spotlightShadowInset = 24.0;
const _bodyHeight = 320.0;
const _listWidth = 260.0;

class SpotlightView extends ConsumerStatefulWidget {
  const SpotlightView({super.key});

  @override
  ConsumerState<SpotlightView> createState() => _SpotlightViewState();
}

class _SpotlightViewState extends ConsumerState<SpotlightView> {
  static const _events = MethodChannel('vocabo/spotlight_events');

  final _inputController = TextEditingController();
  final _inputFocus = FocusNode(debugLabel: 'spotlight-input');
  final _cardKey = GlobalKey();
  final _listController = ScrollController();
  double _reportedHeight = 0;

  @override
  void initState() {
    super.initState();
    _events.setMethodCallHandler((call) async {
      if (call.method == 'shown') _onShown();
    });
    _onShown();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocus.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _onShown() {
    ref.invalidate(interfaceLanguageProvider);
    _inputController.clear();
    ref.read(spotlightControllerProvider.notifier).onShown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inputFocus.requestFocus();
    });
  }

  void _reportHeight() {
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final height = box.size.height;
    if ((height - _reportedHeight).abs() < 0.5) return;
    _reportedHeight = height;
    ref.read(spotlightHostProvider).setHeight(height);
  }

  void _ensureSelectionVisible(int index) {
    if (!_listController.hasClients) return;
    const rowHeight = 44.0;
    final top = index * rowHeight;
    final position = _listController.position;
    if (top < position.pixels) {
      _listController.jumpTo(top);
    } else if (top + rowHeight > position.pixels + position.viewportDimension) {
      _listController.jumpTo(top + rowHeight - position.viewportDimension);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final controller = ref.read(spotlightControllerProvider.notifier);
    final state = ref.read(spotlightControllerProvider);
    final meta = HardwareKeyboard.instance.isMetaPressed;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowDown) {
      controller.moveSelection(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      controller.moveSelection(-1);
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.escape) {
      controller.dismiss();
      _inputController.text = '';
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      meta ? controller.saveSelected() : controller.primaryAction();
      return KeyEventResult.handled;
    }
    if (meta && key == LogicalKeyboardKey.keyP) {
      controller.playSelected();
      return KeyEventResult.handled;
    }
    if (meta && key == LogicalKeyboardKey.keyO) {
      controller.openSelectedInApp();
      return KeyEventResult.handled;
    }
    if (meta && key == LogicalKeyboardKey.backspace && state.query.isEmpty) {
      controller.removeSelectedFromHistory();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dictionaryInitProvider);
    final state = ref.watch(spotlightControllerProvider);
    final controller = ref.read(spotlightControllerProvider.notifier);

    ref.listen(
      spotlightControllerProvider.select((s) => s.selectedIndex),
      (_, index) => _ensureSelectionVisible(index),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _reportHeight());

    final showBody = state.items.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(spotlightShadowInset),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Container(
          key: _cardKey,
          decoration: BoxDecoration(
            color: VocaboColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Focus(
            onKeyEvent: _onKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SearchField(
                  controller: _inputController,
                  focusNode: _inputFocus,
                  isBusy: state.resolvingKey != null || state.isSaving,
                  onChanged: controller.setQuery,
                ),
                if (showBody) ...[
                  const Divider(height: 1, color: VocaboColors.neutral200),
                  SizedBox(
                    height: _bodyHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: _listWidth,
                          child: _ResultList(
                            state: state,
                            scrollController: _listController,
                            onSelect: controller.select,
                            onActivate: (index) {
                              controller.select(index);
                              controller.primaryAction();
                            },
                          ),
                        ),
                        Expanded(
                          child: Container(
                            color: VocaboColors.surfaceContainerLow,
                            child: _Preview(state: state),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (state.query.isEmpty && !state.isLoadingLookups)
                  const _EmptyHint(),
                _Footer(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.isBusy,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBusy;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          const SizedBox(width: VocaboSpacing.lg),
          const Icon(Icons.translate, size: 20, color: VocaboColors.neutral),
          const SizedBox(width: VocaboSpacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              maxLength: 200,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              style: VocaboTypography.titleLg.copyWith(
                fontWeight: FontWeight.w500,
              ),
              cursorColor: VocaboColors.primary,
              decoration: InputDecoration(
                hintText: context.l10n.spotlightSearchHint,
                hintStyle: VocaboTypography.titleLg.copyWith(
                  color: VocaboColors.neutral,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
              ),
            ),
          ),
          if (isBusy)
            const Padding(
              padding: EdgeInsets.only(left: VocaboSpacing.sm),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          const SizedBox(width: VocaboSpacing.lg),
        ],
      ),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({
    required this.state,
    required this.scrollController,
    required this.onSelect,
    required this.onActivate,
  });

  final SpotlightState state;
  final ScrollController scrollController;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onActivate;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: VocaboSpacing.xs),
      itemCount: state.items.length,
      itemExtent: 44,
      itemBuilder: (context, index) {
        final item = state.items[index];
        final previous = index > 0 ? state.items[index - 1] : null;
        return _ResultRow(
          item: item,
          sectionLabel: previous?.section == item.section
              ? null
              : item.section.label(context.l10n),
          isSelected: index == state.selectedIndex,
          isResolving: state.resolvingKey == item.key,
          quickTranslation: state.quickTranslations[item.term.toLowerCase()],
          onHover: () => onSelect(index),
          onTap: () => onActivate(index),
        );
      },
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.item,
    required this.sectionLabel,
    required this.isSelected,
    required this.isResolving,
    required this.quickTranslation,
    required this.onHover,
    required this.onTap,
  });

  final SpotlightItem item;
  final String? sectionLabel;
  final bool isSelected;
  final bool isResolving;
  final String? quickTranslation;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTranslateRow = item.section == SpotlightSection.translate;
    final subtitle = item.translation ?? quickTranslation;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onHover: (_) {
        if (!isSelected) onHover();
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: VocaboSpacing.sm),
          padding: const EdgeInsets.symmetric(horizontal: VocaboSpacing.sm),
          decoration: BoxDecoration(
            color: isSelected ? VocaboColors.primary50 : Colors.transparent,
            borderRadius: VocaboRadius.sm,
          ),
          child: Row(
            children: [
              Icon(
                switch (item.section) {
                  SpotlightSection.recent => Icons.history,
                  SpotlightSection.library => Icons.bookmark_outline,
                  SpotlightSection.dictionary => Icons.menu_book_outlined,
                  SpotlightSection.translate => Icons.auto_awesome_outlined,
                },
                size: 16,
                color: isSelected ? VocaboColors.primary : VocaboColors.neutral,
              ),
              const SizedBox(width: VocaboSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTranslateRow
                          ? context.l10n.spotlightTranslateTerm(item.term)
                          : item.term,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VocaboTypography.bodyMd.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null && !isTranslateRow)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VocaboTypography.bodySm.copyWith(
                          color: VocaboColors.neutral,
                        ),
                      ),
                  ],
                ),
              ),
              if (isResolving)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 1.5),
                )
              else if (sectionLabel != null)
                Text(
                  sectionLabel!.toUpperCase(),
                  style: VocaboTypography.labelSm.copyWith(
                    color: VocaboColors.neutral,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.state});

  final SpotlightState state;

  @override
  Widget build(BuildContext context) {
    final item = state.selected;
    if (item == null) return const SizedBox.shrink();

    if (state.resolvingKey == item.key) {
      return Center(
        child: Text(
          context.l10n.spotlightTranslatingTerm(item.term),
          style: VocaboTypography.bodySm.copyWith(color: VocaboColors.neutral),
        ),
      );
    }

    final vocabulary = item.vocabulary;
    if (vocabulary == null) {
      return _QuickPreview(
        term: item.term,
        translation: state.quickTranslations[item.term.toLowerCase()],
      );
    }

    return _FullPreview(item: item, vocabulary: vocabulary);
  }
}

class _QuickPreview extends StatelessWidget {
  const _QuickPreview({required this.term, required this.translation});

  final String term;
  final String? translation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(term, style: VocaboTypography.headlineSm),
          const SizedBox(height: VocaboSpacing.md),
          if (translation != null) ...[
            Text(
              context.l10n.spotlightQuickTranslation.toUpperCase(),
              style: VocaboTypography.labelSm.copyWith(
                color: VocaboColors.neutral,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: VocaboSpacing.xs),
            Text(
              translation!,
              style: VocaboTypography.titleLg.copyWith(
                color: VocaboColors.primary,
              ),
            ),
            const SizedBox(height: VocaboSpacing.lg),
          ],
          Text(
            context.l10n.spotlightPressEnterHint,
            style: VocaboTypography.bodySm.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
        ],
      ),
    );
  }
}

class _FullPreview extends StatelessWidget {
  const _FullPreview({required this.item, required this.vocabulary});

  final SpotlightItem item;
  final Vocabulary vocabulary;

  @override
  Widget build(BuildContext context) {
    final example = vocabulary.usageExamples?.sourceLang.firstOrNull;
    final flashcard = item.flashcard;
    final lookupCount = item.lookup?.lookupCount ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  vocabulary.term,
                  style: VocaboTypography.headlineSm,
                ),
              ),
              const SizedBox(width: VocaboSpacing.sm),
              if (vocabulary.pronunciation?.isNotEmpty ?? false)
                Flexible(
                  child: Text(
                    vocabulary.pronunciation!,
                    overflow: TextOverflow.ellipsis,
                    style: VocaboTypography.bodySm.copyWith(
                      color: VocaboColors.neutral,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VocaboSpacing.xs),
          VocaboTagChip(
            label: wordTypeLabel(context.l10n, vocabulary.wordType),
          ),
          const SizedBox(height: VocaboSpacing.md),
          Text(
            vocabulary.translation ?? '—',
            style: VocaboTypography.titleLg.copyWith(
              color: VocaboColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (vocabulary.meaning?.isNotEmpty ?? false) ...[
            const SizedBox(height: VocaboSpacing.sm),
            Text(
              vocabulary.meaning!,
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral600,
              ),
            ),
          ],
          if (example != null) ...[
            const SizedBox(height: VocaboSpacing.md),
            HighlightedExampleText(
              example: example,
              term: vocabulary.term,
              fontSize: 13,
              color: VocaboColors.neutral600,
            ),
          ],
          const SizedBox(height: VocaboSpacing.lg),
          if (flashcard != null)
            LocalizedMemoryStrengthDots(strength: flashcard.strength)
          else if (lookupCount > 0)
            Text(
              context.l10n.spotlightLookedUpCount(lookupCount),
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
          if (item.shouldSuggestSaving) ...[
            const SizedBox(height: VocaboSpacing.md),
            Container(
              padding: const EdgeInsets.all(VocaboSpacing.sm),
              decoration: BoxDecoration(
                color: VocaboColors.primary50,
                borderRadius: VocaboRadius.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.spotlightSuggestSave(lookupCount),
                      style: VocaboTypography.bodySm.copyWith(
                        color: VocaboColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const VocaboKeyCap('⌘ Enter', color: VocaboColors.primary),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VocaboSpacing.lg,
        0,
        VocaboSpacing.lg,
        VocaboSpacing.md,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          context.l10n.spotlightEmptyHint,
          style: VocaboTypography.bodySm.copyWith(color: VocaboColors.neutral),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final SpotlightState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = state.selected;
    final hints = <(String, String)>[
      if (item != null && !item.isResolved)
        ('Enter', l10n.spotlightHintTranslate),
      if (item != null && item.isResolved) ('Enter', l10n.spotlightHintCopy),
      if (item != null && !item.isInLibrary)
        ('⌘ Enter', l10n.spotlightHintSave),
      if (item?.vocabulary?.contentHash != null)
        ('⌘ P', l10n.spotlightHintListen),
      if (item != null) ('⌘ O', l10n.spotlightHintOpen),
      ('Esc', l10n.commonClose),
    ];

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: VocaboSpacing.md),
      decoration: const BoxDecoration(
        color: VocaboColors.surfaceContainerLow,
        border: Border(top: BorderSide(color: VocaboColors.neutral200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              state.notice ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final (key, label) in hints) ...[
            const SizedBox(width: VocaboSpacing.md),
            VocaboKeyCap(key, color: VocaboColors.neutral600),
            const SizedBox(width: 4),
            Text(
              label,
              style: VocaboTypography.labelSm.copyWith(
                color: VocaboColors.neutral600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
