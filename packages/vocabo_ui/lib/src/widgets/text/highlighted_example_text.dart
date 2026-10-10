import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';

/// Renders an example sentence in italics with the studied term in bold.
class HighlightedExampleText extends StatelessWidget {
  const HighlightedExampleText({
    super.key,
    required this.example,
    required this.term,
    this.quoted = true,
    this.fontSize = 14,
    this.color,
    this.textAlign,
  });

  final String example;
  final String term;
  final bool quoted;
  final double fontSize;
  final Color? color;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final text = quoted ? '"$example"' : example;
    final index = text.toLowerCase().indexOf(term.toLowerCase());
    final textColor = color ?? VocaboColors.onSurface;

    final baseStyle = GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      color: textColor,
      height: 1.5,
    );

    if (index == -1 || term.isEmpty) {
      return Text(text, style: baseStyle, textAlign: textAlign);
    }

    final boldStyle = baseStyle.copyWith(fontWeight: FontWeight.w700);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, index), style: baseStyle),
          TextSpan(
            text: text.substring(index, index + term.length),
            style: boldStyle,
          ),
          TextSpan(text: text.substring(index + term.length), style: baseStyle),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
