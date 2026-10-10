import 'package:flutter/widgets.dart';

/// Takes keyboard focus once mounted. Plain `autofocus` is skipped when the
/// previous screen still holds focus during an animated transition, which
/// would silently disable the flashcard shortcuts.
class ClaimFocus extends StatefulWidget {
  const ClaimFocus({
    super.key,
    required this.child,
    required this.onKeyEvent,
    this.debugLabel,
  });

  final Widget child;
  final FocusOnKeyEventCallback onKeyEvent;
  final String? debugLabel;

  @override
  State<ClaimFocus> createState() => _ClaimFocusState();
}

class _ClaimFocusState extends State<ClaimFocus> {
  late final FocusNode _focusNode = FocusNode(debugLabel: widget.debugLabel);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: widget.onKeyEvent,
      child: widget.child,
    );
  }
}
