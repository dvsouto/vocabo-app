import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/providers/auth_providers.dart';
import 'package:vocabo_desktop/src/widgets/account/auth_scaffold.dart';
import 'package:vocabo_desktop/src/widgets/account/password_field.dart';

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
    setState(() {
      _error = switch (error) {
        AppException(code: 'incorrect_password') =>
          'The password is incorrect.',
        NetworkException() =>
          'No connection. Check your internet and try again.',
        _ => 'Could not delete the account. Please try again.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final deleting = ref.watch(deleteAccountProvider).isLoading;

    return AlertDialog(
      backgroundColor: VocaboColors.surfaceContainerLowest,
      title: const Text('Delete account'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This permanently deletes your account, your library, your '
              'flashcards and progress, your translation history and your '
              'photo. It cannot be undone.',
              style: VocaboTypography.bodyMd.copyWith(
                color: VocaboColors.neutral700,
              ),
            ),
            const SizedBox(height: VocaboSpacing.lg),
            if (_hasPassword) ...[
              const FieldLabel('Confirm with your password'),
              PasswordField(
                controller: _controller,
                hint: 'Password',
                autofocus: true,
                enabled: !deleting,
                errorText: _error,
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _delete(),
              ),
            ] else ...[
              const FieldLabel('Type $_confirmationWord to confirm'),
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
          label: 'Cancel',
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
              : const Text('Delete account'),
        ),
      ],
    );
  }
}
