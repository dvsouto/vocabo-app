sealed class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message);
}

class BadRequestException extends AppException {
  const BadRequestException(super.message);
}

class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

class ConflictException extends AppException {
  const ConflictException(super.message);
}

class UnprocessableException extends AppException {
  const UnprocessableException(super.message);
}

class ServerException extends AppException {
  const ServerException(super.message);
}

class NetworkException extends AppException {
  const NetworkException(super.message);
}

class TranslationException extends AppException {
  const TranslationException(super.message);
}

class TranslationUnavailableException extends AppException {
  const TranslationUnavailableException(super.message);
}

class TranslationLanguageNotSupportedException extends AppException {
  const TranslationLanguageNotSupportedException(super.message);
}
