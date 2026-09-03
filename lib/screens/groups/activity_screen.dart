import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key, required this.group});
  final Group group;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(activityLogsProvider(group.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: activityAsync.when(
        data: (logs) => logs.isEmpty
            ? const EmptyState(
                icon: Icons.timeline_outlined,
                title: 'No activity yet',
                message: 'Group activity will appear here.',
              )
            : ListView.separated(
                itemCount: logs.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final log = logs[i];
                  final dt = log.createdAt;
                  final dateStr = dt != null
                      ? '${dt.day}/${dt.month}/${dt.year} ${_formatTime(dt)}'
                      : '';
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      child: Text(
                        log.actorName.isNotEmpty
                            ? log.actorName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    title: Text(log.description),
                    subtitle: Text(
                      '${log.actorName.isNotEmpty ? log.actorName : "System"} • $dateStr',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load activity',
          message: 'Please check your connection and try again.',
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
