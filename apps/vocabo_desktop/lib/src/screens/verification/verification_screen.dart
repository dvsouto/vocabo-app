import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/auth_providers.dart';
import 'package:vocabo_desktop/src/providers/user_profile_provider.dart';
import 'package:vocabo_desktop/src/widgets/account/auth_scaffold.dart';
import 'package:vocabo_desktop/src/widgets/account/code_verification_panel.dart';

/// Shown after signup until the account is confirmed with a code sent by
/// email or SMS. The rest of the app stays locked meanwhile.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  VerificationChannel _channel = VerificationChannel.email;

  Future<void> _confirm(String code) async {
    final api = ref.read(apiClientProvider);
    final user = await api.auth.confirmVerification(code);
    if (user.verified) {
      ref.invalidate(userProfileProvider);
      ref.invalidate(authStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProfileProvider).valueOrNull;
    final api = ref.read(apiClientProvider);

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: VocaboColors.primary50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _channel == VerificationChannel.email
                  ? Icons.mark_email_unread_outlined
                  : Icons.sms_outlined,
              color: VocaboColors.primary,
            ),
          ),
          const SizedBox(height: VocaboSpacing.md),
          Text('Confirm your account', style: VocaboTypography.headlineSm),
          const SizedBox(height: VocaboSpacing.lg),
          if (user?.hasPhone ?? false) ...[
            Wrap(
              spacing: VocaboSpacing.sm,
              children: [
                for (final channel in VerificationChannel.values)
                  VocaboSelectableChip(
                    label: channel == VerificationChannel.email
                        ? 'Email'
                        : 'SMS',
                    isSelected: _channel == channel,
                    onTap: () => setState(() => _channel = channel),
                  ),
              ],
            ),
            const SizedBox(height: VocaboSpacing.lg),
          ],
          CodeVerificationPanel(
            key: ValueKey(_channel),
            send: () => api.auth.sendVerification(_channel),
            confirm: _confirm,
          ),
          const SizedBox(height: VocaboSpacing.xl),
          Text(
            user == null ? '' : 'Signed in as ${user.email}',
            style: VocaboTypography.bodySm.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
          VocaboTextButton(
            label: 'Use another account',
            onPressed: () => ref.read(logoutProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}
