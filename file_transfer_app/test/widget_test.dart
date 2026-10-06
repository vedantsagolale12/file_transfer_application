import 'package:flutter_test/flutter_test.dart';
import 'package:file_transfer_app/core/utils/format_utils.dart';
import 'package:file_transfer_app/core/utils/checksum_utils.dart';
import 'package:file_transfer_app/core/constants/api_constants.dart';
import 'package:file_transfer_app/features/connection/domain/entities/server_config.dart';

void main() {
  group('FormatUtils', () {
    test('formats bytes correctly', () {
      expect(FormatUtils.formatFileSize(500), '500 B');
      expect(FormatUtils.formatFileSize(1024), '1.0 KB');
      expect(FormatUtils.formatFileSize(1024 * 1024), '1.0 MB');
      expect(FormatUtils.formatFileSize(1024 * 1024 * 1024), '1.00 GB');
    });

    test('formats speed correctly', () {
      expect(FormatUtils.formatSpeed(500), '500 B/s');
      expect(FormatUtils.formatSpeed(1024 * 5), '5.0 KB/s');
      expect(FormatUtils.formatSpeed(1024 * 1024 * 10), '10.0 MB/s');
    });

    test('formats duration correctly', () {
      expect(FormatUtils.formatDuration(30), '30s');
      expect(FormatUtils.formatDuration(90), '1m 30s');
      expect(FormatUtils.formatDuration(3661), '1h 1m');
    });
  });

  group('ApiConstants', () {
    test('builds base URL correctly', () {
      expect(ApiConstants.baseUrl('http', '192.168.1.10', 8080),
          'http://192.168.1.10:8080');
      expect(ApiConstants.baseUrl('https', '192.168.1.10', 8443),
          'https://192.168.1.10:8443');
    });

    test('builds health URL correctly', () {
      expect(ApiConstants.healthUrl('http://192.168.1.10:8080'),
          'http://192.168.1.10:8080/api/v1/health');
    });

    test('builds files URL correctly', () {
      expect(ApiConstants.filesUrl('http://192.168.1.10:8080'),
          'http://192.168.1.10:8080/api/v1/files');
    });

    test('builds file download URL correctly', () {
      expect(
        ApiConstants.fileDownloadUrl('http://192.168.1.10:8080', 'abc123'),
        'http://192.168.1.10:8080/api/v1/files/abc123/download',
      );
    });

    test('builds checksum URL correctly', () {
      expect(
        ApiConstants.fileChecksumUrl('http://192.168.1.10:8080', 'abc123'),
        'http://192.168.1.10:8080/api/v1/files/abc123/checksum',
      );
    });

    test('builds upload URL correctly', () {
      expect(
        ApiConstants.uploadUrl('http://192.168.1.10:8080', 'upload-id-123'),
        'http://192.168.1.10:8080/api/v1/uploads/upload-id-123',
      );
    });
  });

  group('ServerConfig', () {
    test('constructs base URL correctly', () {
      const config = ServerConfig(
        host: '192.168.1.10',
        port: 8080,
        protocol: 'http',
      );
      expect(config.baseUrl, 'http://192.168.1.10:8080');
    });

    test('serializes and deserializes correctly', () {
      const config = ServerConfig(
        host: '192.168.1.10',
        port: 8080,
        protocol: 'http',
        displayName: 'My PC',
      );
      final json = config.toJson();
      final restored = ServerConfig.fromJson(json);
      expect(restored.host, config.host);
      expect(restored.port, config.port);
      expect(restored.protocol, config.protocol);
      expect(restored.displayName, config.displayName);
    });

    test('copyWith works correctly', () {
      const config = ServerConfig(host: '192.168.1.10', port: 8080);
      final updated = config.copyWith(port: 8443, protocol: 'https');
      expect(updated.host, '192.168.1.10');
      expect(updated.port, 8443);
      expect(updated.protocol, 'https');
    });
  });

  group('ChecksumUtils', () {
    test('compareChecksums is case insensitive', () {
      const a = 'ABCDEF1234';
      const b = 'abcdef1234';
      expect(ChecksumUtils.compareChecksums(a, b), true);
    });

    test('compareChecksums detects mismatch', () {
      const a = 'abc123';
      const b = 'abc124';
      expect(ChecksumUtils.compareChecksums(a, b), false);
    });

    test('chunk size is within bounds', () {
      expect(
          ApiConstants.chunkSize, lessThanOrEqualTo(ApiConstants.maxChunkSize));
      expect(ApiConstants.chunkSize, greaterThan(0));
    });
  });
}
