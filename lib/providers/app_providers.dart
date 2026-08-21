import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_models.dart';
import '../repositories/auth_repository.dart';
import '../repositories/group_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/workspace_repository.dart';
import '../repositories/collaboration_repository.dart';

final authRepositoryProvider = Provider(
  (_) => AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance),
);
final groupRepositoryProvider = Provider(
  (_) => GroupRepository(FirebaseFirestore.instance),
);
final taskRepositoryProvider = Provider(
  (_) => TaskRepository(FirebaseFirestore.instance),
);
final workspaceRepositoryProvider = Provider(
  (_) => WorkspaceRepository(FirebaseFirestore.instance),
);
final collaborationRepositoryProvider = Provider(
  (_) => CollaborationRepository(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  ),
);
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authChanges,
);
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user == null
      ? Stream.value(null)
      : ref.watch(authRepositoryProvider).profile(user.uid);
});
final membershipsProvider = StreamProvider.family<List<Membership>, String>(
  (ref, uid) => ref.watch(groupRepositoryProvider).memberships(uid),
);
final groupProvider = StreamProvider.family<Group?, String>(
  (ref, id) => ref.watch(groupRepositoryProvider).group(id),
);
final membersProvider = StreamProvider.family<List<Membership>, String>(
  (ref, id) => ref.watch(groupRepositoryProvider).members(id),
);
final groupTasksProvider = StreamProvider.family<List<GroupTask>, String>(
  (ref, id) => ref.watch(taskRepositoryProvider).groupTasks(id),
);
final assignedTasksProvider = StreamProvider.family<List<GroupTask>, String>(
  (ref, uid) => ref.watch(taskRepositoryProvider).assignedTasks(uid),
);
final notesProvider = StreamProvider.family<List<GroupNote>, String>(
  (ref, id) => ref.watch(workspaceRepositoryProvider).notes(id),
);
final filesProvider = StreamProvider.family<List<WorkspaceFile>, String>(
  (ref, id) => ref.watch(collaborationRepositoryProvider).files(id),
);
final postsProvider = StreamProvider.family<List<DiscussionPost>, String>(
  (ref, id) => ref.watch(collaborationRepositoryProvider).posts(id),
);
final notificationsProvider =
    StreamProvider.family<List<AppNotification>, String>(
      (ref, id) => ref.watch(collaborationRepositoryProvider).notifications(id),
    );
