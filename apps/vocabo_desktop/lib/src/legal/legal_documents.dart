/// A titled block of paragraphs in a legal or help document.
class LegalSection {
  const LegalSection(this.heading, this.paragraphs);

  final String heading;
  final List<String> paragraphs;
}

class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.updatedOn,
    required this.sections,
    this.intro,
  });

  final String title;
  final String updatedOn;
  final String? intro;
  final List<LegalSection> sections;
}

const companyName = 'Bitnary Digital';
const supportEmail = 'contact@bitnarydigital.com';
const _updatedOn = 'October 11, 2026';

const privacyPolicy = LegalDocument(
  title: 'Privacy Policy',
  updatedOn: _updatedOn,
  intro:
      'Vocabo is an English vocabulary app operated by $companyName ("we", '
      '"us"). This policy explains what personal data we collect, why we '
      'collect it, who processes it on our behalf and the rights you have. '
      'We are the controller of your personal data under the Brazilian '
      'General Data Protection Law (LGPD) and, where it applies, the EU '
      'General Data Protection Regulation (GDPR).',
  sections: [
    LegalSection('1. Data we collect', [
      'Account data: your name, email address and password. Passwords are '
          'stored only as a secure one-way hash. Optionally, your phone '
          'number, age, profile photo and native language.',
      'Learning data: the words in your library, words you create yourself, '
          'your flashcard reviews, answers and progress, the words you look '
          'up in the translation spotlight and your app preferences, such as '
          'reminder times.',
      'Device and security data: the name and operating system of each '
          'signed-in device, the app version, IP address, user agent and the '
          'time each session was last used.',
      'Sign in with Google or Apple: your name, email address and an account '
          'identifier provided by Google or Apple. We never receive your '
          'Google or Apple password.',
      'We do not use advertising identifiers, we do not track you across '
          'other apps or websites and we do not collect payment card data.',
    ]),
    LegalSection('2. How and why we use it', [
      'To provide the service (performance of a contract): create and secure '
          'your account, keep your library and progress in sync between '
          'devices, schedule your flashcards and generate translations, '
          'definitions and pronunciation for new words.',
      'To protect your account (legitimate interest): verify your email or '
          'phone, send sign-in and password reset codes, limit the number of '
          'signed-in devices and detect abuse.',
      'To comply with legal obligations, such as keeping records required by '
          'law.',
      'We do not sell your personal data and we do not use it for '
          'advertising.',
    ]),
    LegalSection('3. Service providers', [
      'OpenAI generates translations, definitions, examples and pronunciation '
          'audio. Only the word being looked up and the target language are '
          'sent; your name, email and other account details are not.',
      'Twilio delivers verification codes by SMS and receives only the phone '
          'number and the message. An email provider delivers verification '
          'and password reset emails and receives only your email address and '
          'the message.',
      'Google and Apple process your sign in when you choose those options, '
          'under their own privacy policies.',
      'Hetzner hosts our servers and databases in the European Union.',
      'Translations made with the menu bar or the spotlight may use Apple '
          'Translation, which runs on your Mac.',
    ]),
    LegalSection('4. International transfers', [
      'Some providers, such as OpenAI and Twilio, process data in the United '
          'States. These transfers rely on the safeguards allowed by the LGPD '
          'and the GDPR, such as standard contractual clauses.',
    ]),
    LegalSection('5. How long we keep it', [
      'We keep your data while your account exists. When you delete your '
          'account, your profile, library, flashcards, progress, translation '
          'history and photo are deleted immediately from our systems. Backups '
          'are overwritten within 30 days. Security logs are kept for up to '
          '6 months.',
    ]),
    LegalSection('6. Security', [
      'Data travels over encrypted connections. Your sign-in token is stored '
          'in the macOS Keychain. Access to our servers is restricted to the '
          'people who operate the service.',
    ]),
    LegalSection('7. Your rights', [
      'You can confirm whether we process your data, access it, correct it, '
          'request a copy in a portable format, ask us to delete it, withdraw '
          'consent and object to processing based on legitimate interest.',
      'You can edit your profile, sign out devices and delete your account '
          'yourself in Settings. For anything else, write to $supportEmail. '
          'We answer within 15 days.',
      'You can also file a complaint with the Brazilian data protection '
          'authority (ANPD) or with the authority of your country.',
    ]),
    LegalSection('8. Children', [
      'Vocabo is not directed to children under 13 and we do not knowingly '
          'collect their data. If you believe a child has created an account, '
          'contact us and we will delete it.',
    ]),
    LegalSection('9. Changes to this policy', [
      'We will update this page and the date above when this policy changes. '
          'Significant changes will be announced in the app before they take '
          'effect.',
    ]),
    LegalSection('10. Contact', [
      '$companyName, $supportEmail. This address is also the contact of our '
          'data protection officer.',
    ]),
  ],
);

