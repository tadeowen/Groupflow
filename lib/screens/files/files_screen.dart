import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class FilesPage extends ConsumerWidget {
  const FilesPage({
    super.key,
    required this.group,
    required this.project,
    required this.isLeader,
  });
  final Group group;
  final Project project;
  final bool isLeader;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(filesProvider(project.id));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pick(context, ref, group, project),
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
      body: data.when(
        data: (files) => files.isEmpty
            ? const EmptyState(
                icon: Icons.folder_open_outlined,
                title: 'No files yet',
                message:
                    'Upload coursework documents, designs, presentations, or code archives.',
              )
            : ListView.builder(
                itemCount: files.length,
                itemBuilder: (_, i) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.insert_drive_file_outlined),
                  ),
                  title: Text(files[i].name),
                  subtitle: Text(
                    '${files[i].category} • ${_formatSize(files[i].size)} • ${files[i].uploaderName}',
                  ),
                  trailing: isLeader || files[i].uploaderId ==
                      ref.read(currentUserProvider).value?.uid
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteFile(
                            context,
                            ref,
                            files[i],
                          ),
                        )
                      : null,
                  onTap: () => launchUrl(
                    Uri.parse(files[i].downloadUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load files',
          message: 'Please check your connection and try again.',
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _deleteFile(
    BuildContext context,
    WidgetRef ref,
    WorkspaceFile file,
  ) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete file?'),
        content: Text('Delete "${file.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(collaborationRepositoryProvider).deleteFile(
            file,
            user.uid,
            isLeader,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${file.name} deleted.')),
        );
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    Group group,
    Project project,
  ) async {
    final chosen = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'xlsx',
        'png',
        'jpg',
        'jpeg',
        'zip',
        'dart',
        'py',
        'java',
        'js',
        'ts',
        'cpp',
        'h',
        'txt',
        'md',
      ],
    );
    if (chosen == null || chosen.files.single.bytes == null) return;
    if (!context.mounted) return;
    final category = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('File category'),
        children: [
          'documents',
          'code',
          'design',
          'reports',
          'presentations',
          'other'
        ]
            .map(
              (c) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, c),
                child: Text(c.toUpperCase()),
              ),
            )
            .toList(),
      ),
    );
    if (category == null) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    try {
      await ref.read(collaborationRepositoryProvider).uploadFile(
            groupId: group.id,
            projectId: project.id,
            uploaderId: user.uid,
            uploaderName: user.fullName,
            filename: chosen.files.single.name,
            category: category,
            bytes: chosen.files.single.bytes!,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${chosen.files.single.name} uploaded.')),
        );
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
