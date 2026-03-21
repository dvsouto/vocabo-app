import 'package:flutter/material.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

class TrayWordItem extends StatelessWidget {
  const TrayWordItem({super.key, required this.vocabulary});

  final Vocabulary vocabulary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: VocaboSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                vocabulary.term,
                style: VocaboTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: VocaboColors.surfaceContainerLow,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.volume_up,
                  size: 14,
                  color: VocaboColors.primary,
                ),
              ),
            ],
          ),
          if (vocabulary.meaning != null) ...[
            const SizedBox(height: 4),
            Text(
              vocabulary.meaning!,
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
