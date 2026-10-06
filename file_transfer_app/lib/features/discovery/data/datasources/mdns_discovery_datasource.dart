import 'dart:async';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:file_transfer_app/features/discovery/domain/entities/discovered_server.dart';
import 'package:file_transfer_app/core/constants/app_constants.dart';

abstract class MdnsDiscoveryDataSource {
  Stream<DiscoveredServer> discoverServers();
  Future<void> stopDiscovery();
}

class MdnsDiscoveryDataSourceImpl implements MdnsDiscoveryDataSource {
  MDnsClient? _client;

  @override
  Stream<DiscoveredServer> discoverServers() async* {
    _client = MDnsClient();
    try {
      await _client!.start();
      const serviceType =
          '${AppConstants.mdnsServiceType}.${AppConstants.mdnsServiceDomain}';

      await for (final ptr in _client!.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(serviceType),
      )) {
        // Look up SRV record
        await for (final srv in _client!.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          // Look up IP address
          await for (final ip in _client!.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          )) {
            final name = ptr.domainName
                .replaceAll('.$serviceType', '')
                .replaceAll(RegExp(r'\.$'), '');
            yield DiscoveredServer(
              name: name.isNotEmpty ? name : 'PC File Server',
              host: ip.address.address,
              port: srv.port,
              protocol: 'http',
            );
          }
        }
      }
    } finally {
      _client?.stop();
      _client = null;
    }
  }

  @override
  Future<void> stopDiscovery() async {
    _client?.stop();
    _client = null;
  }
}
