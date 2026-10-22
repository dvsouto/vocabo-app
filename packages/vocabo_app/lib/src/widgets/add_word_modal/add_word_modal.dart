import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';

class AddWordModal extends ConsumerStatefulWidget {
  const AddWordModal({super.key, this.initialTerm});

  final String? initialTerm;

  @override
  ConsumerState<AddWordModal> createState() => _AddWordModalState();
}

class _AddWordModalState extends ConsumerState<AddWordModal> {
  final _termController = TextEditingController();
  final _meaningController = TextEditingController();
  final _translationController = TextEditingController();
  final _exampleController = TextEditingController();
  final _termFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    if (widget.initialTerm != null && widget.initialTerm!.isNotEmpty) {
      _termController.text = widget.initialTerm!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(addWordNotifierProvider.notifier)
            .initFromTerm(widget.initialTerm!);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _termFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _termController.dispose();
    _meaningController.dispose();
    _translationController.dispose();
    _exampleController.dispose();
    _termFocusNode.dispose();
    super.dispose();
  }

  void _close() {
    ref.read(addWordNotifierProvider.notifier).reset();
    ref.read(showAddWordModalProvider.notifier).state = false;
  }

  void _syncControllersFromState(AddWordState state) {
    if (_meaningController.text != (state.meaning ?? '')) {
      _meaningController.text = state.meaning ?? '';
    }
    if (_translationController.text != (state.translation ?? '')) {
      _translationController.text = state.translation ?? '';
    }
    if (_exampleController.text != (state.exampleSentence ?? '')) {
      _exampleController.text = state.exampleSentence ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordState = ref.watch(addWordNotifierProvider);
    final notifier = ref.read(addWordNotifierProvider.notifier);
    final isAlreadyInVocabulary = ref.watch(
      isTermInVocabularyProvider(wordState.term.trim()),
    );

    final fieldsEnabled = !wordState.autoDetect;

    if (wordState.autoDetect && !wordState.isSearching) {
      _syncControllersFromState(wordState);
    }

    final inSheet = VocaboSheetScope.of(context);
    const side = EdgeInsets.symmetric(horizontal: VocaboSpacing.lg);

    return VocaboModalSurface(
      width: 680,
      maxHeight: MediaQuery.of(context).size.height - VocaboSpacing.xl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              VocaboSpacing.lg,
              inSheet ? 0 : VocaboSpacing.lg,
              VocaboSpacing.lg,
              VocaboSpacing.md,
            ),
            child: _buildHeader(),
          ),

          // Only the form scrolls when the window is short; the header
          // and the actions stay in view.
          Flexible(
            child: SingleChildScrollView(
              padding: side,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLanguageRow(wordState),
                  const SizedBox(height: VocaboSpacing.md),

                  _buildTermInput(wordState, notifier),
                  const SizedBox(height: VocaboSpacing.md),

                  _buildFieldsSection(wordState, notifier, fieldsEnabled),
                  const SizedBox(height: VocaboSpacing.md),

                  _buildAutoDetectToggle(wordState, notifier),
                  const SizedBox(height: VocaboSpacing.md),
                ],
              ),
            ),
          ),
          Padding(
            padding: inSheet
                ? EdgeInsets.zero
                : const EdgeInsets.fromLTRB(
                    VocaboSpacing.lg,
                    VocaboSpacing.sm,
                    VocaboSpacing.lg,
                    VocaboSpacing.lg,
                  ),
            child: _buildActions(wordState, notifier, isAlreadyInVocabulary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(context.l10n.addWordTitle, style: VocaboTypography.titleLg),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          color: VocaboColors.neutral,
          onPressed: _close,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          style: const ButtonStyle(
            mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.click),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageRow(AddWordState state) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.addWordLearningLanguage,
              style: VocaboTypography.labelSm.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.language,
              style: VocaboTypography.bodyMd.copyWith(
                color: VocaboColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              context.l10n.addWordEntryType,
              style: VocaboTypography.labelSm.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.addWordEntryTypeVocabularyCard,
              style: VocaboTypography.bodyMd,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTermInput(AddWordState state, AddWordNotifier notifier) {
    final showPlayButton = state.autoDetect;
    final canPlay = state.isValid && state.backendResult != null;
    final contentHash = state.backendResult?.contentHash ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: TextField(
            controller: _termController,
            focusNode: _termFocusNode,
            onChanged: notifier.setTerm,
            maxLength: 255,
            buildCounter:
                (
                  _, {
                  required currentLength,
                  required isFocused,
                  required maxLength,
                }) => null,
            style: VocaboTypography.headlineSm.copyWith(
              color: VocaboColors.primary,
            ),
            decoration: InputDecoration(
              labelText: context.l10n.addWordTermHint,
              labelStyle: VocaboTypography.headlineSm.copyWith(
                color: VocaboColors.primary.withValues(alpha: 0.3),
              ),
              floatingLabelStyle: VocaboTypography.labelSm.copyWith(
                color: VocaboColors.neutral,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.never,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              // Remove the background color
              filled: false,
              fillColor: Colors.transparent,
            ),
          ),
        ),
        if (showPlayButton) _buildPlayButton(canPlay, contentHash, state),
      ],
    );
  }

  Widget _buildPlayButton(
    bool canPlay,
    String contentHash,
    AddWordState wordState,
  ) {
    return PronunciationButton(
      vocabularyId: canPlay ? wordState.backendResult!.id : null,
      type: 'system',
      contentHash: contentHash,
      size: 44,
      iconSize: 20,
    );
  }

  Widget _buildMeaningAndPartOfSpeech(
    AddWordState state,
    AddWordNotifier notifier,
    bool fieldsEnabled,
  ) {
    final meaning = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.addWordMeaningLabel,
          style: VocaboTypography.labelSm.copyWith(color: VocaboColors.neutral),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            VocaboTextArea(
              controller: _meaningController,
              hint: context.l10n.addWordMeaningHint,
              readOnly: !fieldsEnabled,
              onChanged: notifier.setMeaning,
            ),
            if (state.isSearching) Positioned.fill(child: _buildFieldLoader()),
          ],
        ),
      ],
    );
    final partOfSpeech = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.addWordPartOfSpeechLabel,
          style: VocaboTypography.labelSm.copyWith(color: VocaboColors.neutral),
        ),
        const SizedBox(height: 4),
        PartOfSpeechSelector(
          selected: state.wordType,
          enabled: fieldsEnabled,
          onSelected: notifier.setWordType,
        ),
      ],
    );

    if (context.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          meaning,
          const SizedBox(height: VocaboSpacing.md),
          partOfSpeech,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: meaning),
        const SizedBox(width: VocaboSpacing.md),
        Expanded(flex: 2, child: partOfSpeech),
      ],
    );
  }

  Widget _buildFieldsSection(
    AddWordState state,
    AddWordNotifier notifier,
    bool fieldsEnabled,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meaning + part of speech: side by side, stacked on phones
        _buildMeaningAndPartOfSpeech(state, notifier, fieldsEnabled),
        const SizedBox(height: VocaboSpacing.md),

        // Translation
        Text(
          context.l10n.addWordTranslationLabel,
          style: VocaboTypography.labelSm.copyWith(color: VocaboColors.neutral),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            VocaboTextField(
              controller: _translationController,
              hint: context.l10n.addWordTranslationHint,
              readOnly: !fieldsEnabled,
            ),
            if (state.isSearching) Positioned.fill(child: _buildFieldLoader()),
          ],
        ),
        const SizedBox(height: VocaboSpacing.md),

        // Example sentences
        Text(
          context.l10n.addWordExamplesLabel,
          style: VocaboTypography.labelSm.copyWith(color: VocaboColors.neutral),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            VocaboTextArea(
              controller: _exampleController,
              hint: context.l10n.addWordExamplesHint,
              readOnly: !fieldsEnabled,
              onChanged: notifier.setExampleSentence,
              minLines: 3,
              maxLines: 3,
            ),
            if (state.isSearching) Positioned.fill(child: _buildFieldLoader()),
          ],
        ),

        // Error message
        if (state.errorMessage != null) ...[
          const SizedBox(height: VocaboSpacing.sm),
          Text(
            state.errorMessage!,
            style: VocaboTypography.bodySm.copyWith(color: Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildFieldLoader() {
    return Container(
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerHigh.withValues(alpha: 0.7),
        borderRadius: VocaboRadius.sm,
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: VocaboColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAutoDetectToggle(AddWordState state, AddWordNotifier notifier) {
    return VocaboToggleSwitch(
      value: state.autoDetect,
      onChanged: notifier.toggleAutoDetect,
      label: context.l10n.addWordAutoDetect,
    );
  }

  Widget _buildActions(
    AddWordState state,
    AddWordNotifier notifier,
    bool isAlreadyInVocabulary,
  ) {
    final canSave = state.canSave && !isAlreadyInVocabulary;
    final inSheet = VocaboSheetScope.of(context);

    return Column(
      crossAxisAlignment: inSheet
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.end,
      children: [
        if (isAlreadyInVocabulary && state.term.trim().isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: inSheet ? VocaboSpacing.lg : 0,
            ),
            child: Text(
              context.l10n.addWordAlreadyInVocabulary,
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral600,
              ),
            ),
          ),
          const SizedBox(height: VocaboSpacing.sm),
        ],
        VocaboModalActions(
          leading: VocaboTextButton(
            label: context.l10n.commonCancel,
            onPressed: _close,
          ),
          actions: [
            VocaboPrimaryButton(
              label: state.isSaving
                  ? context.l10n.addWordSaving
                  : context.l10n.addWordSaveToLibrary,
              trailing: state.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward, size: 18),
              onPressed: canSave
                  ? () async {
                      final success = await notifier.save();
                      if (success && mounted) {
                        _close();
                      }
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }
}
