import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';

/// Password input with a show/hide toggle.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.hint,
    this.errorText,
    this.isNewPassword = false,
    this.enabled = true,
    this.autofocus = false,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;

  /// Defaults to the localized "Password".
  final String? hint;
  final String? errorText;

  /// Lets the system suggest a strong password instead of a saved one.
  final bool isNewPassword;
  final bool enabled;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return VocaboTextField(
      controller: widget.controller,
      hint: widget.hint ?? context.l10n.authFieldPassword,
      obscureText: !_visible,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      errorText: widget.errorText,
      autofillHints: [
        widget.isNewPassword
            ? AutofillHints.newPassword
            : AutofillHints.password,
      ],
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffix: IconButton(
        tooltip: _visible
            ? context.l10n.authHidePassword
            : context.l10n.authShowPassword,
        icon: Icon(
          _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 18,
        ),
        color: VocaboColors.neutral,
        onPressed: () => setState(() => _visible = !_visible),
      ),
    );
  }
}
