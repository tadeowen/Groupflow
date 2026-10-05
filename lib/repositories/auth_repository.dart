import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_models.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db);
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  Stream<User?> get authChanges => _auth.authStateChanges();
  Stream<AppUser?> profile(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((d) => d.exists ? AppUser.fromMap(d.id, d.data()!) : null);
  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  Future<void> signOut() => _auth.signOut();
  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? studentNumber,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;
    await _db.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'fullName': fullName.trim(),
      'email': user.email,
      'studentNumber': studentNumber?.trim(),
      'photoUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  Future<void> updateLastSeen(String uid) => _db
      .collection('users')
      .doc(uid)
      .update({'lastSeen': FieldValue.serverTimestamp()});
  Future<void> updateProfile({
    required String uid,
    required String fullName,
    String? studentNumber,
    String? photoUrl,
  }) => _db.collection('users').doc(uid).update({
    'fullName': fullName.trim(),
    'studentNumber': studentNumber?.trim(),
    'photoUrl': photoUrl,
  });
}
