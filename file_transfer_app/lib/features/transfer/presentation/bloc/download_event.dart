import 'package:equatable/equatable.dart';
import 'package:file_transfer_app/features/files/domain/entities/file_entity.dart';

abstract class DownloadEvent extends Equatable {
  const DownloadEvent();

  @override
  List<Object?> get props => [];
}

class StartDownloadEvent extends DownloadEvent {
  final FileEntity file;

  const StartDownloadEvent({required this.file});

  @override
  List<Object?> get props => [file];
}

class PauseDownloadEvent extends DownloadEvent {
  const PauseDownloadEvent();
}

class ResumeDownloadEvent extends DownloadEvent {
  const ResumeDownloadEvent();
}

class CancelDownloadEvent extends DownloadEvent {
  const CancelDownloadEvent();
}

class RetryDownloadEvent extends DownloadEvent {
  const RetryDownloadEvent();
}

class DownloadProgressEvent extends DownloadEvent {
  final int downloadedBytes;
  final double speed;
  final int? eta;

  const DownloadProgressEvent({
    required this.downloadedBytes,
    required this.speed,
    this.eta,
  });

  @override
  List<Object?> get props => [downloadedBytes, speed, eta];
}
