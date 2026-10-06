import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_transfer_app/features/files/data/datasources/file_remote_datasource.dart';

class DownloadProgressUpdate {
  final int downloadedBytes;
  final double speed;
  final int? eta;

  const DownloadProgressUpdate({
    required this.downloadedBytes,
    required this.speed,
    this.eta,
  });
}

class DownloadResult {
  final bool success;
  final String? localPath;
  final bool checksumVerified;
  final String? error;

  const DownloadResult({
    required this.success,
    this.localPath,
    required this.checksumVerified,
    this.error,
  });
}

class DownloadManager {
  final FileRemoteDataSource dataSource;
  final String baseUrl;
  bool _cancelled = false;
  bool _paused = false;

  DownloadManager({required this.dataSource, required this.baseUrl});

  void pause() => _paused = true;
  void cancel() => _cancelled = true;
  void resume() => _paused = false;

  Future<DownloadResult> download({
    required String fileId,
    required String fileName,
    required int totalBytes,
    String? existingLocalPath,
    required void Function(DownloadProgressUpdate) onProgress,
  }) async {
    final downloadsDir = await getApplicationDocumentsDirectory();
    final localPath =
        existingLocalPath ?? '${downloadsDir.path}/${_sanitize(fileName)}';
    final file = File(localPath);

    int startBytes = 0;
    if (await file.exists()) {
      startBytes = await file.length();
      // If already complete
      if (totalBytes > 0 && startBytes >= totalBytes) {
        return DownloadResult(
          success: true,
          localPath: localPath,
          checksumVerified: false,
        );
      }
    }

    final response = await dataSource.downloadFile(
      baseUrl,
      fileId,
      startBytes: startBytes > 0 ? startBytes : null,
    );

    if (response.statusCode == 416) {
      // Range not satisfiable - likely already downloaded
      return DownloadResult(
        success: true,
        localPath: localPath,
        checksumVerified: false,
      );
    }

    final sink = file.openWrite(
      mode: startBytes > 0 ? FileMode.append : FileMode.write,
    );

    try {
      final stream = response.data as ResponseBody;
      int downloaded = startBytes;
      DateTime chunkStart = DateTime.now();

      await for (final chunk in stream.stream) {
        if (_cancelled) {
          await sink.flush();
          await sink.close();
          return const DownloadResult(
            success: false,
            checksumVerified: false,
            error: 'Cancelled',
          );
        }

        while (_paused) {
          await Future.delayed(const Duration(milliseconds: 200));
          if (_cancelled) {
            await sink.flush();
            await sink.close();
            return const DownloadResult(
              success: false,
              checksumVerified: false,
              error: 'Cancelled',
            );
          }
        }

        sink.add(chunk);
        downloaded += chunk.length;

        final now = DateTime.now();
        final elapsed = now.difference(chunkStart).inMilliseconds / 1000.0;
        final speed = elapsed > 0 ? downloaded / elapsed : 0.0;
        final remainingBytes = totalBytes > 0 ? totalBytes - downloaded : 0;
        final eta = speed > 0 && remainingBytes > 0
            ? (remainingBytes / speed).round()
            : null;

        onProgress(DownloadProgressUpdate(
          downloadedBytes: downloaded,
          speed: speed,
          eta: eta,
        ));
      }

      await sink.flush();
    } finally {
      await sink.close();
    }

    return DownloadResult(
      success: true,
      localPath: localPath,
      checksumVerified: false,
    );
  }

  String _sanitize(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
