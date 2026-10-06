import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_transfer_app/app/theme/app_theme.dart';
import 'package:file_transfer_app/core/widgets/app_error_view.dart';
import 'package:file_transfer_app/core/widgets/app_empty_view.dart';
import 'package:file_transfer_app/core/widgets/app_loader.dart';
import 'package:file_transfer_app/core/utils/format_utils.dart';
import 'package:file_transfer_app/features/files/domain/entities/file_entity.dart';
import 'package:file_transfer_app/features/files/presentation/bloc/file_bloc.dart';
import 'package:file_transfer_app/features/files/presentation/bloc/file_event.dart';
import 'package:file_transfer_app/features/files/presentation/bloc/file_state.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/download_bloc.dart';
import 'package:file_transfer_app/features/transfer/presentation/bloc/download_event.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<FileBloc>().add(const LoadFilesEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Files'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search files...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<FileBloc>()
                              .add(const SearchFilesEvent(query: ''));
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                context.read<FileBloc>().add(SearchFilesEvent(query: value));
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<FileBloc, FileState>(
              builder: (context, state) {
                if (state is FileLoadingState) {
                  return const AppLoader(message: 'Loading files...');
                }

                if (state is FileErrorState) {
                  return AppErrorView(
                    message: state.message,
                    onRetry: () =>
                        context.read<FileBloc>().add(const LoadFilesEvent()),
                  );
                }

                if (state is FileEmptyState) {
                  return const AppEmptyView(
                    message: 'No files found',
                    subtitle: 'Upload files from your PC to see them here',
                    icon: Icons.folder_open,
                  );
                }

                if (state is FileLoadedState) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<FileBloc>().add(const RefreshFilesEvent());
                    },
                    child: ListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      itemCount: state.filteredFiles.length,
                      itemBuilder: (context, index) {
                        final file = state.filteredFiles[index];
                        return _FileListItem(
                          file: file,
                          onTap: () => _showFileDetails(file),
                          onDownload: () => _downloadFile(file),
                          onDelete: () => _confirmDelete(file),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFileDetails(FileEntity file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _FileDetailsSheet(file: file),
    );
  }

  void _downloadFile(FileEntity file) {
    context.read<DownloadBloc>().add(StartDownloadEvent(file: file));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading ${file.name}...')),
    );
  }

  void _confirmDelete(FileEntity file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              this
                  .context
                  .read<FileBloc>()
                  .add(DeleteFileEvent(fileId: file.id));
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _FileListItem extends StatelessWidget {
  final FileEntity file;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _FileListItem({
    required this.file,
    required this.onTap,
    required this.onDownload,
    required this.onDelete,
  });

  IconData _getFileIcon() {
    if (file.isImage) return Icons.image;
    if (file.isVideo) return Icons.video_file;
    if (file.isAudio) return Icons.audio_file;
    if (file.isPdf) return Icons.picture_as_pdf;
    if (file.isDocument) return Icons.description;
    if (file.isArchive) return Icons.archive;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(_getFileIcon(),
              color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          file.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${FormatUtils.formatFileSize(file.size)} • ${FormatUtils.formatDate(file.lastModified.millisecondsSinceEpoch)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'download', child: Text('Download')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) {
            if (value == 'download') onDownload();
            if (value == 'delete') onDelete();
          },
        ),
        onTap: onTap,
      ),
    );
  }
}

class _FileDetailsSheet extends StatelessWidget {
  final FileEntity file;

  const _FileDetailsSheet({required this.file});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(file.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          _DetailRow(
              label: 'Size', value: FormatUtils.formatFileSize(file.size)),
          _DetailRow(label: 'Type', value: file.contentType),
          _DetailRow(
            label: 'Modified',
            value: FormatUtils.formatDate(
                file.lastModified.millisecondsSinceEpoch),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    context
                        .read<DownloadBloc>()
                        .add(StartDownloadEvent(file: file));
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context
                        .read<FileBloc>()
                        .add(DeleteFileEvent(fileId: file.id));
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
