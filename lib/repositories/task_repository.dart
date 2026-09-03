import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

class TaskRepository {
  TaskRepository(this._db);
  final FirebaseFirestore _db;

  Stream<List<GroupTask>> projectTasks(String projectId) => _db
      .collection('tasks')
      .where('projectId', isEqualTo: projectId)
      .snapshots()
      .map((s) {
        final result =
            s.docs.map((d) => GroupTask.fromMap(d.id, d.data())).toList();
        result.sort(
          (a, b) => (a.deadline ?? DateTime(2100)).compareTo(
            b.deadline ?? DateTime(2100),
          ),
        );
        return result;
      });
  Stream<List<GroupTask>> assignedTasks(String uid) => _db
      .collection('tasks')
      .where('assignedTo', isEqualTo: uid)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => GroupTask.fromMap(d.id, d.data())).toList(),
      );
  Stream<int> projectProgress(String projectId) {
    final stream = projectTasks(projectId);
    return stream.map((tasks) {
      if (tasks.isEmpty) return 0;
      final done = tasks.where((t) => t.completed).length;
      return ((done / tasks.length) * 100).round();
    });
  }

  Future<void> create({
    required Project project,
    required String title,
    required String description,
    required String assignedTo,
    required String assignedName,
    required String priority,
    required DateTime deadline,
    required String actorId,
    required String actorName,
  }) async {
    final groupDoc = await _db.collection('groups').doc(project.groupId).get();
    if (!groupDoc.exists) throw StateError('Group not found.');
    final group = Group.fromMap(groupDoc.id, groupDoc.data()!);
    if (group.leaderId != actorId) {
      throw StateError('Only the leader can create tasks.');
    }
    final ref = _db.collection('tasks').doc();
    final batch = _db.batch();
    batch.set(ref, {
      'groupId': project.groupId,
      'projectId': project.id,
      'title': title.trim(),
      'description': description.trim(),
      'assignedTo': assignedTo,
      'assignedName': assignedName,
      'createdBy': actorId,
      'createdByName': actorName,
      'priority': priority,
      'status': 'notStarted',
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': null,
    });
    batch.set(_db.collection('notifications').doc(), {
      'groupId': project.groupId,
      'userId': assignedTo,
      'title': 'New task assigned',
      'message': title.trim(),
      'type': 'taskAssigned',
      'relatedId': ref.id,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('activityLogs').doc(), {
      'groupId': project.groupId,
      'projectId': project.id,
      'actorId': actorId,
      'actorName': actorName,
      'actionType': 'taskCreated',
      'description': '$actorName assigned "$title" to $assignedName',
      'targetId': ref.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> updateStatus(
    GroupTask task,
    String status,
    String actorId,
    bool isLeader,
    String actorName,
  ) async {
    if (task.assignedTo != actorId && !isLeader) {
      throw StateError('Only the assignee can update this task.');
    }
    final batch = _db.batch();
    final updates = <String, dynamic>{'status': status};
    if (status == 'completed') {
      updates['completedAt'] = FieldValue.serverTimestamp();
    }
    batch.update(_db.collection('tasks').doc(task.id), updates);
    final actionType =
        status == 'completed' ? 'taskCompleted' : 'taskUpdated';
    batch.set(_db.collection('activityLogs').doc(), {
      'groupId': task.groupId,
      'projectId': task.projectId,
      'actorId': actorId,
      'actorName': actorName,
      'actionType': actionType,
      'description': '$actorName marked "${task.title}" as $status',
      'targetId': task.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> delete(
    GroupTask task,
    String actorId,
    bool isLeader,
  ) async {
    if (!isLeader) {
      throw StateError('Only the leader can delete tasks.');
    }
    final batch = _db.batch();
    batch.delete(_db.collection('tasks').doc(task.id));
    batch.set(_db.collection('activityLogs').doc(), {
      'groupId': task.groupId,
      'projectId': task.projectId,
      'actorId': actorId,
      'actorName': '',
      'actionType': 'taskDeleted',
      'description': 'Task "${task.title}" was deleted',
      'targetId': task.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> updateTaskDetails({
    required GroupTask task,
    required String actorId,
    bool isLeader = false,
    String? title,
    String? description,
    String? assignedTo,
    String? priority,
    DateTime? deadline,
  }) async {
    if (!isLeader && task.assignedTo != actorId) {
      throw StateError('Only the leader or assignee can update this task.');
    }
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title.trim();
    if (description != null) updates['description'] = description.trim();
    if (assignedTo != null) updates['assignedTo'] = assignedTo;
    if (priority != null) updates['priority'] = priority;
    if (deadline != null) updates['deadline'] = Timestamp.fromDate(deadline);
    if (updates.isEmpty) return;
    await _db.collection('tasks').doc(task.id).update(updates);
  }
}
