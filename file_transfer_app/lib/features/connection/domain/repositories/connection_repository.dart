import 'package:file_transfer_app/core/error/failure.dart';
import 'package:file_transfer_app/features/connection/domain/entities/server_config.dart';

abstract class ConnectionRepository {
  Future<Either<Failure, bool>> checkHealth(String baseUrl);
  Future<Either<Failure, ServerConfig?>> getLastServer();
  Future<Either<Failure, void>> saveServer(ServerConfig config);
  Future<Either<Failure, void>> clearServer();
}

// Simple Either implementation (no dartz needed)
class Either<L, R> {
  final L? _left;
  final R? _right;
  final bool _isRight;

  const Either._left(this._left)
      : _right = null,
        _isRight = false;
  const Either._right(this._right)
      : _left = null,
        _isRight = true;

  static Either<L, R> leftValue<L, R>(L value) => Either._left(value);
  static Either<L, R> rightValue<L, R>(R value) => Either._right(value);

  bool get isLeft => !_isRight;
  bool get isRight => _isRight;

  L get left => _left as L;
  R get right => _right as R;

  T fold<T>(T Function(L) onLeft, T Function(R) onRight) {
    if (_isRight) return onRight(_right as R);
    return onLeft(_left as L);
  }
}
