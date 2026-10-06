import 'package:file_transfer_app/core/error/failure.dart';
import 'package:file_transfer_app/features/files/domain/entities/file_entity.dart';
import 'package:file_transfer_app/features/connection/domain/repositories/connection_repository.dart';

abstract class FileRepository {
  Future<Either<Failure, List<FileEntity>>> getFiles(String baseUrl);
  Future<Either<Failure, FileEntity>> getFileMetadata(
      String baseUrl, String fileId);
  Future<Either<Failure, void>> deleteFile(String baseUrl, String fileId);
  Future<Either<Failure, String>> getChecksum(String baseUrl, String fileId);
}
