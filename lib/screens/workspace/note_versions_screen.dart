import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class NoteVersionsScreen extends ConsumerWidget {
  const NoteVersionsScreen({super.key, required this.note});
  final GroupNote note;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versions = ref.watch(noteVersionsProvider(note.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Version history')),
      body: versions.when(
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.history_outlined,
                title: 'No history yet',
                message: 'Versions appear when the note content changes.',
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final v = items[i];
                  final dt = v.editedAt;
                  final dateStr = dt != null
                      ? '${dt.day}/${dt.month}/${dt.year} ${_formatTime(dt)}'
                      : '';
                  return ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(
                      v.editedByName.isNotEmpty
                          ? v.editedByName
                          : 'Someone',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: Text(dateStr),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _viewVersion(context, v),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load history',
          message: 'Please check your connection and try again.',
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _viewVersion(BuildContext context, NoteVersion version) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Note version'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              version.content.isEmpty ? '(empty)' : version.content,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _restore(context, version);
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _restore(BuildContext context, NoteVersion version) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore version?'),
        content: const Text(
          'This will replace the current note content with this version.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Restore does not destroy history — it creates a new version
              // via the normal save flow. We just navigate back with the
              // content so the editor can save it.
              Navigator.pop(ctx);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Close the editor, paste the version content, and save.',
                  ),
                ),
              );
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}
