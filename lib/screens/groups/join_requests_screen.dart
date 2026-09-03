import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class JoinRequestsScreen extends ConsumerWidget {
  const JoinRequestsScreen({super.key, required this.group});
  final Group group;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingJoinRequestsProvider(group.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Join requests')),
      body: requestsAsync.when(
        data: (requests) => requests.isEmpty
            ? const EmptyState(
                icon: Icons.person_add_disabled_outlined,
                title: 'No pending requests',
                message: 'Users who request to join will appear here.',
              )
            : ListView.separated(
                itemCount: requests.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final r = requests[i];
                  final dt = r.createdAt;
                  final dateStr = dt != null
                      ? '${dt.day}/${dt.month}/${dt.year}'
                      : 'Unknown';
                  return ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.person_outline),
                    ),
                    title: Text(r.fullName),
                    subtitle: Text('${r.email} • requested $dateStr'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.green),
                          onPressed: () => _approve(context, ref, r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined,
                              color: Colors.red),
                          onPressed: () => _reject(context, ref, r),
                        ),
                      ],
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load requests',
          message: 'Please check your connection and try again.',
        ),
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    WidgetRef ref,
    JoinRequest request,
  ) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || group.leaderId != user.uid) {
      if (context.mounted) {
        showError(context, 'Only the leader can approve requests.');
      }
      return;
    }
    try {
      await ref.read(groupRepositoryProvider).approveJoinRequest(
            groupId: group.id,
            userId: request.userId,
            userName: request.fullName,
            approver: user,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${request.fullName} approved.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _reject(
    BuildContext context,
    WidgetRef ref,
    JoinRequest request,
  ) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || group.leaderId != user.uid) {
      if (context.mounted) {
        showError(context, 'Only the leader can reject requests.');
      }
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject join request?'),
        content: Text(
          'Reject "${request.fullName}"\'s request to join?',
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
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(groupRepositoryProvider).rejectJoinRequest(
            groupId: group.id,
            userId: request.userId,
            rejecter: user,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${request.fullName} rejected.')),
        );
      }
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}
