import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/providers/translation_providers.dart';

class TrayTranslateTab extends ConsumerStatefulWidget {
  const TrayTranslateTab({super.key});

  @override
  ConsumerState<TrayTranslateTab> createState() => _TrayTranslateTabState();
}

class _TrayTranslateTabState extends ConsumerState<TrayTranslateTab> {
  static const _channel = MethodChannel('vocabo/tray_panel_actions');

  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _onSwapLanguages() {
    final translationState = ref.read(translationNotifierProvider);
    ref.read(translationDirectionProvider.notifier).swapLanguages();
    ref.read(translationNotifierProvider.notifier).onLanguagesSwapped(
          oldInputText: translationState.inputText,
          oldTranslatedText: translationState.translatedText,
        );
    _inputController.text =
        translationState.translatedText ?? '';
  }

  void _onSaveToVocabulary() {
    final state = ref.read(translationNotifierProvider);
    _channel.invokeMethod('openAddWord', {'term': state.inputText});
  }

  void _onOpenTranslationSettings() {
    final service = ref.read(translationServiceProvider);
    service.openTranslationSettings();
  }

  @override
  Widget build(BuildContext context) {
    final availabilityAsync = ref.watch(translationAvailabilityProvider);
    final directionAsync = ref.watch(translationDirectionProvider);
    final translationState = ref.watch(translationNotifierProvider);

    return availabilityAsync.when(
      data: (isAvailable) {
        if (!isAvailable) {
          return _buildSetupRequired();
        }
        return directionAsync.when(
          data: (direction) => _buildContent(direction, translationState),
          loading: () => const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => _buildContent(
            const TranslationDirection(),
            translationState,
          ),
        );
      },
      loading: () => const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => _buildSetupRequired(),
    );
  }

  Widget _buildSetupRequired() {
    return Center(
      child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: VocaboColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.translate,
            size: 28,
            color: VocaboColors.primary,
          ),
        ),
        const SizedBox(height: VocaboSpacing.md),
        Text(
          'Translation Setup Required',
          style: VocaboTypography.bodyMd.copyWith(
            fontWeight: FontWeight.w600,
            color: VocaboColors.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: VocaboSpacing.xs),
        Text(
          'Download translation languages in\nSystem Settings to enable offline translation.',
          style: VocaboTypography.bodySm.copyWith(
            color: VocaboColors.neutral,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: VocaboSpacing.lg),
        VocaboPrimaryButton(
          label: 'Open Settings',
          trailing: const Icon(
            Icons.open_in_new,
            size: 16,
            color: VocaboColors.onPrimary,
          ),
          onPressed: _onOpenTranslationSettings,
        ),
      ],
    ),
    );
  }

  Widget _buildContent(
    TranslationDirection direction,
    TranslationState translationState,
  ) {
    return Column(
      children: [
        // Source language section
        Container(
          decoration: BoxDecoration(
            color: VocaboColors.surfaceContainerLow,
            borderRadius: VocaboRadius.sm,
            border: Border.all(
              color: VocaboColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VocaboSpacing.md,
                  VocaboSpacing.sm,
                  VocaboSpacing.xs,
                  0,
                ),
                child: Row(
                  children: [
                    Text(
                      direction.sourceLanguage.toUpperCase(),
                      style: VocaboTypography.labelSm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: VocaboColors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    _SwapButton(onPressed: _onSwapLanguages),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VocaboSpacing.md,
                  VocaboSpacing.xs,
                  VocaboSpacing.md,
                  VocaboSpacing.sm,
                ),
                child: TextField(
                  controller: _inputController,
                  autofocus: false,
                  maxLines: 3,
                  minLines: 2,
                  style: VocaboTypography.bodyMd,
                  decoration: InputDecoration(
                    hintText: 'Enter text to translate...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(0),
                      borderSide: const BorderSide(
                        color: Colors.transparent,
                      ),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: VocaboSpacing.md,
                      horizontal: VocaboSpacing.sm,
                    ),
                    filled: true,
                    fillColor: VocaboColors.surfaceContainerLow,
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.transparent,
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.transparent,
                      ),
                    ),
                    hoverColor: Colors.transparent,
                    focusColor: Colors.transparent,
                  ),
                  onChanged: (value) {
                    ref
                        .read(translationNotifierProvider.notifier)
                        .setInputText(value);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: VocaboSpacing.sm),

        // Target language section
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: VocaboColors.surfaceContainerLow,
              borderRadius: VocaboRadius.sm,
              border: Border.all(
                color: VocaboColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    VocaboSpacing.md,
                    VocaboSpacing.sm,
                    VocaboSpacing.xs,
                    0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        direction.targetLanguage.toUpperCase(),
                        style: VocaboTypography.labelSm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: VocaboColors.primary,
                        ),
                      ),
                      const Spacer(),
                      // Audio button placeholder - disabled until API provides audio
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: null,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: VocaboColors.surfaceContainerHigh
                                  .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.volume_up,
                              size: 14,
                              color: VocaboColors.primary
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: VocaboSpacing.xs),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VocaboSpacing.md,
                      VocaboSpacing.xs,
                      VocaboSpacing.md,
                      VocaboSpacing.sm,
                    ),
                    child: _buildTranslationResult(translationState),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: VocaboSpacing.md),

        // Save to Vocabulary button
        VocaboPrimaryButton(
          label: 'Save to Vocabulary',
          isExpanded: true,
          onPressed:
              translationState.hasTranslation ? _onSaveToVocabulary : null,
        ),
      ],
    );
  }

  Widget _buildTranslationResult(TranslationState state) {
    if (state.isTranslating) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: VocaboColors.primary,
          ),
        ),
      );
    }

    if (state.errorMessage != null) {
      return Text(
        state.errorMessage!,
        style: VocaboTypography.bodySm.copyWith(
          color: Colors.red,
        ),
      );
    }

    if (state.hasTranslation) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            state.translatedText!,
            style: VocaboTypography.bodyMd.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          if (state.pronunciation != null) ...[
            const SizedBox(height: 2),
            Text(
              state.pronunciation!,
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      );
    }

    if (state.inputText.isEmpty) {
      return Text(
        'Translation will appear here',
        style: VocaboTypography.bodySm.copyWith(
          color: VocaboColors.neutral,
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _SwapButton extends StatelessWidget {
  const _SwapButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        mouseCursor: SystemMouseCursors.click,
        customBorder: const CircleBorder(),
        child: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: VocaboColors.surfaceContainerHigh,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.swap_vert,
            size: 16,
            color: VocaboColors.primary,
          ),
        ),
      ),
    );
  }
}
