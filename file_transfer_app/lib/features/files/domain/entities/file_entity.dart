import 'package:equatable/equatable.dart';

class FileEntity extends Equatable {
  final String id;
  final String name;
  final int size;
  final String contentType;
  final DateTime lastModified;

  const FileEntity({
    required this.id,
    required this.name,
    required this.size,
    required this.contentType,
    required this.lastModified,
  });

  bool get isImage => contentType.startsWith('image/');
  bool get isVideo => contentType.startsWith('video/');
  bool get isAudio => contentType.startsWith('audio/');
  bool get isPdf => contentType == 'application/pdf';
  bool get isDocument =>
      contentType.contains('document') || contentType.contains('msword');
  bool get isArchive =>
      contentType.contains('zip') ||
      contentType.contains('rar') ||
      contentType.contains('tar');

  @override
  List<Object?> get props => [id, name, size, contentType, lastModified];
}
