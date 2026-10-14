import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';

/// Two steps: ask for the email, then the emailed code and a new password.
/// A successful reset signs the user in.
class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key, this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<PasswordResetScreen> createState() =>
      _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  late final _emailController = TextEditingController(
    text: widget.initialEmail ?? '',
  );
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  VerificationDispatch? _dispatch;
  bool _sending = false;
  String? _emailError;
  String? _codeError;
  String? _passwordError;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startCountdown(Duration duration) {
    _timer?.cancel();
    setState(() => _resendIn = duration.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _resendIn--);
      if (_resendIn <= 0) timer.cancel();
    });
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (!isValidEmail(email)) {
      setState(() => _emailError = context.l10n.authInvalidEmail);
      return;
    }

    setState(() {
      _sending = true;
      _emailError = null;
      _codeError = null;
    });
    try {
      final dispatch = await ref
          .read(apiClientProvider)
          .auth
          .requestPasswordReset(email);
      if (!mounted) return;
      _codeController.clear();
      setState(() => _dispatch = dispatch);
      _startCountdown(dispatch.retryAfter);
    } on TooManyRequestsException catch (e) {
      if (!mounted) return;
      _startCountdown(e.retryAfter ?? const Duration(seconds: 30));
    } catch (e) {
      if (!mounted) return;
      final message = verificationErrorMessage(context.l10n, e);
      setState(() {
        if (_dispatch == null) {
          _emailError = message;
        } else {
          _codeError = message;
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _reset() async {
    final code = _codeController.text;
    final password = _passwordController.text;
    final l10n = context.l10n;
    setState(() {
      _codeError = code.length == 6 ? null : l10n.authEnterSixDigitCode;
      _passwordError = isValidPassword(password)
          ? null
          : l10n.authPasswordRulesNotMet;
    });
    if (_codeError != null || _passwordError != null) return;

    await ref
        .read(passwordResetProvider.notifier)
        .reset(
          email: _emailController.text.trim(),
          code: code,
          password: password,
        );
    if (!mounted) return;

    final error = ref.read(passwordResetProvider).error;
    if (error == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() => _codeError = verificationErrorMessage(context.l10n, error));
  }

  @override
  Widget build(BuildContext context) {
    final dispatch = _dispatch;
    final l10n = context.l10n;

    return AuthScaffold(
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.authResetPasswordTitle, style: VocaboTypography.headlineSm),
          const SizedBox(height: VocaboSpacing.sm),
          Text(
            dispatch == null
                ? l10n.authResetPasswordIntro
                : l10n.authResetPasswordCodeIntro(dispatch.sentTo),
            style: VocaboTypography.bodyMd.copyWith(
              color: VocaboColors.neutral600,
            ),
          ),
          const SizedBox(height: VocaboSpacing.xl),
          if (dispatch == null) ..._emailStep() else ..._resetStep(dispatch),
        ],
      ),
    );
  }

  List<Widget> _emailStep() => [
    FieldLabel(context.l10n.authFieldEmail),
    VocaboTextField(
      controller: _emailController,
      hint: 'you@example.com',
      autofocus: true,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      errorText: _emailError,
      onChanged: (_) {
        if (_emailError != null) setState(() => _emailError = null);
      },
      onSubmitted: (_) => _sendCode(),
    ),
    const SizedBox(height: VocaboSpacing.lg),
    VocaboPrimaryButton(
      label: context.l10n.authSendCode,
      isExpanded: true,
      isLoading: _sending,
      onPressed: _sending ? null : _sendCode,
    ),
  ];

  List<Widget> _resetStep(VerificationDispatch dispatch) {
    final isLoading = ref.watch(passwordResetProvider).isLoading;
    final minutes = _resendIn ~/ 60;
    final seconds = (_resendIn % 60).toString().padLeft(2, '0');
    final l10n = context.l10n;

    return [
      FieldLabel(l10n.authFieldCode),
      VocaboCodeInput(
        controller: _codeController,
        enabled: !isLoading,
        errorText: _codeError,
        onChanged: (_) {
          if (_codeError != null) setState(() => _codeError = null);
        },
      ),
      if (dispatch.debugCode case final debugCode?) ...[
        const SizedBox(height: VocaboSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(VocaboSpacing.sm + 4),
          decoration: BoxDecoration(
            color: VocaboColors.primary50,
            borderRadius: VocaboRadius.sm,
          ),
          child: Text(
            l10n.authSimulatedEmailDelivery(debugCode),
            style: VocaboTypography.bodySm.copyWith(
              color: VocaboColors.primary800,
            ),
          ),
        ),
      ],
      const SizedBox(height: VocaboSpacing.sm),
      _resendIn > 0
          ? Text(
              l10n.authResendCodeIn('$minutes:$seconds'),
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
              ),
            )
          : VocaboTextButton(
              label: l10n.authResendCode,
              onPressed: _sending ? null : _sendCode,
            ),
      const SizedBox(height: VocaboSpacing.lg),
      FieldLabel(l10n.authFieldNewPassword),
      PasswordField(
        controller: _passwordController,
        hint: l10n.passwordRuleLength(minPasswordLength),
        isNewPassword: true,
        enabled: !isLoading,
        errorText: _passwordError,
        onChanged: (_) => setState(() => _passwordError = null),
        onSubmitted: (_) => _reset(),
      ),
      const SizedBox(height: VocaboSpacing.sm),
      PasswordRequirements(password: _passwordController.text),
      const SizedBox(height: VocaboSpacing.xl),
      VocaboPrimaryButton(
        label: l10n.authResetPasswordAndSignIn,
        isExpanded: true,
        isLoading: isLoading,
        onPressed: isLoading ? null : _reset,
      ),
    ];
  }
}
