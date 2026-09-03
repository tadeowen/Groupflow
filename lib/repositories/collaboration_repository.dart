import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/app_models.dart';

class CollaborationRepository {
  CollaborationRepository(this._db, this._storage);
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  Stream<List<WorkspaceFile>> projectFiles(String projectId) => _db
      .collection('files')
      .where('projectId', isEqualTo: projectId)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => WorkspaceFile.fromMap(d.id, d.data())).toList(),
      );
  Future<String> uploadFile({
    required String groupId,
    required String? projectId,
    required String uploaderId,
    required String uploaderName,
    required String filename,
    required String category,
    required Uint8List bytes,
  }) async {
    final id = _db.collection('files').doc().id;
    final safeName = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final storagePath = 'groups/$groupId/$category/$id-$safeName';
    final task = await _storage
        .ref(storagePath)
        .putData(
          bytes,
          SettableMetadata(
            customMetadata: {
              'groupId': groupId,
              'projectId': projectId ?? groupId,
              'uploaderId': uploaderId,
              'uploaderName': uploaderName,
              'filename': filename,
            },
          ),
        );
    final url = await task.ref.getDownloadURL();
    final batch = _db.batch();
    batch.set(_db.collection('files').doc(id), {
      'groupId': groupId,
      'projectId': projectId,
      'filename': filename,
      'storagePath': storagePath,
      'downloadUrl': url,
      'size': bytes.length,
      'fileType': filename.contains('.') ? filename.split('.').last : '',
      'category': category,
      'uploaderId': uploaderId,
      'uploaderName': uploaderName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('activityLogs').doc(), {
      'groupId': groupId,
      'projectId': projectId,
      'actorId': uploaderId,
      'actorName': uploaderName,
      'actionType': 'fileUploaded',
      'description': '$uploaderName uploaded "$filename"',
      'targetId': id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return url;
  }

  Future<void> deleteFile(WorkspaceFile file, String actorId, bool isLeader) async {
    if (!isLeader && file.uploaderId != actorId) {
      throw StateError('Only the leader or uploader can delete files.');
    }
    await _storage.ref(file.storagePath).delete();
    await _db.collection('files').doc(file.id).delete();
  }

  Stream<List<DiscussionPost>> projectPosts(String projectId) => _db
      .collection('discussionPosts')
      .where('projectId', isEqualTo: projectId)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => DiscussionPost.fromMap(d.id, d.data())).toList(),
      );
  Future<void> addPost({
    required String groupId,
    required String projectId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    await _db.collection('discussionPosts').add({
      'groupId': groupId,
      'projectId': projectId,
      'authorId': authorId,
      'authorName': authorName,
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    });
    await _db.collection('activityLogs').add({
      'groupId': groupId,
      'projectId': projectId,
      'actorId': authorId,
      'actorName': authorName,
      'actionType': 'postCreated',
      'description': '$authorName started a discussion',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePost(DiscussionPost post, String content, String actorId, bool isLeader) async {
    if (post.authorId != actorId && !isLeader) {
      throw StateError('Only the author or leader can edit this post.');
    }
    await _db.collection('discussionPosts').doc(post.id).update({
      'content': content.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(DiscussionPost post, String actorId, bool isLeader) async {
    if (post.authorId != actorId && !isLeader) {
      throw StateError('Only the author or leader can delete this post.');
    }
    final batch = _db.batch();
    final comments = await _db
        .collection('comments')
        .where('postId', isEqualTo: post.id)
        .get();
    for (final c in comments.docs) {
      batch.delete(c.reference);
    }
    batch.delete(_db.collection('discussionPosts').doc(post.id));
    await batch.commit();
  }

  Stream<List<Comment>> postComments(String postId) => _db
      .collection('comments')
      .where('postId', isEqualTo: postId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Comment.fromMap(d.id, d.data())).toList());
  Future<void> addComment({
    required String groupId,
    required String postId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    await _db.collection('comments').add({
      'groupId': groupId,
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Announcement>> announcements(String groupId) => _db
      .collection('announcements')
      .where('groupId', isEqualTo: groupId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Announcement.fromMap(d.id, d.data())).toList());
  Future<String> addAnnouncement({
    required String groupId,
    required String authorId,
    required String authorName,
    required String content,
  }) async {
    final ref = _db.collection('announcements').doc();
    final batch = _db.batch();
    batch.set(ref, {
      'groupId': groupId,
      'authorId': authorId,
      'authorName': authorName,
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    });
    batch.set(_db.collection('activityLogs').doc(), {
      'groupId': groupId,
      'actorId': authorId,
      'actorName': authorName,
      'actionType': 'announcementCreated',
      'description': '$authorName posted an announcement',
      'targetId': ref.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return ref.id;
  }

  Future<void> updateAnnouncement(Announcement announcement, String content, String actorId) async {
    await _db.collection('announcements').doc(announcement.id).update({
      'content': content.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('activityLogs').add({
      'groupId': announcement.groupId,
      'actorId': actorId,
      'actorName': announcement.authorName,
      'actionType': 'announcementUpdated',
      'description': 'Announcement updated',
      'targetId': announcement.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAnnouncement(String id, String groupId, String actorId) async {
    await _db.collection('announcements').doc(id).delete();
    await _db.collection('activityLogs').add({
      'groupId': groupId,
      'actorId': actorId,
      'actorName': '',
      'actionType': 'announcementDeleted',
      'description': 'Announcement deleted',
      'targetId': id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> submit({
    required Project project,
    required String authorId,
    required String authorName,
    required String title,
    required String description,
    String? fileUrl,
    String status = 'submitted',
  }) async {
    final groupDoc = await _db.collection('groups').doc(project.groupId).get();
    String? repoUrl;
    if (groupDoc.exists) {
      final data = groupDoc.data()!;
      repoUrl = data['repositoryUrl'] as String?;
    }
    final batch = _db.batch();
    final ref = _db.collection('submissions').doc();
    batch.set(ref, {
      'groupId': project.groupId,
      'projectId': project.id,
      'submittedBy': authorId,
      'submittedByName': authorName,
      'title': title.trim(),
      'description': description.trim(),
      'fileUrl': fileUrl,
      'repositoryUrl': repoUrl,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'submittedAt': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('activityLogs').doc(), {
      'groupId': project.groupId,
      'projectId': project.id,
      'actorId': authorId,
      'actorName': authorName,
      'actionType': 'submissionCreated',
      'description': '$authorName submitted "$title"',
      'targetId': ref.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> submitDirect({
    required Project project,
    required String authorId,
    required String authorName,
    required String title,
    required String description,
    String? fileUrl,
    required String status,
  }) =>
      submit(
        project: project,
        authorId: authorId,
        authorName: authorName,
        title: title,
        description: description,
        fileUrl: fileUrl,
        status: status,
      );

  Stream<List<Submission>> submissions(String projectId) => _db
      .collection('submissions')
      .where('projectId', isEqualTo: projectId)
      .orderBy('submittedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Submission.fromMap(d.id, d.data())).toList());

  Stream<List<ActivityLog>> activityLogs(String groupId) => _db
      .collection('activityLogs')
      .where('groupId', isEqualTo: groupId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => ActivityLog.fromMap(d.id, d.data())).toList());
  Stream<List<AppNotification>> notifications(String uid) => _db
      .collection('notifications')
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList(),
      );
  Future<void> markRead(String id) =>
      _db.collection('notifications').doc(id).update({'isRead': true});
}
