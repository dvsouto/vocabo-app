import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

/// Background and centered card shared by the signup and verification
/// screens, matching the login screens.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.width = 440,
    this.onBack,
  });

  final Widget child;
  final double width;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: VocaboSpacing.xl),
              child: GlassCard(
                width: width,
                padding: const EdgeInsets.symmetric(
                  horizontal: VocaboSpacing.xl,
                  vertical: VocaboSpacing.xxl,
                ),
                child: child,
              ),
            ),
          ),
          if (onBack != null)
            Positioned(
              top: VocaboSpacing.xl,
              left: VocaboSpacing.lg,
              child: IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back),
                color: VocaboColors.neutral700,
                onPressed: onBack,
              ),
            ),
        ],
      ),
    );
  }
}

/// Uppercase caption above a form field, with an optional marker.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: VocaboSpacing.sm),
      child: Text.rich(
        TextSpan(
          text: text.toUpperCase(),
          style: VocaboTypography.labelSm,
          children: [
            if (optional)
              TextSpan(
                text: '  OPTIONAL',
                style: VocaboTypography.labelSm.copyWith(
                  color: VocaboColors.neutral,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
