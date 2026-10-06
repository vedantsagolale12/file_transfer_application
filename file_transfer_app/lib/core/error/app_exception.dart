class AppException implements Exception {
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
  final int? statusCode;

  const NetworkException({
    required super.message,
    super.code,
    super.originalError,
    this.statusCode,
  });
}

class ServerNotFoundException extends AppException {
  const ServerNotFoundException(
      {super.message = 'Server not found', super.code, super.originalError});
}

class ConnectionRefusedException extends AppException {
  const ConnectionRefusedException(
      {super.message = 'Connection refused', super.code, super.originalError});
}

class TimeoutException extends AppException {
  const TimeoutException(
      {super.message = 'Request timed out', super.code, super.originalError});
}

class FileNotFoundException extends AppException {
  const FileNotFoundException(
      {super.message = 'File not found', super.code, super.originalError});
}

class FileTooLargeException extends AppException {
  const FileTooLargeException(
      {super.message = 'File is too large', super.code, super.originalError});
}

class ChecksumMismatchException extends AppException {
  final String expected;
  final String actual;

  const ChecksumMismatchException({
    super.message = 'Checksum mismatch - file integrity check failed',
    super.code,
    super.originalError,
    required this.expected,
    required this.actual,
  });
}

class UploadNotFoundException extends AppException {
  const UploadNotFoundException(
      {super.message = 'Upload session not found',
      super.code,
      super.originalError});
}

class TransferOutOfSyncException extends AppException {
  const TransferOutOfSyncException(
      {super.message = 'Transfer out of sync',
      super.code,
      super.originalError});
}

class InvalidUrlException extends AppException {
  const InvalidUrlException(
      {super.message = 'Invalid server URL', super.code, super.originalError});
}

class NoNetworkException extends AppException {
  const NoNetworkException(
      {super.message = 'No network connection',
      super.code,
      super.originalError});
}
