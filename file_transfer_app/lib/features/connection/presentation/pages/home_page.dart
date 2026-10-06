import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_transfer_app/app/router/app_router.dart';
import 'package:file_transfer_app/app/theme/app_theme.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_bloc.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_event.dart';
import 'package:file_transfer_app/features/connection/presentation/bloc/connection_state.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/upload_bloc.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/upload_event.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/upload_state.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/download_bloc.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/download_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectionBloc, ConnectionState>(
      listener: (context, state) {
        if (state is ConnectionDisconnectedState ||
            state is ConnectionInitialState) {
          context.go(AppRoutes.discovery);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PC File Transfer'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.go('${AppRoutes.home}/settings'),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ConnectionStatusCard(),
              const SizedBox(height: AppSpacing.md),
              _QuickActionsSection(),
              const SizedBox(height: AppSpacing.md),
              _ActiveTransfersSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionStatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionBloc, ConnectionState>(
      builder: (context, state) {
        if (state is ConnectionConnectedState) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: AppRadius.medium,
                    ),
                    child: const Icon(Icons.computer, color: Colors.green),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.config.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${state.config.host}:${state.config.port}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: AppRadius.extraLarge,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.green),
                        SizedBox(width: 4),
                        Text(
                          'Connected',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                )),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.folder_open,
                label: 'Browse Files',
                color: Theme.of(context).colorScheme.primary,
                onTap: () => context.go('${AppRoutes.home}/files'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionCard(
                icon: Icons.upload,
                label: 'Upload File',
                color: Theme.of(context).colorScheme.secondary,
                onTap: () {
                  context.read<UploadBloc>().add(const SelectUploadFileEvent());
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.swap_vert,
                label: 'Transfers',
                color: Colors.orange,
                onTap: () => context.go('${AppRoutes.home}/transfers'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _ActionCard(
                icon: Icons.wifi_off,
                label: 'Disconnect',
                color: Colors.red,
                onTap: () {
                  context
                      .read<ConnectionBloc>()
                      .add(const DisconnectFromServerEvent());
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveTransfersSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Transfers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            TextButton(
              onPressed: () => context.go('${AppRoutes.home}/transfers'),
              child: const Text('View All'),
            ),
          ],
        ),
        BlocBuilder<UploadBloc, UploadState>(
          builder: (context, uploadState) {
            return BlocBuilder<DownloadBloc, DownloadState>(
              builder: (context, downloadState) {
                final hasActiveUpload = uploadState is UploadUploadingState ||
                    uploadState is UploadPreparingState;
                final hasActiveDownload =
                    downloadState is DownloadDownloadingState ||
                        downloadState is DownloadPreparingState;

                if (!hasActiveUpload && !hasActiveDownload) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: Text(
                          'No active transfers',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    if (hasActiveUpload && uploadState is UploadUploadingState)
                      _TransferProgressCard(
                        fileName: uploadState.fileName,
                        progress: uploadState.progress,
                        transferred: uploadState.transferredBytes,
                        total: uploadState.totalBytes,
                        speed: uploadState.speed,
                        eta: uploadState.estimatedSecondsRemaining,
                        isUpload: true,
                      ),
                    if (hasActiveDownload &&
                        downloadState is DownloadDownloadingState)
                      _TransferProgressCard(
                        fileName: downloadState.fileName,
                        progress: downloadState.progress,
                        transferred: downloadState.downloadedBytes,
                        total: downloadState.totalBytes,
                        speed: downloadState.speed,
                        eta: downloadState.estimatedSecondsRemaining,
                        isUpload: false,
                      ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _TransferProgressCard extends StatelessWidget {
  final String fileName;
  final double progress;
  final int transferred;
  final int total;
  final double speed;
  final int? eta;
  final bool isUpload;

  const _TransferProgressCard({
    required this.fileName,
    required this.progress,
    required this.transferred,
    required this.total,
    required this.speed,
    this.eta,
    required this.isUpload,
  });

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatSpeed(double bps) {
    if (bps < 1024 * 1024) return '${(bps / 1024).toStringAsFixed(1)} KB/s';
    return '${(bps / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isUpload ? Icons.upload : Icons.download,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              borderRadius: AppRadius.extraLarge,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_formatBytes(transferred)} / ${_formatBytes(total)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%  •  ${_formatSpeed(speed)}${eta != null ? '  •  ${eta}s' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
