import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_app/vocabo_app.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';

/// What the user is doing when agreeing to the documents.
enum LegalConsentAction { continuing, creatingAccount }

const _termsMarker = '\u{E000}';
const _privacyMarker = '\u{E001}';

/// "By creating an account you agree to…" with links to both documents.
class LegalConsentText extends StatefulWidget {
  const LegalConsentText({super.key, required this.action});

  final LegalConsentAction action;

  @override
  State<LegalConsentText> createState() => _LegalConsentTextState();
}

class _LegalConsentTextState extends State<LegalConsentText> {
  late final _terms = TapGestureRecognizer()
    ..onTap = () => showLegalDocument(
      context,
      termsOfServiceFor(Localizations.localeOf(context)),
    );
  late final _privacy = TapGestureRecognizer()
    ..onTap = () => showLegalDocument(
      context,
      privacyPolicyFor(Localizations.localeOf(context)),
    );

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

    final l10n = context.l10n;
    // The sentence is translated as a whole; the markers mark where the
    // links go so each language can place them where it needs.
    final sentence = switch (widget.action) {
      LegalConsentAction.continuing => l10n.authLegalConsentContinuing(
        _termsMarker,
        _privacyMarker,
      ),
      LegalConsentAction.creatingAccount =>
        l10n.authLegalConsentCreatingAccount(_termsMarker, _privacyMarker),
    };

    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in RegExp(
      '$_termsMarker|$_privacyMarker',
    ).allMatches(sentence)) {
      if (match.start > start) {
        spans.add(TextSpan(text: sentence.substring(start, match.start)));
      }
      final isTerms = match[0] == _termsMarker;
      spans.add(
        TextSpan(
          text: isTerms ? l10n.authTermsOfService : l10n.authPrivacyPolicy,
          style: link,
          recognizer: isTerms ? _terms : _privacy,
          mouseCursor: SystemMouseCursors.click,
        ),
      );
      start = match.end;
    }
    if (start < sentence.length) {
      spans.add(TextSpan(text: sentence.substring(start)));
    }

    return Text.rich(
      TextSpan(style: base, children: spans),
      textAlign: TextAlign.center,
    );
  }
}
