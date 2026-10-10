import 'dart:async';

import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

class FlashcardCountdown extends StatefulWidget {
  const FlashcardCountdown({
    super.key,
    required this.target,
    required this.onFinished,
  });

  final DateTime target;
  final VoidCallback onFinished;

  @override
  State<FlashcardCountdown> createState() => _FlashcardCountdownState();
}

class _FlashcardCountdownState extends State<FlashcardCountdown> {
  Timer? _timer;
  late ReviewCountdown _countdown = ReviewCountdown.until(widget.target);
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant FlashcardCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      _finished = false;
      _tick();
    }
  }

  void _tick() {
    final next = ReviewCountdown.until(widget.target);
    setState(() => _countdown = next);

    if (next.isOver && !_finished) {
      _finished = true;
      _timer?.cancel();
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _countdown.label,
      style: VocaboTypography.displayMd.copyWith(
        color: VocaboColors.primary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
