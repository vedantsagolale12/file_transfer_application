import 'package:equatable/equatable.dart';
import 'package:file_transfer_app/features/connection/domain/entities/server_config.dart';

abstract class ConnectionEvent extends Equatable {
  const ConnectionEvent();

  @override
  List<Object?> get props => [];
}

class LoadLastServerEvent extends ConnectionEvent {
  const LoadLastServerEvent();
}

class ConnectToServerEvent extends ConnectionEvent {
  final ServerConfig config;

  const ConnectToServerEvent({required this.config});

  @override
  List<Object?> get props => [config];
}

class DisconnectFromServerEvent extends ConnectionEvent {
  const DisconnectFromServerEvent();
}

class ReconnectEvent extends ConnectionEvent {
  const ReconnectEvent();
}

class CheckConnectionEvent extends ConnectionEvent {
  const CheckConnectionEvent();
}
