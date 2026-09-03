import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';
import 'package:url_launcher/url_launcher.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  const GroupSettingsScreen({super.key, required this.group});
  final Group group;
  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      course = TextEditingController(),
      description = TextEditingController(),
      title = TextEditingController(),
      max = TextEditingController(),
      repoUrl = TextEditingController();
  DateTime? deadline;
  String join = 'open';
  bool loading = false;

  @override
  void initState() {
    super.initState();
    name.text = widget.group.name;
    course.text = widget.group.course;
    description.text = widget.group.description;
    title.text = widget.group.courseworkTitle;
    max.text = widget.group.maxMembers.toString();
    repoUrl.text = widget.group.repositoryUrl ?? '';
    deadline = widget.group.deadline;
    join = widget.group.joinType;
  }
  @override
  void dispose() {
    for (final c in [name, course, description, title, max, repoUrl]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Group settings')),
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
                subtitle: Text(deadline == null
                    ? 'Not set'
                    : '${deadline!.day}/${deadline!.month}/${deadline!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035),
                    initialDate: deadline ?? DateTime.now(),
                  );
                  if (d != null) setState(() => deadline = d);
                },
              ),
              DropdownButtonFormField<String>(
                initialValue: join,
                decoration: const InputDecoration(labelText: 'Join mode'),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: repoUrl,
                decoration: const InputDecoration(
                  labelText: 'GitHub repository URL',
                  hintText: 'https://github.com/user/repo',
                ),
              ),
              if (widget.group.repositoryUrl != null)
                TextButton.icon(
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in browser'),
                  onPressed: () => launchUrl(Uri.parse(widget.group.repositoryUrl!)),
                ),
              const SizedBox(height: 24),
              SwitchListTile(
                value: widget.group.isLocked,
                onChanged: (v) => _toggleLock(v),
                title: const Text('Lock group'),
                subtitle: const Text(
                  'Prevent new members from joining',
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Save settings',
                loading: loading,
                onPressed: save,
              ),
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
  ]) =>
      Padding(
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

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null || widget.group.leaderId != user.uid) {
      showError(context, 'Only the leader can update group settings.');
      return;
    }
    setState(() => loading = true);
    try {
      await ref.read(groupRepositoryProvider).updateSettings(
            group: widget.group,
            actorId: user.uid,
            name: name.text,
            description: description.text,
            courseworkTitle: title.text,
            maxMembers: int.parse(max.text),
            joinType: join,
            deadline: deadline,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group settings updated.')),
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _toggleLock(bool value) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() => loading = true);
    try {
      await ref.read(groupRepositoryProvider).updateSettings(
            group: widget.group,
            actorId: user.uid,
            isLocked: value,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Group locked.' : 'Group unlocked.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
