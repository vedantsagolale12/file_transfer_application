import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_transfer_app/app/theme/app_theme.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_bloc.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_event.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_state.dart';
import 'package:file_transfer_app/app/router/app_router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Connection section
          Text(
            'Connection',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            child: Column(
              children: [
                BlocBuilder<ConnectionBloc, ConnectionState>(
                  builder: (context, state) {
                    if (state is ConnectionConnectedState) {
                      return ListTile(
                        leading: const Icon(Icons.computer),
                        title: Text(state.config.displayName),
                        subtitle:
                            Text('${state.config.host}:${state.config.port}'),
                        trailing: const Icon(Icons.circle,
                            color: Colors.green, size: 12),
                      );
                    }
                    return const ListTile(
                      leading: Icon(Icons.computer_outlined),
                      title: Text('No server connected'),
                      subtitle: Text('Tap to connect'),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.wifi_find),
                  title: const Text('Discover servers'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context
                        .read<ConnectionBloc>()
                        .add(const DisconnectFromServerEvent());
                    context.go(AppRoutes.discovery);
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Manual connection'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.manualConnect),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.wifi_off_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Disconnect',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () {
                    context
                        .read<ConnectionBloc>()
                        .add(const DisconnectFromServerEvent());
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // App Info section
          Text(
            'About',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('PC File Transfer'),
                  subtitle: Text('Version 1.0.0'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Transfer files over Wi-Fi'),
                  subtitle: Text(
                    'Connects to a Spring Boot server on your PC using mDNS discovery or manual IP entry.',
                  ),
                  isThreeLine: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
