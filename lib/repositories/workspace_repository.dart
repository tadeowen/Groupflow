import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

class WorkspaceRepository {
  WorkspaceRepository(this._db);
  final FirebaseFirestore _db;
  Stream<List<GroupNote>> notes(String groupId) => _db
      .collection('notes')
      .where('groupId', isEqualTo: groupId)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => GroupNote.fromMap(d.id, d.data())).toList(),
      );
  Future<void> saveNote({
    required String groupId,
    required String? noteId,
    required String title,
    required String content,
    required String editorId,
  }) async {
    final ref = noteId == null
        ? _db.collection('notes').doc()
        : _db.collection('notes').doc(noteId);
    final old = await ref.get();
    final batch = _db.batch();
    if (old.exists && old.data()!['content'] != content)
      batch.set(_db.collection('noteVersions').doc(), {
        'noteId': ref.id,
        'content': old.data()!['content'],
        'editedBy': editorId,
        'editedAt': FieldValue.serverTimestamp(),
      });
    batch.set(ref, {
      'groupId': groupId,
      'title': title.trim(),
      'content': content,
      'updatedBy': editorId,
      'updatedAt': FieldValue.serverTimestamp(),
      if (!old.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }
}
