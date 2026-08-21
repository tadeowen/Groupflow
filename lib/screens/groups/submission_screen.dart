import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class SubmissionScreen extends ConsumerStatefulWidget {
  const SubmissionScreen({super.key, required this.group});
  final Group group;
  @override
  ConsumerState<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends ConsumerState<SubmissionScreen> {
  final title = TextEditingController(text: 'Final coursework submission'),
      description = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Submit coursework')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: title,
            decoration: const InputDecoration(labelText: 'Submission title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: description,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Description'),
          ),
          const Spacer(),
          AppButton(
            label: 'Submit coursework',
            loading: busy,
            onPressed: submit,
          ),
        ],
      ),
    ),
  );
  Future<void> submit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Submit coursework?'),
        content: const Text(
          'This creates a final submission record with a timestamp.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;
    setState(() => busy = true);
    try {
      await ref
          .read(collaborationRepositoryProvider)
          .submit(
            group: widget.group,
            authorId: user.uid,
            title: title.text,
            description: description.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coursework submitted successfully.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
