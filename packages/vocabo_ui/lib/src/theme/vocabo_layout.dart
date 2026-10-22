import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../widgets/modal/vocabo_modal.dart';

/// Breakpoint below which the app uses its phone layout: bottom navigation,
/// full-width sheets and stacked rows.
const vocaboCompactBreakpoint = 720.0;

extension VocaboLayout on BuildContext {
  /// True on phones and narrow windows.
  bool get isCompact => MediaQuery.sizeOf(this).width < vocaboCompactBreakpoint;

  /// The width of a dialog that wants [preferred] but must fit the screen;
  /// inside a bottom sheet, the full width.
  double dialogWidth(double preferred) => VocaboSheetScope.of(this)
      ? double.infinity
      : math.min(preferred, MediaQuery.sizeOf(this).width - 2 * 16);
}
