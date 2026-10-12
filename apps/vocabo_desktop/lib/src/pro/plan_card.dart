import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';
import 'package:vocabo_desktop/src/pro/paywall_dialog.dart';
import 'package:vocabo_desktop/src/pro/plan_providers.dart';
import 'package:vocabo_desktop/src/providers/api_client_provider.dart';
import 'package:vocabo_desktop/src/providers/user_profile_provider.dart';

/// Plan, usage of the free limits, upgrade, restore and library export.
class PlanCard extends ConsumerWidget {
  const PlanCard({super.key, required this.cardBuilder});

  /// Wraps the content in the settings card chrome.
  final Widget Function({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  })
  cardBuilder;

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final user = await ref.read(userProfileProvider.future);
    await ref.read(storeServiceProvider).restore(userId: user.id);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.proRestoreRequested)));
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final location = await getSaveLocation(
        suggestedName: 'vocabo-library.csv',
        acceptedTypeGroups: const [
          XTypeGroup(label: 'CSV', extensions: ['csv']),
        ],
      );
      if (location == null) return;
      final csv = await ref.read(apiClientProvider).userVocabulary.exportCsv();
      await File(location.path).writeAsString(csv);
      messenger.showSnackBar(SnackBar(content: Text(l10n.proExportDone)));
    } catch (e, st) {
      if (upgradeReasonFor(e) case final reason?) {
        if (context.mounted) showPaywall(context, reason);
        return;
      }
      appLogger.handle(e, st, 'Library export failed');
      messenger.showSnackBar(SnackBar(content: Text(l10n.proExportFailed)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final status = ref.watch(planStatusProvider).valueOrNull;
    final isPro = status?.isPro ?? false;
    final subscription = status?.subscription;

    return cardBuilder(
      icon: Icons.workspace_premium_outlined,
      iconColor: VocaboColors.primary,
      title: isPro ? l10n.proPlanProTitle : l10n.proPlanFreeTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status != null && !isPro) ...[
            _Usage(
              label: l10n.proUsageWords,
              used: status.libraryWords,
              max: status.limits.libraryWords,
            ),
            const SizedBox(height: VocaboSpacing.sm),
            _Usage(
              label: l10n.proUsageLookupsToday,
              used: status.dailyLookups,
              max: status.limits.dailyLookups,
            ),
            const SizedBox(height: VocaboSpacing.md),
            VocaboPrimaryButton(
              label: l10n.proUpgradeButton,
              isExpanded: true,
              onPressed: () => showPaywall(context),
            ),
          ],
          if (isPro) ...[
            Text(
              subscription == null
                  ? l10n.proGrantedNote
                  : subscription.isTrial
                  ? l10n.proTrialUntil(_date(context, subscription.expiresAt))
                  : subscription.autoRenew
                  ? l10n.proRenewsOn(_date(context, subscription.expiresAt))
                  : l10n.proEndsOn(_date(context, subscription.expiresAt)),
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral600,
              ),
            ),
            const SizedBox(height: VocaboSpacing.md),
            VocaboTextButton(
              label: l10n.proExportLibrary,
              onPressed: () => _export(context, ref),
            ),
            if (subscription != null)
              VocaboTextButton(
                label: l10n.proManageSubscription,
                onPressed: openManageSubscriptions,
              ),
          ],
          VocaboTextButton(
            label: l10n.proRestorePurchases,
            onPressed: () => _restore(context, ref),
          ),
        ],
      ),
    );
  }

  String _date(BuildContext context, DateTime? date) {
    if (date == null) return '—';
    return MaterialLocalizations.of(context).formatMediumDate(date.toLocal());
  }
}

class _Usage extends StatelessWidget {
  const _Usage({required this.label, required this.used, this.max});

  final String label;
  final int used;
  final int? max;

  @override
  Widget build(BuildContext context) {
    final limit = max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: VocaboTypography.bodySm)),
            Text(
              limit == null ? '$used' : '$used / $limit',
              style: VocaboTypography.bodySm.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (limit != null) ...[
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: VocaboRadius.sm,
            child: LinearProgressIndicator(
              value: limit == 0 ? 0 : (used / limit).clamp(0, 1),
              minHeight: 6,
              color: used >= limit
                  ? Theme.of(context).colorScheme.error
                  : VocaboColors.primary,
              backgroundColor: VocaboColors.neutral200,
            ),
          ),
        ],
      ],
    );
  }
}
