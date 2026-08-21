import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class DiscussionPage extends ConsumerStatefulWidget {
  const DiscussionPage({
    super.key,
    required this.group,
    required this.isLeader,
  });
  final Group group;
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
    final data = ref.watch(postsProvider(widget.group.id));
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
            : ListView.builder(
                itemCount: posts.length,
                itemBuilder: (_, i) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(posts[i].content),
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load discussion',
          message: '$e',
        ),
      ),
    );
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
              onPressed: () {
                Navigator.pop(ctx, true);
              },
            ),
          ],
        ),
      ),
    );
    if (posted != true || text.text.trim().isEmpty) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    try {
      await ref
          .read(collaborationRepositoryProvider)
          .addPost(widget.group.id, user.uid, text.text);
      text.clear();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }
}
