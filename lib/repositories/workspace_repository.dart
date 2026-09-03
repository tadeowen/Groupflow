import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

class WorkspaceRepository {
  WorkspaceRepository(this._db);
  final FirebaseFirestore _db;
  Stream<List<GroupNote>> projectNotes(String projectId) => _db
      .collection('notes')
      .where('projectId', isEqualTo: projectId)
      .snapshots()
      .map(
        (s) => s.docs.map((d) => GroupNote.fromMap(d.id, d.data())).toList(),
      );
  Stream<List<NoteVersion>> noteVersions(String noteId) => _db
      .collection('noteVersions')
      .where('noteId', isEqualTo: noteId)
      .orderBy('editedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => NoteVersion.fromMap(d.id, d.data())).toList());

  Future<void> saveNote({
    required String groupId,
    required String projectId,
    required String? noteId,
    required String title,
    required String content,
    required String editorId,
    required String editorName,
  }) async {
    final ref = noteId == null
        ? _db.collection('notes').doc()
        : _db.collection('notes').doc(noteId);
    final old = await ref.get();
    final batch = _db.batch();
    if (old.exists && old.data()!['content'] != content) {
      batch.set(_db.collection('noteVersions').doc(), {
        'noteId': ref.id,
        'content': old.data()!['content'],
        'editedBy': editorId,
        'editedByName': editorName,
        'editedAt': FieldValue.serverTimestamp(),
      });
    }
    batch.set(
      ref,
      {
        'groupId': groupId,
        'projectId': projectId,
        'title': title.trim(),
        'content': content,
        'updatedBy': editorId,
        'updatedByName': editorName,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!old.exists) 'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(_db.collection('activityLogs').doc(), {
      'groupId': groupId,
      'projectId': projectId,
      'actorId': editorId,
      'actorName': editorName,
      'actionType': old.exists ? 'noteEdited' : 'noteCreated',
      'description': old.exists
          ? '$editorName edited "$title"'
          : '$editorName created note "$title"',
      'targetId': ref.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> deleteNote(GroupNote note) async {
    final versions = await _db
        .collection('noteVersions')
        .where('noteId', isEqualTo: note.id)
        .get();
    final batch = _db.batch();
    for (final v in versions.docs) {
      batch.delete(v.reference);
    }
    batch.delete(_db.collection('notes').doc(note.id));
    await batch.commit();
  }
}
