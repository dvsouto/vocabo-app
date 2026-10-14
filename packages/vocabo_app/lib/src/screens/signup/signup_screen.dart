import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  late final _emailController = TextEditingController(
    text: widget.initialEmail,
  );
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();

  late PhoneCountry _phoneCountry =
      phoneCountryByIso(systemCountryCode()) ?? phoneCountryByIso('US')!;
  late String _nativeLanguage = systemNativeLanguage();
  Uint8List? _avatar;
  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    Future.microtask(() => ref.invalidate(signUpProvider));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _clearError(String field) {
    if (_errors.containsKey(field)) {
      setState(() => _errors = Map.of(_errors)..remove(field));
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final png = await pickAvatarPng(ref.read(platformAdapterProvider));
      if (png != null) setState(() => _avatar = png);
    } catch (e, st) {
      appLogger.handle(e, st, 'Avatar pick failed');
      if (mounted) _showMessage(context.l10n.authAvatarReadFailed);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Map<String, String> _validate() {
    final l10n = context.l10n;
    final errors = <String, String>{};
    if (_nameController.text.trim().isEmpty) {
      errors['name'] = l10n.authEnterName;
    }
    if (!isValidEmail(_emailController.text.trim())) {
      errors['email'] = l10n.authInvalidEmail;
    }
    if (!isValidPassword(_passwordController.text)) {
      errors['password'] = l10n.authPasswordRulesNotMet;
    }
    final phone = _phoneController.text.trim();
    if (phone.isNotEmpty && !isValidPhone(_phoneCountry.isoCode, phone)) {
      errors['phone_number'] = l10n.authInvalidPhone;
    }
    final age = _ageController.text.trim();
    if (age.isNotEmpty) {
      final value = int.tryParse(age);
      if (value == null || value < 5 || value > 120) {
        errors['age'] = l10n.authInvalidAge(5, 120);
      }
    }
    return errors;
  }

  Future<void> _submit() async {
    final errors = _validate();
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return;

    final phone = _phoneController.text.trim();
    final age = _ageController.text.trim();

    await ref
        .read(signUpProvider.notifier)
        .signUp(
          SignUpRequest(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            nativeLanguage: _nativeLanguage,
            interfaceLanguage: ref.read(interfaceLanguageProvider).valueOrNull,
            age: age.isEmpty ? null : int.parse(age),
            phoneCountry: phone.isEmpty ? null : _phoneCountry.isoCode,
            phoneNumber: phone.isEmpty
                ? null
                : toE164(_phoneCountry.isoCode, phone),
          ),
          avatarPng: _avatar,
        );

    if (!mounted) return;
    final state = ref.read(signUpProvider);
    if (!state.hasError) {
      // The auth status now routes to the confirmation screen.
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final l10n = context.l10n;
    switch (state.error) {
      case AppException(code: 'email_taken'):
        setState(() => _errors = {'email': l10n.authEmailTakenSignIn});
      case AppException(:final details) when details.isNotEmpty:
        setState(
          () => _errors = {
            for (final entry in details.entries) entry.key: entry.value.first,
          },
        );
      case NetworkException():
        _showMessage(l10n.commonNoConnection);
      case AppException(:final message):
        _showMessage(message);
      default:
        _showMessage(l10n.authSignUpFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(signUpProvider).isLoading;
    final name = _nameController.text;
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final l10n = context.l10n;

    return AuthScaffold(
      width: wide ? 640 : 480,
      onBack: () => Navigator.of(context).pop(),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.authSignUpTitle, style: VocaboTypography.headlineSm),
            const SizedBox(height: VocaboSpacing.xs),
            Text(
              l10n.authSignUpSubtitle,
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
            const SizedBox(height: VocaboSpacing.xl),

            Row(
              children: [
                VocaboAvatar(
                  name: name,
                  image: _avatar == null ? null : MemoryImage(_avatar!),
                  radius: 28,
                ),
                const SizedBox(width: VocaboSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FieldLabel(l10n.authFieldPhoto, optional: true),
                      Wrap(
                        spacing: VocaboSpacing.sm,
                        children: [
                          VocaboTextButton(
                            label: _avatar == null
                                ? l10n.authChoosePhoto
                                : l10n.authChangePhoto,
                            onPressed: isLoading ? null : _pickAvatar,
                          ),
                          if (_avatar != null)
                            VocaboTextButton(
                              label: l10n.commonRemove,
                              onPressed: isLoading
                                  ? null
                                  : () => setState(() => _avatar = null),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: VocaboSpacing.md),

            _pair(
              wide,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FieldLabel(l10n.authFieldName),
                  VocaboTextField(
                    controller: _nameController,
                    hint: l10n.authNameHint,
                    autofocus: true,
                    autofillHints: const [AutofillHints.name],
                    errorText: _errors['name'],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      _clearError('name');
                      setState(() {});
                    },
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FieldLabel(l10n.authFieldEmail),
                  VocaboTextField(
                    controller: _emailController,
                    hint: 'alex@atelier.io',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    errorText: _errors['email'],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => _clearError('email'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VocaboSpacing.md),

            _pair(
              wide,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FieldLabel(l10n.authFieldPassword),
                  PasswordField(
                    controller: _passwordController,
                    hint: l10n.passwordRuleLength(minPasswordLength),
                    isNewPassword: true,
                    errorText: _errors['password'],
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      _clearError('password');
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: VocaboSpacing.sm),
                  PasswordRequirements(password: _passwordController.text),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FieldLabel(l10n.authFieldNativeLanguage),
                  NativeLanguageField(
                    value: _nativeLanguage,
                    enabled: !isLoading,
                    onChanged: (code) => setState(() => _nativeLanguage = code),
                  ),
                  const SizedBox(height: VocaboSpacing.xs),
                  Text(
                    l10n.authNativeLanguageSuggested,
                    style: VocaboTypography.bodySm.copyWith(
                      color: VocaboColors.neutral,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VocaboSpacing.md),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FieldLabel(l10n.authFieldPhone, optional: true),
                      VocaboPhoneField(
                        country: _phoneCountry,
                        hint: l10n.authPhoneNumberHint,
                        countryPickerTitle: l10n.authCountryPickerTitle,
                        countrySearchHint: l10n.authCountrySearchHint,
                        noCountryFoundText: l10n.authNoCountryFound,
                        controller: _phoneController,
                        errorText: _errors['phone_number'],
                        enabled: !isLoading,
                        onCountryChanged: (country) {
                          _clearError('phone_number');
                          setState(() => _phoneCountry = country);
                        },
                        onChanged: (_) => _clearError('phone_number'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: VocaboSpacing.md),
                SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FieldLabel(l10n.authFieldAge, optional: true),
                      VocaboTextField(
                        controller: _ageController,
                        hint: '30',
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        errorText: _errors['age'],
                        onChanged: (_) => _clearError('age'),
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: VocaboSpacing.xl),

            const LegalConsentText(action: LegalConsentAction.creatingAccount),
            const SizedBox(height: VocaboSpacing.md),
            VocaboPrimaryButton(
              label: l10n.authCreateAccount,
              isExpanded: true,
              isLoading: isLoading,
              onPressed: isLoading ? null : _submit,
            ),
            const SizedBox(height: VocaboSpacing.md),
            Center(
              child: VocaboTextButton(
                label: l10n.authHaveAccount,
                onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Two fields side by side on wide windows, stacked otherwise.
  Widget _pair(bool wide, Widget first, Widget second) {
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          first,
          const SizedBox(height: VocaboSpacing.md),
          second,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: VocaboSpacing.md),
        Expanded(child: second),
      ],
    );
  }
}
