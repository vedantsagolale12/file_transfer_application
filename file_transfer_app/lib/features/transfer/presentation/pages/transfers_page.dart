import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_transfer_app/app/theme/app_theme.dart';
import 'package:file_transfer_app/core/utils/format_utils.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/upload_bloc.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/upload_event.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/upload_state.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/download_bloc.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/download_event.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/download_state.dart';
import 'package:open_filex/open_filex.dart';

class TransfersPage extends StatelessWidget {
  const TransfersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfers'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Uploads',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          BlocBuilder<UploadBloc, UploadState>(
            builder: (context, state) => _buildUploadCard(context, state),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Downloads',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          BlocBuilder<DownloadBloc, DownloadState>(
            builder: (context, state) => _buildDownloadCard(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard(BuildContext context, UploadState state) {
    if (state is UploadInitialState || state is UploadCancelledState) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Text(
                state is UploadCancelledState
                    ? 'Upload cancelled'
                    : 'No active upload',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: () => context
                    .read<UploadBloc>()
                    .add(const SelectUploadFileEvent()),
                icon: const Icon(Icons.upload_file),
                label: const Text('Select File to Upload'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is UploadUploadingState) {
      return _TransferCard(
        icon: Icons.upload,
        fileName: state.fileName,
        progress: state.progress,
        transferred: state.transferredBytes,
        total: state.totalBytes,
        speed: state.speed,
        eta: state.estimatedSecondsRemaining,
        isUpload: true,
        onPause: () => context.read<UploadBloc>().add(const PauseUploadEvent()),
        onCancel: () =>
            context.read<UploadBloc>().add(const CancelUploadEvent()),
      );
    }

    if (state is UploadPausedState) {
      return _TransferCard(
        icon: Icons.upload,
        fileName: state.fileName,
        progress: state.progress,
        transferred: state.transferredBytes,
        total: state.totalBytes,
        speed: 0,
        eta: null,
        isUpload: true,
        isPaused: true,
        onResume: () =>
            context.read<UploadBloc>().add(const ResumeUploadEvent()),
        onCancel: () =>
            context.read<UploadBloc>().add(const CancelUploadEvent()),
      );
    }

    if (state is UploadVerifyingState) {
      return Card(
        child: ListTile(
          leading: const CircularProgressIndicator(),
          title: Text(state.fileName),
          subtitle: const Text('Verifying integrity...'),
        ),
      );
    }

    if (state is UploadCompletedState) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(state.fileName),
          subtitle: Text(state.verified
              ? '✓ Upload completed  ✓ Integrity verified'
              : '✓ Upload completed'),
        ),
      );
    }

    if (state is UploadFailedState) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Text(state.fileName ?? 'Upload failed'),
                ],
              ),
              const SizedBox(height: 4),
              Text(state.message, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context
                        .read<UploadBloc>()
                        .add(const RetryUploadEvent()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (state is UploadIntegrityFailedState) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.warning, color: Colors.orange),
          title: Text(state.fileName),
          subtitle:
              const Text('Integrity check failed — file may be corrupted'),
        ),
      );
    }

    return const Card(child: ListTile(title: Text('Preparing upload...')));
  }

  Widget _buildDownloadCard(BuildContext context, DownloadState state) {
    if (state is DownloadInitialState || state is DownloadCancelledState) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Center(
            child: Text(
              state is DownloadCancelledState
                  ? 'Download cancelled'
                  : 'No active download',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

    if (state is DownloadDownloadingState) {
      return _TransferCard(
        icon: Icons.download,
        fileName: state.fileName,
        progress: state.progress,
        transferred: state.downloadedBytes,
        total: state.totalBytes,
        speed: state.speed,
        eta: state.estimatedSecondsRemaining,
        isUpload: false,
        onPause: () =>
            context.read<DownloadBloc>().add(const PauseDownloadEvent()),
        onCancel: () =>
            context.read<DownloadBloc>().add(const CancelDownloadEvent()),
      );
    }

    if (state is DownloadPausedState) {
      return _TransferCard(
        icon: Icons.download,
        fileName: state.fileName,
        progress: state.progress,
        transferred: state.downloadedBytes,
        total: state.totalBytes,
        speed: 0,
        eta: null,
        isUpload: false,
        isPaused: true,
        onResume: () =>
            context.read<DownloadBloc>().add(const ResumeDownloadEvent()),
        onCancel: () =>
            context.read<DownloadBloc>().add(const CancelDownloadEvent()),
      );
    }

    if (state is DownloadVerifyingState) {
      return Card(
        child: ListTile(
          leading: const CircularProgressIndicator(),
          title: Text(state.fileName),
          subtitle: const Text('Verifying integrity...'),
        ),
      );
    }

    if (state is DownloadCompletedState) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.check_circle, color: Colors.green),
          title: Text(state.fileName),
          subtitle: Text(state.verified
              ? '✓ Download completed  ✓ Integrity verified'
              : '✓ Download completed'),
          trailing: IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () => OpenFilex.open(state.localPath),
          ),
        ),
      );
    }

    if (state is DownloadFailedState) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Text(state.fileName ?? 'Download failed'),
                ],
              ),
              const SizedBox(height: 4),
              Text(state.message, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: () => context
                    .read<DownloadBloc>()
                    .add(const RetryDownloadEvent()),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is DownloadIntegrityFailedState) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.warning, color: Colors.orange),
          title: Text(state.fileName),
          subtitle:
              const Text('Integrity check failed — file may be corrupted'),
        ),
      );
    }

    return const Card(child: ListTile(title: Text('Preparing download...')));
  }
}

class _TransferCard extends StatelessWidget {
  final IconData icon;
  final String fileName;
  final double progress;
  final int transferred;
  final int total;
  final double speed;
  final int? eta;
  final bool isUpload;
  final bool isPaused;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  const _TransferCard({
    required this.icon,
    required this.fileName,
    required this.progress,
    required this.transferred,
    required this.total,
    required this.speed,
    this.eta,
    required this.isUpload,
    this.isPaused = false,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isPaused)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: AppRadius.extraLarge,
                    ),
                    child: const Text('Paused',
                        style: TextStyle(color: Colors.orange, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              borderRadius: AppRadius.extraLarge,
              minHeight: 6,
            ),
            const SizedBox(height: 4),
            Text(
              '${FormatUtils.buildProgressBar(progress)}  ${(progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${FormatUtils.formatFileSize(transferred)} / ${FormatUtils.formatFileSize(total)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  speed > 0
                      ? '${FormatUtils.formatSpeed(speed)}${eta != null ? '  •  ETA: ${FormatUtils.formatDuration(eta!)}' : ''}'
                      : (isPaused ? 'Paused' : 'Calculating...'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (!isPaused && onPause != null)
                  OutlinedButton.icon(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause, size: 16),
                    label: const Text('Pause'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (isPaused && onResume != null)
                  FilledButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Resume'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                const SizedBox(width: 8),
                if (onCancel != null)
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
