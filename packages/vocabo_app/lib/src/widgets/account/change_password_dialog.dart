import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';

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
    final l10n = context.l10n;
    setState(() {
      _currentError = _hasPassword && current.isEmpty
          ? l10n.authEnterCurrentPassword
          : null;
      _newError = isValidPassword(next) ? null : l10n.authPasswordRulesNotMet;
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
          _currentError = l10n.authCurrentPasswordIncorrect;
        } else {
          _newError = e is AppException
              ? e.message
              : l10n.authChangePasswordFailed;
        }
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      backgroundColor: VocaboColors.surfaceContainerLowest,
      title: Text(
        _hasPassword ? l10n.authChangePasswordTitle : l10n.authSetPasswordTitle,
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _hasPassword
                  ? l10n.authChangePasswordNotice
                  : l10n.authSetPasswordNotice,
              style: VocaboTypography.bodyMd.copyWith(
                color: VocaboColors.neutral600,
              ),
            ),
            const SizedBox(height: VocaboSpacing.lg),
            if (_hasPassword) ...[
              FieldLabel(l10n.authFieldCurrentPassword),
              PasswordField(
                controller: _currentController,
                hint: l10n.authFieldCurrentPassword,
                autofocus: true,
                enabled: !_saving,
                errorText: _currentError,
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() => _currentError = null),
              ),
              const SizedBox(height: VocaboSpacing.md),
            ],
            FieldLabel(l10n.authFieldNewPassword),
            PasswordField(
              controller: _newController,
              hint: l10n.passwordRuleLength(minPasswordLength),
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
          label: l10n.commonCancel,
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
        VocaboPrimaryButton(
          label: l10n.commonSave,
          isLoading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
