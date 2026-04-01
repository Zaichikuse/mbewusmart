abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException: $message (code: $code)';
}

class NetworkException extends AppException {
  const NetworkException({
    super.message = 'Network error occurred',
    super.code,
    super.originalError,
  });
}

class ServerException extends AppException {
  final int? statusCode;

  const ServerException({
    super.message = 'Server error occurred',
    super.code,
    super.originalError,
    this.statusCode,
  });
}

class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache error occurred',
    super.code,
    super.originalError,
  });
}

class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException({
    super.message = 'Validation error occurred',
    super.code,
    super.originalError,
    this.fieldErrors,
  });
}

class LocationException extends AppException {
  const LocationException({
    super.message = 'Location error occurred',
    super.code,
    super.originalError,
  });
}

class AuthenticationException extends AppException {
  const AuthenticationException({
    super.message = 'Authentication error occurred',
    super.code,
    super.originalError,
  });
}