const termsOfService = LegalDocument(
  title: 'Terms of Service',
  updatedOn: _updatedOn,
  intro:
      'These terms govern your use of Vocabo, an app operated by '
      '$companyName. By creating an account or using the app you agree to '
      'them. If you do not agree, please do not use Vocabo.',
  sections: [
    LegalSection('1. Eligibility', [
      'You must be at least 13 years old to use Vocabo. If you are under 18, '
          'you need the permission of a parent or legal guardian.',
    ]),
    LegalSection('2. Your account', [
      'Provide accurate information and keep your password safe. You are '
          'responsible for the activity on your account. Tell us right away '
          'at $supportEmail if you suspect unauthorized use.',
      'An account may be signed in on up to three devices at the same time. '
          'Signing in on another device signs out the oldest one.',
    ]),
    LegalSection('3. License', [
      'We grant you a personal, non-exclusive, non-transferable and revocable '
          'license to use Vocabo for your own language learning. The app, its '
          'design, content and brand belong to $companyName.',
    ]),
    LegalSection('4. Acceptable use', [
      'Do not use Vocabo to break the law, to infringe the rights of others or '
          'to send abusive content. Do not try to access the service other '
          'than through the app, reverse engineer it, overload it, scrape it, '
          'or bypass its limits and security measures.',
    ]),
    LegalSection('5. Your content', [
      'Words, translations and examples you create remain yours. You give us '
          'the permission needed to store and display them to you so the '
          'service works.',
    ]),
    LegalSection('6. Generated content', [
      'Translations, definitions, examples and audio are generated '
          'automatically, partly with artificial intelligence, and may contain '
          'mistakes. They are a learning aid and are not professional '
          'translation or advice.',
    ]),
    LegalSection('7. Plans and payments', [
      'Vocabo offers a free plan. Paid plans, when available, will show their '
          'price, billing period and features before you subscribe. '
          'Subscriptions bought through the App Store are billed and renewed '
          'by Apple under its terms, and can be cancelled in your Apple '
          'account settings at least 24 hours before renewal.',
      'We may change the features of the free plan. Changes to a paid plan '
          'you already have take effect only at the next billing period, after '
          'notice.',
    ]),
    LegalSection('8. Availability and changes', [
      'We work to keep Vocabo available but cannot guarantee it will always '
          'be uninterrupted or error free. We may change, suspend or '
          'discontinue features, and will give reasonable notice of '
          'significant changes when possible.',
    ]),
    LegalSection('9. Ending your account', [
      'You can delete your account at any time in Settings > Account '
          'security. We may suspend or close accounts that violate these '
          'terms, after notice when the law requires it.',
    ]),
    LegalSection('10. Disclaimer and liability', [
      'To the extent permitted by law, Vocabo is provided "as is", and '
          '$companyName is not liable for indirect, incidental or '
          'consequential damages, or for loss of data or profits arising from '
          'the use of the app. Nothing in these terms limits rights that '
          'cannot be waived under consumer protection law.',
    ]),
    LegalSection('11. Privacy', [
      'How we handle your personal data is described in the Privacy Policy, '
          'which is part of these terms.',
    ]),
    LegalSection('12. Changes to these terms', [
      'We may update these terms. The date above shows the latest version, '
          'and significant changes will be announced in the app. Continuing to '
          'use Vocabo after a change means you accept the new terms.',
    ]),
    LegalSection('13. Governing law', [
      'These terms are governed by the laws of Brazil. Consumers may also '
          'rely on the mandatory protections of the country where they live '
          'and bring claims in their local courts.',
    ]),
    LegalSection('14. Contact', ['$companyName, $supportEmail.']),
  ],
);
