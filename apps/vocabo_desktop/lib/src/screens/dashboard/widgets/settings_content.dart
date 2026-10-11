import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/config/env.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/auth_providers.dart';
import 'package:vocabo_desktop/src/providers/daily_reminder_provider.dart';
import 'package:vocabo_desktop/src/providers/spotlight_providers.dart';
import 'package:vocabo_desktop/src/providers/user_preferences_provider.dart';
import 'package:vocabo_desktop/src/providers/user_profile_provider.dart';
import 'package:vocabo_desktop/src/providers/user_vocabulary_providers.dart';
import 'package:vocabo_desktop/src/widgets/account/edit_profile_dialog.dart';

class SettingsContent extends ConsumerWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final statsAsync = ref.watch(vocabularyStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VocaboSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Settings', style: VocaboTypography.headlineSm),
          const SizedBox(height: VocaboSpacing.xs),
          Text(
            'Curate your learning environment and profile',
            style: VocaboTypography.bodyMd.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
          const SizedBox(height: VocaboSpacing.xl),

          // Profile section
          _ProfileSection(userAsync: userAsync, statsAsync: statsAsync),
          const SizedBox(height: VocaboSpacing.xl),

          // Settings cards grid
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - VocaboSpacing.md) / 2;
              return Wrap(
                spacing: VocaboSpacing.md,
                runSpacing: VocaboSpacing.md,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: _AccountInfoCard(userAsync: userAsync),
                  ),
                  SizedBox(width: cardWidth, child: const _SessionsCard()),
                  SizedBox(width: cardWidth, child: const _NotificationsCard()),
                  SizedBox(width: cardWidth, child: const _SpotlightCard()),
                  SizedBox(width: cardWidth, child: const _StudyLanguageCard()),
                  SizedBox(width: cardWidth, child: const _SupportCard()),
                ],
              );
            },
          ),
          const SizedBox(height: VocaboSpacing.xl),

          // Sign Out button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _confirmSignOut(context, ref),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: VocaboSpacing.md,
                  vertical: VocaboSpacing.sm,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(logoutProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.userAsync, required this.statsAsync});

  final AsyncValue<User> userAsync;
  final AsyncValue<VocabularyStats> statsAsync;

  @override
  Widget build(BuildContext context) {
    final user = userAsync.valueOrNull;
    final name = user?.name ?? '...';
    final stats = statsAsync.valueOrNull;

    return Container(
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VocaboColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          VocaboAvatar(name: name, imageUrl: Env.resolveUrl(user?.avatarUrl)),
          const SizedBox(width: VocaboSpacing.md),

          // Name, plan and edit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: VocaboTypography.titleLg),
                const SizedBox(height: VocaboSpacing.sm),
                Wrap(
                  spacing: VocaboSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (user != null)
                      _Badge(
                        label: user.plan.label,
                        color: user.plan == UserPlan.pro
                            ? VocaboColors.primary
                            : VocaboColors.neutral600,
                      ),
                    if (user != null)
                      VocaboTextButton(
                        label: 'Edit profile',
                        onPressed: () => showEditProfileDialog(context, user),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Stats
          _StatColumn(
            label: 'CURRENT STREAK',
            value: stats == null ? '--' : '${stats.currentStreak} days',
          ),
          const SizedBox(width: VocaboSpacing.xl),
          _StatColumn(
            label: 'THIS WEEK',
            value: stats == null ? '--' : '${stats.wordsThisWeek} words',
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: VocaboTypography.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: VocaboTypography.labelSm.copyWith(color: VocaboColors.neutral),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: VocaboTypography.titleLg.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VocaboColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: VocaboSpacing.sm),
              Text(title, style: VocaboTypography.titleLg),
            ],
          ),
          const SizedBox(height: VocaboSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({required this.userAsync});

  final AsyncValue<User> userAsync;

  @override
  Widget build(BuildContext context) {
    final user = userAsync.valueOrNull;
    final phone = user?.phoneNumber;
    final language = NativeLanguage.byCode(user?.nativeLanguage ?? '');
    final providers = user?.providers ?? const <String>[];

    return _SettingsCard(
      icon: Icons.person_outline,
      iconColor: VocaboColors.primary,
      title: 'Account Info',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: 'EMAIL ADDRESS',
            value: user?.email ?? '...',
            verified: user?.emailVerified ?? false,
          ),
          _InfoRow(
            label: 'PHONE',
            value: phone == null
                ? 'Not added'
                : formatPhoneInternational(phone, isoHint: user?.phoneCountry),
            verified: user?.phoneVerified ?? false,
          ),
          _InfoRow(
            label: 'NATIVE LANGUAGE',
            value: language?.displayName ?? '...',
          ),
          _InfoRow(
            label: 'SIGN IN',
            value: [
              if (user?.hasPassword ?? true) 'Password',
              for (final provider in providers)
                provider == 'apple' ? 'Apple' : 'Google',
            ].join(' · '),
            last: true,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.verified = false,
    this.last = false,
  });

  final String label;
  final String value;
  final bool verified;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : VocaboSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: VocaboTypography.labelSm.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
          const SizedBox(height: VocaboSpacing.xs),
          Row(
            children: [
              Flexible(child: Text(value, style: VocaboTypography.bodyMd)),
              if (verified) ...[
                const SizedBox(width: VocaboSpacing.xs),
                const Tooltip(
                  message: 'Verified',
                  child: Icon(
                    Icons.verified_outlined,
                    size: 14,
                    color: VocaboColors.tertiary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionsCard extends ConsumerWidget {
  const _SessionsCard();

  String _lastSeen(DateTime moment) {
    final elapsed = DateTime.now().difference(moment.toLocal());
    if (elapsed.inMinutes < 5) return 'Active now';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes} min ago';
    if (elapsed.inDays < 1) return '${elapsed.inHours} h ago';
    return '${elapsed.inDays} d ago';
  }

  Future<void> _signOut(
    BuildContext context,
    WidgetRef ref,
    UserSession session,
  ) async {
    try {
      await ref.read(apiClientProvider).user.revokeSession(session.id);
    } catch (e, st) {
      appLogger.handle(e, st, 'Session revoke failed');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not sign out that device.')),
        );
      }
    }
    ref.invalidate(userSessionsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(userSessionsProvider);

    return _SettingsCard(
      icon: Icons.devices_outlined,
      iconColor: VocaboColors.secondary,
      title: 'Signed-in devices',
      child: sessions.when(
        loading: () => const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, _) => VocaboTextButton(
          label: 'Could not load devices. Retry',
          onPressed: () => ref.invalidate(userSessionsProvider),
        ),
        data: (list) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final session in list)
              Padding(
                padding: const EdgeInsets.only(bottom: VocaboSpacing.sm),
                child: Row(
                  children: [
                    const Icon(
                      Icons.laptop_mac_outlined,
                      size: 18,
                      color: VocaboColors.neutral,
                    ),
                    const SizedBox(width: VocaboSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.deviceName ?? 'Unknown device',
                            style: VocaboTypography.bodyMd.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            session.current
                                ? 'This device'
                                : _lastSeen(session.lastSeenAt),
                            style: VocaboTypography.bodySm.copyWith(
                              color: VocaboColors.neutral,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!session.current)
                      VocaboTextButton(
                        label: 'Sign out',
                        onPressed: () => _signOut(context, ref, session),
                      ),
                  ],
                ),
              ),
            Text(
              'Up to $maxActiveSessions devices stay signed in. Signing in on '
              'another one signs out the oldest.',
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsCard extends ConsumerStatefulWidget {
  const _NotificationsCard();

  @override
  ConsumerState<_NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends ConsumerState<_NotificationsCard> {
  bool _weeklyReport = false;

  Future<void> _setDailyReminder(bool enabled) async {
    if (enabled) {
      final granted = await ref
          .read(dailyReminderServiceProvider)
          .requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Allow notifications for Vocabo in System Settings to get '
                'daily reminders.',
              ),
            ),
          );
        }
        return;
      }
    }

    await ref
        .read(userPreferencesProvider.notifier)
        .setDailyReminder(enabled: enabled);
  }

  Future<void> _pickTime(String current) async {
    final parsed = DailyReminderSchedule.reminderAt(current, DateTime.now());
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: parsed?.hour ?? 8,
        minute: parsed?.minute ?? 0,
      ),
    );
    if (picked == null) return;

    await ref
        .read(userPreferencesProvider.notifier)
        .setDailyReminder(
          time: DailyReminderSchedule.format(picked.hour, picked.minute),
        );
  }

  @override
  Widget build(BuildContext context) {
    final preferences =
        ref.watch(userPreferencesProvider).valueOrNull ??
        const UserPreferences();

    return _SettingsCard(
      icon: Icons.notifications_outlined,
      iconColor: VocaboColors.secondary,
      title: 'Notifications',
      child: Column(
        children: [
          _NotificationRow(
            title: 'Daily Reminder',
            subtitle:
                'Flashcards waiting, every day at '
                '${preferences.dailyReminderTime}',
            actionLabel: 'Change time',
            onAction: () => _pickTime(preferences.dailyReminderTime),
            value: preferences.dailyReminderEnabled,
            onChanged: _setDailyReminder,
          ),
          const SizedBox(height: VocaboSpacing.md),
          _NotificationRow(
            title: 'Weekly Progress Report',
            subtitle: 'Summary of your learned words',
            value: _weeklyReport,
            onChanged: (v) => setState(() => _weeklyReport = v),
          ),
        ],
      ),
    );
  }
}

class _SpotlightCard extends ConsumerWidget {
  const _SpotlightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(spotlightEnabledProvider).valueOrNull ?? true;

    return _SettingsCard(
      icon: Icons.translate,
      iconColor: VocaboColors.primary,
      title: 'Shortcuts',
      child: _NotificationRow(
        title: 'Translation spotlight',
        subtitle: 'Press Control + Option + Space anywhere to translate a word',
        value: enabled,
        onChanged: (value) =>
            ref.read(spotlightEnabledProvider.notifier).setEnabled(value),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: VocaboTypography.bodyMd),
              Text(
                subtitle,
                style: VocaboTypography.bodySm.copyWith(
                  color: VocaboColors.neutral,
                ),
              ),
              if (actionLabel != null && onAction != null)
                InkWell(
                  onTap: onAction,
                  mouseCursor: SystemMouseCursors.click,
                  child: Text(
                    actionLabel!,
                    style: VocaboTypography.bodySm.copyWith(
                      color: VocaboColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        VocaboToggleSwitch(value: value, onChanged: onChanged),
      ],
    );
  }
}

class _StudyLanguageCard extends StatelessWidget {
  const _StudyLanguageCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.language,
      iconColor: VocaboColors.tertiary,
      title: 'Study Language',
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('English (US)', style: VocaboTypography.bodyMd),
                const SizedBox(height: 2),
                Text(
                  'Mastering 2,400+ vocabulary tokens',
                  style: VocaboTypography.bodySm.copyWith(
                    color: VocaboColors.neutral,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(foregroundColor: VocaboColors.primary),
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.support_agent,
      iconColor: Colors.orange,
      title: 'Support',
      child: Column(
        children: [
          _SupportRow(label: 'Help Center & FAQ', onTap: () {}),
          const Divider(height: 1),
          _SupportRow(label: 'Privacy Policy', onTap: () {}),
          const Divider(height: 1),
          _SupportRow(label: 'Submit Feedback', onTap: () {}),
        ],
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(label, style: VocaboTypography.bodyMd)),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: VocaboColors.neutral,
            ),
          ],
        ),
      ),
    );
  }
}
