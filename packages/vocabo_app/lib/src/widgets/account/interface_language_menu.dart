import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/vocabo_ui.dart';

import 'package:vocabo_app/vocabo_app.dart';

/// Globe button that switches the interface language before signing in.
class InterfaceLanguageMenu extends ConsumerWidget {
  const InterfaceLanguageMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(interfaceLanguageProvider).valueOrNull ?? 'en';
    final current = interfaceLanguageByCode(code);

    return PopupMenuButton<String>(
      tooltip: '',
      color: VocaboColors.surfaceContainerLowest,
      onSelected: (selected) => ref
          .read(interfaceLanguageProvider.notifier)
          .select(selected, signedIn: false),
      itemBuilder: (_) => [
        for (final language in interfaceLanguages)
          CheckedPopupMenuItem(
            value: language.code,
            checked: language.code == code,
            child: Text(language.nativeName),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(VocaboSpacing.sm),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language,
              size: 18,
              color: VocaboColors.neutral700,
            ),
            const SizedBox(width: VocaboSpacing.xs),
            Text(
              current?.nativeName ?? 'English',
              style: VocaboTypography.bodySm.copyWith(
                color: VocaboColors.neutral700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
