final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

/// Loose email check: something@domain.tld, without spaces.
bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());
