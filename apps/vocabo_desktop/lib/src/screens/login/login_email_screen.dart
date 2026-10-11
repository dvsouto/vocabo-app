import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_api/vocabo_api.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/auth/social_sign_in.dart';
import 'package:vocabo_desktop/src/providers/auth_providers.dart';
import 'package:vocabo_desktop/src/screens/login/login_password_screen.dart';
import 'package:vocabo_desktop/src/screens/signup/signup_screen.dart';

class LoginEmailScreen extends ConsumerStatefulWidget {
  const LoginEmailScreen({super.key});

  @override
  ConsumerState<LoginEmailScreen> createState() => _LoginEmailScreenState();
}

class _LoginEmailScreenState extends ConsumerState<LoginEmailScreen> {
  SocialAuthProvider? _pendingProvider;

  final _emailController = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onContinue() {
    final email = _emailController.text.trim();
    if (!isValidEmail(email)) {
      setState(() => _emailError = 'Enter a valid email address.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginPasswordScreen(email: email),
      ),
    );
  }

  void _openSignUp() {
    final email = _emailController.text.trim();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SignUpScreen(initialEmail: isValidEmail(email) ? email : null),
      ),
    );
  }

  Future<void> _signInWith(SocialSignIn provider) async {
    setState(() => _pendingProvider = provider.provider);
    await ref.read(socialLoginProvider.notifier).signIn(provider);
    if (!mounted) return;
    setState(() => _pendingProvider = null);

    final error = ref.read(socialLoginProvider).error;
    if (error == null) return;
    final message = switch (error) {
      SocialSignInException(:final message) => message,
      AppException(code: 'provider_not_configured') =>
        'Sign in with ${provider.label} is not set up on the server yet.',
      AppException(code: 'email_taken') =>
        'This email already has an account. Sign in with your password.',
      NetworkException() => 'No connection. Check your internet and try again.',
      AppException(:final message) => message,
      _ => 'Could not sign in with ${provider.label}. Please try again.',
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

                    // Email
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('EMAIL', style: VocaboTypography.labelSm),
                    ),
                    const SizedBox(height: VocaboSpacing.sm),
                    VocaboTextField(
                      controller: _emailController,
                      hint: 'alex@atelier.io',
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      onChanged: (_) {
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
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
                            icon: _socialIcon(
                              SocialAuthProvider.google,
                              const Icon(Icons.g_mobiledata, size: 20),
                            ),
                            onPressed: _pendingProvider != null
                                ? null
                                : () => _signInWith(
                                    ref.read(googleSignInProvider),
                                  ),
                          ),
                        ),
                        const SizedBox(width: VocaboSpacing.sm),
                        Expanded(
                          child: VocaboSocialAuthButton(
                            label: 'Apple',
                            icon: _socialIcon(
                              SocialAuthProvider.apple,
                              const Icon(Icons.apple, size: 18),
                            ),
                            onPressed: _pendingProvider != null
                                ? null
                                : () => _signInWith(
                                    ref.read(appleSignInProvider),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VocaboSpacing.lg),

                    // Bottom links
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: VocaboSpacing.sm,
                      children: [
                        VocaboTextButton(
                          label: 'Forgot Secret?',
                          uppercase: true,
                          onPressed: () {},
                        ),
                        VocaboTextButton(
                          label: 'Create Account',
                          uppercase: true,
                          onPressed: _openSignUp,
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

  Widget _socialIcon(SocialAuthProvider provider, Widget icon) {
    if (_pendingProvider != provider) return icon;
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
