import 'dart:async';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_transfer_app/app/router/app_router.dart';
import 'package:file_transfer_app/app/theme/app_theme.dart';
import 'package:file_transfer_app/features/connection/domain/entities/server_config.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_bloc.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_event.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_state.dart';
import 'package:file_transfer_app/features/discovery/domain/entities/discovered_server.dart';
import 'package:file_transfer_app/injection_container.dart' as di;
import 'package:file_transfer_app/features/discovery/domain/repositories/discovery_repository.dart';

class DiscoveryPage extends StatefulWidget {
  const DiscoveryPage({super.key});

  @override
  State<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends State<DiscoveryPage>
    with SingleTickerProviderStateMixin {
  final List<DiscoveredServer> _servers = [];
  bool _isScanning = false;
  StreamSubscription<DiscoveredServer>? _subscription;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.6, end: 1.0).animate(_pulseController);

    // Try to reconnect from last saved server
    context.read<ConnectionBloc>().add(const LoadLastServerEvent());
    _startScan();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startScan() {
    _subscription?.cancel();
    setState(() {
      _servers.clear();
      _isScanning = true;
    });

    final repo = di.sl<DiscoveryRepository>();
    _subscription = repo.discoverServers().listen(
      (server) {
        if (mounted) {
          setState(() {
            if (!_servers
                .any((s) => s.host == server.host && s.port == server.port)) {
              _servers.add(server);
            }
          });
        }
      },
      onDone: () {
        if (mounted) setState(() => _isScanning = false);
      },
      onError: (_) {
        if (mounted) setState(() => _isScanning = false);
      },
    );

    // Stop scan after duration
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isScanning) {
        _subscription?.cancel();
        setState(() => _isScanning = false);
      }
    });
  }

  void _connectToServer(DiscoveredServer server) {
    final config = ServerConfig(
      host: server.host,
      port: server.port,
      protocol: server.protocol,
      displayName: server.name,
    );
    context.read<ConnectionBloc>().add(ConnectToServerEvent(config: config));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectionBloc, ConnectionState>(
      listener: (context, state) {
        if (state is ConnectionConnectedState) {
          context.go(AppRoutes.home);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Connect to PC',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Searching for PC File Transfer servers on your network',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildScanningIndicator(),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: _buildServerList(),
                ),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanningIndicator() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _isScanning ? _pulseAnimation.value : 0.4,
            child: child,
          );
        },
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.2),
              ),
              child: Center(
                child: Icon(
                  Icons.wifi_find,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServerList() {
    if (_isScanning && _servers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Scanning your network...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (!_isScanning && _servers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.computer_outlined,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No PC found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure the PC server is running\nand on the same network',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startScan,
              icon: const Icon(Icons.refresh),
              label: const Text('Scan Again'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _servers.length,
      itemBuilder: (context, index) {
        final server = _servers[index];
        return _ServerCard(
          server: server,
          onConnect: () => _connectToServer(server),
        );
      },
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.manualConnect),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Connect manually'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _ServerCard extends StatelessWidget {
  final DiscoveredServer server;
  final VoidCallback onConnect;

  const _ServerCard({
    required this.server,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionBloc, ConnectionState>(
      builder: (context, state) {
        final isConnecting = state is ConnectionCheckingState &&
            state.config.host == server.host &&
            state.config.port == server.port;

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: AppRadius.medium,
              ),
              child: Icon(
                Icons.computer,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              server.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${server.host}:${server.port}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: isConnecting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : FilledButton(
                    onPressed: onConnect,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Connect'),
                  ),
          ),
        );
      },
    );
  }
}
