import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vocabo_desktop/src/l10n/l10n.dart';

/// "Updated today at 9:41", or with the date when it was another day.
String updatedAtLabel(BuildContext context, DateTime moment) {
  final local = moment.toLocal();
  final now = DateTime.now();
  final time = MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(local));
  final sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
  if (sameDay) return context.l10n.commonUpdatedToday(time);

  final date = DateFormat.MMMd(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(local);
  return context.l10n.commonUpdatedOn(date, time);
}
