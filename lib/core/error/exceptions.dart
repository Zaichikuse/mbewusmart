class AppException implements Exception {
  final String message;
  final String? code;
  
  const AppException(this.message, {this.code});
  
  @override
  String toString() => message;
}

class ServerException extends AppException {
  const ServerException([super.message = 'Server error']);
}

class CacheException extends AppException {
  const CacheException([super.message = 'Cache error']);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network error']);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class AuthException extends AppException {
  const AuthException([super.message = 'Auth error']);
}

class PermissionException extends AppException {
  const PermissionException([super.message = 'Permission error']);
}

class StorageException extends AppException {
  const StorageException([super.message = 'Storage error']);
}