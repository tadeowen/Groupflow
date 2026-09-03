import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';
import '../workspace/note_versions_screen.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({
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
    final notes = ref.watch(notesProvider(project.id));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NoteEditor(group: group, project: project),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New note'),
      ),
      body: notes.when(
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.edit_note_outlined,
              title: 'Your shared notebook is ready',
              message:
                  'Capture research, meeting notes, requirements, and code snippets.',
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => Dismissible(
              key: Key(items[i].id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Theme.of(context).colorScheme.error,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (_) => isLeader
                  ? _confirmDelete(context, ref, items[i])
                  : Future<bool>.value(false),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.description_outlined),
                ),
                title: Text(items[i].title),
                subtitle: Text(
                  items[i].content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: items[i].updatedAt != null
                    ? Text(
                        '${items[i].updatedAt!.hour.toString().padLeft(2, '0')}:${items[i].updatedAt!.minute.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoteEditor(
                      group: group,
                      project: project,
                      note: items[i],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load notes',
          message: 'Please check your connection and try again.',
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    GroupNote note,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: Text('Delete "${note.title}"? This cannot be undone.'),
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
    if (confirmed != true) return false;
    try {
      await ref.read(workspaceRepositoryProvider).deleteNote(note);
      return true;
    } catch (e) {
      if (context.mounted) showError(context, e);
      return false;
    }
  }
}

class NoteEditor extends ConsumerStatefulWidget {
  const NoteEditor({
    super.key,
    required this.group,
    required this.project,
    this.note,
  });
  final Group group;
  final Project project;
  final GroupNote? note;
  @override
  ConsumerState<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<NoteEditor> {
  late final title = TextEditingController(text: widget.note?.title ?? '');
  late final content = TextEditingController(text: widget.note?.content ?? '');
  Timer? timer;
  String status = 'Saved';
  @override
  void initState() {
    super.initState();
    title.addListener(schedule);
    content.addListener(schedule);
  }

  void schedule() {
    timer?.cancel();
    setState(() => status = 'Saving…');
    timer = Timer(const Duration(seconds: 1), save);
  }

  Future<void> save() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || title.text.trim().isEmpty) {
      if (mounted) setState(() => status = 'Enter a title');
      return;
    }
    try {
      await ref.read(workspaceRepositoryProvider).saveNote(
            groupId: widget.group.id,
            projectId: widget.project.id,
            noteId: widget.note?.id,
            title: title.text,
            content: content.text,
            editorId: user.uid,
            editorName: user.fullName,
          );
      if (mounted) setState(() => status = 'Saved');
    } catch (_) {
      if (mounted) setState(() => status = 'Unable to save');
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    title.dispose();
    content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.note == null ? 'New note' : widget.note!.title),
          actions: [
            if (widget.note != null)
              IconButton(
                icon: const Icon(Icons.history_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        NoteVersionsScreen(note: widget.note!),
                  ),
                ),
              ),
            IconButton(onPressed: save, icon: const Icon(Icons.save_outlined)),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                status,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: title,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: const InputDecoration(hintText: 'Note title'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: content,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(hintText: 'Start writing…'),
                ),
              ),
            ],
          ),
        ),
      );
}
