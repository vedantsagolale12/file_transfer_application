import 'package:equatable/equatable.dart';

abstract class FileEvent extends Equatable {
  const FileEvent();

  @override
  List<Object?> get props => [];
}

class LoadFilesEvent extends FileEvent {
  const LoadFilesEvent();
}

class RefreshFilesEvent extends FileEvent {
  const RefreshFilesEvent();
}

class SearchFilesEvent extends FileEvent {
  final String query;

  const SearchFilesEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

class DeleteFileEvent extends FileEvent {
  final String fileId;

  const DeleteFileEvent({required this.fileId});

  @override
  List<Object?> get props => [fileId];
}

class VerifyChecksumEvent extends FileEvent {
  final String fileId;

  const VerifyChecksumEvent({required this.fileId});

  @override
  List<Object?> get props => [fileId];
}

class SelectFileEvent extends FileEvent {
  final String fileId;

  const SelectFileEvent({required this.fileId});

  @override
  List<Object?> get props => [fileId];
}

class ClearSelectedFileEvent extends FileEvent {
  const ClearSelectedFileEvent();
}
