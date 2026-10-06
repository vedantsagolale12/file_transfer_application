import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_transfer_app/app/router/app_router.dart';
import 'package:file_transfer_app/app/theme/app_theme.dart';
import 'package:file_transfer_app/features/connection/domain/entities/server_config.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_bloc.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_event.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_state.dart';

class ManualConnectPage extends StatefulWidget {
  const ManualConnectPage({super.key});

  @override
  State<ManualConnectPage> createState() => _ManualConnectPageState();
}

class _ManualConnectPageState extends State<ManualConnectPage> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  String _protocol = 'http';

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _connect() {
    if (!_formKey.currentState!.validate()) return;

    final config = ServerConfig(
      host: _ipController.text.trim(),
      port: int.parse(_portController.text.trim()),
      protocol: _protocol,
      displayName: 'PC (${_ipController.text.trim()})',
    );

    context.read<ConnectionBloc>().add(ConnectToServerEvent(config: config));
  }

  String? _validateIp(String? value) {
    if (value == null || value.isEmpty) return 'Please enter an IP address';
    final ipRegex = RegExp(
        r'^(\d{1,3}\.){3}\d{1,3}$|^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$');
    if (!ipRegex.hasMatch(value.trim())) return 'Enter a valid IP or hostname';
    return null;
  }

  String? _validatePort(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a port';
    final port = int.tryParse(value);
    if (port == null || port < 1 || port > 65535) {
      return 'Port must be between 1 and 65535';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectionBloc, ConnectionState>(
      listener: (context, state) {
        if (state is ConnectionConnectedState) {
          context.go(AppRoutes.home);
        } else if (state is ConnectionFailureState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manual Connection'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocBuilder<ConnectionBloc, ConnectionState>(
          builder: (context, state) {
            final isLoading = state is ConnectionCheckingState;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Enter Server Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Connect directly using your PC\'s IP address',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextFormField(
                      controller: _ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP Address or Hostname',
                        hintText: '192.168.1.10',
                        prefixIcon: Icon(Icons.computer),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      validator: _validateIp,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        hintText: '8080',
                        prefixIcon: Icon(Icons.settings_ethernet),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.done,
                      validator: _validatePort,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: _protocol,
                      decoration: const InputDecoration(
                        labelText: 'Protocol',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'http', child: Text('HTTP')),
                        DropdownMenuItem(value: 'https', child: Text('HTTPS')),
                      ],
                      onChanged: isLoading
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _protocol = value);
                              }
                            },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isLoading ? null : _connect,
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.link),
                        label: Text(isLoading ? 'Connecting...' : 'Connect'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
