import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  final int? statusCode;
  const NetworkFailure({required super.message, super.code, this.statusCode});

  @override
  List<Object?> get props => [message, code, statusCode];
}

class ServerNotFoundFailure extends Failure {
  const ServerNotFoundFailure({super.message = 'Server not found', super.code});
}

class ConnectionRefusedFailure extends Failure {
  const ConnectionRefusedFailure({
    super.message =
        'Unable to connect to the PC. Make sure the PC server is running and both devices are connected to the same network.',
    super.code,
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure(
      {super.message = 'Request timed out. Check your network connection.',
      super.code});
}

class FileNotFoundFailure extends Failure {
  const FileNotFoundFailure(
      {super.message = 'File not found on server.', super.code});
}

class FileTooLargeFailure extends Failure {
  const FileTooLargeFailure(
      {super.message = 'The selected file is larger than the server allows.',
      super.code});
}

class ChecksumMismatchFailure extends Failure {
  const ChecksumMismatchFailure({
    super.message =
        'File integrity check failed. The transferred file may be corrupted.',
    super.code,
  });
}

class UploadNotFoundFailure extends Failure {
  const UploadNotFoundFailure(
      {super.message = 'Upload session expired. Restarting upload.',
      super.code});
}

class TransferOutOfSyncFailure extends Failure {
  const TransferOutOfSyncFailure({
    super.message =
        'Transfer position is out of sync. Synchronizing transfer...',
    super.code,
  });
}

class InvalidUrlFailure extends Failure {
  const InvalidUrlFailure(
      {super.message =
          'Invalid server URL. Please check the IP address and port.',
      super.code});
}

class NoNetworkFailure extends Failure {
  const NoNetworkFailure(
      {super.message = 'No network connection available.', super.code});
}

class TooManyRequestsFailure extends Failure {
  const TooManyRequestsFailure({
    super.message = 'Too many requests. Please wait a moment and try again.',
    super.code,
  });
}

class ServerErrorFailure extends Failure {
  const ServerErrorFailure(
      {super.message = 'Server error. Please try again later.', super.code});
}

class ServiceUnavailableFailure extends Failure {
  const ServiceUnavailableFailure({
    super.message =
        'Server is temporarily unavailable. Please try again later.',
    super.code,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure(
      {super.message = 'An unexpected error occurred.', super.code});
}
