import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/user_profile_provider.dart';
import 'package:vocabo_desktop/src/widgets/account/auth_scaffold.dart';
import 'package:vocabo_desktop/src/widgets/account/password_field.dart';
import 'package:vocabo_desktop/src/widgets/account/password_requirements.dart';

/// Changes the password, or sets a first one for accounts created with
/// Google or Apple. Returns true when saved.
Future<bool?> showChangePasswordDialog(BuildContext context, User user) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _ChangePasswordDialog(user: user),
  );
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog({required this.user});

  final User user;

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  String? _currentError;
  String? _newError;
  bool _saving = false;

  bool get _hasPassword => widget.user.hasPassword;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final current = _currentController.text;
    final next = _newController.text;
    setState(() {
      _currentError = _hasPassword && current.isEmpty
          ? 'Enter your current password.'
          : null;
      _newError = isValidPassword(next)
          ? null
          : 'The password does not meet the rules below.';
    });
    if (_currentError != null || _newError != null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(apiClientProvider)
          .user
          .changePassword(
            currentPassword: _hasPassword ? current : null,
            newPassword: next,
          );
      ref.invalidate(userProfileProvider);
      ref.invalidate(userSessionsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (e case AppException(code: 'incorrect_password')) {
          _currentError = 'The current password is incorrect.';
        } else {
          _newError = e is AppException
              ? e.message
              : 'Could not change the password. Please try again.';
        }
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: VocaboColors.surfaceContainerLowest,
      title: Text(_hasPassword ? 'Change password' : 'Set a password'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _hasPassword
                  ? 'Your other devices will be signed out.'
                  : 'Sign in with your email and this password, besides '
                        'Google or Apple.',
              style: VocaboTypography.bodyMd.copyWith(
                color: VocaboColors.neutral600,
              ),
            ),
            const SizedBox(height: VocaboSpacing.lg),
            if (_hasPassword) ...[
              const FieldLabel('Current password'),
              PasswordField(
                controller: _currentController,
                hint: 'Current password',
                autofocus: true,
                enabled: !_saving,
                errorText: _currentError,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _currentError = null),
              ),
              const SizedBox(height: VocaboSpacing.md),
            ],
            const FieldLabel('New password'),
            PasswordField(
              controller: _newController,
              hint: 'At least 6 characters',
              isNewPassword: true,
              autofocus: !_hasPassword,
              enabled: !_saving,
              errorText: _newError,
              onChanged: (_) => setState(() => _newError = null),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: VocaboSpacing.sm),
            PasswordRequirements(password: _newController.text),
          ],
        ),
      ),
      actions: [
        VocaboTextButton(
          label: 'Cancel',
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
        VocaboPrimaryButton(
          label: 'Save',
          isLoading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
