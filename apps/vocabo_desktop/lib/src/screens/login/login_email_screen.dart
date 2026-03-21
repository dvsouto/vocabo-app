import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/screens/login/login_password_screen.dart';

class LoginEmailScreen extends StatefulWidget {
  const LoginEmailScreen({super.key});

  @override
  State<LoginEmailScreen> createState() => _LoginEmailScreenState();
}

class _LoginEmailScreenState extends State<LoginEmailScreen> {
  final _emailController = TextEditingController();
  String _selectedLanguage = 'PT-BR';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginPasswordScreen(email: email),
      ),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Em breve'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.brown.shade200.withValues(alpha: 0.4),
                  Colors.blueGrey.shade100.withValues(alpha: 0.3),
                  VocaboColors.surfaceContainerLow,
                ],
              ),
            ),
          ),

          // Centered login card
          Center(
            child: SingleChildScrollView(
              child: GlassCard(
                width: 440,
                padding: const EdgeInsets.symmetric(
                  horizontal: VocaboSpacing.xl,
                  vertical: VocaboSpacing.xxl,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: VocaboColors.primary,
                        borderRadius: VocaboRadius.md,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: VocaboColors.onPrimary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: VocaboSpacing.md),

                    // Title
                    Text('Vocabo', style: VocaboTypography.headlineSm),
                    const SizedBox(height: VocaboSpacing.sm),

                    // Subtitle
                    Text(
                      'Refine your vocabulary in the digital\nworkshop of a polymath.',
                      style: VocaboTypography.bodySm.copyWith(
                        color: VocaboColors.neutral,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: VocaboSpacing.xl),

                    // Native language
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'NATIVE LANGUAGE',
                        style: VocaboTypography.labelSm,
                      ),
                    ),
                    const SizedBox(height: VocaboSpacing.sm),
                    VocaboLanguageChipGroup(
                      options: const ['PT-BR', 'ES'],
                      selected: _selectedLanguage,
                      onSelected: (lang) =>
                          setState(() => _selectedLanguage = lang),
                    ),
                    const SizedBox(height: VocaboSpacing.lg),

                    // Email
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'WORK EMAIL',
                        style: VocaboTypography.labelSm,
                      ),
                    ),
                    const SizedBox(height: VocaboSpacing.sm),
                    VocaboTextField(
                      controller: _emailController,
                      hint: 'alex@atelier.io',
                      keyboardType: TextInputType.emailAddress,
                      onSubmitted: (_) => _onContinue(),
                    ),
                    const SizedBox(height: VocaboSpacing.lg),

                    // Primary CTA
                    SizedBox(
                      width: double.infinity,
                      child: VocaboPrimaryButton(
                        label: 'Continue to Library',
                        isExpanded: true,
                        trailing: const Icon(
                          Icons.arrow_forward,
                          color: VocaboColors.onPrimary,
                          size: 18,
                        ),
                        onPressed: _onContinue,
                      ),
                    ),
                    const SizedBox(height: VocaboSpacing.lg),

                    // Divider
                    Text(
                      'OR AUTHENTICATE VIA',
                      style: VocaboTypography.labelSm.copyWith(
                        color: VocaboColors.neutral,
                      ),
                    ),
                    const SizedBox(height: VocaboSpacing.md),

                    // Social auth
                    Row(
                      children: [
                        Expanded(
                          child: VocaboSocialAuthButton(
                            label: 'Google',
                            icon: const Icon(Icons.g_mobiledata, size: 20),
                            onPressed: _showComingSoon,
                          ),
                        ),
                        const SizedBox(width: VocaboSpacing.sm),
                        Expanded(
                          child: VocaboSocialAuthButton(
                            label: 'GitHub',
                            icon: const Icon(Icons.code, size: 18),
                            onPressed: _showComingSoon,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VocaboSpacing.lg),

                    // Bottom links
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        VocaboTextButton(
                          label: 'Forgot Secret?',
                          uppercase: true,
                          onPressed: () {},
                        ),
                        VocaboTextButton(
                          label: 'Create Account',
                          uppercase: true,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: VocaboSpacing.md),

                    // Footer
                    Text(
                      'END-TO-END ENCRYPTED  \u00b7  ICLOUD SYNC READY',
                      style: VocaboTypography.labelSm.copyWith(
                        color: VocaboColors.neutral,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

