import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_models.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (profile != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(user: profile),
                ),
              ),
            ),
        ],
      ),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainer,
                  child: profile.photoUrl != null
                      ? CircleAvatar(
                          radius: 36,
                          backgroundImage: NetworkImage(profile.photoUrl!),
                        )
                      : Text(
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
                Center(
                  child: Text(
                    profile.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (profile.studentNumber != null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Student #${profile.studentNumber}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
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
                      ListTile(
                        leading: const Icon(Icons.email_outlined),
                        title: const Text('Email'),
                        subtitle: Text(profile.email),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('Member since'),
                        subtitle: Text(
                          profile.createdAt != null
                              ? '${profile.createdAt!.day}/${profile.createdAt!.month}/${profile.createdAt!.year}'
                              : 'Unknown',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Change password'),
                        subtitle: const Text('Reset via email'),
                        onTap: () => _showPasswordReset(context, ref),
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

  void _showPasswordReset(BuildContext context, WidgetRef ref) {
    final emailCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('We will send a password reset link to your email.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
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
              if (emailCtrl.text.trim().isEmpty) return;
              try {
                await ref
                    .read(authRepositoryProvider)
                    .resetPassword(emailCtrl.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password reset email sent. Check your inbox.',
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) showError(context, e);
              }
            },
            child: const Text('Send reset email'),
          ),
        ],
      ),
    );
  }
}

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.user});
  final AppUser user;
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final name = TextEditingController(text: widget.user.fullName);
  late final student = TextEditingController(
    text: widget.user.studentNumber ?? '',
  );
  bool loading = false;
  @override
  void dispose() {
    name.dispose();
    student.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Edit profile')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Full name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: student,
            decoration: const InputDecoration(
              labelText: 'Student number (optional)',
            ),
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Save', loading: loading, onPressed: save),
        ],
      ),
    ),
  );

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      showError(context, 'Name is required.');
      return;
    }
    setState(() => loading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(
            uid: widget.user.uid,
            fullName: name.text,
            studentNumber: student.text.trim().isEmpty
                ? null
                : student.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile updated.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
