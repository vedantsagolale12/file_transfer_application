import 'package:flutter_test/flutter_test.dart';
import 'package:file_transfer_app/features/files/domain/entities/file_entity.dart';

void main() {
  group('FileEntity', () {
    final testDate = DateTime(2025, 1, 1, 12, 0);

    test('identifies image files correctly', () {
      final file = FileEntity(
        id: 'img1',
        name: 'photo.jpg',
        size: 2048,
        contentType: 'image/jpeg',
        lastModified: testDate,
      );
      expect(file.isImage, isTrue);
      expect(file.isVideo, isFalse);
      expect(file.isPdf, isFalse);
    });

    test('identifies video files correctly', () {
      final file = FileEntity(
        id: 'vid1',
        name: 'movie.mp4',
        size: 10485760,
        contentType: 'video/mp4',
        lastModified: testDate,
      );
      expect(file.isVideo, isTrue);
      expect(file.isImage, isFalse);
    });

    test('identifies audio files correctly', () {
      final file = FileEntity(
        id: 'aud1',
        name: 'song.mp3',
        size: 5242880,
        contentType: 'audio/mpeg',
        lastModified: testDate,
      );
      expect(file.isAudio, isTrue);
    });

    test('identifies pdf files correctly', () {
      final file = FileEntity(
        id: 'doc1',
        name: 'report.pdf',
        size: 102400,
        contentType: 'application/pdf',
        lastModified: testDate,
      );
      expect(file.isPdf, isTrue);
    });

    test('identifies archive files correctly', () {
      final zip = FileEntity(
        id: 'arch1',
        name: 'data.zip',
        size: 102400,
        contentType: 'application/zip',
        lastModified: testDate,
      );
      expect(zip.isArchive, isTrue);
    });

    test('supports Equatable equality', () {
      final f1 = FileEntity(
        id: '1',
        name: 'test.txt',
        size: 100,
        contentType: 'text/plain',
        lastModified: testDate,
      );
      final f2 = FileEntity(
        id: '1',
        name: 'test.txt',
        size: 100,
        contentType: 'text/plain',
        lastModified: testDate,
      );
      expect(f1, equals(f2));
    });
  });
}
