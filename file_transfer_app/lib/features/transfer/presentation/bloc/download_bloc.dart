import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_transfer_app/core/utils/checksum_utils.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_bloc.dart';
import 'package:file_transfer_app/features/files/data/datasources/file_remote_datasource.dart';
import 'package:file_transfer_app/features/files/domain/entities/file_entity.dart';
import 'package:file_transfer_app/features/transfer/data/download_manager.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/download_event.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/download_state.dart';

class DownloadBloc extends Bloc<DownloadEvent, DownloadState> {
  final ConnectionBloc connectionBloc;
  final FileRemoteDataSource remoteDataSource;
  DownloadManager? _downloadManager;

  FileEntity? _pendingFile;
  String? _pendingLocalPath;
  int _resumeOffset = 0;

  DownloadBloc({
    required this.connectionBloc,
    required this.remoteDataSource,
  }) : super(const DownloadInitialState()) {
    on<StartDownloadEvent>(_onStartDownload);
    on<PauseDownloadEvent>(_onPause);
    on<ResumeDownloadEvent>(_onResume);
    on<CancelDownloadEvent>(_onCancel);
    on<RetryDownloadEvent>(_onRetry);
    on<DownloadProgressEvent>(_onProgress);
  }

  String? get _baseUrl => connectionBloc.currentBaseUrl;

  Future<void> _onStartDownload(
    StartDownloadEvent event,
    Emitter<DownloadState> emit,
  ) async {
    final baseUrl = _baseUrl;
    if (baseUrl == null) {
      emit(const DownloadFailedState(message: 'Not connected to server'));
      return;
    }

    _pendingFile = event.file;
    _pendingLocalPath = null;
    _resumeOffset = 0;

    emit(DownloadPreparingState(fileName: event.file.name));

    _downloadManager = DownloadManager(
      dataSource: remoteDataSource,
      baseUrl: baseUrl,
    );

    try {
      final result = await _downloadManager!.download(
        fileId: event.file.id,
        fileName: event.file.name,
        totalBytes: event.file.size,
        existingLocalPath: _pendingLocalPath,
        onProgress: (update) {
          if (!isClosed) {
            add(DownloadProgressEvent(
              downloadedBytes: update.downloadedBytes,
              speed: update.speed,
              eta: update.eta,
            ));
          }
        },
      );

      if (!result.success) {
        if (result.error == 'Cancelled') {
          emit(const DownloadCancelledState());
        } else {
          emit(DownloadFailedState(
            message: result.error ?? 'Download failed',
            fileName: event.file.name,
            fileId: event.file.id,
          ));
        }
        return;
      }

      _pendingLocalPath = result.localPath;

      // Checksum verification
      emit(DownloadVerifyingState(fileName: event.file.name));

      try {
        final localChecksum =
            await ChecksumUtils.computeSha256(result.localPath!);
        final serverChecksumResult =
            await remoteDataSource.getChecksum(baseUrl, event.file.id);
        final verified =
            ChecksumUtils.compareChecksums(localChecksum, serverChecksumResult);

        if (verified) {
          emit(DownloadCompletedState(
            fileName: event.file.name,
            localPath: result.localPath!,
            verified: true,
          ));
        } else {
          emit(DownloadIntegrityFailedState(fileName: event.file.name));
        }
      } catch (_) {
        // Checksum verification failed but download succeeded - still emit completed
        emit(DownloadCompletedState(
          fileName: event.file.name,
          localPath: result.localPath!,
          verified: false,
        ));
      }
    } catch (e) {
      emit(DownloadFailedState(
        message: e.toString(),
        fileName: event.file.name,
        fileId: event.file.id,
        resumeOffset: _resumeOffset,
        localPath: _pendingLocalPath,
      ));
    }
  }

  void _onProgress(
    DownloadProgressEvent event,
    Emitter<DownloadState> emit,
  ) {
    if (state is DownloadDownloadingState || state is DownloadPreparingState) {
      final currentState = state;
      int totalBytes = _pendingFile?.size ?? 0;
      String fileName = _pendingFile?.name ?? '';
      String localPath = _pendingLocalPath ?? '';

      if (currentState is DownloadDownloadingState) {
        totalBytes = currentState.totalBytes;
        fileName = currentState.fileName;
        localPath = currentState.localPath;
      }

      final progress =
          totalBytes > 0 ? event.downloadedBytes / totalBytes : 0.0;
      emit(DownloadDownloadingState(
        fileName: fileName,
        totalBytes: totalBytes,
        downloadedBytes: event.downloadedBytes,
        progress: progress,
        speed: event.speed,
        estimatedSecondsRemaining: event.eta,
        localPath: localPath,
      ));
    }
  }

  Future<void> _onPause(
      PauseDownloadEvent event, Emitter<DownloadState> emit) async {
    _downloadManager?.pause();
    if (state is DownloadDownloadingState) {
      final s = state as DownloadDownloadingState;
      _resumeOffset = s.downloadedBytes;
      _pendingLocalPath = s.localPath;
      emit(DownloadPausedState(
        fileName: s.fileName,
        totalBytes: s.totalBytes,
        downloadedBytes: s.downloadedBytes,
        progress: s.progress,
        localPath: s.localPath,
      ));
    }
  }

  Future<void> _onResume(
      ResumeDownloadEvent event, Emitter<DownloadState> emit) async {
    _downloadManager?.resume();
    if (state is DownloadPausedState && _pendingFile != null) {
      add(StartDownloadEvent(file: _pendingFile!));
    }
  }

  Future<void> _onCancel(
      CancelDownloadEvent event, Emitter<DownloadState> emit) async {
    _downloadManager?.cancel();
    emit(const DownloadCancelledState());
  }

  Future<void> _onRetry(
      RetryDownloadEvent event, Emitter<DownloadState> emit) async {
    if (_pendingFile != null) {
      add(StartDownloadEvent(file: _pendingFile!));
    } else {
      emit(const DownloadFailedState(message: 'No pending download to retry'));
    }
  }
}
