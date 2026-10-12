import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';
import 'package:vocabo_desktop/src/pro/plan_providers.dart';
import 'package:vocabo_desktop/src/pro/plan_card.dart';
import 'package:vocabo_desktop/src/legal/legal_documents_for.dart';
import 'package:vocabo_desktop/src/config/env.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/auth_providers.dart';
import 'package:vocabo_desktop/src/providers/daily_reminder_provider.dart';
import 'package:vocabo_desktop/src/providers/spotlight_providers.dart';
import 'package:vocabo_desktop/src/providers/user_preferences_provider.dart';
import 'package:vocabo_desktop/src/providers/user_profile_provider.dart';
import 'package:vocabo_desktop/src/providers/user_vocabulary_providers.dart';
import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/l10n/locale_providers.dart';
import 'package:vocabo_desktop/src/legal/legal_documents.dart';
import 'package:vocabo_desktop/src/widgets/account/change_password_dialog.dart';
import 'package:vocabo_desktop/src/widgets/account/delete_account_dialog.dart';
import 'package:vocabo_desktop/src/widgets/account/edit_profile_dialog.dart';
import 'package:vocabo_desktop/src/widgets/account/native_language_field.dart';
import 'package:vocabo_desktop/src/widgets/legal/legal_document_dialog.dart';

