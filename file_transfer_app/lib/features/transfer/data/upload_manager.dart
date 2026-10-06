import 'dart:async';
import 'dart:io';
import 'package:file_transfer_app/core/constants/api_constants.dart';
import 'package:file_transfer_app/features/files/data/datasources/file_remote_datasource.dart';

class UploadProgressUpdate {
  final int transferredBytes;
  final double speed;
  final int? eta;

  const UploadProgressUpdate({
    required this.transferredBytes,
    required this.speed,
    this.eta,
  });
}

class UploadResult {
  final bool success;
  final bool checksumVerified;
  final String? error;
  final String? serverFileId;
  final String? uploadId;

  const UploadResult({
    required this.success,
    required this.checksumVerified,
    this.error,
    this.serverFileId,
    this.uploadId,
  });
}

class ChunkUploadManager {
  final FileRemoteDataSource dataSource;
  final String baseUrl;
  bool _cancelled = false;
  bool _paused = false;
  final _pauseCompleter = Completer<void>();

  ChunkUploadManager({required this.dataSource, required this.baseUrl});

  void pause() => _paused = true;
  void cancel() => _cancelled = true;
  void resume() {
    _paused = false;
    if (!_pauseCompleter.isCompleted) _pauseCompleter.complete();
  }

  /// Upload using resumable API. Calls onProgress for each chunk completion.
  /// Returns (uploadId, serverResponse) on success.
  Future<UploadResult> uploadResumable({
    required String filePath,
    required String fileName,
    required int totalBytes,
    required String? existingUploadId,
    required int startOffset,
    required void Function(UploadProgressUpdate) onProgress,
  }) async {
    String uploadId;
    int offset = startOffset;

    if (existingUploadId != null && existingUploadId.isNotEmpty) {
      try {
        final progress =
            await dataSource.getUploadProgress(baseUrl, existingUploadId);
        uploadId = existingUploadId;
        offset = (progress['receivedBytes'] as int?) ?? startOffset;
      } catch (e) {
        final session = await dataSource.startResumableUpload(
            baseUrl, fileName, totalBytes);
        uploadId = session['uploadId'] as String;
        offset = 0;
      }
    } else {
      final session =
          await dataSource.startResumableUpload(baseUrl, fileName, totalBytes);
      uploadId = session['uploadId'] as String;
      offset = 0;
    }

    final file = File(filePath);
    final raf = await file.open();

    try {
      await raf.setPosition(offset);

      DateTime chunkStart = DateTime.now();
      int bytesAtChunkStart = offset;

      while (offset < totalBytes) {
        if (_cancelled) {
          await dataSource.cancelUpload(baseUrl, uploadId);
          return const UploadResult(
              success: false, checksumVerified: false, error: 'Cancelled');
        }

        while (_paused) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (_cancelled) {
            return const UploadResult(
                success: false, checksumVerified: false, error: 'Cancelled');
          }
        }

        final remaining = totalBytes - offset;
        final chunkLen = remaining < ApiConstants.chunkSize
            ? remaining
            : ApiConstants.chunkSize;
        final chunk = await raf.read(chunkLen);

        final response =
            await dataSource.uploadChunk(baseUrl, uploadId, chunk, offset);
        final receivedBytes =
            (response['receivedBytes'] as int?) ?? (offset + chunkLen);

        offset = receivedBytes;

        final now = DateTime.now();
        final elapsed = now.difference(chunkStart).inMilliseconds / 1000.0;
        final bytesDone = offset - bytesAtChunkStart;
        final speed = elapsed > 0 ? bytesDone / elapsed : 0.0;
        final remaining2 = totalBytes - offset;
        final eta = speed > 0 ? (remaining2 / speed).round() : null;

        onProgress(UploadProgressUpdate(
          transferredBytes: offset,
          speed: speed,
          eta: eta,
        ));

        if (response['complete'] == true) break;
      }
    } finally {
      await raf.close();
    }

    if (_cancelled) {
      return const UploadResult(
          success: false, checksumVerified: false, error: 'Cancelled');
    }

    return UploadResult(
        success: true, checksumVerified: false, uploadId: uploadId);
  }

  /// Upload using multipart for small files
  Future<UploadResult> uploadMultipart({
    required String filePath,
    required String fileName,
    required void Function(UploadProgressUpdate) onProgress,
  }) async {
    final file = File(filePath);
    final totalBytes = await file.length();

    // Stream-based progress for multipart
    onProgress(const UploadProgressUpdate(transferredBytes: 0, speed: 0));

    await dataSource.uploadFileMultipart(baseUrl, filePath, fileName);

    onProgress(UploadProgressUpdate(
      transferredBytes: totalBytes,
      speed: 0,
    ));

    return const UploadResult(success: true, checksumVerified: false);
  }
}
