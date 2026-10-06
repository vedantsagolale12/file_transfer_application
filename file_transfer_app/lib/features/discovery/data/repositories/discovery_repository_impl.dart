import 'package:file_transfer_app/features/discovery/data/datasources/mdns_discovery_datasource.dart';
import 'package:file_transfer_app/features/discovery/domain/entities/discovered_server.dart';
import 'package:file_transfer_app/features/discovery/domain/repositories/discovery_repository.dart';

class DiscoveryRepositoryImpl implements DiscoveryRepository {
  final MdnsDiscoveryDataSource dataSource;

  DiscoveryRepositoryImpl({required this.dataSource});

  @override
  Stream<DiscoveredServer> discoverServers() {
    return dataSource.discoverServers();
  }

  @override
  Future<void> stopDiscovery() async {
    await dataSource.stopDiscovery();
  }
}
