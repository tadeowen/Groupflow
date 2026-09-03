import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class TasksPage extends ConsumerWidget {
  const TasksPage({super.key, required this.userId});
  final String userId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(assignedTasksProvider(userId));
    return Scaffold(
      appBar: AppBar(title: const Text('My tasks')),
      body: tasks.when(
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.task_alt,
                title: 'No assigned tasks',
                message: 'Tasks assigned to you will appear here.',
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: items
                    .map((t) => TaskCard(task: t, isLeader: false))
                    .toList(),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load tasks',
          message: 'Please check your connection and try again.',
        ),
      ),
    );
  }
}

class GroupTasksPage extends ConsumerWidget {
  const GroupTasksPage({
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
    final result = ref.watch(projectTasksProvider(project.id));
    return Scaffold(
      floatingActionButton: membership.isLeader
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CreateTaskScreen(group: group, project: project),
                ),
              ),
              child: const Icon(Icons.add),
            )
          : null,
      body: result.when(
        data: (tasks) => tasks.isEmpty
            ? const EmptyState(
                icon: Icons.checklist_outlined,
                title: 'No tasks yet',
                message:
                    'Create your first task to start organizing the project.',
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: tasks
                    .map(
                      (t) => TaskCard(
                        task: t,
                        isLeader: membership.isLeader,
                        project: project,
                        group: group,
                      ),
                    )
                    .toList(),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load tasks',
          message: 'Please check your connection and try again.',
        ),
      ),
    );
  }
}

class TaskCard extends ConsumerWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.isLeader,
    this.project,
    this.group,
  });
  final GroupTask task;
  final bool isLeader;
  final Project? project;
  final Group? group;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final canEdit = task.assignedTo == user?.uid || isLeader;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusBadge(status: task.status),
              ],
            ),
            if (task.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 16,
                  color: _priority(task.priority),
                ),
                const SizedBox(width: 5),
                Text(task.priority.toUpperCase()),
                const Spacer(),
                if (task.deadline != null)
                  Text(
                    '${task.deadline!.day}/${task.deadline!.month}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color:
                            task.isOverdue ? Colors.red : null),
                  ),
              ],
            ),
            if (task.assignedTo != null && task.assignedName.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Assigned to ${task.assignedName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (canEdit)
              Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<String>(
                  onSelected: (v) async {
                    try {
                      await ref.read(taskRepositoryProvider).updateStatus(
                            task,
                            v,
                            user!.uid,
                            isLeader,
                            user.fullName,
                          );
                    } catch (e) {
                      if (context.mounted) showError(context, e);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'notStarted',
                      child: Text('Not started'),
                    ),
                    PopupMenuItem(
                      value: 'inProgress',
                      child: Text('In progress'),
                    ),
                    PopupMenuItem(
                      value: 'blocked',
                      child: Text('Blocked'),
                    ),
                    PopupMenuItem(
                      value: 'completed',
                      child: Text('Mark complete'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _priority(String p) => switch (p) {
        'urgent' => Colors.red,
        'high' => Colors.orange,
        _ => Colors.blue,
      };
}

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({
    super.key,
    required this.group,
    required this.project,
  });
  final Group group;
  final Project project;
  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final form = GlobalKey<FormState>(),
      title = TextEditingController(),
      description = TextEditingController();
  String? assignee;
  String? assigneeName;
  String priority = 'medium';
  DateTime deadline = DateTime.now().add(const Duration(days: 7));
  bool loading = false;
  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider(widget.group.id)).value ?? [];
    final activeMembers = members.where((m) => m.status == 'active').toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Create task')),
      body: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Task title'),
              validator: (v) =>
                  v!.trim().isEmpty ? 'A title is required.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: assignee,
              decoration: const InputDecoration(labelText: 'Assign to'),
              items: activeMembers
                  .map(
                    (m) => DropdownMenuItem(
                      value: m.userId,
                      child: Text(m.fullName),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  assignee = v;
                  assigneeName = activeMembers
                      .firstWhere((m) => m.userId == v, orElse: () => const Membership(
                          id: '', groupId: '', userId: '', role: '', status: ''))
                      .fullName;
                });
              },
              validator: (v) => v == null ? 'Choose a member.' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              initialValue: priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const ['low', 'medium', 'high', 'urgent']
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(v.toUpperCase()),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => priority = v!),
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
                if (d != null) setState(() => deadline = d);
              },
            ),
            AppButton(
              label: 'Create task',
              loading: loading,
              onPressed: () async {
                if (!form.currentState!.validate()) return;
                final user = ref.read(currentUserProvider).value;
                if (user == null || widget.group.leaderId != user.uid) {
                  showError(context, 'Only the leader can create tasks.');
                  return;
                }
                setState(() => loading = true);
                try {
                  await ref.read(taskRepositoryProvider).create(
                        project: widget.project,
                        title: title.text,
                        description: description.text,
                        assignedTo: assignee!,
                        assignedName: assigneeName ?? '',
                        priority: priority,
                        deadline: deadline,
                        actorId: user.uid,
                        actorName: user.fullName,
                      );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) showError(context, e);
                } finally {
                  if (mounted) setState(() => loading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
