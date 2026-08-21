import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

class TaskRepository {
  TaskRepository(this._db);
  final FirebaseFirestore _db;
  Stream<List<GroupTask>> groupTasks(String groupId) => _db
      .collection('tasks')
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map((s) {
        final result = s.docs
            .map((d) => GroupTask.fromMap(d.id, d.data()))
            .toList();
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
  Future<void> create({
    required Group group,
    required String title,
    required String description,
    required String assignedTo,
    required String priority,
    required DateTime deadline,
    required String actorId,
  }) async {
    if (group.leaderId != actorId)
      throw StateError('Only the leader can create tasks.');
    final ref = _db.collection('tasks').doc();
    final batch = _db.batch();
    batch.set(ref, {
      'groupId': group.id,
      'title': title.trim(),
      'description': description.trim(),
      'assignedTo': assignedTo,
      'createdBy': actorId,
      'priority': priority,
      'status': 'notStarted',
      'deadline': Timestamp.fromDate(deadline),
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': null,
    });
    batch.set(_db.collection('notifications').doc(), {
      'userId': assignedTo,
      'title': 'New task assigned',
      'message': title.trim(),
      'type': 'taskAssigned',
      'relatedId': ref.id,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> updateStatus(
    GroupTask task,
    String status,
    String actorId,
    bool isLeader,
  ) async {
    if (task.assignedTo != actorId && !isLeader)
      throw StateError('Only the assignee can update this task.');
    await _db.collection('tasks').doc(task.id).update({
      'status': status,
      if (status == 'completed') 'completedAt': FieldValue.serverTimestamp(),
    });
  }
}
