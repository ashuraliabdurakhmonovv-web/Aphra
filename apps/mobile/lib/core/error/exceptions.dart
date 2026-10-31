sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

final class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});
  final int? statusCode;
}

final class NetworkException extends AppException {
  const NetworkException([super.message = 'Network connection failed']);
}

final class CacheException extends AppException {
  const CacheException([super.message = 'Local cache operation failed']);
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Authentication required']);
}

final class ParsingException extends AppException {
  const ParsingException([super.message = 'Invalid response format']);
}
