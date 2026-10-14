import 'package:flutter/material.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/src/pro/pro_feature_gate.dart';

/// Placeholder for the Pro statistics on the free plan.
class ProLockedCard extends StatelessWidget {
  const ProLockedCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ProLockedPanel(
      icon: Icons.insights_outlined,
      title: context.l10n.proStatsLockedTitle,
      body: context.l10n.proStatsLockedBody,
    );
  }
}
