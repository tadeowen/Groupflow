import 'package:firebase_core/firebase_core.dart';

abstract final class FirebaseService {
  static Future<void> initialize() => Firebase.initializeApp();
}
