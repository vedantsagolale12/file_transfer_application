import 'package:file_transfer_app/core/error/failure.dart';
import 'package:file_transfer_app/features/connection/domain/repositories/connection_repository.dart';
import 'package:file_transfer_app/features/files/domain/entities/file_entity.dart';
import 'package:file_transfer_app/features/files/domain/repositories/file_repository.dart';

class GetFilesUseCase {
  final FileRepository repository;

  GetFilesUseCase({required this.repository});

  Future<Either<Failure, List<FileEntity>>> call(String baseUrl) async {
    return repository.getFiles(baseUrl);
  }
}

class GetFileMetadataUseCase {
  final FileRepository repository;

  GetFileMetadataUseCase({required this.repository});

  Future<Either<Failure, FileEntity>> call(
      String baseUrl, String fileId) async {
    return repository.getFileMetadata(baseUrl, fileId);
  }
}

class DeleteFileUseCase {
  final FileRepository repository;

  DeleteFileUseCase({required this.repository});

  Future<Either<Failure, void>> call(String baseUrl, String fileId) async {
    return repository.deleteFile(baseUrl, fileId);
  }
}

class GetChecksumUseCase {
  final FileRepository repository;

  GetChecksumUseCase({required this.repository});

  Future<Either<Failure, String>> call(String baseUrl, String fileId) async {
    return repository.getChecksum(baseUrl, fileId);
  }
}
