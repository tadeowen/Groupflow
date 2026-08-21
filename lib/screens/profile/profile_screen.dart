import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CircleAvatar(
                  radius: 38,
                  child: Text(
                    profile.fullName.isEmpty
                        ? '?'
                        : profile.fullName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    profile.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Center(child: Text(profile.email)),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.badge_outlined),
                        title: const Text('Student number'),
                        subtitle: Text(profile.studentNumber ?? 'Not added'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: Theme.of(context).brightness == Brightness.dark,
                        onChanged: null,
                        title: const Text('Dark mode'),
                        subtitle: const Text('Follows your device setting'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ],
            ),
    );
  }
}
