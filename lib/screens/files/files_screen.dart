import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class FilesPage extends ConsumerWidget {
  const FilesPage({super.key, required this.group, required this.isLeader});
  final Group group;
  final bool isLeader;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(filesProvider(group.id));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pick(context, ref, group),
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
                    '${files[i].category} • ${(files[i].size / 1024).toStringAsFixed(1)} KB',
                  ),
                  onTap: () => launchUrl(
                    Uri.parse(files[i].downloadUrl),
                    mode: LaunchMode.externalApplication,
                  ),
                  trailing: isLeader
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ref
                              .read(collaborationRepositoryProvider)
                              .deleteFile(files[i]),
                        )
                      : null,
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load files',
          message: '$e',
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, Group group) async {
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
      ],
    );
    if (chosen == null || chosen.files.single.bytes == null) return;
    final category = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('File category'),
        children:
            ['documents', 'code', 'design', 'reports', 'presentations', 'other']
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
      await ref
          .read(collaborationRepositoryProvider)
          .uploadFile(
            groupId: group.id,
            uploaderId: user.uid,
            filename: chosen.files.single.name,
            category: category,
            bytes: chosen.files.single.bytes!,
          );
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
