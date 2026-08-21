import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

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
      .snapshots()
      .map(
        (s) => s.docs
            .map((d) => Membership.fromMap(d.id, d.data()))
            .where((m) => m.status == 'active')
            .toList(),
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
    final groupRef = _groups.doc();
    final membershipRef = _db
        .collection('groupMembers')
        .doc('${groupRef.id}_${leader.uid}');
    final code = _code();
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
    batch.set(membershipRef, {
      'groupId': groupRef.id,
      'userId': leader.uid,
      'fullName': leader.fullName,
      'role': 'leader',
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('activityLogs').doc(), {
      'groupId': groupRef.id,
      'actorId': leader.uid,
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

  Future<String> joinByCode({
    required String code,
    required AppUser user,
  }) async {
    final found = await _groups
        .where('code', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();
    if (found.docs.isEmpty) throw StateError('That group code does not exist.');
    final group = Group.fromMap(found.docs.first.id, found.docs.first.data());
    if (group.isLocked) throw StateError('This group is locked.');
    final memberRef = _db
        .collection('groupMembers')
        .doc('${group.id}_${user.uid}');
    if ((await memberRef.get()).exists)
      throw StateError('You already have a membership record for this group.');
    final active = await _db
        .collection('groupMembers')
        .where('groupId', isEqualTo: group.id)
        .where('status', isEqualTo: 'active')
        .count()
        .get();
    if (active.count! >= group.maxMembers)
      throw StateError('This group is already full.');
    if (group.joinType == 'invite')
      throw StateError('This group is invite only.');
    if (group.joinType == 'request') {
      await _db.collection('joinRequests').doc('${group.id}_${user.uid}').set({
        'groupId': group.id,
        'userId': user.uid,
        'fullName': user.fullName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return 'Your request has been sent to the group leader.';
    }
    await memberRef.set({
      'groupId': group.id,
      'userId': user.uid,
      'fullName': user.fullName,
      'role': 'member',
      'status': 'active',
      'joinedAt': FieldValue.serverTimestamp(),
    });
    return 'You joined ${group.name}.';
  }

  Future<void> removeMember({
    required Group group,
    required Membership member,
    required String actorId,
  }) async {
    if (group.leaderId != actorId || member.isLeader)
      throw StateError('Only the leader can remove members.');
    await _db.collection('groupMembers').doc(member.id).update({
      'status': 'removed',
      'removedAt': FieldValue.serverTimestamp(),
      'removedBy': actorId,
    });
  }

  Future<void> updateRepository(Group group, String actorId, String url) async {
    if (group.leaderId != actorId)
      throw StateError('Only the leader can update the repository.');
    await _groups.doc(group.id).update({
      'repositoryUrl': url.trim(),
      'repositoryName': _repositoryName(url),
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
