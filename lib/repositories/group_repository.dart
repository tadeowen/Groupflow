import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

const groupCreatorEmail = 'mugalu2026@gmail.com';

class GroupRepository {
  GroupRepository(this._db);
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _groups =>
      _db.collection('groups');
  String _code() =>
      'GF-${List.generate(4, (_) => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'[Random.secure().nextInt(32)]).join()}';

  Stream<List<Membership>> memberships(String uid) => _db
      .collection('groupMembers')
      .where('userId', isEqualTo: uid)
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map(
        (s) => s.docs.map((d) => Membership.fromMap(d.id, d.data())).toList(),
      );
  Stream<Group?> group(String id) => _groups
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Group.fromMap(d.id, d.data()!) : null);
  Stream<List<Membership>> members(String groupId) => _db
      .collection('groupMembers')
      .where('groupId', isEqualTo: groupId)
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map(
        (s) => s.docs.map((d) => Membership.fromMap(d.id, d.data())).toList(),
      );

  Future<Group> create({
    required String name,
    required String course,
    required String description,
    required int maxMembers,
    required String courseworkTitle,
    required DateTime deadline,
    required String joinType,
    required AppUser leader,
  }) async {
    if (leader.email.trim().toLowerCase() != groupCreatorEmail) {
      throw StateError(
        'Only $groupCreatorEmail is allowed to create groups.',
      );
    }
    final groupRef = _groups.doc();
    final membershipRef = _db
        .collection('groupMembers')
        .doc('${groupRef.id}_${leader.uid}');
    final code = _code();
    final projectRef = _db.collection('projects').doc();
    final batch = _db.batch();
    batch.set(groupRef, {
      'name': name.trim(),
      'course': course.trim(),
      'description': description.trim(),
      'maxMembers': maxMembers,
      'courseworkTitle': courseworkTitle.trim(),
      'deadline': Timestamp.fromDate(deadline),
      'joinType': joinType,
      'code': code,
      'leaderId': leader.uid,
      'isLocked': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('groupJoinCodes').doc(code), {
      'code': code,
      'groupId': groupRef.id,
      'name': name.trim(),
      'maxMembers': maxMembers,
      'joinType': joinType,
      'isLocked': false,
    });
    batch.set(membershipRef, {
      'groupId': groupRef.id,
      'userId': leader.uid,
      'fullName': leader.fullName,
      'role': 'leader',
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(projectRef, {
      'groupId': groupRef.id,
      'title': courseworkTitle.trim(),
      'description': description.trim(),
      'deadline': Timestamp.fromDate(deadline),
      'status': 'active',
      'createdBy': leader.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('activityLogs').doc(), {
      'groupId': groupRef.id,
      'projectId': projectRef.id,
      'actorId': leader.uid,
      'actorName': leader.fullName,
      'actionType': 'groupCreated',
      'description': '${leader.fullName} created the group',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return Group(
      id: groupRef.id,
      name: name,
      course: course,
      leaderId: leader.uid,
      code: code,
      maxMembers: maxMembers,
      joinType: joinType,
      description: description,
      courseworkTitle: courseworkTitle,
      deadline: deadline,
    );
  }

  Stream<List<Project>> projects(String groupId) => _db
      .collection('projects')
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map((s) => s.docs.map((d) => Project.fromMap(d.id, d.data())).toList());
  Stream<Project?> project(String id) => _db
      .collection('projects')
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Project.fromMap(d.id, d.data()!) : null);

  Future<Project> createProject({
    required String groupId,
    required String title,
    required String description,
    required DateTime deadline,
    required String actorId,
  }) async {
    final groupSnap = await _groups.doc(groupId).get();
    if (!groupSnap.exists) throw StateError('Group not found.');
    final group = Group.fromMap(groupSnap.id, groupSnap.data()!);
    if (group.leaderId != actorId) {
      throw StateError('Only the leader can create projects.');
    }
    final ref = _db.collection('projects').doc();
    final batch = _db.batch();
    batch.set(ref, {
      'groupId': groupId,
      'title': title.trim(),
      'description': description.trim(),
      'deadline': Timestamp.fromDate(deadline),
      'status': 'active',
      'createdBy': actorId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('activityLogs').doc(), {
      'groupId': groupId,
      'projectId': ref.id,
      'actorId': actorId,
      'actorName': '',
      'actionType': 'projectCreated',
      'description': 'Created project "$title"',
      'targetId': ref.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return Project(
      id: ref.id,
      groupId: groupId,
      title: title,
      description: description,
      deadline: deadline,
      createdBy: actorId,
    );
  }

  Future<String> joinByCode({
    required String code,
    required AppUser user,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    final codeSnap =
        await _db.collection('groupJoinCodes').doc(normalizedCode).get();
    if (!codeSnap.exists) throw StateError('That group code does not exist.');
    final codeData = codeSnap.data()!;
    final groupId = codeData['groupId'] as String;
    final groupName = codeData['name'] as String? ?? 'group';
    final joinType = codeData['joinType'] as String? ?? 'invite';
    if (codeData['isLocked'] == true) throw StateError('This group is locked.');
    final groupSnap = await _groups.doc(groupId).get();
    if (!groupSnap.exists) throw StateError('This group is no longer available.');
    final group = Group.fromMap(groupSnap.id, groupSnap.data()!);
    if (group.code != normalizedCode) {
      throw StateError('This group code is no longer valid.');
    }
    final memberRef = _db
        .collection('groupMembers')
        .doc('${groupId}_${user.uid}');
    final existing = await memberRef.get();
    if (existing.exists) {
      final status = existing.data()!['status'] as String? ?? 'unknown';
      if (status == 'active') {
        throw StateError('You are already a member of this group.');
      }
      throw StateError(
        'You were removed from this group. Contact the leader.',
      );
    }
    if (joinType == 'invite') {
      throw StateError('This group is invite only.');
    }
    if (joinType == 'request') {
      final requestRef = _db
          .collection('joinRequests')
          .doc('${groupId}_${user.uid}');
      final existingRequest = await requestRef.get();
      if (existingRequest.exists) {
        final reqStatus =
            existingRequest.data()!['status'] as String? ?? 'unknown';
        if (reqStatus == 'pending') {
          throw StateError('Your join request is already pending.');
        }
        if (reqStatus == 'rejected') {
          await requestRef.update({
            'fullName': user.fullName,
            'email': user.email,
            'status': 'pending',
            'createdAt': FieldValue.serverTimestamp(),
            'rejectedBy': FieldValue.delete(),
            'rejectedAt': FieldValue.delete(),
          });
          return 'Your request has been sent to the group leader.';
        }
      }
      await requestRef.set({
        'groupId': groupId,
        'userId': user.uid,
        'fullName': user.fullName,
        'email': user.email,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return 'Your request has been sent to the group leader.';
    }
    final active = await _db
        .collection('groupMembers')
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    if (active.count! >= group.maxMembers) {
      throw StateError('This group is full.');
    }
    await memberRef.set({
      'groupId': groupId,
      'userId': user.uid,
      'fullName': user.fullName,
      'role': 'member',
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('activityLogs').add({
      'groupId': groupId,
      'actorId': user.uid,
      'actorName': user.fullName,
      'actionType': 'memberJoined',
      'description': '${user.fullName} joined the group',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return 'You joined $groupName.';
  }

  Stream<List<JoinRequest>> joinRequests(String groupId) => _db
      .collection('joinRequests')
      .where('groupId', isEqualTo: groupId)
      .where('status', isEqualTo: 'pending')
      .snapshots()
      .map((s) => s.docs.map((d) => JoinRequest.fromMap(d.id, d.data())).toList());

  Future<void> approveJoinRequest({
    required String groupId,
    required String userId,
    required String userName,
    required AppUser approver,
  }) async {
    final requestRef =
        _db.collection('joinRequests').doc('${groupId}_$userId');
    final existing = await requestRef.get();
    if (!existing.exists) throw StateError('No pending request found.');
    final data = existing.data()!;
    if ((data['status'] as String? ?? 'unknown') != 'pending') {
      throw StateError('This request has already been handled.');
    }
    final memberRef = _db.collection('groupMembers').doc('${groupId}_$userId');
    final groupSnap = await _groups.doc(groupId).get();
    if (!groupSnap.exists) throw StateError('Group not found.');
    final group = Group.fromMap(groupSnap.id, groupSnap.data()!);
    final active = await _db
        .collection('groupMembers')
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    if (active.count! >= group.maxMembers) {
      throw StateError('The group is now full.');
    }
    final batch = _db.batch();
    batch.update(requestRef, {
      'status': 'approved',
      'approvedBy': approver.uid,
      'approvedAt': FieldValue.serverTimestamp(),
    });
    batch.set(memberRef, {
      'groupId': groupId,
      'userId': userId,
      'fullName': data['fullName'] ?? userName,
      'role': 'member',
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('activityLogs').doc(), {
      'groupId': groupId,
      'actorId': approver.uid,
      'actorName': approver.fullName,
      'actionType': 'memberJoined',
      'description': '${approver.fullName} approved ${data['fullName']} to join',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> rejectJoinRequest({
    required String groupId,
    required String userId,
    required AppUser rejecter,
  }) async {
    final requestRef =
        _db.collection('joinRequests').doc('${groupId}_$userId');
    final existing = await requestRef.get();
    if (!existing.exists) throw StateError('No pending request found.');
    final data = existing.data()!;
    if ((data['status'] as String? ?? 'unknown') != 'pending') {
      throw StateError('This request has already been handled.');
    }
    await requestRef.update({
      'status': 'rejected',
      'rejectedBy': rejecter.uid,
      'rejectedAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('activityLogs').add({
      'groupId': groupId,
      'actorId': rejecter.uid,
      'actorName': rejecter.fullName,
      'actionType': 'joinRequestRejected',
      'description': '${rejecter.fullName} rejected a join request',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeMember({
    required Group group,
    required Membership member,
    required String actorId,
    required String actorName,
  }) async {
    if (group.leaderId != actorId) {
      throw StateError('Only the leader can remove members.');
    }
    if (member.isLeader) {
      throw StateError('Cannot remove the group leader.');
    }
    await _db.collection('groupMembers').doc(member.id).update({
      'status': 'removed',
      'removedAt': FieldValue.serverTimestamp(),
      'removedBy': actorId,
    });
    await _db.collection('activityLogs').add({
      'groupId': group.id,
      'actorId': actorId,
      'actorName': actorName,
      'actionType': 'memberRemoved',
      'description': '$actorName removed ${member.fullName} from the group',
      'targetId': member.userId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSettings({
    required Group group,
    required String actorId,
    String? name,
    String? description,
    String? courseworkTitle,
    int? maxMembers,
    String? joinType,
    bool? isLocked,
    DateTime? deadline,
  }) async {
    if (group.leaderId != actorId) {
      throw StateError('Only the leader can update group settings.');
    }
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name.trim();
    if (description != null) updates['description'] = description.trim();
    if (courseworkTitle != null) updates['courseworkTitle'] = courseworkTitle.trim();
    if (maxMembers != null) updates['maxMembers'] = maxMembers;
    if (joinType != null) updates['joinType'] = joinType;
    if (isLocked != null) updates['isLocked'] = isLocked;
    if (deadline != null) updates['deadline'] = Timestamp.fromDate(deadline);
    if (updates.isEmpty) return;
    final batch = _db.batch();
    batch.update(_groups.doc(group.id), updates);
    if (name != null ||
        maxMembers != null ||
        joinType != null ||
        isLocked != null) {
      final joinCodeUpdates = <String, dynamic>{};
      if (name != null) joinCodeUpdates['name'] = name.trim();
      if (maxMembers != null) joinCodeUpdates['maxMembers'] = maxMembers;
      if (joinType != null) joinCodeUpdates['joinType'] = joinType;
      if (isLocked != null) joinCodeUpdates['isLocked'] = isLocked;
      batch.update(
        _db.collection('groupJoinCodes').doc(group.code),
        joinCodeUpdates,
      );
    }
    await batch.commit();
  }

  Future<void> updateProject({
    required Project project,
    required String actorId,
    String? title,
    String? description,
    DateTime? deadline,
    String? status,
  }) async {
    final groupSnap = await _groups.doc(project.groupId).get();
    if (!groupSnap.exists) throw StateError('Group not found.');
    final group = Group.fromMap(groupSnap.id, groupSnap.data()!);
    if (group.leaderId != actorId) {
      throw StateError('Only the leader can update the project.');
    }
    final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (title != null) updates['title'] = title.trim();
    if (description != null) updates['description'] = description.trim();
    if (deadline != null) updates['deadline'] = Timestamp.fromDate(deadline);
    if (status != null) updates['status'] = status;
    await _db.collection('projects').doc(project.id).update(updates);
  }

  Future<void> updateRepository(Group group, String actorId, String url) async {
    if (group.leaderId != actorId) {
      throw StateError('Only the leader can update the repository.');
    }
    final repoName = _repositoryName(url);
    await _groups.doc(group.id).update({
      'repositoryUrl': url.trim(),
      'repositoryName': repoName,
      'addedBy': actorId,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  String? _repositoryName(String url) {
    final segments =
        Uri.tryParse(url)?.pathSegments.where((s) => s.isNotEmpty).toList() ??
        [];
    return segments.isEmpty ? null : segments.last;
  }
}
