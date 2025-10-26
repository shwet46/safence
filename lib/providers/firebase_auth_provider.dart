import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:safence/services/firestore_service.dart';

class FirebaseAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _db = FirestoreService.instance;

  void _ensureConfigured() {
    // Defensive check: provide a clear error if Firebase hasn't been initialized.
    try {
      // Access default app name to detect initialization. Value is unused.
  // ignore: unused_local_variable
  final _unused = FirebaseAuth.instance.app.name;
    } catch (_) {
      throw StateError('Firebase configuration not found. Ensure platform config files or .env values are present and that Firebase.initializeApp() was called.');
    }
  }

  User? get user => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signUp({required String email, required String password, required String username}) async {
    _ensureConfigured();
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await cred.user?.updateDisplayName(username);
    await _db.setUserProfile(cred.user!.uid, {
      'email': email,
      'username': username,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    _ensureConfigured();
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream(String uid) {
    return _db.userProfileStream(uid);
  }

  Future<void> updateUsername(String uid, String username) async {
    await _db.setUserProfile(uid, {
      'username': username,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _auth.currentUser?.updateDisplayName(username);
    notifyListeners();
  }
}
