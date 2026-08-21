import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';
import '../tasks/task_screens.dart';
import '../workspace/note_screens.dart';
import '../files/files_screen.dart';
import '../discussion/discussion_screen.dart';
import 'submission_screen.dart';

class GroupsPage extends ConsumerWidget {
  const GroupsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox();
    final data = ref.watch(membershipsProvider(user.uid));
    return Scaffold(
      appBar: AppBar(title: const Text('My groups')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
      body: data.when(
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.groups_outlined,
                title: 'Create your first group',
                message:
                    'Bring your coursework, tasks, files, and conversations together.',
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) => _GroupTile(membership: items[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load groups',
          message: '$e',
        ),
      ),
    );
  }
}

class _GroupTile extends ConsumerWidget {
  const _GroupTile({required this.membership});
  final Membership membership;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(membership.groupId)).value;
    if (group == null) return const SizedBox();
    return Card(
      child: ListTile(
        title: Text(group.name),
        subtitle: Text('${group.course} • ${group.code}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                GroupDetailScreen(groupId: group.id, membership: membership),
          ),
        ),
      ),
    );
  }
}

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});
  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      course = TextEditingController(),
      description = TextEditingController(),
      title = TextEditingController(),
      max = TextEditingController(text: '6');
  DateTime deadline = DateTime.now().add(const Duration(days: 14));
  String join = 'open';
  bool loading = false;
  @override
  void dispose() {
    for (final c in [name, course, description, title, max]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create group')),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          input(name, 'Group name', true),
          input(course, 'Course / subject', true),
          input(description, 'Description', false, 3),
          input(title, 'Coursework title', true),
          input(max, 'Maximum members', true, 1, true),
          ListTile(
            title: const Text('Deadline'),
            subtitle: Text(
              '${deadline.day}/${deadline.month}/${deadline.year}',
            ),
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime(2035),
                initialDate: deadline,
              );
              if (d != null) setState(() => deadline = d);
            },
          ),
          DropdownButtonFormField(
            value: join,
            items: const [
              DropdownMenuItem(value: 'open', child: Text('Open')),
              DropdownMenuItem(
                value: 'request',
                child: Text('Request to join'),
              ),
              DropdownMenuItem(value: 'invite', child: Text('Invite only')),
            ],
            onChanged: (v) => setState(() => join = v!),
          ),
          const SizedBox(height: 20),
          AppButton(label: 'Create group', loading: loading, onPressed: create),
        ],
      ),
    ),
  );
  Widget input(
    TextEditingController c,
    String label,
    bool required, [
    int lines = 1,
    bool num = false,
  ]) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      maxLines: lines,
      keyboardType: num ? TextInputType.number : null,
      decoration: InputDecoration(labelText: label),
      validator: (v) => required && (v == null || v.trim().isEmpty)
          ? '$label is required.'
          : null,
    ),
  );
  Future<void> create() async {
    if (!form.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() => loading = true);
    try {
      final g = await ref
          .read(groupRepositoryProvider)
          .create(
            name: name.text,
            course: course.text,
            description: description.text,
            maxMembers: int.parse(max.text),
            courseworkTitle: title.text,
            deadline: deadline,
            joinType: join,
            leader: user,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Group created. Code: ${g.code}')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});
  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final code = TextEditingController();
  bool loading = false;
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Join group')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Enter the code shared by your group leader.'),
          const SizedBox(height: 16),
          TextField(
            controller: code,
            decoration: const InputDecoration(labelText: 'Group code'),
          ),
          const SizedBox(height: 16),
          AppButton(label: 'Join group', loading: loading, onPressed: join),
        ],
      ),
    ),
  );
  Future<void> join() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() => loading = true);
    try {
      final m = await ref
          .read(groupRepositoryProvider)
          .joinByCode(code: code.text, user: user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

class GroupDetailScreen extends ConsumerWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.membership,
  });
  final String groupId;
  final Membership membership;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(groupProvider(groupId));
    return item.when(
      data: (g) => g == null
          ? const Scaffold(
              body: EmptyState(
                icon: Icons.lock_outline,
                title: 'Group unavailable',
                message: 'You no longer have access.',
              ),
            )
          : DefaultTabController(
              length: 6,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(g.name),
                  actions: [
                    if (membership.isLeader)
                      IconButton(
                        icon: const Icon(Icons.send_outlined),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubmissionScreen(group: g),
                          ),
                        ),
                      ),
                  ],
                  bottom: const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'Overview'),
                      Tab(text: 'Tasks'),
                      Tab(text: 'Workspace'),
                      Tab(text: 'Files'),
                      Tab(text: 'Discussion'),
                      Tab(text: 'Members'),
                    ],
                  ),
                ),
                body: TabBarView(
                  children: [
                    Overview(group: g),
                    GroupTasksPage(group: g, membership: membership),
                    NotesPage(group: g),
                    FilesPage(group: g, isLeader: membership.isLeader),
                    DiscussionPage(group: g, isLeader: membership.isLeader),
                    MembersPage(group: g, membership: membership),
                  ],
                ),
              ),
            ),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load group',
          message: '$e',
        ),
      ),
    );
  }
}

class Overview extends ConsumerWidget {
  const Overview({super.key, required this.group});
  final Group group;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(groupTasksProvider(group.id)).value ?? [];
    final done = tasks.where((t) => t.completed).length;
    final progress = tasks.isEmpty ? 0.0 : done / tasks.length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.course),
                Text(
                  group.courseworkTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).round()}% complete • $done/${tasks.length} tasks',
                ),
              ],
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.vpn_key),
          title: const Text('Group code'),
          subtitle: Text(group.code),
        ),
        if (group.deadline != null)
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Coursework deadline'),
            subtitle: Text(
              '${group.deadline!.day}/${group.deadline!.month}/${group.deadline!.year}',
            ),
          ),
        if (group.repositoryUrl != null)
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('GitHub repository'),
            subtitle: Text(group.repositoryUrl!),
          ),
      ],
    );
  }
}

class MembersPage extends ConsumerWidget {
  const MembersPage({super.key, required this.group, required this.membership});
  final Group group;
  final Membership membership;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(membersProvider(group.id));
    return data.when(
      data: (items) => ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          final m = items[i];
          return ListTile(
            leading: CircleAvatar(
              child: Text(m.fullName.isEmpty ? '?' : m.fullName[0]),
            ),
            title: Text(m.fullName),
            subtitle: Text(m.isLeader ? 'Group leader' : 'Member'),
            trailing: membership.isLeader && !m.isLeader
                ? IconButton(
                    icon: const Icon(Icons.person_remove_outlined),
                    onPressed: () async {
                      try {
                        await ref
                            .read(groupRepositoryProvider)
                            .removeMember(
                              group: group,
                              member: m,
                              actorId: membership.userId,
                            );
                      } catch (e) {
                        if (context.mounted) showError(context, e);
                      }
                    },
                  )
                : null,
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
    );
  }
}
