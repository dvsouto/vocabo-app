import 'package:flutter/widgets.dart';
import 'package:vocabo_core/vocabo_core.dart';

import 'package:vocabo_desktop/src/l10n/generated/app_localizations.dart';

export 'package:vocabo_desktop/src/l10n/generated/app_localizations.dart';

extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Display names of values computed in `vocabo_core`, which has no access
/// to the app translations.
extension CoreL10n on AppLocalizations {
  String memoryStrengthName(MemoryStrength strength) {
    if (strength.name == MemoryStrength.masteredName) return memoryMastered;
    if (strength.name == MemoryStrength.archivedName) return memoryArchived;
    return memoryStageName(MemoryStrength.stageNames.indexOf(strength.name));
  }

  String memoryStageName(int stageIndex) => switch (stageIndex) {
    0 => memoryStageNew,
    1 => memoryStageFresh,
    2 => memoryStageFamiliar,
    3 => memoryStageSettling,
    4 => memoryStageAnchored,
    5 => memoryStageDeep,
    _ => memoryStageLasting,
  };

  String passwordRequirementLabel(PasswordRequirement requirement) =>
      switch (requirement) {
        PasswordRequirement.minLength => passwordRuleLength(minPasswordLength),
        PasswordRequirement.letter => passwordRuleLetter,
        PasswordRequirement.number => passwordRuleNumber,
      };

  String clarityLabel(FlashcardEvaluation evaluation) => switch (evaluation) {
    FlashcardEvaluation.hard => clarityBlank,
    FlashcardEvaluation.medium => clarityFuzzy,
    FlashcardEvaluation.easy => clarityClear,
  };

  /// When the card comes back after the given answer, for button captions.
  String nextReviewCaption(
    FlashcardEvaluation evaluation, {
    required int stageIndex,
    required List<int> stages,
  }) {
    switch (evaluation) {
      case FlashcardEvaluation.hard:
        return nextReviewToday;
      case FlashcardEvaluation.medium:
        return nextReviewTomorrow;
      case FlashcardEvaluation.easy:
        if (stageIndex >= stages.length - 1) return nextReviewMastered;
        final days = stages[stageIndex + 1] - stages[stageIndex];
        return days == 1 ? nextReviewTomorrow : nextReviewInDays(days);
    }
  }

  String countdownLabel(ReviewCountdown countdown) =>
      countdown.usesDays ? countDays(countdown.days) : countdown.clock;

  String planLabel(UserPlan plan) => switch (plan) {
    UserPlan.free => planFree,
    UserPlan.pro => planPro,
  };
}
