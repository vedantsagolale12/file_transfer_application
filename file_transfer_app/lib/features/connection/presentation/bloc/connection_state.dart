import 'package:equatable/equatable.dart';
import 'package:file_transfer_app/features/connection/domain/entities/server_config.dart';

abstract class ConnectionState extends Equatable {
  const ConnectionState();

  @override
  List<Object?> get props => [];
}

class ConnectionInitialState extends ConnectionState {
  const ConnectionInitialState();
}

class ConnectionCheckingState extends ConnectionState {
  final ServerConfig config;

  const ConnectionCheckingState({required this.config});

  @override
  List<Object?> get props => [config];
}

class ConnectionConnectedState extends ConnectionState {
  final ServerConfig config;

  const ConnectionConnectedState({required this.config});

  @override
  List<Object?> get props => [config];
}

class ConnectionDisconnectedState extends ConnectionState {
  const ConnectionDisconnectedState();
}

class ConnectionFailureState extends ConnectionState {
  final String message;
  final ServerConfig? lastConfig;

  const ConnectionFailureState({required this.message, this.lastConfig});

  @override
  List<Object?> get props => [message, lastConfig];
}