class SettingsContent extends ConsumerWidget {
  const SettingsContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProfileProvider);
    final statsAsync = ref.watch(vocabularyStatsProvider);
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(VocaboSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsTitle, style: VocaboTypography.headlineSm),
          const SizedBox(height: VocaboSpacing.xs),
          Text(
            l10n.settingsSubtitle,
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
              final columns = constraints.maxWidth >= 640 ? 2 : 1;
              final cardWidth =
                  (constraints.maxWidth - VocaboSpacing.md * (columns - 1)) /
                  columns;
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
                    child: PlanCard(
                      cardBuilder:
                          ({
                            required icon,
                            required iconColor,
                            required title,
                            required child,
                          }) => _SettingsCard(
                            icon: icon,
                            iconColor: iconColor,
                            title: title,
                            child: child,
                          ),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: _LanguageCard(user: userAsync.valueOrNull),
                  ),
                  SizedBox(width: cardWidth, child: const _SessionsCard()),
                  SizedBox(
                    width: cardWidth,
                    child: _SecurityCard(user: userAsync.valueOrNull),
                  ),
                  SizedBox(width: cardWidth, child: const _NotificationsCard()),
                  SizedBox(width: cardWidth, child: const _SpotlightCard()),
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
              label: Text(l10n.settingsSignOut),
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
        title: Text(ctx.l10n.settingsSignOut),
        content: Text(ctx.l10n.settingsSignOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(ctx.l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(logoutProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(ctx.l10n.settingsSignOut),
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
    final l10n = context.l10n;

    final identity = Row(
      children: [
        VocaboAvatar(name: name, imageUrl: Env.resolveUrl(user?.avatarUrl)),
        const SizedBox(width: VocaboSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: VocaboTypography.titleLg,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: VocaboSpacing.sm),
              Wrap(
                spacing: VocaboSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (user != null)
                    _Badge(
                      label: l10n.planLabel(user.plan),
                      color: user.plan == UserPlan.pro
                          ? VocaboColors.primary
                          : VocaboColors.neutral600,
                    ),
                  if (user != null)
                    VocaboTextButton(
                      label: l10n.settingsEditProfile,
                      onPressed: () => showEditProfileDialog(context, user),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    Widget figures({required bool alignEnd}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatColumn(
          alignEnd: alignEnd,
          label: l10n.settingsCurrentStreak,
          value: stats == null ? '--' : l10n.countDays(stats.currentStreak),
        ),
        const SizedBox(width: VocaboSpacing.xl),
        _StatColumn(
          alignEnd: alignEnd,
          label: l10n.settingsReviewedThisWeek,
          value: stats == null ? '--' : l10n.countCards(stats.reviewsThisWeek),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(VocaboSpacing.lg),
      decoration: BoxDecoration(
        color: VocaboColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: VocaboColors.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 560) {
            return Row(
              children: [
                Expanded(child: identity),
                figures(alignEnd: true),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              identity,
              const SizedBox(height: VocaboSpacing.lg),
              figures(alignEnd: false),
            ],
          );
        },
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
  const _StatColumn({
    required this.label,
    required this.value,
    this.alignEnd = true,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
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
              Expanded(
                child: Text(
                  title,
                  style: VocaboTypography.titleLg,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
    final providers = user?.providers ?? const <String>[];
    final l10n = context.l10n;

    return _SettingsCard(
      icon: Icons.person_outline,
      iconColor: VocaboColors.primary,
      title: l10n.settingsAccountInfo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: l10n.settingsEmailAddress,
            value: user?.email ?? '...',
            verified: user?.emailVerified ?? false,
          ),
          _InfoRow(
            label: l10n.settingsPhone,
            value: phone == null
                ? l10n.settingsPhoneNotAdded
                : formatPhoneInternational(phone, isoHint: user?.phoneCountry),
            verified: user?.phoneVerified ?? false,
          ),
          _InfoRow(
            label: l10n.settingsSignInMethods,
            value: [
              if (user?.hasPassword ?? true) l10n.settingsSignInPassword,
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
                Tooltip(
                  message: context.l10n.settingsVerified,
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

  String _lastSeen(AppLocalizations l10n, DateTime moment) {
    final elapsed = DateTime.now().difference(moment.toLocal());
    if (elapsed.inMinutes < 5) return l10n.settingsLastSeenNow;
    if (elapsed.inHours < 1) {
      return l10n.settingsLastSeenMinutes(elapsed.inMinutes);
    }
    if (elapsed.inDays < 1) return l10n.settingsLastSeenHours(elapsed.inHours);
    return l10n.settingsLastSeenDays(elapsed.inDays);
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
          SnackBar(content: Text(context.l10n.settingsSignOutDeviceFailed)),
        );
      }
    }
    ref.invalidate(userSessionsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(userSessionsProvider);
    final l10n = context.l10n;

    return _SettingsCard(
      icon: Icons.devices_outlined,
      iconColor: VocaboColors.secondary,
      title: l10n.settingsDevicesTitle,
      child: sessions.when(
        loading: () => const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, _) => VocaboTextButton(
          label: l10n.settingsDevicesLoadFailed,
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
                            session.deviceName ?? l10n.settingsUnknownDevice,
                            style: VocaboTypography.bodyMd.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            session.current
                                ? l10n.settingsThisDevice
                                : _lastSeen(l10n, session.lastSeenAt),
                            style: VocaboTypography.bodySm.copyWith(
                              color: VocaboColors.neutral,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!session.current)
                      VocaboTextButton(
                        label: l10n.settingsSignOutDevice,
                        onPressed: () => _signOut(context, ref, session),
                      ),
                  ],
                ),
              ),
            Text(
              l10n.settingsDevicesLimit(
                ref.watch(planStatusProvider).valueOrNull?.limits.devices ??
                    maxActiveSessions,
              ),
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
  Future<void> _setDailyReminder(bool enabled) async {
    if (enabled) {
      final granted = await ref
          .read(dailyReminderServiceProvider)
          .requestPermission();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.settingsNotificationsDenied)),
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
    final l10n = context.l10n;

    return _SettingsCard(
      icon: Icons.notifications_outlined,
      iconColor: VocaboColors.secondary,
      title: l10n.settingsNotificationsTitle,
      child: _NotificationRow(
        title: l10n.settingsDailyReminder,
        subtitle: l10n.settingsDailyReminderSubtitle(
          preferences.dailyReminderTime,
        ),
        actionLabel: l10n.settingsChangeTime,
        onAction: () => _pickTime(preferences.dailyReminderTime),
        value: preferences.dailyReminderEnabled,
        onChanged: _setDailyReminder,
      ),
    );
  }
}

class _SpotlightCard extends ConsumerWidget {
  const _SpotlightCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(spotlightEnabledProvider).valueOrNull ?? true;
    final l10n = context.l10n;

    return _SettingsCard(
      icon: Icons.translate,
      iconColor: VocaboColors.primary,
      title: l10n.settingsShortcutsTitle,
      child: _NotificationRow(
        title: l10n.settingsSpotlightTitle,
        subtitle: l10n.settingsSpotlightSubtitle,
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

class _LanguageCard extends ConsumerStatefulWidget {
  const _LanguageCard({required this.user});

  final User? user;

  @override
  ConsumerState<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends ConsumerState<_LanguageCard> {
  bool _savingNative = false;

  Future<void> _setNativeLanguage(String code) async {
    setState(() => _savingNative = true);
    try {
      await ref
          .read(apiClientProvider)
          .user
          .updateProfile(nativeLanguage: code);
      ref.invalidate(userProfileProvider);
    } catch (e, st) {
      appLogger.handle(e, st, 'Native language update failed');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.settingsLanguageChangeFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _savingNative = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final interfaceLanguage =
        ref.watch(interfaceLanguageProvider).valueOrNull ?? 'en';
    final l10n = context.l10n;

    return _SettingsCard(
      icon: Icons.language,
      iconColor: VocaboColors.tertiary,
      title: l10n.settingsLanguageTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.settingsAppLanguage,
            style: VocaboTypography.labelSm.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
          const SizedBox(height: VocaboSpacing.xs),
          NativeLanguageField.interface(
            value: interfaceLanguage,
            onChanged: (code) =>
                ref.read(interfaceLanguageProvider.notifier).select(code),
          ),
          const SizedBox(height: VocaboSpacing.md),
          Text(
            l10n.settingsNativeLanguage,
            style: VocaboTypography.labelSm.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
          const SizedBox(height: VocaboSpacing.xs),
          if (user != null)
            NativeLanguageField(
              value:
                  NativeLanguage.byCode(user.nativeLanguage)?.code ??
                  defaultNativeLanguage,
              enabled: !_savingNative,
              onChanged: _setNativeLanguage,
            ),
          const SizedBox(height: VocaboSpacing.xs),
          Text(
            l10n.settingsNativeLanguageHint,
            style: VocaboTypography.bodySm.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
          const SizedBox(height: VocaboSpacing.md),
          Text(
            l10n.settingsVoiceLabel,
            style: VocaboTypography.labelSm.copyWith(
              color: VocaboColors.neutral,
            ),
          ),
          const SizedBox(height: VocaboSpacing.xs),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: 'female',
                label: Text(l10n.settingsVoiceFemale),
              ),
              ButtonSegment(value: 'male', label: Text(l10n.settingsVoiceMale)),
            ],
            selected: {
              ref.watch(userPreferencesProvider).valueOrNull?.voiceGender ??
                  'female',
            },
            onSelectionChanged: (selection) => ref
                .read(userPreferencesProvider.notifier)
                .setVoiceGender(selection.first),
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final user = this.user;
    final danger = Theme.of(context).colorScheme.error;
    final l10n = context.l10n;

    return _SettingsCard(
      icon: Icons.lock_outline,
      iconColor: VocaboColors.primary,
      title: l10n.settingsSecurityTitle,
      child: Column(
        children: [
          _SupportRow(
            label: (user?.hasPassword ?? true)
                ? l10n.settingsChangePassword
                : l10n.settingsSetPassword,
            onTap: user == null
                ? null
                : () async {
                    final saved = await showChangePasswordDialog(context, user);
                    if (saved == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.settingsPasswordSaved)),
                      );
                    }
                  },
          ),
          const Divider(height: 1),
          _SupportRow(
            label: l10n.settingsDeleteAccount,
            color: danger,
            onTap: user == null
                ? null
                : () => showDeleteAccountDialog(context, user),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  Future<void> _contactSupport(BuildContext context) async {
    final opened = await launchUrl(
      Uri(
        scheme: 'mailto',
        path: supportEmail,
        queryParameters: {'subject': context.l10n.settingsSupportEmailSubject},
      ),
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsWriteToUs(supportEmail))),
      );
    }
  }

  Future<void> _showAbout(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationName: 'Vocabo',
      applicationVersion: '${info.version} (${info.buildNumber})',
      applicationLegalese: '© ${DateTime.now().year} $companyName',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _SettingsCard(
      icon: Icons.support_agent,
      iconColor: Colors.orange,
      title: l10n.settingsSupportTitle,
      child: Column(
        children: [
          _SupportRow(
            label: l10n.settingsContactSupport,
            onTap: () => _contactSupport(context),
          ),
          const Divider(height: 1),
          _SupportRow(
            label: l10n.settingsTermsOfService,
            onTap: () => showLegalDocument(
              context,
              termsOfServiceFor(Localizations.localeOf(context)),
            ),
          ),
          const Divider(height: 1),
          _SupportRow(
            label: l10n.settingsPrivacyPolicy,
            onTap: () => showLegalDocument(
              context,
              privacyPolicyFor(Localizations.localeOf(context)),
            ),
          ),
          const Divider(height: 1),
          _SupportRow(
            label: l10n.settingsAboutApp,
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow({required this.label, required this.onTap, this.color});

  final String label;
  final VoidCallback? onTap;
  final Color? color;

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
              child: Text(
                label,
                style: VocaboTypography.bodyMd.copyWith(color: color),
              ),
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
