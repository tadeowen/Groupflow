import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';
import '../groups/group_screens.dart';
import '../tasks/task_screens.dart';
import '../profile/profile_screen.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final pages = [
      DashboardPage(userName: user.fullName, userId: user.uid),
      const GroupsPage(),
      TasksPage(userId: user.uid),
      const NotificationsPage(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: tab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (v) => setState(() => tab = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({
    super.key,
    required this.userName,
    required this.userId,
  });
  final String userName, userId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(membershipsProvider(userId));
    return Scaffold(
      appBar: AppBar(
        title: Text('Good morning, ${userName.split(' ').first}'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                'One workspace for your whole group.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      body: data.when(
        data: (items) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('My groups', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (items.isEmpty)
              EmptyState(
                icon: Icons.groups_2_outlined,
                title: 'No groups yet',
                message: 'Create a group or join one with a code.',
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
            else
              ...items.map(
                (m) => _DashboardGroupTile(membership: m),
              ),
            const SizedBox(height: 26),
            Wrap(
              spacing: 10,
              children: [
                ActionChip(
                  label: const Text('Create group'),
                  avatar: const Icon(Icons.add),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateGroupScreen(),
                    ),
                  ),
                ),
                ActionChip(
                  label: const Text('Join group'),
                  avatar: const Icon(Icons.group_add),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const JoinGroupScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
         loading: () => const Center(child: CircularProgressIndicator()),
         error: (e, _) => const EmptyState(
           icon: Icons.cloud_off,
           title: 'Unable to load groups',
           message: 'Please check your connection and try again.',
         ),
       ),
     );
   }
}

class _DashboardGroupTile extends ConsumerWidget {
  const _DashboardGroupTile({required this.membership});
  final Membership membership;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final group = ref.watch(groupProvider(membership.groupId)).value;
    if (group == null) return const SizedBox();
    return Card(
      child: ListTile(
        title: Text(group.name),
        subtitle: Text(
          membership.isLeader ? 'Group leader' : 'Group member',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GroupDetailScreen(
              groupId: group.id,
              membership: membership,
            ),
          ),
        ),
      ),
    );
  }
}

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final data = ref.watch(notificationsProvider(user.uid));
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: data.when(
        data: (items) => items.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none,
                title: 'You’re all caught up',
                message:
                    'Task assignments and announcements will appear here.',
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final item = items[index];
                  return ListTile(
                    leading: Icon(
                      item.isRead
                          ? Icons.notifications_none
                          : Icons.notifications,
                    ),
                    title: Text(item.title),
                    subtitle: Text(item.message),
                    onTap: () => ref
                        .read(collaborationRepositoryProvider)
                        .markRead(item.id),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load notifications',
          message: 'Please check your connection and try again.',
        ),
      ),
    );
  }
}
