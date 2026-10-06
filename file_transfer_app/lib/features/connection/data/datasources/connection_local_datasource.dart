import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_transfer_app/core/constants/storage_constants.dart';
import 'package:file_transfer_app/features/connection/domain/entities/server_config.dart';

abstract class ConnectionLocalDataSource {
  Future<ServerConfig?> getLastServer();
  Future<void> saveServer(ServerConfig config);
  Future<void> clearServer();
}

class ConnectionLocalDataSourceImpl implements ConnectionLocalDataSource {
  final SharedPreferences prefs;

  ConnectionLocalDataSourceImpl({required this.prefs});

  @override
  Future<ServerConfig?> getLastServer() async {
    final json = prefs.getString(StorageConstants.lastServerKey);
    if (json == null) return null;
    try {
      return ServerConfig.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveServer(ServerConfig config) async {
    await prefs.setString(
        StorageConstants.lastServerKey, jsonEncode(config.toJson()));
  }

  @override
  Future<void> clearServer() async {
    await prefs.remove(StorageConstants.lastServerKey);
  }
}
