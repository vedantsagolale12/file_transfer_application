import 'package:equatable/equatable.dart';

abstract class UploadEvent extends Equatable {
  const UploadEvent();

  @override
  List<Object?> get props => [];
}

class SelectUploadFileEvent extends UploadEvent {
  const SelectUploadFileEvent();
}

class StartUploadEvent extends UploadEvent {
  final String filePath;
  final String fileName;
  final int fileSize;

  const StartUploadEvent({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
  });

  @override
  List<Object?> get props => [filePath, fileName, fileSize];
}

class PauseUploadEvent extends UploadEvent {
  const PauseUploadEvent();
}

class ResumeUploadEvent extends UploadEvent {
  const ResumeUploadEvent();
}

class CancelUploadEvent extends UploadEvent {
  const CancelUploadEvent();
}

class RetryUploadEvent extends UploadEvent {
  const RetryUploadEvent();
}

class UploadProgressEvent extends UploadEvent {
  final int transferredBytes;
  final double speed;
  final int? eta;

  const UploadProgressEvent({
    required this.transferredBytes,
    required this.speed,
    this.eta,
  });

  @override
  List<Object?> get props => [transferredBytes, speed, eta];
}
