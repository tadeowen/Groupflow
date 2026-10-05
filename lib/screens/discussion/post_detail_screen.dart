import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({
    super.key,
    required this.post,
    required this.group,
    required this.isLeader,
    required this.members,
  });
  final DiscussionPost post;
  final Group group;
  final bool isLeader;
  final Map<String, String> members;
  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final commentCtrl = TextEditingController();
  bool sending = false;

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider(widget.post.id));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion'),
        actions: [
          if (widget.isLeader)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deletePost,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      widget.post.authorName.isNotEmpty
                          ? widget.post.authorName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(
                    widget.post.authorName.isNotEmpty
                        ? widget.post.authorName
                        : 'Someone',
                  ),
                  subtitle: Text(_formatTime(widget.post.createdAt)),
                ),
                const SizedBox(height: 8),
                Text(widget.post.content),
                const SizedBox(height: 24),
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                comments.when(
                  data: (items) => items.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'No comments yet. Be the first to comment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final c = items[i];
                            return _commentTile(c);
                          },
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Failed to load comments'),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              8 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment…',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: sending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: sending ? null : _sendComment,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _commentTile(Comment comment) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        radius: 14,
        child: Text(
          comment.authorName.isNotEmpty
              ? comment.authorName[0].toUpperCase()
              : '?',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comment.authorName.isNotEmpty ? comment.authorName : 'Someone',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              _formatTime(comment.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(comment.content),
          ],
        ),
      ),
    ],
  );

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Future<void> _sendComment() async {
    if (commentCtrl.text.trim().isEmpty) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() => sending = true);
    try {
      await ref
          .read(collaborationRepositoryProvider)
          .addComment(
            groupId: widget.group.id,
            postId: widget.post.id,
            authorId: user.uid,
            authorName: user.fullName,
            content: commentCtrl.text,
          );
      commentCtrl.clear();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _deletePost() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This will also delete all comments.'),
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
          .deletePost(widget.post, widget.post.authorId, widget.isLeader);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post deleted.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  void dispose() {
    commentCtrl.dispose();
    super.dispose();
  }
}
