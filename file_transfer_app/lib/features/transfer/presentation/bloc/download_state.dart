import 'package:equatable/equatable.dart';

abstract class DownloadState extends Equatable {
  const DownloadState();

  @override
  List<Object?> get props => [];
}

class DownloadInitialState extends DownloadState {
  const DownloadInitialState();
}

class DownloadPreparingState extends DownloadState {
  final String fileName;

  const DownloadPreparingState({required this.fileName});

  @override
  List<Object?> get props => [fileName];
}

class DownloadDownloadingState extends DownloadState {
  final String fileName;
  final int totalBytes;
  final int downloadedBytes;
  final double progress;
  final double speed;
  final int? estimatedSecondsRemaining;
  final String localPath;

  const DownloadDownloadingState({
    required this.fileName,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.progress,
    required this.speed,
    this.estimatedSecondsRemaining,
    required this.localPath,
  });

  @override
  List<Object?> get props => [
        fileName,
        totalBytes,
        downloadedBytes,
        progress,
        speed,
        estimatedSecondsRemaining,
        localPath,
      ];
}

class DownloadPausedState extends DownloadState {
  final String fileName;
  final int totalBytes;
  final int downloadedBytes;
  final double progress;
  final String localPath;

  const DownloadPausedState({
    required this.fileName,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.progress,
    required this.localPath,
  });

  @override
  List<Object?> get props =>
      [fileName, totalBytes, downloadedBytes, progress, localPath];
}

class DownloadVerifyingState extends DownloadState {
  final String fileName;

  const DownloadVerifyingState({required this.fileName});

  @override
  List<Object?> get props => [fileName];
}

class DownloadCompletedState extends DownloadState {
  final String fileName;
  final String localPath;
  final bool verified;

  const DownloadCompletedState({
    required this.fileName,
    required this.localPath,
    required this.verified,
  });

  @override
  List<Object?> get props => [fileName, localPath, verified];
}

class DownloadCancelledState extends DownloadState {
  const DownloadCancelledState();
}

class DownloadFailedState extends DownloadState {
  final String message;
  final String? fileName;
  final String? fileId;
  final int resumeOffset;
  final String? localPath;

  const DownloadFailedState({
    required this.message,
    this.fileName,
    this.fileId,
    this.resumeOffset = 0,
    this.localPath,
  });

  @override
  List<Object?> get props =>
      [message, fileName, fileId, resumeOffset, localPath];
}

class DownloadIntegrityFailedState extends DownloadState {
  final String fileName;

  const DownloadIntegrityFailedState({required this.fileName});

  @override
  List<Object?> get props => [fileName];
}
