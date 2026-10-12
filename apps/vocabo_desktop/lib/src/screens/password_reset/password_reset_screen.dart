import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/auth_providers.dart';
import 'package:vocabo_desktop/src/widgets/account/auth_scaffold.dart';
import 'package:vocabo_desktop/src/widgets/account/code_verification_panel.dart';
import 'package:vocabo_desktop/src/widgets/account/password_field.dart';
import 'package:vocabo_desktop/src/widgets/account/password_requirements.dart';

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
      setState(() => _emailError = 'Enter a valid email address.');
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
      final message = verificationErrorMessage(e);
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
    setState(() {
      _codeError = code.length == 6 ? null : 'Enter the 6-digit code.';
      _passwordError = isValidPassword(password)
          ? null
          : 'The password does not meet the rules below.';
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
    setState(() => _codeError = verificationErrorMessage(error));
  }

  @override
  Widget build(BuildContext context) {
    final dispatch = _dispatch;

    return AuthScaffold(
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Reset your password', style: VocaboTypography.headlineSm),
          const SizedBox(height: VocaboSpacing.sm),
          Text(
            dispatch == null
                ? 'Enter the email of your account and we will send you a '
                      'code to choose a new password.'
                : 'Enter the 6-digit code sent to ${dispatch.sentTo} and '
                      'choose a new password.',
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
    const FieldLabel('Email'),
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
      label: 'Send code',
      isExpanded: true,
      isLoading: _sending,
      onPressed: _sending ? null : _sendCode,
    ),
  ];

  List<Widget> _resetStep(VerificationDispatch dispatch) {
    final isLoading = ref.watch(passwordResetProvider).isLoading;
    final minutes = _resendIn ~/ 60;
    final seconds = (_resendIn % 60).toString().padLeft(2, '0');

    return [
      const FieldLabel('Code'),
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
            'Delivery is simulated while email is not set up. '
            'Your code is $debugCode.',
            style: VocaboTypography.bodySm.copyWith(
              color: VocaboColors.primary800,
            ),
          ),
        ),
      ],
      const SizedBox(height: VocaboSpacing.sm),
      _resendIn > 0
          ? Text(
              'Resend code in $minutes:$seconds',
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
              ),
            )
          : VocaboTextButton(
              label: 'Resend code',
              onPressed: _sending ? null : _sendCode,
            ),
      const SizedBox(height: VocaboSpacing.lg),
      const FieldLabel('New password'),
      PasswordField(
        controller: _passwordController,
        hint: 'At least 6 characters',
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
        label: 'Reset password and sign in',
        isExpanded: true,
        isLoading: isLoading,
        onPressed: isLoading ? null : _reset,
      ),
    ];
  }
}
