import 'package:flutter/material.dart';

import '../../theme/vocabo_colors.dart';
import '../../theme/vocabo_layout.dart';
import '../../theme/vocabo_radius.dart';
import '../../theme/vocabo_shadows.dart';
import '../../theme/vocabo_spacing.dart';
import '../../theme/vocabo_typography.dart';

/// Marks content shown inside a bottom sheet, so dialogs built for the
/// desktop drop their own frame and use the full width.
class VocaboSheetScope extends InheritedWidget {
  const VocaboSheetScope({super.key, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VocaboSheetScope>() != null;

  @override
  bool updateShouldNotify(VocaboSheetScope oldWidget) => false;
}

/// Opens [builder] as a bottom sheet on phones and as a dialog elsewhere.
/// Every modal of the app goes through here.
Future<T?> showVocaboModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  if (!context.isCompact) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      builder: builder,
    );
  }
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    isDismissible: dismissible,
    enableDrag: dismissible,
    backgroundColor: VocaboColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => VocaboSheetScope(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: builder(sheetContext),
      ),
    ),
  );
}

/// A [Dialog] on wide screens; inside a bottom sheet only its content.
class VocaboDialog extends StatelessWidget {
  const VocaboDialog({
    super.key,
    required this.child,
    this.backgroundColor,
    this.shape,
  });

  final Widget child;
  final Color? backgroundColor;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    if (VocaboSheetScope.of(context)) {
      return SafeArea(top: false, child: child);
    }
    return Dialog(
      backgroundColor: backgroundColor,
      shape: shape ?? RoundedRectangleBorder(borderRadius: VocaboRadius.lg),
      child: child,
    );
  }
}

/// An [AlertDialog] on wide screens; inside a bottom sheet the same title,
/// content and actions laid out for the sheet.
class VocaboAlertDialog extends StatelessWidget {
  const VocaboAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.backgroundColor,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (!VocaboSheetScope.of(context)) {
      return AlertDialog(
        backgroundColor: backgroundColor,
        title: title,
        content: content,
        actions: actions,
      );
    }

    final buttons = actions ?? const <Widget>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: VocaboSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) ...[
                  DefaultTextStyle(
                    style: VocaboTypography.titleLg.copyWith(
                      color: VocaboColors.onSurface,
                    ),
                    child: title!,
                  ),
                  const SizedBox(height: VocaboSpacing.md),
                ],
                if (content != null)
                  DefaultTextStyle(
                    style: VocaboTypography.bodyMd.copyWith(
                      color: VocaboColors.neutral700,
                    ),
                    child: content!,
                  ),
              ],
            ),
          ),
        ),
        if (buttons.isEmpty)
          const SafeArea(top: false, child: SizedBox(height: VocaboSpacing.lg))
        else
          VocaboModalActions(
            leading: buttons.length > 1 ? buttons.first : null,
            actions: buttons.length > 1 ? buttons.sublist(1) : buttons,
          ),
      ],
    );
  }
}

/// The action row of a modal: [leading] (usually Cancel) on the left and
/// the main [actions] on the right. In a bottom sheet it is pinned to the
/// bottom edge, above the safe area.
class VocaboModalActions extends StatelessWidget {
  const VocaboModalActions({super.key, this.leading, required this.actions});

  final Widget? leading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    if (!VocaboSheetScope.of(context)) {
      return Row(
        children: [
          ?leading,
          const Spacer(),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: VocaboSpacing.sm),
            actions[i],
          ],
        ],
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: VocaboColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: VocaboColors.surfaceContainerLow),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: VocaboSpacing.md),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            VocaboSpacing.lg,
            VocaboSpacing.md,
            VocaboSpacing.lg,
            0,
          ),
          child: Row(
            children: [
              ?leading,
              const Spacer(),
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: VocaboSpacing.sm),
                actions[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The frame of the large app modals (word detail, add word): a floating
/// card on wide screens, the bare content inside a bottom sheet.
class VocaboModalSurface extends StatelessWidget {
  const VocaboModalSurface({
    super.key,
    required this.width,
    required this.maxHeight,
    required this.child,
  });

  final double width;
  final double maxHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (VocaboSheetScope.of(context)) return child;
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: context.dialogWidth(width),
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: VocaboColors.surface,
            borderRadius: VocaboRadius.lg,
            boxShadow: [VocaboShadows.whisper],
          ),
          child: child,
        ),
      ),
    );
  }
}
