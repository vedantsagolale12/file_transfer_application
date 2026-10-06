import 'package:flutter_test/flutter_test.dart';
import 'package:file_transfer_app/core/constants/api_constants.dart';

void main() {
  group('Chunk Calculations', () {
    test('chunk size is exactly 5 MB as required', () {
      expect(ApiConstants.chunkSize, 5 * 1024 * 1024);
    });

    test('max chunk size does not exceed 10 MB backend limit', () {
      expect(ApiConstants.maxChunkSize, 10 * 1024 * 1024);
      expect(
          ApiConstants.chunkSize, lessThanOrEqualTo(ApiConstants.maxChunkSize));
    });

    test('small file threshold is 10 MB', () {
      expect(ApiConstants.smallFileThreshold, 10 * 1024 * 1024);
    });

    test('computes correct chunk count for arbitrary file size', () {
      const fileSize = 23 * 1024 * 1024; // 23 MB
      const chunkSize = ApiConstants.chunkSize; // 5 MB

      const fullChunks = fileSize ~/ chunkSize; // 4
      const remainingBytes = fileSize % chunkSize; // 3 MB

      expect(fullChunks, 4);
      expect(remainingBytes, 3 * 1024 * 1024);
      const totalChunks = (fileSize + chunkSize - 1) ~/ chunkSize;
      expect(totalChunks, 5);
    });

    test('resume offset calculation correctly advances', () {
      int offset = 0;
      const totalBytes = 12 * 1024 * 1024; // 12 MB
      const chunkSize = ApiConstants.chunkSize; // 5 MB

      // Chunk 1
      offset += chunkSize; // 5 MB
      expect(offset, 5 * 1024 * 1024);

      // Chunk 2
      offset += chunkSize; // 10 MB
      expect(offset, 10 * 1024 * 1024);

      // Last chunk: remaining bytes
      final remaining = totalBytes - offset;
      expect(remaining, 2 * 1024 * 1024);
      offset += remaining;
      expect(offset, totalBytes);
    });
  });
}
