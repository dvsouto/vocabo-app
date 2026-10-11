sealed class AppException implements Exception {
  final String message;

  /// Stable machine readable reason sent by the API, e.g. `email_taken`.
  final String? code;

  /// Field validation errors, keyed by the API field name.
  final Map<String, List<String>> details;

  const AppException(this.message, {this.code, this.details = const {}});

  @override
  String toString() => '$runtimeType: $message';
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message, {super.code, super.details});
}

class ForbiddenException extends AppException {
  const ForbiddenException(super.message, {super.code, super.details});
}

class BadRequestException extends AppException {
  const BadRequestException(super.message, {super.code, super.details});
}

class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.code, super.details});
}

class ConflictException extends AppException {
  const ConflictException(super.message, {super.code, super.details});
}

class UnprocessableException extends AppException {
  const UnprocessableException(super.message, {super.code, super.details});
}

class TooManyRequestsException extends AppException {
  const TooManyRequestsException(
    super.message, {
    super.code,
    super.details,
    this.retryAfter,
  });

  final Duration? retryAfter;
}

class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.details});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.details});
}

class TranslationException extends AppException {
  const TranslationException(super.message, {super.code, super.details});
}

class TranslationUnavailableException extends AppException {
  const TranslationUnavailableException(
    super.message, {
    super.code,
    super.details,
  });
}

class TranslationLanguageNotSupportedException extends AppException {
  const TranslationLanguageNotSupportedException(
    super.message, {
    super.code,
    super.details,
  });
}
