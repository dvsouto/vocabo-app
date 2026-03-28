import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/providers/add_word_providers.dart';
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
  }

  @override
  void dispose() {
    _termController.dispose();
    _meaningController.dispose();
    _translationController.dispose();
    _exampleController.dispose();
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

    final fieldsEnabled = !wordState.autoDetect;

    if (wordState.autoDetect && !wordState.isSearching) {
      _syncControllersFromState(wordState);
    }

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 560,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: VocaboColors.surface,
            borderRadius: VocaboRadius.lg,
            boxShadow: [VocaboShadows.whisper],
          ),
          child: SingleChildScrollView(
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

                  _buildTermInput(notifier),
                  const SizedBox(height: VocaboSpacing.md),

                  _buildFieldsSection(wordState, notifier, fieldsEnabled),
                  const SizedBox(height: VocaboSpacing.md),

                  _buildAutoDetectToggle(wordState, notifier),
                  const SizedBox(height: VocaboSpacing.lg),

                  _buildActions(wordState, notifier),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.add_circle,
          color: VocaboColors.primary,
          size: 22,
        ),
        const SizedBox(width: 8),
        Text('Vocabo', style: VocaboTypography.titleLg),
        const Spacer(),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: IconButton(
            icon: const Icon(Icons.history, size: 20),
            color: VocaboColors.neutral,
            onPressed: () {},
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: IconButton(
            icon: const Icon(Icons.close, size: 20),
            color: VocaboColors.neutral,
            onPressed: _close,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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

  Widget _buildTermInput(AddWordNotifier notifier) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _termController,
            onChanged: notifier.setTerm,
            style: VocaboTypography.headlineSm.copyWith(
              color: VocaboColors.primary.withValues(alpha: 0.5),
            ),
            decoration: InputDecoration(
              hintText: 'Enter word or phrase...',
              hintStyle: VocaboTypography.headlineSm.copyWith(
                color: VocaboColors.primary.withValues(alpha: 0.3),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: IconButton(
            icon: Icon(
              Icons.volume_up,
              color: VocaboColors.primary,
              size: 24,
            ),
            onPressed: () {},
          ),
        ),
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
                        enabled: fieldsEnabled,
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
              enabled: fieldsEnabled,
            ),
            if (state.isSearching)
              Positioned.fill(
                child: _buildFieldLoader(),
              ),
          ],
        ),
        const SizedBox(height: VocaboSpacing.md),

        // Example sentence
        Text(
          'EXAMPLE SENTENCE',
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
              enabled: fieldsEnabled,
              onChanged: notifier.setExampleSentence,
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

  Widget _buildActions(AddWordState state, AddWordNotifier notifier) {
    return Row(
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
                    color: VocaboColors.onPrimary,
                  ),
                )
              : const Icon(
                  Icons.arrow_forward,
                  color: VocaboColors.onPrimary,
                  size: 18,
                ),
          onPressed: state.canSave
              ? () async {
                  final success = await notifier.save();
                  if (success && mounted) {
                    _close();
                  }
                }
              : null,
        ),
      ],
    );
  }
}
