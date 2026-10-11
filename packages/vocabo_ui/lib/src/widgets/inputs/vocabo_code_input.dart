import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_spacing.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';

/// Keeps only digits, so a pasted "Your code is 123-456" still fills the
/// slots, and caps the value at [length].
class CodeDigitsFormatter extends TextInputFormatter {
  const CodeDigitsFormatter(this.length);

  final int length;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > length) digits = digits.substring(0, length);
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

/// One time code entry: one slot per digit over an underline.
///
/// A single text field sits under the slots, so typing, pasting and the
/// macOS suggestion of codes received by SMS (one time code autofill) all
/// work as in a native field.
class VocaboCodeInput extends StatefulWidget {
  const VocaboCodeInput({
    super.key,
    this.controller,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.autofocus = true,
  });

  final TextEditingController? controller;
  final int length;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final bool enabled;
  final bool autofocus;

  @override
  State<VocaboCodeInput> createState() => _VocaboCodeInputState();
}

class _VocaboCodeInputState extends State<VocaboCodeInput> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  final _focusNode = FocusNode(debugLabel: 'vocabo-code-input');

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
    _focusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _onChanged(String value) {
    widget.onChanged?.call(value);
    if (value.length == widget.length) widget.onCompleted?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final error = Theme.of(context).colorScheme.error;
    final hasError = widget.errorText != null;
    final code = _controller.text;
    final focused = _focusNode.hasFocus;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64,
          child: Stack(
            children: [
              Positioned.fill(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  keyboardType: TextInputType.number,
                  inputFormatters: [CodeDigitsFormatter(widget.length)],
                  onChanged: _onChanged,
                  showCursor: false,
                  style: const TextStyle(color: Colors.transparent),
                  cursorColor: Colors.transparent,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    counterText: '',
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Row(
                    children: [
                      for (var i = 0; i < widget.length; i++) ...[
                        if (i > 0) const SizedBox(width: VocaboSpacing.sm),
                        Expanded(
                          child: _CodeSlot(
                            digit: i < code.length ? code[i] : null,
                            active:
                                focused &&
                                (i == code.length ||
                                    (code.length == widget.length &&
                                        i == widget.length - 1)),
                            color: hasError ? error : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: VocaboSpacing.sm),
          Text(
            widget.errorText!,
            style: VocaboTypography.bodySm.copyWith(color: error),
          ),
        ],
      ],
    );
  }
}

class _CodeSlot extends StatelessWidget {
  const _CodeSlot({required this.digit, required this.active, this.color});

  final String? digit;
  final bool active;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final lineColor =
        color ??
        (active
            ? VocaboColors.primary
            : digit != null
            ? VocaboColors.onSurface
            : VocaboColors.neutral200);

    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: lineColor, width: active ? 3 : 2),
        ),
      ),
      child: Text(
        digit ?? '',
        style: VocaboTypography.headlineSm.copyWith(
          color: color ?? VocaboColors.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
