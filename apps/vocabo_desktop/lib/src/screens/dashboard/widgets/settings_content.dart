import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/providers/auth_providers.dart';
import 'package:vocabo_desktop/src/providers/user_profile_provider.dart';

class SettingsContent extends ConsumerWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);

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
          _ProfileSection(userAsync: userAsync),
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
                  SizedBox(
                    width: cardWidth,
                    child: const _NotificationsCard(),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const _StudyLanguageCard(),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const _SupportCard(),
                  ),
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
  const _ProfileSection({required this.userAsync});

  final AsyncValue userAsync;

  @override
  Widget build(BuildContext context) {
    final name = userAsync.whenOrNull<String>(
          data: (user) => user.name,
        ) ??
        '...';

    return Container(
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VocaboColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: VocaboColors.primary.withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: VocaboTypography.headlineSm.copyWith(
                color: VocaboColors.primary,
              ),
            ),
          ),
          const SizedBox(width: VocaboSpacing.md),

          // Name and badges
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: VocaboTypography.titleLg),
                const SizedBox(height: VocaboSpacing.sm),
                Wrap(
                  spacing: VocaboSpacing.sm,
                  children: [
                    _Badge(
                      label: 'BEGINNER',
                      color: VocaboColors.tertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats
          _StatColumn(label: 'CURRENT STREAK', value: '--'),
          const SizedBox(width: VocaboSpacing.xl),
          _StatColumn(label: 'WEEKLY GOAL', value: '--'),
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
        color: color.withOpacity(0.15),
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
          style: VocaboTypography.labelSm.copyWith(
            color: VocaboColors.neutral,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: VocaboTypography.titleLg.copyWith(
            fontWeight: FontWeight.w700,
          ),
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
        border: Border.all(color: VocaboColors.outlineVariant.withOpacity(0.3)),
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

  final AsyncValue userAsync;

  @override
  Widget build(BuildContext context) {
    final email = userAsync.whenOrNull<String>(
          data: (user) => user.email,
        ) ??
        '...';

    return _SettingsCard(
      icon: Icons.person_outline,
      iconColor: VocaboColors.primary,
      title: 'Account Info',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EMAIL ADDRESS',
            style: VocaboTypography.labelSm.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
          const SizedBox(height: VocaboSpacing.xs),
          Text(email, style: VocaboTypography.bodyMd),
          const SizedBox(height: VocaboSpacing.md),
          Text(
            'PASSWORD',
            style: VocaboTypography.labelSm.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
          const SizedBox(height: VocaboSpacing.xs),
          Text(
            '\u2022' * 12,
            style: VocaboTypography.bodyMd,
          ),
        ],
      ),
    );
  }
}

class _NotificationsCard extends StatefulWidget {
  const _NotificationsCard();

  @override
  State<_NotificationsCard> createState() => _NotificationsCardState();
}

class _NotificationsCardState extends State<_NotificationsCard> {
  bool _dailyReminder = true;
  bool _weeklyReport = false;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      icon: Icons.notifications_outlined,
      iconColor: VocaboColors.secondary,
      title: 'Notifications',
      child: Column(
        children: [
          _NotificationRow(
            title: 'Daily Reminder',
            subtitle: 'Get notified to study at 8:00 AM',
            value: _dailyReminder,
            onChanged: (v) => setState(() => _dailyReminder = v),
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

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

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
            ],
          ),
        ),
        VocaboToggleSwitch(
          value: value,
          onChanged: onChanged,
        ),
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
            style: TextButton.styleFrom(
              foregroundColor: VocaboColors.primary,
            ),
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
            Expanded(
              child: Text(label, style: VocaboTypography.bodyMd),
            ),
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
