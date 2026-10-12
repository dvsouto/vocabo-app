import 'dart:ui';

import 'package:vocabo_desktop/src/legal/legal_documents.dart';
import 'package:vocabo_desktop/src/legal/legal_documents_pt.dart';

/// Legal texts are available in English and Portuguese; other interface
/// languages show the English version.
LegalDocument termsOfServiceFor(Locale locale) =>
    locale.languageCode == 'pt' ? termsOfServicePt : termsOfService;

LegalDocument privacyPolicyFor(Locale locale) =>
    locale.languageCode == 'pt' ? privacyPolicyPt : privacyPolicy;
