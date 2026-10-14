import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';

const _confirmationWord = 'DELETE';

/// Permanently deletes the account. Password accounts confirm with the
/// password; Google and Apple accounts type a confirmation word.
Future<void> showDeleteAccountDialog(BuildContext context, User user) {
  return showDialog<void>(
    context: context,
    builder: (_) => _DeleteAccountDialog(user: user),
  );
}

class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog({required this.user});

  final User user;

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  String? _error;

  bool get _hasPassword => widget.user.hasPassword;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSubmit => _hasPassword
      ? _controller.text.isNotEmpty
      : _controller.text.trim().toUpperCase() == _confirmationWord;

  Future<void> _delete() async {
    if (!_canSubmit) return;

    await ref
        .read(deleteAccountProvider.notifier)
        .delete(password: _hasPassword ? _controller.text : null);
    if (!mounted) return;

    final error = ref.read(deleteAccountProvider).error;
    if (error == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    final l10n = context.l10n;
    setState(() {
      _error = switch (error) {
        AppException(code: 'incorrect_password') => l10n.authPasswordIncorrect,
        NetworkException() => l10n.commonNoConnection,
        _ => l10n.authDeleteAccountFailed,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final deleting = ref.watch(deleteAccountProvider).isLoading;
    final l10n = context.l10n;

    return AlertDialog(
      backgroundColor: VocaboColors.surfaceContainerLowest,
      title: Text(l10n.authDeleteAccountTitle),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.authDeleteAccountWarning,
              style: VocaboTypography.bodyMd.copyWith(
                color: VocaboColors.neutral700,
              ),
            ),
            const SizedBox(height: VocaboSpacing.lg),
            if (_hasPassword) ...[
              FieldLabel(l10n.authConfirmWithPassword),
              PasswordField(
                controller: _controller,
                hint: l10n.authFieldPassword,
                autofocus: true,
                enabled: !deleting,
                errorText: _error,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _delete(),
              ),
            ] else ...[
              FieldLabel(l10n.authTypeWordToConfirm(_confirmationWord)),
              VocaboTextField(
                controller: _controller,
                hint: _confirmationWord,
                autofocus: true,
                enabled: !deleting,
                errorText: _error,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _delete(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        VocaboTextButton(
          label: l10n.commonCancel,
          onPressed: deleting ? null : () => Navigator.of(context).pop(),
        ),
        FilledButton(
          onPressed: deleting || !_canSubmit ? null : _delete,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: VocaboColors.onPrimary,
          ),
          child: deleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: VocaboColors.onPrimary,
                  ),
                )
              : Text(l10n.authDeleteAccountTitle),
        ),
      ],
    );
  }
}
