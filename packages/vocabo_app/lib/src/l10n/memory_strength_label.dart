import 'package:flutter/widgets.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';

/// [MemoryStrengthDots] with the strength name in the interface language.
class LocalizedMemoryStrengthDots extends StatelessWidget {
  const LocalizedMemoryStrengthDots({super.key, required this.strength});

  final MemoryStrength strength;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final name = l10n.memoryStrengthName(strength);
    return MemoryStrengthDots(
      strength: strength,
      label: name,
      semanticsLabel: l10n.flashcardsStrengthSemantics(
        name,
        strength.level,
        MemoryStrength.totalLevels,
      ),
    );
  }
}
