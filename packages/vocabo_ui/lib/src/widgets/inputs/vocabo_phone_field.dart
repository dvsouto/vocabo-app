import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vocabo_core/vocabo_core.dart';
import 'package:vocabo_ui/src/theme/vocabo_colors.dart';
import 'package:vocabo_ui/src/theme/vocabo_radius.dart';
import 'package:vocabo_ui/src/theme/vocabo_spacing.dart';
import 'package:vocabo_ui/src/theme/vocabo_typography.dart';
import 'package:vocabo_ui/src/widgets/inputs/vocabo_search_field.dart';
import 'package:vocabo_ui/src/widgets/inputs/vocabo_text_field.dart';

/// Formats the national number of [isoCode] as the user types, e.g.
/// `(11) 98765-4321` for Brazil.
class PhoneNationalFormatter extends TextInputFormatter {
  const PhoneNationalFormatter(this.isoCode);

  final String isoCode;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = phoneDigits(newValue.text);

    // Backspace over a separator removes the digit before it instead.
    final deletedSeparator =
        newValue.text.length < oldValue.text.length &&
        digits == phoneDigits(oldValue.text);
    if (deletedSeparator && digits.isNotEmpty) {
      digits = digits.substring(0, digits.length - 1);
    }

    final max = maxNationalDigits(isoCode);
    if (digits.length > max) digits = digits.substring(0, max);

    final text = formatPhoneNational(isoCode, digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Phone input with a country picker (flag and calling code) and a
/// national number formatted as it is typed.
class VocaboPhoneField extends StatelessWidget {
  const VocaboPhoneField({
    super.key,
    required this.country,
    required this.onCountryChanged,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.hint = 'Phone number',
    this.countryPickerTitle = 'Country',
    this.countrySearchHint = 'Search country or code',
    this.noCountryFoundText = 'No country found',
  });

  final PhoneCountry country;
  final ValueChanged<PhoneCountry> onCountryChanged;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;

  /// Placeholder of the number, except for Brazil, which shows a sample.
  final String hint;
  final String countryPickerTitle;
  final String countrySearchHint;
  final String noCountryFoundText;

  Future<void> _pickCountry(BuildContext context) async {
    final picked = await showDialog<PhoneCountry>(
      context: context,
      builder: (_) => _CountryPickerDialog(
        selected: country,
        title: countryPickerTitle,
        searchHint: countrySearchHint,
        emptyText: noCountryFoundText,
      ),
    );
    if (picked == null || picked.isoCode == country.isoCode) return;

    controller.text = formatPhoneNational(picked.isoCode, controller.text);
    onCountryChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return VocaboTextField(
      controller: controller,
      hint: country.isoCode == 'BR' ? '(11) 98765-4321' : hint,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      inputFormatters: [PhoneNationalFormatter(country.isoCode)],
      errorText: errorText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enabled: enabled,
      autofocus: autofocus,
      prefix: Padding(
        padding: const EdgeInsets.only(left: VocaboSpacing.xs),
        child: TextButton(
          onPressed: enabled ? () => _pickCountry(context) : null,
          style: TextButton.styleFrom(
            foregroundColor: VocaboColors.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: VocaboSpacing.sm),
            minimumSize: const Size(44, 36),
            enabledMouseCursor: SystemMouseCursors.click,
            shape: RoundedRectangleBorder(borderRadius: VocaboRadius.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(country.flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                '+${country.dialCode}',
                style: VocaboTypography.bodyMd.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.expand_more,
                size: 18,
                color: VocaboColors.neutral,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryPickerDialog extends StatefulWidget {
  const _CountryPickerDialog({
    required this.selected,
    required this.title,
    required this.searchHint,
    required this.emptyText,
  });

  final PhoneCountry selected;
  final String title;
  final String searchHint;
  final String emptyText;

  @override
  State<_CountryPickerDialog> createState() => _CountryPickerDialogState();
}

class _CountryPickerDialogState extends State<_CountryPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final countries = phoneCountries.where((c) => c.matches(_query)).toList();

    return Dialog(
      backgroundColor: VocaboColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: VocaboRadius.lg),
      child: SizedBox(
        width: 380,
        height: 480,
        child: Padding(
          padding: const EdgeInsets.all(VocaboSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: VocaboTypography.titleLg),
              const SizedBox(height: VocaboSpacing.md),
              VocaboSearchField(
                hint: widget.searchHint,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: VocaboSpacing.sm),
              Expanded(
                child: countries.isEmpty
                    ? Center(
                        child: Text(
                          widget.emptyText,
                          style: VocaboTypography.bodySm.copyWith(
                            color: VocaboColors.neutral,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: countries.length,
                        itemBuilder: (context, index) {
                          final country = countries[index];
                          final selected =
                              country.isoCode == widget.selected.isoCode;
                          return ListTile(
                            dense: true,
                            selected: selected,
                            selectedTileColor: VocaboColors.primary50,
                            mouseCursor: SystemMouseCursors.click,
                            shape: RoundedRectangleBorder(
                              borderRadius: VocaboRadius.sm,
                            ),
                            leading: Text(
                              country.flag,
                              style: const TextStyle(fontSize: 20),
                            ),
                            title: Text(
                              country.name,
                              style: VocaboTypography.bodyMd,
                            ),
                            trailing: Text(
                              '+${country.dialCode}',
                              style: VocaboTypography.bodySm.copyWith(
                                color: VocaboColors.neutral,
                              ),
                            ),
                            onTap: () => Navigator.of(context).pop(country),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
