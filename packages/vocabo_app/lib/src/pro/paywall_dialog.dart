import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';

final _manageSubscriptionsUrl = Platform.isAndroid
    ? Uri.parse('https://play.google.com/store/account/subscriptions')
    : Uri.parse('https://apps.apple.com/account/subscriptions');

Future<void> showPaywall(
  BuildContext context, [
  UpgradeReason reason = const UpgradeReason.manual(),
]) {
  return showDialog<void>(
    context: context,
    builder: (_) => _PaywallDialog(reason: reason),
  );
}

/// Opens the store's subscription management page.
Future<void> openManageSubscriptions() =>
    launchUrl(_manageSubscriptionsUrl, mode: LaunchMode.externalApplication);

class _PaywallDialog extends ConsumerStatefulWidget {
  const _PaywallDialog({required this.reason});

  final UpgradeReason reason;

  @override
  ConsumerState<_PaywallDialog> createState() => _PaywallDialogState();
}

class _PaywallDialogState extends ConsumerState<_PaywallDialog> {
  String _selectedId = proYearlyProductId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(storeEventProvider.notifier).state = null;
    });
  }

  Future<void> _buy(ProductDetails product) async {
    final user = await ref.read(userProfileProvider.future);
    setState(() => _busy = true);
    try {
      await ref.read(storeServiceProvider).buy(product, userId: user.id);
    } catch (_) {
      ref.read(storeEventProvider.notifier).state = StorePurchaseEvent.failed;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final user = await ref.read(userProfileProvider.future);
    setState(() => _busy = true);
    try {
      await ref.read(storeServiceProvider).restore(userId: user.id);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final products = ref.watch(storeProductsProvider);
    final isPro = ref.watch(planStatusProvider).valueOrNull?.isPro ?? false;

    ref.listen(storeEventProvider, (_, event) {
      if (event == StorePurchaseEvent.completed && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.proWelcome)));
      }
    });
    final event = ref.watch(storeEventProvider);

    return Dialog(
      backgroundColor: VocaboColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: VocaboRadius.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.sizeOf(context).height - VocaboSpacing.xl,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(VocaboSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: VocaboColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'VOCABO PRO',
                      style: VocaboTypography.labelSm.copyWith(
                        color: VocaboColors.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.commonClose,
                    icon: const Icon(Icons.close),
                    color: VocaboColors.neutral,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: VocaboSpacing.sm),
              Text(
                widget.reason.headline(l10n),
                style: VocaboTypography.headlineSm,
              ),
              const SizedBox(height: VocaboSpacing.xs),
              Text(
                l10n.proPaywallSubtitle,
                style: VocaboTypography.bodyMd.copyWith(
                  color: VocaboColors.neutral600,
                ),
              ),
              const SizedBox(height: VocaboSpacing.lg),
              for (final benefit in [
                l10n.proBenefitUnlimitedWords,
                l10n.proBenefitUnlimitedLookups,
                l10n.proBenefitDevices,
                l10n.proBenefitStudyNote,
                l10n.proBenefitRecommendations,
                l10n.proBenefitCollections,
                l10n.proBenefitStats,
                l10n.proBenefitArchive,
                l10n.proBenefitExport,
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: VocaboSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: VocaboColors.tertiary,
                      ),
                      const SizedBox(width: VocaboSpacing.sm),
                      Expanded(
                        child: Text(benefit, style: VocaboTypography.bodyMd),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: VocaboSpacing.md),
              if (isPro) ...[
                Text(l10n.proAlreadyPro, style: VocaboTypography.bodyMd),
                const SizedBox(height: VocaboSpacing.md),
                VocaboPrimaryButton(
                  label: l10n.proManageSubscription,
                  isExpanded: true,
                  onPressed: openManageSubscriptions,
                ),
              ] else
                products.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(VocaboSpacing.lg),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, _) => Text(l10n.proStoreUnavailable),
                  data: (list) => list.isEmpty
                      ? Text(
                          l10n.proStoreUnavailable,
                          style: VocaboTypography.bodyMd.copyWith(
                            color: VocaboColors.neutral600,
                          ),
                        )
                      : _plans(list),
                ),
              if (event case final current?) ...[
                const SizedBox(height: VocaboSpacing.sm),
                Text(
                  switch (current) {
                    StorePurchaseEvent.pending => l10n.proPurchasePending,
                    StorePurchaseEvent.failed => l10n.proPurchaseFailed,
                    StorePurchaseEvent.canceled => '',
                    StorePurchaseEvent.completed => l10n.proWelcome,
                  },
                  style: VocaboTypography.bodySm.copyWith(
                    color: current == StorePurchaseEvent.failed
                        ? Theme.of(context).colorScheme.error
                        : VocaboColors.neutral600,
                  ),
                ),
              ],
              const SizedBox(height: VocaboSpacing.md),
              Wrap(
                spacing: VocaboSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (!isPro)
                    VocaboTextButton(
                      label: l10n.proRestorePurchases,
                      onPressed: _busy ? null : _restore,
                    ),
                  VocaboTextButton(
                    label: l10n.authTermsOfService,
                    onPressed: () => showLegalDocument(
                      context,
                      termsOfServiceFor(Localizations.localeOf(context)),
                    ),
                  ),
                  VocaboTextButton(
                    label: l10n.authPrivacyPolicy,
                    onPressed: () => showLegalDocument(
                      context,
                      privacyPolicyFor(Localizations.localeOf(context)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _plans(List<ProductDetails> products) {
    final l10n = context.l10n;
    final monthly = products
        .where((p) => p.id == proMonthlyProductId)
        .firstOrNull;
    final yearly = products
        .where((p) => p.id == proYearlyProductId)
        .firstOrNull;
    final selected =
        products.where((p) => p.id == _selectedId).firstOrNull ??
        products.first;

    final saving = monthly != null && yearly != null && monthly.rawPrice > 0
        ? (100 - yearly.rawPrice / (monthly.rawPrice * 12) * 100).round()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final product in [?yearly, ?monthly])
          Padding(
            padding: const EdgeInsets.only(bottom: VocaboSpacing.sm),
            child: _PlanOption(
              title: product.id == proYearlyProductId
                  ? l10n.proPlanYearly
                  : l10n.proPlanMonthly,
              price: product.id == proYearlyProductId
                  ? l10n.proPricePerYear(product.price)
                  : l10n.proPricePerMonth(product.price),
              badge: product.id == proYearlyProductId && saving != null
                  ? l10n.proYearlySaving(saving)
                  : null,
              selected: product.id == selected.id,
              onTap: () => setState(() => _selectedId = product.id),
            ),
          ),
        const SizedBox(height: VocaboSpacing.sm),
        VocaboPrimaryButton(
          label: l10n.proStartTrial,
          isExpanded: true,
          isLoading: _busy,
          onPressed: _busy ? null : () => _buy(selected),
        ),
        const SizedBox(height: VocaboSpacing.sm),
        Text(
          l10n.proTrialDisclosure(selected.price),
          style: VocaboTypography.bodySm.copyWith(color: VocaboColors.neutral),
        ),
      ],
    );
  }
}

class _PlanOption extends StatelessWidget {
  const _PlanOption({
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String? badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: VocaboRadius.md,
      child: Container(
        padding: const EdgeInsets.all(VocaboSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? VocaboColors.primary50
              : VocaboColors.surfaceContainerLow,
          borderRadius: VocaboRadius.md,
          border: Border.all(
            color: selected ? VocaboColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? VocaboColors.primary : VocaboColors.neutral,
            ),
            const SizedBox(width: VocaboSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VocaboTypography.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    price,
                    style: VocaboTypography.bodySm.copyWith(
                      color: VocaboColors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: VocaboColors.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge!,
                  style: VocaboTypography.labelSm.copyWith(
                    color: const Color(0xFF1E8E3E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
