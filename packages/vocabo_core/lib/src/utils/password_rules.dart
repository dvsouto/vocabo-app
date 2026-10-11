/// A rule shown next to the password field while the user types.
enum PasswordRequirement {
  minLength('At least $minPasswordLength characters'),
  letter('One letter'),
  number('One number');

  const PasswordRequirement(this.label);

  final String label;

  bool isMetBy(String password) => switch (this) {
    PasswordRequirement.minLength => password.length >= minPasswordLength,
    PasswordRequirement.letter => RegExp('[A-Za-z]').hasMatch(password),
    PasswordRequirement.number => RegExp(r'\d').hasMatch(password),
  };
}

const minPasswordLength = 6;

bool isValidPassword(String password) =>
    PasswordRequirement.values.every((rule) => rule.isMetBy(password));
