import 'package:flutter/foundation.dart';
import 'app_exceptions.dart';

class ErrorHandler {
  static String handle(dynamic error) {
    if (kDebugMode) {
      print('Error: $error');
      print('StackTrace: ${StackTrace.current}');
    }

    if (error is AppException) {
      return error.message;
    }

    if (error is NetworkException) {
      return 'No internet connection. Please check your network.';
    }

    if (error is ServerException) {
      return _handleServerError(error);
    }

    if (error is CacheException) {
      return 'Failed to save data locally. Please try again.';
    }

    if (error is ValidationException) {
      return error.message;
    }

    if (error is LocationException) {
      return 'Could not get your location. Please enable GPS.';
    }

    if (error is AuthenticationException) {
      return 'Authentication failed. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  static String _handleServerError(ServerException error) {
    final statusCode = error.statusCode;

    if (statusCode == null) {
      return 'Server is busy. Please try again later.';
    }

    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please login again.';
      case 403:
        return 'Access denied.';
      case 404:
        return 'Resource not found.';
      case 408:
        return 'Request timed out. Please try again.';
      case 429:
        return 'Too many requests. Please wait a moment.';
      case 500:
        return 'Server maintenance. Please try again later.';
      case 502:
      case 503:
      case 504:
        return 'Server unavailable. Please try again later.';
      default:
        return 'Server error ($statusCode). Please try again.';
    }
  }

  static bool isNetworkError(dynamic error) {
    return error is NetworkException || 
           error.toString().contains('SocketException') ||
           error.toString().contains('TimeoutException');
  }

  static bool isServerError(dynamic error) {
    return error is ServerException;
  }

  static bool isCacheError(dynamic error) {
    return error is CacheException;
  }
}
