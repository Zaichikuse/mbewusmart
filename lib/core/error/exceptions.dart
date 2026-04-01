class AppException implements Exception {
  final String message;
  final String? code;
  
  const AppException(this.message, {this.code});
  
  @override
  String toString() => message;
}

class ServerException extends AppException {
  const ServerException([String message = 'Server error']) : super(message);
}

class CacheException extends AppException {
  const CacheException([String message = 'Cache error']) : super(message);
}

class NetworkException extends AppException {
  const NetworkException([String message = 'Network error']) : super(message);
}

class ValidationException extends AppException {
  const ValidationException(String message) : super(message);
}

class AuthException extends AppException {
  const AuthException([String message = 'Auth error']) : super(message);
}

class PermissionException extends AppException {
  const PermissionException([String message = 'Permission error']) : super(message);
}

class StorageException extends AppException {
  const StorageException([String message = 'Storage error']) : super(message);
}