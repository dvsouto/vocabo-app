import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import 'package:vocabo_core/src/phone/country_names.dart';

/// A country in the phone picker: flag, name and calling code.
class PhoneCountry {
  const PhoneCountry({
    required this.isoCode,
    required this.name,
    required this.dialCode,
  });

  /// ISO 3166-1 alpha-2, e.g. `BR`.
  final String isoCode;
  final String name;

  /// Calling code without `+`, e.g. `55`.
  final String dialCode;

  /// Regional indicator emoji built from the ISO code.
  String get flag => String.fromCharCodes(
    isoCode.codeUnits.map((unit) => 0x1F1E6 + unit - 0x41),
  );

  bool matches(String query) {
    final normalized = query.trim().toLowerCase().replaceAll('+', '');
    if (normalized.isEmpty) return true;
    return name.toLowerCase().contains(normalized) ||
        isoCode.toLowerCase() == normalized ||
        dialCode.startsWith(normalized);
  }
}

/// Maximum digits in an E.164 number, calling code included.
const _maxE164Digits = 15;

final List<PhoneCountry> phoneCountries = () {
  final countries = [
    for (final iso in IsoCode.values)
      if (countryNames[iso.name] case final name?)
        PhoneCountry(
          isoCode: iso.name,
          name: name,
          dialCode: PhoneNumber(isoCode: iso, nsn: '').countryCode,
        ),
  ];
  countries.sort((a, b) => a.name.compareTo(b.name));
  return List<PhoneCountry>.unmodifiable(countries);
}();

PhoneCountry? phoneCountryByIso(String? isoCode) {
  if (isoCode == null) return null;
  final code = isoCode.toUpperCase();
  for (final country in phoneCountries) {
    if (country.isoCode == code) return country;
  }
  return null;
}

IsoCode? _isoCode(String isoCode) {
  for (final value in IsoCode.values) {
    if (value.name == isoCode.toUpperCase()) return value;
  }
  return null;
}

String phoneDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

/// Longest national number accepted for the country while typing.
int maxNationalDigits(String isoCode) {
  if (isoCode.toUpperCase() == 'BR') return 11;
  final country = phoneCountryByIso(isoCode);
  return _maxE164Digits - (country?.dialCode.length ?? 1);
}

/// Formats the national part as the user types. Brazil gets the area code
/// in parentheses, e.g. `(11) 98765-4321`; other countries use the
/// libphonenumber patterns once enough digits are typed.
String formatPhoneNational(String isoCode, String input) {
  final digits = phoneDigits(input);
  if (digits.isEmpty) return '';

  if (isoCode.toUpperCase() == 'BR') return _formatBrazil(digits);

  final iso = _isoCode(isoCode);
  if (iso == null) return digits;
  return PhoneNumber(isoCode: iso, nsn: digits).formatNsn();
}

String _formatBrazil(String digits) {
  final value = digits.length > 11 ? digits.substring(0, 11) : digits;
  if (value.length <= 2) return '($value';

  final area = value.substring(0, 2);
  final rest = value.substring(2);
  if (rest.length <= 4) return '($area) $rest';

  final split = rest.length == 9 ? 5 : 4;
  final end = rest.length > split ? split : rest.length;
  return '($area) ${rest.substring(0, end)}-${rest.substring(end)}';
}

PhoneNumber? _parse(String isoCode, String input) {
  final iso = _isoCode(isoCode);
  final digits = phoneDigits(input);
  if (iso == null || digits.isEmpty) return null;
  try {
    return PhoneNumber.parse(digits, callerCountry: iso);
  } catch (_) {
    return null;
  }
}

/// True when the number can receive SMS codes in that country.
bool isValidPhone(String isoCode, String input) {
  final phone = _parse(isoCode, input);
  return phone != null && phone.isValid(type: PhoneNumberType.mobile);
}

/// E.164 format, e.g. `+5511987654321`. Null when the number is invalid.
String? toE164(String isoCode, String input) {
  if (!isValidPhone(isoCode, input)) return null;
  return _parse(isoCode, input)!.international;
}

/// Splits an E.164 number back into country and national digits.
({String isoCode, String nationalNumber})? parseE164(
  String e164, {
  String? isoHint,
}) {
  try {
    final hint = isoHint == null ? null : _isoCode(isoHint);
    final phone = PhoneNumber.parse(e164, callerCountry: hint);
    return (isoCode: phone.isoCode.name, nationalNumber: phone.nsn);
  } catch (_) {
    return null;
  }
}

/// Display format with the calling code, e.g. `+55 (11) 98765-4321`.
String formatPhoneInternational(String e164, {String? isoHint}) {
  final parsed = parseE164(e164, isoHint: isoHint);
  if (parsed == null) return e164;
  final country = phoneCountryByIso(parsed.isoCode);
  final national = formatPhoneNational(parsed.isoCode, parsed.nationalNumber);
  return '+${country?.dialCode ?? ''} $national';
}
