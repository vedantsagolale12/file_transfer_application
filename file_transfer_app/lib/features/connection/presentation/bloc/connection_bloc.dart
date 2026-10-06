import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_transfer_app/features/connection/domain/usecases/check_connection_usecase.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_event.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_state.dart';

class ConnectionBloc extends Bloc<ConnectionEvent, ConnectionState> {
  final CheckConnectionUseCase checkConnectionUseCase;
  final GetLastServerUseCase getLastServerUseCase;
  final SaveServerUseCase saveServerUseCase;
  final ClearServerUseCase clearServerUseCase;

  ConnectionBloc({
    required this.checkConnectionUseCase,
    required this.getLastServerUseCase,
    required this.saveServerUseCase,
    required this.clearServerUseCase,
  }) : super(const ConnectionInitialState()) {
    on<LoadLastServerEvent>(_onLoadLastServer);
    on<ConnectToServerEvent>(_onConnectToServer);
    on<DisconnectFromServerEvent>(_onDisconnect);
    on<ReconnectEvent>(_onReconnect);
    on<CheckConnectionEvent>(_onCheckConnection);
  }

  Future<void> _onLoadLastServer(
    LoadLastServerEvent event,
    Emitter<ConnectionState> emit,
  ) async {
    final result = await getLastServerUseCase();
    result.fold(
      (_) => emit(const ConnectionDisconnectedState()),
      (config) {
        if (config != null) {
          add(ConnectToServerEvent(config: config));
        } else {
          emit(const ConnectionDisconnectedState());
        }
      },
    );
  }

  Future<void> _onConnectToServer(
    ConnectToServerEvent event,
    Emitter<ConnectionState> emit,
  ) async {
    emit(ConnectionCheckingState(config: event.config));
    final result = await checkConnectionUseCase(event.config);
    await result.fold(
      (failure) async {
        emit(ConnectionFailureState(
          message: failure.message,
          lastConfig: event.config,
        ));
      },
      (isHealthy) async {
        if (isHealthy) {
          await saveServerUseCase(event.config);
          emit(ConnectionConnectedState(config: event.config));
        } else {
          emit(ConnectionFailureState(
            message: 'Server is not healthy',
            lastConfig: event.config,
          ));
        }
      },
    );
  }

  Future<void> _onDisconnect(
    DisconnectFromServerEvent event,
    Emitter<ConnectionState> emit,
  ) async {
    await clearServerUseCase();
    emit(const ConnectionDisconnectedState());
  }

  Future<void> _onReconnect(
    ReconnectEvent event,
    Emitter<ConnectionState> emit,
  ) async {
    if (state is ConnectionConnectedState) {
      final config = (state as ConnectionConnectedState).config;
      add(ConnectToServerEvent(config: config));
    } else if (state is ConnectionFailureState) {
      final config = (state as ConnectionFailureState).lastConfig;
      if (config != null) {
        add(ConnectToServerEvent(config: config));
      }
    } else {
      add(const LoadLastServerEvent());
    }
  }

  Future<void> _onCheckConnection(
    CheckConnectionEvent event,
    Emitter<ConnectionState> emit,
  ) async {
    if (state is ConnectionConnectedState) {
      final config = (state as ConnectionConnectedState).config;
      add(ConnectToServerEvent(config: config));
    }
  }

  bool get isConnected => state is ConnectionConnectedState;

  String? get currentBaseUrl {
    if (state is ConnectionConnectedState) {
      return (state as ConnectionConnectedState).config.baseUrl;
    }
    return null;
  }
}
