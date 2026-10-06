import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class FileUtils {
  FileUtils._();

  static String getFileExtension(String fileName) {
    return path.extension(fileName).toLowerCase();
  }

  static String getMimeType(String fileName) {
    return lookupMimeType(fileName) ?? 'application/octet-stream';
  }

  static bool isImageFile(String fileName) {
    final mime = getMimeType(fileName);
    return mime.startsWith('image/');
  }

  static bool isVideoFile(String fileName) {
    final mime = getMimeType(fileName);
    return mime.startsWith('video/');
  }

  static bool isAudioFile(String fileName) {
    final mime = getMimeType(fileName);
    return mime.startsWith('audio/');
  }

  static bool isPdfFile(String fileName) {
    return getMimeType(fileName) == 'application/pdf';
  }

  static bool isDocumentFile(String fileName) {
    final mime = getMimeType(fileName);
    return mime.contains('document') ||
        mime.contains('msword') ||
        mime.contains('spreadsheet') ||
        mime.contains('presentation');
  }

  static bool isArchiveFile(String fileName) {
    final mime = getMimeType(fileName);
    return mime.contains('zip') ||
        mime.contains('rar') ||
        mime.contains('tar') ||
        mime.contains('7z') ||
        mime.contains('gzip');
  }

  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  static String sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
