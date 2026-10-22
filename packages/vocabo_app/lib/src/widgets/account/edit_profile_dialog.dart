import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_app/vocabo_app.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';

Future<void> showEditProfileDialog(BuildContext context, User user) {
  return showVocaboModal<void>(
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
      NativeLanguage.byCode(widget.user.nativeLanguage)?.code ??
      defaultNativeLanguage;
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
      final png = await pickAvatarPng(ref.read(platformAdapterProvider));
      if (png == null) return;
      setState(() => _savingPhoto = true);
      await ref.read(apiClientProvider).user.uploadAvatar(base64Encode(png));
      ref.invalidate(userProfileProvider);
    } catch (e, st) {
      appLogger.handle(e, st, 'Avatar update failed');
      if (mounted) _showMessage(context.l10n.authPhotoSaveFailed);
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
      if (mounted) _showMessage(context.l10n.authPhotoRemoveFailed);
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final ageText = _ageController.text.trim();
    final age = ageText.isEmpty ? null : int.tryParse(ageText);
    final l10n = context.l10n;
    final errors = <String, String>{
      if (name.isEmpty) 'name': l10n.authEnterName,
      if (ageText.isNotEmpty && (age == null || age < 5 || age > 120))
        'age': l10n.authInvalidAge(5, 120),
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
      if (mounted) {
        _showMessage(e is AppException ? e.message : l10n.authSaveFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider).valueOrNull ?? widget.user;
    final l10n = context.l10n;

    return VocaboAlertDialog(
      backgroundColor: VocaboColors.surfaceContainerLowest,
      title: Text(l10n.authEditProfileTitle),
      content: SizedBox(
        width: context.dialogWidth(440),
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
                          ? l10n.authAddPhoto
                          : l10n.authChangePhoto,
                      onPressed: _changePhoto,
                    ),
                    if (user.avatarUrl != null)
                      VocaboTextButton(
                        label: l10n.commonRemove,
                        onPressed: _removePhoto,
                      ),
                  ],
                ],
              ),
              const SizedBox(height: VocaboSpacing.lg),
              FieldLabel(l10n.authFieldName),
              VocaboTextField(
                controller: _nameController,
                errorText: _errors['name'],
                autofocus: true,
              ),
              const SizedBox(height: VocaboSpacing.md),
              FieldLabel(l10n.authFieldEmail),
              VocaboTextField(
                controller: _emailController,
                readOnly: true,
                enabled: false,
                suffix: Tooltip(
                  message: l10n.authEmailCannotChange,
                  child: const Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: VocaboColors.neutral,
                  ),
                ),
              ),
              const SizedBox(height: VocaboSpacing.md),
              FieldLabel(l10n.authFieldPhone),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user.hasPhone
                          ? formatPhoneInternational(
                              user.phoneNumber!,
                              isoHint: user.phoneCountry,
                            )
                          : l10n.authNoPhoneNumber,
                      style: VocaboTypography.bodyMd.copyWith(
                        color: user.hasPhone
                            ? VocaboColors.onSurface
                            : VocaboColors.neutral,
                      ),
                    ),
                  ),
                  VocaboTextButton(
                    label: user.hasPhone
                        ? l10n.authChangePhone
                        : l10n.authAddPhone,
                    onPressed: () => showChangePhoneDialog(context, user: user),
                  ),
                ],
              ),
              const SizedBox(height: VocaboSpacing.md),
              FieldLabel(l10n.authFieldNativeLanguage),
              NativeLanguageField(
                value: _nativeLanguage,
                onChanged: (code) => setState(() => _nativeLanguage = code),
              ),
              const SizedBox(height: VocaboSpacing.md),
              FieldLabel(l10n.authFieldAge, optional: true),
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
          label: l10n.commonCancel,
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
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
