import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/legal/legal_documents.dart';
import 'package:vocabo_desktop/src/widgets/legal/legal_document_dialog.dart';

/// "By creating an account you agree to…" with links to both documents.
class LegalConsentText extends StatefulWidget {
  const LegalConsentText({super.key, required this.action});

  /// What the user is doing, e.g. "creating an account".
  final String action;

  @override
  State<LegalConsentText> createState() => _LegalConsentTextState();
}

class _LegalConsentTextState extends State<LegalConsentText> {
  late final _terms = TapGestureRecognizer()
    ..onTap = () => showLegalDocument(context, termsOfService);
  late final _privacy = TapGestureRecognizer()
    ..onTap = () => showLegalDocument(context, privacyPolicy);

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = VocaboTypography.bodySm.copyWith(color: VocaboColors.neutral);
    final link = base.copyWith(
      color: VocaboColors.primary,
      fontWeight: FontWeight.w600,
    );

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: 'By ${widget.action} you agree to the '),
          TextSpan(
            text: 'Terms of Service',
            style: link,
            recognizer: _terms,
            mouseCursor: SystemMouseCursors.click,
          ),
          const TextSpan(text: ' and the '),
          TextSpan(
            text: 'Privacy Policy',
            style: link,
            recognizer: _privacy,
            mouseCursor: SystemMouseCursors.click,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
