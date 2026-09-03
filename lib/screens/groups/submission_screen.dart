import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class SubmissionScreen extends ConsumerStatefulWidget {
  const SubmissionScreen({super.key, required this.project});
  final Project project;
  @override
  ConsumerState<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends ConsumerState<SubmissionScreen> {
  final title = TextEditingController(text: 'Final coursework submission'),
      description = TextEditingController();
  String status = 'draft';
  PlatformFile? chosenFile;
  bool busy = false;
  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final existingSubmissions =
        ref.watch(submissionsProvider(widget.project.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Submit coursework')),
      body: existingSubmissions.when(
        data: (subs) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subs.isNotEmpty) ...[
                Text(
                  'Previous submissions',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...subs.map((s) => ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(s.title),
                      subtitle: Text(
                        '${s.status.toUpperCase()} • ${_formatDate(s.submittedAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Submission title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                maxLines: 4,
                decoration:
                    const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  chosenFile != null
                      ? chosenFile!.name
                      : 'Attach a file (optional)',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              AppButton(
                label: status == 'draft'
                    ? 'Submit coursework'
                    : 'Resubmit coursework',
                loading: busy,
                onPressed: submit,
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load submissions',
          message: 'Please check your connection and try again.',
        ),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _pickFile() async {
    final chosen = await FilePicker.platform.pickFiles(
      withData: true,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'zip',
        'dart',
        'py',
        'java',
        'js',
        'txt',
        'md',
      ],
    );
    if (chosen != null && chosen.files.single.bytes != null) {
      setState(() => chosenFile = chosen.files.single);
    }
  }

  Future<void> submit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Submit coursework?'),
        content: Text(
          status == 'draft'
              ? 'This creates a final submission record with a timestamp.'
              : 'This creates a new submission (resubmission).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() => busy = true);
    String? fileUrl;
    if (chosenFile != null) {
      try {
        fileUrl = await ref
            .read(collaborationRepositoryProvider)
            .uploadFile(
              groupId: widget.project.groupId,
              projectId: widget.project.id,
              uploaderId: user.uid,
              uploaderName: user.fullName,
              filename: chosenFile!.name,
              category: 'documents',
              bytes: chosenFile!.bytes!,
            );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload file: ${friendlyError(e)}')),
          );
        }
      }
    }
    try {
      await ref.read(collaborationRepositoryProvider).submitDirect(
            project: widget.project,
            authorId: user.uid,
            authorName: user.fullName,
            title: title.text,
            description: description.text,
            fileUrl: fileUrl,
            status: status == 'draft' ? 'submitted' : 'resubmitted',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coursework submitted successfully.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
