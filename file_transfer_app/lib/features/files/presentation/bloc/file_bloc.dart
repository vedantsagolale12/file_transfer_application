import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_bloc.dart';
import 'package:file_transfer_app/features/files/domain/usecases/file_usecases.dart';
import 'package:file_transfer_app/features/files/presentation/bloc/file_event.dart';
import 'package:file_transfer_app/features/files/presentation/bloc/file_state.dart';

class FileBloc extends Bloc<FileEvent, FileState> {
  final GetFilesUseCase getFilesUseCase;
  final DeleteFileUseCase deleteFileUseCase;
  final GetChecksumUseCase getChecksumUseCase;
  final ConnectionBloc connectionBloc;

  FileBloc({
    required this.getFilesUseCase,
    required this.deleteFileUseCase,
    required this.getChecksumUseCase,
    required this.connectionBloc,
  }) : super(const FileInitialState()) {
    on<LoadFilesEvent>(_onLoadFiles);
    on<RefreshFilesEvent>(_onRefreshFiles);
    on<SearchFilesEvent>(_onSearchFiles);
    on<DeleteFileEvent>(_onDeleteFile);
    on<VerifyChecksumEvent>(_onVerifyChecksum);
    on<SelectFileEvent>(_onSelectFile);
    on<ClearSelectedFileEvent>(_onClearSelectedFile);
  }

  String? get _baseUrl => connectionBloc.currentBaseUrl;

  Future<void> _onLoadFiles(
      LoadFilesEvent event, Emitter<FileState> emit) async {
    final baseUrl = _baseUrl;
    if (baseUrl == null) {
      emit(const FileErrorState(message: 'Not connected to server'));
      return;
    }

    emit(const FileLoadingState());

    final result = await getFilesUseCase(baseUrl);
    result.fold(
      (failure) => emit(FileErrorState(message: failure.message)),
      (files) {
        if (files.isEmpty) {
          emit(const FileEmptyState());
        } else {
          emit(FileLoadedState(
            files: files,
            filteredFiles: files,
          ));
        }
      },
    );
  }

  Future<void> _onRefreshFiles(
      RefreshFilesEvent event, Emitter<FileState> emit) async {
    add(const LoadFilesEvent());
  }

  void _onSearchFiles(SearchFilesEvent event, Emitter<FileState> emit) {
    if (state is FileLoadedState) {
      final currentState = state as FileLoadedState;
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        emit(currentState.copyWith(
          filteredFiles: currentState.files,
          searchQuery: '',
        ));
      } else {
        final filtered = currentState.files
            .where((file) => file.name.toLowerCase().contains(query))
            .toList();
        emit(currentState.copyWith(
          filteredFiles: filtered,
          searchQuery: query,
        ));
      }
    }
  }

  Future<void> _onDeleteFile(
      DeleteFileEvent event, Emitter<FileState> emit) async {
    final baseUrl = _baseUrl;
    if (baseUrl == null) return;

    if (state is FileLoadedState) {
      final currentState = state as FileLoadedState;
      emit(currentState.copyWith(isDeleting: true));

      final result = await deleteFileUseCase(baseUrl, event.fileId);
      result.fold(
        (failure) {
          emit(currentState.copyWith(isDeleting: false));
          emit(FileErrorState(message: failure.message));
        },
        (_) {
          final updatedFiles =
              currentState.files.where((f) => f.id != event.fileId).toList();
          final updatedFiltered = currentState.filteredFiles
              .where((f) => f.id != event.fileId)
              .toList();
          emit(FileLoadedState(
            files: updatedFiles,
            filteredFiles: updatedFiltered,
            searchQuery: currentState.searchQuery,
          ));
        },
      );
    }
  }

  Future<void> _onVerifyChecksum(
      VerifyChecksumEvent event, Emitter<FileState> emit) async {
    final baseUrl = _baseUrl;
    if (baseUrl == null) return;

    emit(const FileChecksumVerifyingState());

    final result = await getChecksumUseCase(baseUrl, event.fileId);
    result.fold(
      (failure) => emit(FileErrorState(message: failure.message)),
      (_) => emit(const FileChecksumVerifiedState(matches: true)),
    );
  }

  void _onSelectFile(SelectFileEvent event, Emitter<FileState> emit) {
    if (state is FileLoadedState) {
      final currentState = state as FileLoadedState;
      final selectedFile = currentState.files.firstWhere(
        (f) => f.id == event.fileId,
        orElse: () => currentState.files.first,
      );
      emit(currentState.copyWith(selectedFile: selectedFile));
    }
  }

  void _onClearSelectedFile(
      ClearSelectedFileEvent event, Emitter<FileState> emit) {
    if (state is FileLoadedState) {
      final currentState = state as FileLoadedState;
      emit(currentState.copyWith(clearSelectedFile: true));
    }
  }
}
