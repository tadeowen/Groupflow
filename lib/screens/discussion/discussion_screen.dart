import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';
import 'post_detail_screen.dart';

class DiscussionPage extends ConsumerStatefulWidget {
  const DiscussionPage({
    super.key,
    required this.group,
    required this.project,
    required this.isLeader,
  });
  final Group group;
  final Project project;
  final bool isLeader;
  @override
  ConsumerState<DiscussionPage> createState() => _DiscussionPageState();
}

class _DiscussionPageState extends ConsumerState<DiscussionPage> {
  final text = TextEditingController();
  bool sending = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(postsProvider(widget.project.id));
    final members = ref.watch(membersProvider(widget.group.id)).value ?? [];
    final memberMap = {for (var m in members) m.userId: m.fullName};

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: compose,
        icon: const Icon(Icons.edit),
        label: const Text('Post'),
      ),
      body: data.when(
        data: (posts) => posts.isEmpty
            ? const EmptyState(
                icon: Icons.forum_outlined,
                title: 'Start the discussion',
                message:
                    'Ask a question, share an idea, or resolve a group decision.',
              )
            : ListView.separated(
                itemCount: posts.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = posts[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        p.authorName.isNotEmpty
                            ? p.authorName[0].toUpperCase()
                            : '?',
                      ),
                    ),
                    title: Text(
                      p.authorName.isNotEmpty ? p.authorName : 'Someone',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      p.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(p.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        if (p.content.length > 100)
                          const Icon(Icons.chevron_right, size: 16),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(
                          post: p,
                          group: widget.group,
                          isLeader: widget.isLeader,
                          members: memberMap,
                        ),
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load discussion',
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

  Future<void> compose() async {
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: text,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'What does the group need to know?',
              ),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Publish post',
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      ),
    );
    if (posted != true || text.text.trim().isEmpty) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() => sending = true);
    try {
      await ref.read(collaborationRepositoryProvider).addPost(
            groupId: widget.group.id,
            projectId: widget.project.id,
            authorId: user.uid,
            authorName: user.fullName,
            content: text.text,
          );
      text.clear();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }
}
