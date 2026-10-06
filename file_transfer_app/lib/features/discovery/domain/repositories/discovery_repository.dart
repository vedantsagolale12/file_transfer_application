import 'package:file_transfer_app/features/discovery/domain/entities/discovered_server.dart';

abstract class DiscoveryRepository {
  Stream<DiscoveredServer> discoverServers();
  Future<void> stopDiscovery();
}
