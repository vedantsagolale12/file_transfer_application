import 'package:equatable/equatable.dart';

class ServerConfig extends Equatable {
  final String host;
  final int port;
  final String protocol;
  final String displayName;

  const ServerConfig({
    required this.host,
    required this.port,
    this.protocol = 'http',
    this.displayName = 'PC Server',
  });

  String get baseUrl => '$protocol://$host:$port';

  ServerConfig copyWith({
    String? host,
    int? port,
    String? protocol,
    String? displayName,
  }) {
    return ServerConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
      displayName: displayName ?? this.displayName,
    );
  }

  Map<String, dynamic> toJson() => {
        'host': host,
        'port': port,
        'protocol': protocol,
        'displayName': displayName,
      };

  factory ServerConfig.fromJson(Map<String, dynamic> json) => ServerConfig(
        host: json['host'] as String,
        port: json['port'] as int,
        protocol: json['protocol'] as String? ?? 'http',
        displayName: json['displayName'] as String? ?? 'PC Server',
      );

  @override
  List<Object?> get props => [host, port, protocol, displayName];
}
