import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/app_models.dart';

class CollaborationRepository {
  CollaborationRepository(this._db, this._storage);
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  Stream<List<WorkspaceFile>> files(String groupId) => _db
      .collection('files')
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => WorkspaceFile.fromMap(d.id, d.data())).toList(),
      );
  Future<void> uploadFile({
    required String groupId,
    required String uploaderId,
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
            customMetadata: {'groupId': groupId, 'uploaderId': uploaderId},
          ),
        );
    final url = await task.ref.getDownloadURL();
    await _db.collection('files').doc(id).set({
      'groupId': groupId,
      'filename': filename,
      'storagePath': storagePath,
      'downloadUrl': url,
      'size': bytes.length,
      'fileType': filename.contains('.') ? filename.split('.').last : '',
      'category': category,
      'uploaderId': uploaderId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteFile(WorkspaceFile file) async {
    await _storage.ref(file.storagePath).delete();
    await _db.collection('files').doc(file.id).delete();
  }

  Stream<List<DiscussionPost>> posts(String groupId) => _db
      .collection('discussionPosts')
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => DiscussionPost.fromMap(d.id, d.data())).toList(),
      );
  Future<void> addPost(String groupId, String authorId, String content) =>
      _db.collection('discussionPosts').add({
        'groupId': groupId,
        'authorId': authorId,
        'content': content.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      });
  Future<void> addAnnouncement(
    String groupId,
    String authorId,
    String content,
  ) => _db.collection('announcements').add({
    'groupId': groupId,
    'authorId': authorId,
    'content': content.trim(),
    'createdAt': FieldValue.serverTimestamp(),
  });
  Future<void> submit({
    required Group group,
    required String authorId,
    required String title,
    required String description,
    String? fileUrl,
  }) => _db.collection('submissions').add({
    'groupId': group.id,
    'title': title.trim(),
    'description': description.trim(),
    'fileUrl': fileUrl,
    'repositoryUrl': group.repositoryUrl,
    'submittedBy': authorId,
    'submittedAt': FieldValue.serverTimestamp(),
    'status': 'submitted',
  });
  Stream<List<AppNotification>> notifications(String uid) => _db
      .collection('notifications')
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => AppNotification.fromMap(d.id, d.data())).toList(),
      );
  Future<void> markRead(String id) =>
      _db.collection('notifications').doc(id).update({'isRead': true});
}
