import 'package:equatable/equatable.dart';
import 'package:file_transfer_app/features/files/domain/entities/file_entity.dart';

abstract class FileState extends Equatable {
  const FileState();

  @override
  List<Object?> get props => [];
}

class FileInitialState extends FileState {
  const FileInitialState();
}

class FileLoadingState extends FileState {
  const FileLoadingState();
}

class FileLoadedState extends FileState {
  final List<FileEntity> files;
  final List<FileEntity> filteredFiles;
  final String searchQuery;
  final FileEntity? selectedFile;
  final bool isDeleting;

  const FileLoadedState({
    required this.files,
    required this.filteredFiles,
    this.searchQuery = '',
    this.selectedFile,
    this.isDeleting = false,
  });

  FileLoadedState copyWith({
    List<FileEntity>? files,
    List<FileEntity>? filteredFiles,
    String? searchQuery,
    FileEntity? selectedFile,
    bool? isDeleting,
    bool clearSelectedFile = false,
  }) {
    return FileLoadedState(
      files: files ?? this.files,
      filteredFiles: filteredFiles ?? this.filteredFiles,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFile:
          clearSelectedFile ? null : (selectedFile ?? this.selectedFile),
      isDeleting: isDeleting ?? this.isDeleting,
    );
  }

  @override
  List<Object?> get props =>
      [files, filteredFiles, searchQuery, selectedFile, isDeleting];
}

class FileEmptyState extends FileState {
  const FileEmptyState();
}

class FileErrorState extends FileState {
  final String message;

  const FileErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}

class FileDeletedState extends FileState {
  const FileDeletedState();
}

class FileChecksumVerifyingState extends FileState {
  const FileChecksumVerifyingState();
}

class FileChecksumVerifiedState extends FileState {
  final bool matches;

  const FileChecksumVerifiedState({required this.matches});

  @override
  List<Object?> get props => [matches];
}
