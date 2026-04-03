import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/providers/add_word_providers.dart';
import 'package:vocabo_desktop/src/providers/audio_player_providers.dart';
import 'package:vocabo_desktop/src/providers/search_providers.dart';
import 'package:vocabo_desktop/src/services/audio_player_service.dart';
import 'package:vocabo_desktop/src/widgets/add_word_modal/part_of_speech_selector.dart';

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
        ref.read(addWordNotifierProvider.notifier).initFromTerm(
              widget.initialTerm!,
            );
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

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 680,
          decoration: BoxDecoration(
            color: VocaboColors.surface,
            borderRadius: VocaboRadius.lg,
            boxShadow: [VocaboShadows.whisper],
          ),
          child: Padding(
            padding: const EdgeInsets.all(VocaboSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  _buildHeader(),
                  const SizedBox(height: VocaboSpacing.md),

                  _buildLanguageRow(wordState),
                  const SizedBox(height: VocaboSpacing.md),

                  _buildTermInput(wordState, notifier),
                  const SizedBox(height: VocaboSpacing.md),

                  _buildFieldsSection(wordState, notifier, fieldsEnabled),
                  const SizedBox(height: VocaboSpacing.md),

                  _buildAutoDetectToggle(wordState, notifier),
                  const SizedBox(height: VocaboSpacing.lg),

                  _buildActions(wordState, notifier, isAlreadyInVocabulary),
                ],
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text('Add New Word', style: VocaboTypography.titleLg),
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
              'LEARNING LANGUAGE',
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
              'ENTRY TYPE',
              style: VocaboTypography.labelSm.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vocabulary Card',
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
            buildCounter: (_, {required currentLength, required isFocused, required maxLength}) => null,
            style: VocaboTypography.headlineSm.copyWith(
              color: VocaboColors.primary,
            ),
            decoration: InputDecoration(
              labelText: 'Enter word or phrase...',
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

  Widget _buildPlayButton(bool canPlay, String contentHash, AddWordState wordState) {
    final audioState = ref.watch(audioPlayerStateProvider);
    final isThisPlaying = contentHash.isNotEmpty &&
        audioState.currentPlayingHash == contentHash;
    final isLoading = isThisPlaying &&
        audioState.status == AudioPlayerStatus.loading;
    final isPlaying = isThisPlaying &&
        audioState.status == AudioPlayerStatus.playing;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canPlay
            ? () {
                final player = ref.read(audioPlayerServiceProvider);
                if (isThisPlaying && (isLoading || isPlaying)) {
                  player.stop();
                } else {
                  player.play(
                    vocabularyId: wordState.backendResult!.id,
                    type: 'system',
                    contentHash: contentHash,
                  );
                }
              }
            : null,
        mouseCursor: canPlay
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: canPlay
                ? VocaboColors.primary
                : VocaboColors.primary.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: VocaboColors.onPrimary,
                  ),
                )
              : Icon(
                  isPlaying ? Icons.stop : Icons.volume_up,
                  color: VocaboColors.onPrimary,
                  size: 20,
                ),
        ),
      ),
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
        // Meaning + Part of Speech row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MEANING',
                    style: VocaboTypography.labelSm.copyWith(
                      color: VocaboColors.neutral,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Stack(
                    children: [
                      VocaboTextArea(
                        controller: _meaningController,
                        hint: 'What does this mean?',
                        readOnly: !fieldsEnabled,
                        onChanged: notifier.setMeaning,
                      ),
                      if (state.isSearching)
                        Positioned.fill(
                          child: _buildFieldLoader(),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: VocaboSpacing.md),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PART OF SPEECH',
                    style: VocaboTypography.labelSm.copyWith(
                      color: VocaboColors.neutral,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PartOfSpeechSelector(
                    selected: state.wordType,
                    enabled: fieldsEnabled,
                    onSelected: notifier.setWordType,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: VocaboSpacing.md),

        // Translation
        Text(
          'TRANSLATION',
          style: VocaboTypography.labelSm.copyWith(
            color: VocaboColors.neutral,
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            VocaboTextField(
              controller: _translationController,
              hint: 'Translation in your language...',
              readOnly: !fieldsEnabled,
            ),
            if (state.isSearching)
              Positioned.fill(
                child: _buildFieldLoader(),
              ),
          ],
        ),
        const SizedBox(height: VocaboSpacing.md),

        // Example sentences
        Text(
          'EXAMPLE SENTENCES',
          style: VocaboTypography.labelSm.copyWith(
            color: VocaboColors.neutral,
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            VocaboTextArea(
              controller: _exampleController,
              hint: 'Use it in a sentence to provide context...',
              readOnly: !fieldsEnabled,
              onChanged: notifier.setExampleSentence,
              minLines: 3,
              maxLines: 3,
            ),
            if (state.isSearching)
              Positioned.fill(
                child: _buildFieldLoader(),
              ),
          ],
        ),

        // Error message
        if (state.errorMessage != null) ...[
          const SizedBox(height: VocaboSpacing.sm),
          Text(
            state.errorMessage!,
            style: VocaboTypography.bodySm.copyWith(
              color: Colors.red,
            ),
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
      label: 'Auto-detect Language',
    );
  }

  Widget _buildActions(
    AddWordState state,
    AddWordNotifier notifier,
    bool isAlreadyInVocabulary,
  ) {
    final canSave = state.canSave && !isAlreadyInVocabulary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isAlreadyInVocabulary && state.term.trim().isNotEmpty) ...[
          Text(
            'This word is already in your vocabulary',
            style: VocaboTypography.bodySm.copyWith(
              color: VocaboColors.neutral600,
            ),
          ),
          const SizedBox(height: VocaboSpacing.sm),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            VocaboTextButton(
              label: 'Cancel',
              onPressed: _close,
            ),
            const SizedBox(width: VocaboSpacing.sm),
            VocaboPrimaryButton(
              label: state.isSaving ? 'Saving...' : 'Save to Library',
              trailing: state.isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_forward,
                      size: 18,
                    ),
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
