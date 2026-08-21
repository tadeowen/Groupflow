import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class NotesPage extends ConsumerWidget {
  const NotesPage({super.key, required this.group});
  final Group group;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(notesProvider(group.id));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NoteEditor(group: group)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New note'),
      ),
      body: notes.when(
        data: (items) {
          if (items.isEmpty)
            return const EmptyState(
              icon: Icons.edit_note_outlined,
              title: 'Your shared notebook is ready',
              message:
                  'Capture research, meeting notes, requirements, and code snippets.',
            );
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (_, i) => ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.description_outlined),
              ),
              title: Text(items[i].title),
              subtitle: Text(
                items[i].content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoteEditor(group: group, note: items[i]),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load notes',
          message: '$e',
        ),
      ),
    );
  }
}

class NoteEditor extends ConsumerStatefulWidget {
  const NoteEditor({super.key, required this.group, this.note});
  final Group group;
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
    if (user == null || title.text.trim().isEmpty) return;
    try {
      await ref
          .read(workspaceRepositoryProvider)
          .saveNote(
            groupId: widget.group.id,
            noteId: widget.note?.id,
            title: title.text,
            content: content.text,
            editorId: user.uid,
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
      title: Text(status),
      actions: [
        IconButton(onPressed: save, icon: const Icon(Icons.save_outlined)),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: title,
            style: Theme.of(context).textTheme.titleLarge,
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
