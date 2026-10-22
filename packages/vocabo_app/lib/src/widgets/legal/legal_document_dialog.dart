import 'package:flutter/material.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_l10n/vocabo_l10n.dart';
import 'package:vocabo_app/vocabo_app.dart';

Future<void> showLegalDocument(BuildContext context, LegalDocument document) {
  return showVocaboModal<void>(
    context: context,
    builder: (_) => _LegalDocumentDialog(document: document),
  );
}

class _LegalDocumentDialog extends StatelessWidget {
  const _LegalDocumentDialog({required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return VocaboDialog(
      backgroundColor: VocaboColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: VocaboRadius.lg),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: context.dialogWidth(620)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VocaboSpacing.xl,
                VocaboSpacing.lg,
                VocaboSpacing.md,
                VocaboSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          style: VocaboTypography.headlineSm,
                        ),
                        Text(
                          context.l10n.legalLastUpdated(document.updatedOn),
                          style: VocaboTypography.bodySm.copyWith(
                            color: VocaboColors.neutral,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.commonClose,
                    icon: const Icon(Icons.close),
                    color: VocaboColors.neutral,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  VocaboSpacing.xl,
                  VocaboSpacing.sm,
                  VocaboSpacing.xl,
                  VocaboSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (document.intro case final intro?) ...[
                      Text(
                        intro,
                        style: VocaboTypography.bodyMd.copyWith(
                          color: VocaboColors.neutral700,
                        ),
                      ),
                      const SizedBox(height: VocaboSpacing.lg),
                    ],
                    for (final section in document.sections) ...[
                      Text(section.heading, style: VocaboTypography.titleLg),
                      const SizedBox(height: VocaboSpacing.xs),
                      for (final paragraph in section.paragraphs)
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: VocaboSpacing.sm,
                          ),
                          child: Text(
                            paragraph,
                            style: VocaboTypography.bodyMd.copyWith(
                              color: VocaboColors.neutral700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      const SizedBox(height: VocaboSpacing.md),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
