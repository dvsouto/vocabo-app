import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

String verificationErrorMessage(Object error) => switch (error) {
  AppException(code: 'invalid_code') =>
    'That code is not right. Check it and try again.',
  AppException(code: 'expired_code') =>
    'This code has expired. Send a new one.',
  AppException(code: 'phone_missing') => 'Add a phone number first.',
  NetworkException() => 'No connection. Check your internet and try again.',
  AppException(:final message) => message,
  _ => 'Something went wrong. Please try again.',
};

/// Sends a 6-digit code and confirms it, with a resend countdown. Shared by
/// the account confirmation screen and the phone change dialog.
class CodeVerificationPanel extends StatefulWidget {
  const CodeVerificationPanel({
    super.key,
    required this.send,
    required this.confirm,
    this.autoSend = true,
  });

  final Future<VerificationDispatch> Function() send;

  /// Throws when the code is rejected.
  final Future<void> Function(String code) confirm;
  final bool autoSend;

  @override
  State<CodeVerificationPanel> createState() => _CodeVerificationPanelState();
}

class _CodeVerificationPanelState extends State<CodeVerificationPanel> {
  final _codeController = TextEditingController();
  VerificationDispatch? _dispatch;
  bool _sending = false;
  bool _confirming = false;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoSend) _send();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
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

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final dispatch = await widget.send();
      if (!mounted) return;
      _codeController.clear();
      setState(() => _dispatch = dispatch);
      _startCountdown(dispatch.retryAfter);
    } on TooManyRequestsException catch (e) {
      if (!mounted) return;
      _startCountdown(e.retryAfter ?? const Duration(seconds: 30));
    } catch (e) {
      if (mounted) setState(() => _error = verificationErrorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirm(String code) async {
    setState(() {
      _confirming = true;
      _error = null;
    });
    try {
      await widget.confirm(code);
    } catch (e) {
      if (!mounted) return;
      _codeController.clear();
      setState(() => _error = verificationErrorMessage(e));
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dispatch = _dispatch;
    final minutes = _resendIn ~/ 60;
    final seconds = (_resendIn % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dispatch == null
              ? (_sending ? 'Sending your code…' : 'We will send you a code.')
              : 'Enter the 6-digit code sent to ${dispatch.sentTo}.',
          style: VocaboTypography.bodyMd.copyWith(
            color: VocaboColors.neutral600,
          ),
        ),
        const SizedBox(height: VocaboSpacing.lg),
        VocaboCodeInput(
          controller: _codeController,
          enabled: !_confirming,
          errorText: _error,
          onCompleted: _confirm,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
        if (dispatch?.debugCode case final debugCode?) ...[
          const SizedBox(height: VocaboSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(VocaboSpacing.sm + 4),
            decoration: BoxDecoration(
              color: VocaboColors.primary50,
              borderRadius: VocaboRadius.sm,
            ),
            child: Text(
              'Delivery is simulated while SMS and email are not set up. '
              'Your code is $debugCode.',
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.primary800,
              ),
            ),
          ),
        ],
        const SizedBox(height: VocaboSpacing.md),
        Row(
          children: [
            if (_confirming || _sending)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (_resendIn > 0)
              Text(
                'Resend code in $minutes:$seconds',
                style: VocaboTypography.bodySm.copyWith(
                  color: VocaboColors.neutral,
                ),
              )
            else
              VocaboTextButton(
                label: dispatch == null ? 'Send code' : 'Resend code',
                onPressed: _send,
              ),
          ],
        ),
      ],
    );
  }
}
