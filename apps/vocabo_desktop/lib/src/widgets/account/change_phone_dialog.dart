import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/auth/device_info.dart';
import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/user_profile_provider.dart';
import 'package:vocabo_desktop/src/widgets/account/code_verification_panel.dart';

/// Changes the phone number in two steps: the new number, then the code
/// sent to it. The profile only changes after the code is confirmed.
Future<bool?> showChangePhoneDialog(BuildContext context, {User? user}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _ChangePhoneDialog(user: user),
  );
}

class _ChangePhoneDialog extends ConsumerStatefulWidget {
  const _ChangePhoneDialog({this.user});

  final User? user;

  @override
  ConsumerState<_ChangePhoneDialog> createState() => _ChangePhoneDialogState();
}

class _ChangePhoneDialogState extends ConsumerState<_ChangePhoneDialog> {
  final _phoneController = TextEditingController();
  late PhoneCountry _country =
      phoneCountryByIso(widget.user?.phoneCountry) ??
      phoneCountryByIso(systemCountryCode()) ??
      phoneCountryByIso('US')!;
  String? _phoneError;

  /// Set once the number is valid; switches to the code step.
  String? _newPhone;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _continue() {
    final e164 = toE164(_country.isoCode, _phoneController.text);
    if (e164 == null) {
      setState(() => _phoneError = context.l10n.authInvalidPhone);
      return;
    }
    if (e164 == widget.user?.phoneNumber) {
      setState(() => _phoneError = context.l10n.authPhoneAlreadyYours);
      return;
    }
    setState(() => _newPhone = e164);
  }

  Future<void> _confirm(String code) async {
    await ref.read(apiClientProvider).user.confirmPhoneChange(code);
    ref.invalidate(userProfileProvider);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.read(apiClientProvider);
    final newPhone = _newPhone;
    final l10n = context.l10n;

    return AlertDialog(
      backgroundColor: VocaboColors.surfaceContainerLowest,
      title: Text(
        newPhone == null
            ? l10n.authChangePhoneTitle
            : l10n.authConfirmNewPhoneTitle,
      ),
      content: SizedBox(
        width: 400,
        child: newPhone == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.authChangePhoneIntro,
                    style: VocaboTypography.bodyMd.copyWith(
                      color: VocaboColors.neutral600,
                    ),
                  ),
                  const SizedBox(height: VocaboSpacing.md),
                  VocaboPhoneField(
                    country: _country,
                    hint: l10n.authPhoneNumberHint,
                    countryPickerTitle: l10n.authCountryPickerTitle,
                    countrySearchHint: l10n.authCountrySearchHint,
                    noCountryFoundText: l10n.authNoCountryFound,
                    controller: _phoneController,
                    autofocus: true,
                    errorText: _phoneError,
                    onCountryChanged: (country) => setState(() {
                      _country = country;
                      _phoneError = null;
                    }),
                    onChanged: (_) {
                      if (_phoneError != null) {
                        setState(() => _phoneError = null);
                      }
                    },
                    onSubmitted: (_) => _continue(),
                  ),
                ],
              )
            : CodeVerificationPanel(
                send: () => api.user.requestPhoneChange(
                  phoneCountry: _country.isoCode,
                  phoneNumber: newPhone,
                ),
                confirm: _confirm,
              ),
      ),
      actions: [
        VocaboTextButton(
          label: l10n.commonCancel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        if (newPhone == null)
          VocaboPrimaryButton(label: l10n.authSendCode, onPressed: _continue)
        else
          VocaboTextButton(
            label: l10n.authUseAnotherNumber,
            onPressed: () => setState(() => _newPhone = null),
          ),
      ],
    );
  }
}
