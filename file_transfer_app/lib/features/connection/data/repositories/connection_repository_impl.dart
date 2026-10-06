import 'package:file_transfer_app/core/error/app_exception.dart';
import 'package:file_transfer_app/core/error/failure.dart';
import 'package:file_transfer_app/features/connection/data/datasources/connection_local_datasource.dart';
import 'package:file_transfer_app/features/connection/data/datasources/connection_remote_datasource.dart';
import 'package:file_transfer_app/features/connection/domain/entities/server_config.dart';
import 'package:file_transfer_app/features/connection/domain/repositories/connection_repository.dart';

class ConnectionRepositoryImpl implements ConnectionRepository {
  final ConnectionRemoteDataSource remoteDataSource;
  final ConnectionLocalDataSource localDataSource;

  ConnectionRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, bool>> checkHealth(String baseUrl) async {
    try {
      final result = await remoteDataSource.checkHealth(baseUrl);
      final status = result['status'] as String?;
      return Either.rightValue(status == 'UP');
    } on ConnectionRefusedException catch (e) {
      return Either.leftValue(ConnectionRefusedFailure(message: e.message));
    } on TimeoutException catch (e) {
      return Either.leftValue(TimeoutFailure(message: e.message));
    } on NoNetworkException catch (e) {
      return Either.leftValue(NoNetworkFailure(message: e.message));
    } on AppException catch (e) {
      return Either.leftValue(NetworkFailure(message: e.message));
    } catch (e) {
      return Either.leftValue(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ServerConfig?>> getLastServer() async {
    try {
      final config = await localDataSource.getLastServer();
      return Either.rightValue(config);
    } catch (e) {
      return Either.leftValue(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveServer(ServerConfig config) async {
    try {
      await localDataSource.saveServer(config);
      return Either.rightValue(null);
    } catch (e) {
      return Either.leftValue(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearServer() async {
    try {
      await localDataSource.clearServer();
      return Either.rightValue(null);
    } catch (e) {
      return Either.leftValue(CacheFailure(message: e.toString()));
    }
  }
}
