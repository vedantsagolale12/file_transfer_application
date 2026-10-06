import 'package:dio/dio.dart';
import 'package:file_transfer_app/core/error/failure.dart';
import 'package:file_transfer_app/features/connection/domain/repositories/connection_repository.dart';
import 'package:file_transfer_app/features/files/data/datasources/file_remote_datasource.dart';
import 'package:file_transfer_app/features/files/domain/entities/file_entity.dart';
import 'package:file_transfer_app/features/files/domain/repositories/file_repository.dart';

class FileRepositoryImpl implements FileRepository {
  final FileRemoteDataSource remoteDataSource;

  FileRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<FileEntity>>> getFiles(String baseUrl) async {
    try {
      final files = await remoteDataSource.getFiles(baseUrl);
      return Either.rightValue(files);
    } on DioException catch (e) {
      return Either.leftValue(_mapDioError(e));
    } catch (e) {
      return Either.leftValue(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FileEntity>> getFileMetadata(
      String baseUrl, String fileId) async {
    try {
      final file = await remoteDataSource.getFileMetadata(baseUrl, fileId);
      return Either.rightValue(file);
    } on DioException catch (e) {
      return Either.leftValue(_mapDioError(e));
    } catch (e) {
      return Either.leftValue(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFile(
      String baseUrl, String fileId) async {
    try {
      await remoteDataSource.deleteFile(baseUrl, fileId);
      return Either.rightValue(null);
    } on DioException catch (e) {
      return Either.leftValue(_mapDioError(e));
    } catch (e) {
      return Either.leftValue(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getChecksum(
      String baseUrl, String fileId) async {
    try {
      final checksum = await remoteDataSource.getChecksum(baseUrl, fileId);
      return Either.rightValue(checksum);
    } on DioException catch (e) {
      return Either.leftValue(_mapDioError(e));
    } catch (e) {
      return Either.leftValue(UnknownFailure(message: e.toString()));
    }
  }

  Failure _mapDioError(DioException e) {
    switch (e.response?.statusCode) {
      case 404:
        return const FileNotFoundFailure();
      case 500:
        return const ServerErrorFailure();
      default:
        return NetworkFailure(message: e.message ?? 'Network error');
    }
  }
}
