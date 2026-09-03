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
final projectsProvider = StreamProvider.family<List<Project>, String>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).projects(groupId),
);
final projectProvider = StreamProvider.family<Project?, String>(
  (ref, id) => ref.watch(groupRepositoryProvider).project(id),
);
final membersProvider = StreamProvider.family<List<Membership>, String>(
  (ref, id) => ref.watch(groupRepositoryProvider).members(id),
);
final pendingJoinRequestsProvider =
    StreamProvider.family<List<JoinRequest>, String>(
  (ref, groupId) => ref.watch(groupRepositoryProvider).joinRequests(groupId),
);
final projectTasksProvider = StreamProvider.family<List<GroupTask>, String>(
  (ref, projectId) => ref.watch(taskRepositoryProvider).projectTasks(projectId),
);
final assignedTasksProvider = StreamProvider.family<List<GroupTask>, String>(
  (ref, uid) => ref.watch(taskRepositoryProvider).assignedTasks(uid),
);
final projectProgressProvider =
    StreamProvider.family<int, String>((ref, projectId) =>
        ref.watch(taskRepositoryProvider).projectProgress(projectId));
final notesProvider = StreamProvider.family<List<GroupNote>, String>(
  (ref, projectId) => ref.watch(workspaceRepositoryProvider).projectNotes(projectId),
);
final noteVersionsProvider = StreamProvider.family<List<NoteVersion>, String>(
  (ref, noteId) =>
      ref.watch(workspaceRepositoryProvider).noteVersions(noteId),
);
final filesProvider = StreamProvider.family<List<WorkspaceFile>, String>(
  (ref, projectId) => ref.watch(collaborationRepositoryProvider).projectFiles(projectId),
);
final postsProvider = StreamProvider.family<List<DiscussionPost>, String>(
  (ref, projectId) =>
      ref.watch(collaborationRepositoryProvider).projectPosts(projectId),
);
final commentsProvider = StreamProvider.family<List<Comment>, String>(
  (ref, postId) =>
      ref.watch(collaborationRepositoryProvider).postComments(postId),
);
final announcementsProvider =
    StreamProvider.family<List<Announcement>, String>((ref, groupId) =>
        ref.watch(collaborationRepositoryProvider).announcements(groupId));
final submissionsProvider = StreamProvider.family<List<Submission>, String>(
  (ref, projectId) =>
      ref.watch(collaborationRepositoryProvider).submissions(projectId),
);
final activityLogsProvider = StreamProvider.family<List<ActivityLog>, String>(
  (ref, groupId) =>
      ref.watch(collaborationRepositoryProvider).activityLogs(groupId),
);
final notificationsProvider =
    StreamProvider.family<List<AppNotification>, String>(
      (ref, uid) => ref.watch(collaborationRepositoryProvider).notifications(uid),
    );
