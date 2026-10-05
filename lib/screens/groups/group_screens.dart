import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';
import '../tasks/task_screens.dart';
import '../workspace/note_screens.dart';
import '../files/files_screen.dart';
import '../discussion/discussion_screen.dart';
import '../groups/group_settings_screen.dart';
import '../groups/join_requests_screen.dart';
import '../groups/activity_screen.dart';
import '../groups/submission_screen.dart';
import '../groups/announcements_screen.dart';

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
            ? EmptyState(
                icon: Icons.groups_outlined,
                title: 'Create your first group',
                message:
                    'Bring your coursework, tasks, files, and conversations together.',
                action: AppButton(
                  label: 'Create group',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateGroupScreen(),
                    ),
                  ),
                ),
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) => _GroupTile(membership: items[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load groups',
          message: 'Please check your connection and try again.',
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
          _input(name, 'Group name', true),
          _input(course, 'Course / subject', true),
          _input(description, 'Description', false, 3),
          _input(title, 'Coursework title', true),
          _input(max, 'Maximum members', true, 1, true),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Deadline'),
            subtitle: Text(
              '${deadline.day}/${deadline.month}/${deadline.year}',
            ),
            trailing: const Icon(Icons.calendar_today),
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
          DropdownButtonFormField<String>(
            initialValue: join,
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
  Widget _input(
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

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.membership,
  });
  final String groupId;
  final Membership membership;
  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  String? selectedProjectId;
  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider(widget.groupId));
    return groupAsync.when(
      data: (g) {
        if (g == null) {
          return const Scaffold(
            body: EmptyState(
              icon: Icons.lock_outline,
              title: 'Group unavailable',
              message: 'You no longer have access.',
            ),
          );
        }
        final projectsAsync = ref.watch(projectsProvider(widget.groupId));
        return projectsAsync.when(
          data: (projects) {
            if (projects.isEmpty) {
              return Scaffold(
                appBar: AppBar(title: Text(g.name)),
                body: const EmptyState(
                  icon: Icons.folder_off_outlined,
                  title: 'No coursework yet',
                  message: 'Create your first coursework project.',
                ),
                floatingActionButton: widget.membership.isLeader
                    ? FloatingActionButton.extended(
                        onPressed: () => _createProject(context, ref, g),
                        icon: const Icon(Icons.add),
                        label: const Text('New project'),
                      )
                    : null,
              );
            }
            if (selectedProjectId == null ||
                !projects.any((p) => p.id == selectedProjectId)) {
              selectedProjectId = projects.first.id;
            }
            final project = projects.firstWhere(
              (p) => p.id == selectedProjectId!,
            );
            return DefaultTabController(
              length: 6,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(g.name),
                  actions: [
                    if (widget.membership.isLeader)
                      IconButton(
                        icon: const Icon(Icons.send_outlined),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubmissionScreen(project: project),
                          ),
                        ),
                      ),
                    if (widget.membership.isLeader)
                      PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'settings') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => GroupSettingsScreen(group: g),
                              ),
                            );
                          } else if (v == 'requests') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JoinRequestsScreen(group: g),
                              ),
                            );
                          } else if (v == 'activity') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActivityScreen(group: g),
                              ),
                            );
                          } else if (v == 'announcements') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AnnouncementsScreen(
                                  group: g,
                                  isLeader: widget.membership.isLeader,
                                ),
                              ),
                            );
                          } else if (v == 'lock') {
                            _toggleLock(g, context, ref);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'settings',
                            child: Text('Group settings'),
                          ),
                          const PopupMenuItem(
                            value: 'requests',
                            child: Text('Join requests'),
                          ),
                          const PopupMenuItem(
                            value: 'activity',
                            child: Text('Activity timeline'),
                          ),
                          PopupMenuItem(
                            value: 'lock',
                            child: Text(
                              g.isLocked ? 'Unlock group' : 'Lock group',
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'announcements',
                            child: Text('Manage announcements'),
                          ),
                        ],
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
                    Overview(
                      group: g,
                      project: project,
                      membership: widget.membership,
                    ),
                    GroupTasksPage(
                      group: g,
                      project: project,
                      membership: widget.membership,
                    ),
                    NotesPage(
                      group: g,
                      project: project,
                      isLeader: widget.membership.isLeader,
                    ),
                    FilesPage(
                      group: g,
                      project: project,
                      isLeader: widget.membership.isLeader,
                    ),
                    DiscussionPage(
                      group: g,
                      project: project,
                      isLeader: widget.membership.isLeader,
                    ),
                    MembersPage(group: g, membership: widget.membership),
                  ],
                ),
              ),
            );
          },
          loading: () => Scaffold(
            appBar: AppBar(title: Text(g.name)),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(title: Text(g.name)),
            body: const EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load projects',
              message: 'Please check your connection and try again.',
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => const Scaffold(
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load group',
          message: 'Please check your connection and try again.',
        ),
      ),
    );
  }

  Future<void> _createProject(
    BuildContext context,
    WidgetRef ref,
    Group group,
  ) async {
    final title = TextEditingController();
    final description = TextEditingController();
    DateTime deadline = DateTime.now().add(const Duration(days: 14));
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New coursework project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Project title'),
            ),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Deadline'),
              subtitle: Text(
                '${deadline.day}/${deadline.month}/${deadline.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2035),
                  initialDate: deadline,
                );
                if (d != null) deadline = d;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (title.text.trim().isEmpty) return;
              try {
                await ref
                    .read(groupRepositoryProvider)
                    .createProject(
                      groupId: group.id,
                      title: title.text,
                      description: description.text,
                      deadline: deadline,
                      actorId: group.leaderId,
                    );
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Project created.')),
                  );
                }
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleLock(
    Group group,
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      await ref
          .read(groupRepositoryProvider)
          .updateSettings(
            group: group,
            actorId: group.leaderId,
            isLocked: !group.isLocked,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(group.isLocked ? 'Group unlocked.' : 'Group locked.'),
        ),
      );
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class Overview extends ConsumerWidget {
  const Overview({
    super.key,
    required this.group,
    required this.project,
    required this.membership,
  });
  final Group group;
  final Project project;
  final Membership membership;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(projectTasksProvider(project.id));
    final announcementsAsync = ref.watch(announcementsProvider(group.id));
    return tasksAsync.when(
      data: (tasks) {
        final done = tasks.where((t) => t.completed).length;
        final progress = tasks.isEmpty ? 0.0 : done / tasks.length;
        final overdue = tasks.where((t) => t.isOverdue).length;
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
                      project.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).round()}% complete • $done/${tasks.length} tasks',
                    ),
                    if (overdue > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$overdue overdue',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.red),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _section(context, 'Coursework details', [
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Description'),
                subtitle: Text(
                  project.description.isEmpty
                      ? 'No description added.'
                      : project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (project.deadline != null)
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Deadline'),
                  subtitle: Text(
                    '${project.deadline!.day}/${project.deadline!.month}/${project.deadline!.year}',
                  ),
                ),
            ]),
            _section(context, 'Group code', [
              ListTile(
                leading: const Icon(Icons.vpn_key),
                title: const Text('Group code'),
                subtitle: Text(group.code),
              ),
            ]),
            if (group.repositoryUrl != null)
              _section(context, 'GitHub repository', [
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Repository'),
                  subtitle: Text(group.repositoryName ?? group.repositoryUrl!),
                  onTap: () => _launchUrl(context, group.repositoryUrl!),
                ),
              ]),
            announcementsAsync.when(
              data: (announcements) => _section(
                context,
                'Announcements',
                announcements.isEmpty
                    ? [
                        const ListTile(
                          leading: Icon(Icons.campaign_outlined),
                          title: Text('No announcements'),
                          subtitle: Text(
                            'Leader announcements will appear here.',
                          ),
                        ),
                      ]
                    : announcements
                          .take(3)
                          .map(
                            (a) => ListTile(
                              leading: const Icon(Icons.campaign_outlined),
                              title: Text(a.content, maxLines: 2),
                              subtitle: Text(
                                a.authorName.isNotEmpty
                                    ? '${a.authorName} • ${_formatTime(a.createdAt)}'
                                    : _formatTime(a.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          )
                          .toList(),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load tasks',
        message: 'Please check your connection and try again.',
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> children) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              ...children,
            ],
          ),
        ),
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

  void _launchUrl(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('GitHub repository'),
        content: Text('Open this link in your browser?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri.tryParse(url);
              if (uri == null ||
                  !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                if (context.mounted)
                  showError(context, 'Could not open the repository link.');
              }
            },
            child: const Text('Open'),
          ),
        ],
      ),
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
                    onPressed: () => _confirmRemove(context, ref, m),
                  )
                : null,
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const EmptyState(
        icon: Icons.error_outline,
        title: 'Could not load members',
        message: 'Please check your connection and try again.',
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    Membership member,
  ) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text(
          'Remove ${member.fullName} from the group? Their historical '
          'contributions will be preserved.',
        ),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(groupRepositoryProvider)
          .removeMember(
            group: group,
            member: member,
            actorId: membership.userId,
            actorName: membership.fullName,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${member.fullName} removed.')));
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
