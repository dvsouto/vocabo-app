import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/auth/device_info.dart';
import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/user_profile_provider.dart';
import 'package:vocabo_desktop/src/widgets/account/native_language_field.dart';

/// Asks accounts created with Google or Apple to confirm the native
/// language, which was only guessed from the system.
Future<void> showNativeLanguagePrompt(BuildContext context, User user) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _NativeLanguagePrompt(user: user),
  );
}

class _NativeLanguagePrompt extends ConsumerStatefulWidget {
  const _NativeLanguagePrompt({required this.user});

  final User user;

  @override
  ConsumerState<_NativeLanguagePrompt> createState() =>
      _NativeLanguagePromptState();
}

class _NativeLanguagePromptState extends ConsumerState<_NativeLanguagePrompt> {
  late String _code =
      NativeLanguage.byCode(widget.user.nativeLanguage)?.code ??
      systemNativeLanguage();
  bool _saving = false;

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      if (_code != widget.user.nativeLanguage) {
        await ref
            .read(apiClientProvider)
            .user
            .updateProfile(nativeLanguage: _code);
        ref.invalidate(userProfileProvider);
      }
    } catch (e, st) {
      appLogger.handle(e, st, 'Native language confirmation failed');
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      backgroundColor: VocaboColors.surfaceContainerLowest,
      title: Text(l10n.authNativeLanguagePromptTitle),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.authNativeLanguagePromptBody,
              style: VocaboTypography.bodyMd.copyWith(
                color: VocaboColors.neutral600,
              ),
            ),
            const SizedBox(height: VocaboSpacing.lg),
            NativeLanguageField(
              value: _code,
              enabled: !_saving,
              onChanged: (code) => setState(() => _code = code),
            ),
          ],
        ),
      ),
      actions: [
        VocaboPrimaryButton(
          label: l10n.commonContinue,
          isLoading: _saving,
          onPressed: _saving ? null : _confirm,
        ),
      ],
    );
  }
}
