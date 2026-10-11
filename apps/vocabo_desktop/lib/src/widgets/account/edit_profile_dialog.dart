import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/config/env.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/user_profile_provider.dart';
import 'package:vocabo_desktop/src/widgets/account/auth_scaffold.dart';
import 'package:vocabo_desktop/src/widgets/account/avatar_picker.dart';
import 'package:vocabo_desktop/src/widgets/account/change_phone_dialog.dart';
import 'package:vocabo_desktop/src/widgets/account/native_language_field.dart';

Future<void> showEditProfileDialog(BuildContext context, User user) {
  return showDialog<void>(
    context: context,
    builder: (_) => _EditProfileDialog(user: user),
  );
}

class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog({required this.user});

  final User user;

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  late final _nameController = TextEditingController(text: widget.user.name);
  late final _emailController = TextEditingController(text: widget.user.email);
  late final _ageController = TextEditingController(
    text: widget.user.age?.toString() ?? '',
  );
  late String _nativeLanguage =
      NativeLanguage.byCode(widget.user.nativeLanguage)?.code ?? 'en';
  Map<String, String> _errors = {};
  bool _saving = false;
  bool _savingPhoto = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _changePhoto() async {
    try {
      final png = await pickAvatarPng();
      if (png == null) return;
      setState(() => _savingPhoto = true);
      await ref.read(apiClientProvider).user.uploadAvatar(base64Encode(png));
      ref.invalidate(userProfileProvider);
    } catch (e, st) {
      appLogger.handle(e, st, 'Avatar update failed');
      _showMessage('Could not save this photo. Try a PNG or JPEG.');
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _savingPhoto = true);
    try {
      await ref.read(apiClientProvider).user.removeAvatar();
      ref.invalidate(userProfileProvider);
    } catch (e, st) {
      appLogger.handle(e, st, 'Avatar removal failed');
      _showMessage('Could not remove the photo. Please try again.');
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    final age = ageText.isEmpty ? null : int.tryParse(ageText);
    final errors = <String, String>{
      if (name.isEmpty) 'name': 'Enter your name.',
      if (ageText.isNotEmpty && (age == null || age < 5 || age > 120))
        'age': 'Enter an age between 5 and 120.',
    };
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(apiClientProvider)
          .user
          .updateProfile(name: name, age: age, nativeLanguage: _nativeLanguage);
      ref.invalidate(userProfileProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      appLogger.handle(e, st, 'Profile update failed');
      _showMessage(
        e is AppException ? e.message : 'Could not save. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider).valueOrNull ?? widget.user;

    return AlertDialog(
      backgroundColor: VocaboColors.surfaceContainerLowest,
      title: const Text('Edit profile'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  VocaboAvatar(
                    name: user.name,
                    imageUrl: Env.resolveUrl(user.avatarUrl),
                    radius: 28,
                  ),
                  const SizedBox(width: VocaboSpacing.md),
                  if (_savingPhoto)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    VocaboTextButton(
                      label: user.avatarUrl == null
                          ? 'Add photo'
                          : 'Change photo',
                      onPressed: _changePhoto,
                    ),
                    if (user.avatarUrl != null)
                      VocaboTextButton(
                        label: 'Remove',
                        onPressed: _removePhoto,
                      ),
                  ],
                ],
              ),
              const SizedBox(height: VocaboSpacing.lg),
              const FieldLabel('Name'),
              VocaboTextField(
                controller: _nameController,
                errorText: _errors['name'],
                autofocus: true,
              ),
              const SizedBox(height: VocaboSpacing.md),
              const FieldLabel('Email'),
              VocaboTextField(
                controller: _emailController,
                readOnly: true,
                enabled: false,
                suffix: const Tooltip(
                  message: 'The email of an account cannot be changed.',
                  child: Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: VocaboColors.neutral,
                  ),
                ),
              ),
              const SizedBox(height: VocaboSpacing.md),
              const FieldLabel('Phone'),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.hasPhone
                          ? formatPhoneInternational(
                              user.phoneNumber!,
                              isoHint: user.phoneCountry,
                            )
                          : 'No phone number',
                      style: VocaboTypography.bodyMd.copyWith(
                        color: user.hasPhone
                            ? VocaboColors.onSurface
                            : VocaboColors.neutral,
                      ),
                    ),
                  ),
                  VocaboTextButton(
                    label: user.hasPhone ? 'Change' : 'Add',
                    onPressed: () => showChangePhoneDialog(context, user: user),
                  ),
                ],
              ),
              const SizedBox(height: VocaboSpacing.md),
              const FieldLabel('Native language'),
              NativeLanguageField(
                value: _nativeLanguage,
                onChanged: (code) => setState(() => _nativeLanguage = code),
              ),
              const SizedBox(height: VocaboSpacing.md),
              const FieldLabel('Age', optional: true),
              SizedBox(
                width: 120,
                child: VocaboTextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  errorText: _errors['age'],
                  onSubmitted: (_) => _save(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        VocaboTextButton(
          label: 'Cancel',
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
