import 'package:file_transfer_app/core/error/failure.dart';
import 'package:file_transfer_app/features/connection/domain/entities/server_config.dart';
import 'package:file_transfer_app/features/connection/domain/repositories/connection_repository.dart';

class CheckConnectionUseCase {
  final ConnectionRepository repository;

  CheckConnectionUseCase({required this.repository});

  Future<Either<Failure, bool>> call(ServerConfig config) async {
    return repository.checkHealth(config.baseUrl);
  }
}

class GetLastServerUseCase {
  final ConnectionRepository repository;

  GetLastServerUseCase({required this.repository});

  Future<Either<Failure, ServerConfig?>> call() async {
    return repository.getLastServer();
  }
}

class SaveServerUseCase {
  final ConnectionRepository repository;

  SaveServerUseCase({required this.repository});

  Future<Either<Failure, void>> call(ServerConfig config) async {
    return repository.saveServer(config);
  }
}

class ClearServerUseCase {
  final ConnectionRepository repository;

  ClearServerUseCase({required this.repository});

  Future<Either<Failure, void>> call() async {
    return repository.clearServer();
  }
}
