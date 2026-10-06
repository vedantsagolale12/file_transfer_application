import 'package:flutter_test/flutter_test.dart';
import 'package:file_transfer_app/core/error/app_exception.dart';
import 'package:file_transfer_app/core/error/failure.dart';

void main() {
  group('AppException hierarchy', () {
    test('NetworkException holds status code and message', () {
      const exception = NetworkException(message: 'Not found', statusCode: 404);
      expect(exception.message, 'Not found');
      expect(exception.statusCode, 404);
    });

    test('ConnectionRefusedException has correct default message', () {
      const exception = ConnectionRefusedException();
      expect(exception.message, 'Connection refused');
    });

    test('TimeoutException has correct message', () {
      const exception = TimeoutException();
      expect(exception.message, 'Request timed out');
    });

    test('FileNotFoundException has correct default message', () {
      const exception = FileNotFoundException();
      expect(exception.message, 'File not found');
    });

    test('FileTooLargeException has correct default message', () {
      const exception = FileTooLargeException();
      expect(exception.message, 'File is too large');
    });

    test('ChecksumMismatchException holds expected and actual checksums', () {
      const exception = ChecksumMismatchException(
        expected: 'abc123expected',
        actual: 'abc123actual',
      );
      expect(exception.expected, 'abc123expected');
      expect(exception.actual, 'abc123actual');
      expect(
          exception.message, 'Checksum mismatch - file integrity check failed');
    });
  });

  group('Failure hierarchy', () {
    test('ConnectionRefusedFailure provides user-friendly guidance', () {
      const failure = ConnectionRefusedFailure();
      expect(
        failure.message,
        contains(
            'Unable to connect to the PC. Make sure the PC server is running'),
      );
    });

    test('TimeoutFailure provides user-friendly guidance', () {
      const failure = TimeoutFailure();
      expect(failure.message, contains('Request timed out'));
    });

    test('FileTooLargeFailure provides clear message', () {
      const failure = FileTooLargeFailure();
      expect(failure.message, contains('larger than the server allows'));
    });

    test('TransferOutOfSyncFailure provides recovery message', () {
      const failure = TransferOutOfSyncFailure();
      expect(failure.message, contains('Transfer position is out of sync'));
    });

    test('TooManyRequestsFailure provides rate limit message', () {
      const failure = TooManyRequestsFailure();
      expect(failure.message, contains('Too many requests'));
    });

    test('Failures support Equatable equality', () {
      const f1 = ConnectionRefusedFailure();
      const f2 = ConnectionRefusedFailure();
      expect(f1, equals(f2));
    });
  });
}
