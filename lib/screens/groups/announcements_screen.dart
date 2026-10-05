import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({
    super.key,
    required this.group,
    required this.isLeader,
  });
  final Group group;
  final bool isLeader;
  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final text = TextEditingController();
  bool posting = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(announcementsProvider(widget.group.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      floatingActionButton: widget.isLeader
          ? FloatingActionButton.extended(
              onPressed: _createAnnouncement,
              icon: const Icon(Icons.campaign_outlined),
              label: const Text('Announce'),
            )
          : null,
      body: data.when(
        data: (items) => items.isEmpty
            ? EmptyState(
                icon: Icons.campaign_outlined,
                title: 'No announcements yet',
                message: widget.isLeader
                    ? 'Create an announcement to inform your group.'
                    : 'Group announcements will appear here.',
                action: widget.isLeader
                    ? AppButton(
                        label: 'Create announcement',
                        onPressed: _createAnnouncement,
                      )
                    : null,
              )
            : ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final a = items[i];
                  return ListTile(
                    leading: const Icon(Icons.campaign_outlined),
                    title: Text(a.content, maxLines: 2),
                    subtitle: Text(
                      '${a.authorName} • ${_formatTime(a.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: widget.isLeader
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(context, ref, a),
                          )
                        : null,
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load announcements',
          message: 'Please check your connection and try again.',
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Future<void> _createAnnouncement() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New announcement'),
        content: TextField(
          controller: text,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'What should the group know?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    if (ok != true || text.text.trim().isEmpty) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() => posting = true);
    try {
      await ref
          .read(collaborationRepositoryProvider)
          .addAnnouncement(
            groupId: widget.group.id,
            authorId: user.uid,
            authorName: user.fullName,
            content: text.text,
          );
      text.clear();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => posting = false);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Announcement announcement,
  ) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: const Text('This cannot be undone.'),
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
      await ref
          .read(collaborationRepositoryProvider)
          .deleteAnnouncement(announcement.id, widget.group.id, user.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Announcement deleted.')));
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
