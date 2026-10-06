import 'package:equatable/equatable.dart';

abstract class UploadState extends Equatable {
  const UploadState();

  @override
  List<Object?> get props => [];
}

class UploadInitialState extends UploadState {
  const UploadInitialState();
}

class UploadPreparingState extends UploadState {
  final String fileName;

  const UploadPreparingState({required this.fileName});

  @override
  List<Object?> get props => [fileName];
}

class UploadStartingState extends UploadState {
  final String fileName;

  const UploadStartingState({required this.fileName});

  @override
  List<Object?> get props => [fileName];
}

class UploadUploadingState extends UploadState {
  final String fileName;
  final int totalBytes;
  final int transferredBytes;
  final double progress;
  final double speed;
  final int? estimatedSecondsRemaining;
  final String? uploadId;

  const UploadUploadingState({
    required this.fileName,
    required this.totalBytes,
    required this.transferredBytes,
    required this.progress,
    required this.speed,
    this.estimatedSecondsRemaining,
    this.uploadId,
  });

  @override
  List<Object?> get props => [
        fileName,
        totalBytes,
        transferredBytes,
        progress,
        speed,
        estimatedSecondsRemaining,
        uploadId,
      ];
}

class UploadPausedState extends UploadState {
  final String fileName;
  final int totalBytes;
  final int transferredBytes;
  final double progress;
  final String? uploadId;

  const UploadPausedState({
    required this.fileName,
    required this.totalBytes,
    required this.transferredBytes,
    required this.progress,
    this.uploadId,
  });

  @override
  List<Object?> get props =>
      [fileName, totalBytes, transferredBytes, progress, uploadId];
}

class UploadVerifyingState extends UploadState {
  final String fileName;

  const UploadVerifyingState({required this.fileName});

  @override
  List<Object?> get props => [fileName];
}

class UploadCompletedState extends UploadState {
  final String fileName;
  final bool verified;

  const UploadCompletedState({required this.fileName, required this.verified});

  @override
  List<Object?> get props => [fileName, verified];
}

class UploadCancelledState extends UploadState {
  const UploadCancelledState();
}

class UploadFailedState extends UploadState {
  final String message;
  final String? fileName;
  final String? filePath;
  final int? fileSize;
  final String? uploadId;
  final int resumeOffset;

  const UploadFailedState({
    required this.message,
    this.fileName,
    this.filePath,
    this.fileSize,
    this.uploadId,
    this.resumeOffset = 0,
  });

  @override
  List<Object?> get props =>
      [message, fileName, filePath, fileSize, uploadId, resumeOffset];
}

class UploadIntegrityFailedState extends UploadState {
  final String fileName;

  const UploadIntegrityFailedState({required this.fileName});

  @override
  List<Object?> get props => [fileName];
}
