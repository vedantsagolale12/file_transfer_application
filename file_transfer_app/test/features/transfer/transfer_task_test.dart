import 'package:flutter_test/flutter_test.dart';
import 'package:file_transfer_app/core/enums/transfer_status.dart';
import 'package:file_transfer_app/features/transfer/domain/entities/transfer_task.dart';

void main() {
  group('TransferTask', () {
    final now = DateTime(2025, 1, 1);

    test('computes progress correctly', () {
      final task = TransferTask(
        id: 't1',
        fileName: 'test.zip',
        totalBytes: 1000,
        transferredBytes: 500,
        type: TransferType.upload,
        createdAt: now,
      );
      expect(task.progress, 0.5);
    });

    test('handles zero totalBytes safely', () {
      final task = TransferTask(
        id: 't1',
        fileName: 'test.zip',
        totalBytes: 0,
        transferredBytes: 0,
        type: TransferType.upload,
        createdAt: now,
      );
      expect(task.progress, 0.0);
    });

    test('serializes to and from JSON', () {
      final task = TransferTask(
        id: 't1',
        fileName: 'test.zip',
        totalBytes: 2000,
        transferredBytes: 1000,
        type: TransferType.upload,
        status: TransferStatus.running,
        speed: 102400.0,
        createdAt: now,
      );

      final json = task.toJson();
      final restored = TransferTask.fromJson(json);

      expect(restored.id, task.id);
      expect(restored.fileName, task.fileName);
      expect(restored.totalBytes, task.totalBytes);
      expect(restored.transferredBytes, task.transferredBytes);
      expect(restored.type, task.type);
      expect(restored.status, task.status);
    });

    test('copyWith updates specified fields', () {
      final task = TransferTask(
        id: 't1',
        fileName: 'test.zip',
        totalBytes: 2000,
        transferredBytes: 500,
        type: TransferType.download,
        status: TransferStatus.queued,
        createdAt: now,
      );

      final updated = task.copyWith(
        transferredBytes: 1500,
        status: TransferStatus.running,
        speed: 50000.0,
      );

      expect(updated.transferredBytes, 1500);
      expect(updated.status, TransferStatus.running);
      expect(updated.speed, 50000.0);
      expect(updated.id, task.id); // unchanged
    });
  });
}
