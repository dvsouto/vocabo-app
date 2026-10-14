import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';

class LoginPasswordScreen extends ConsumerStatefulWidget {
  const LoginPasswordScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<LoginPasswordScreen> createState() =>
      _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends ConsumerState<LoginPasswordScreen> {
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // The login state is global; a failed or abandoned attempt must not
    // leak into a new visit of this screen.
    Future.microtask(() => ref.invalidate(loginProvider));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;

    await ref
        .read(loginProvider.notifier)
        .login(email: widget.email, password: password);

    final loginState = ref.read(loginProvider);
    if (loginState.hasError && mounted) {
      final error = loginState.error;
      final message = switch (error) {
        UnauthorizedException() => context.l10n.authIncorrectCredentials,
        AppException(:final message) => message,
        _ => context.l10n.authSignInFailed,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } else if (!loginState.hasError && mounted) {
      // Auth status will change and routing will handle navigation
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);
    final isLoading = loginState.isLoading;
    final l10n = context.l10n;

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

          // Centered card
          Center(
            child: GlassCard(
              width: 440,
              padding: const EdgeInsets.all(VocaboSpacing.xl),
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

                  Text('Vocabo', style: VocaboTypography.headlineSm),
                  const SizedBox(height: VocaboSpacing.sm),

                  Text(
                    l10n.authEnterYourPassword,
                    style: VocaboTypography.bodySm.copyWith(
                      color: VocaboColors.neutral,
                    ),
                  ),
                  const SizedBox(height: VocaboSpacing.xl),

                  // Email display
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: VocaboColors.surfaceContainerLow,
                      borderRadius: VocaboRadius.sm,
                    ),
                    child: Text(
                      widget.email,
                      style: VocaboTypography.bodyMd.copyWith(
                        color: VocaboColors.neutral,
                      ),
                    ),
                  ),
                  const SizedBox(height: VocaboSpacing.md),

                  // Password field
                  PasswordField(
                    controller: _passwordController,
                    hint: l10n.authYourPasswordHint,
                    autofocus: true,
                    onSubmitted: (_) => _onLogin(),
                  ),
                  const SizedBox(height: VocaboSpacing.lg),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: VocaboPrimaryButton(
                      label: l10n.authEnterLibrary,
                      isExpanded: true,
                      isLoading: isLoading,
                      trailing: const Icon(
                        Icons.arrow_forward,
                        color: VocaboColors.onPrimary,
                        size: 18,
                      ),
                      onPressed: isLoading ? null : _onLogin,
                    ),
                  ),
                  const SizedBox(height: VocaboSpacing.md),

                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: VocaboSpacing.sm,
                    children: [
                      VocaboTextButton(
                        label: l10n.commonBack,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      VocaboTextButton(
                        label: l10n.authForgotPassword,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                PasswordResetScreen(initialEmail: widget.email),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
