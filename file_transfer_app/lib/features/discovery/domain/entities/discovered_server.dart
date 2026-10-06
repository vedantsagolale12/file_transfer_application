import 'package:equatable/equatable.dart';

class DiscoveredServer extends Equatable {
  final String name;
  final String host;
  final int port;
  final String protocol;

  const DiscoveredServer({
    required this.name,
    required this.host,
    required this.port,
    this.protocol = 'http',
  });

  String get baseUrl => '$protocol://$host:$port';

  @override
  List<Object?> get props => [name, host, port, protocol];
}
