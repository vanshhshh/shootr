import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../models/app_user.dart';
import 'firestore_paths.dart';
import 'firestore_serializers.dart';

class FirestoreUserService {
  FirestoreUserService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(FirestoreCollections.users);

  String? get currentUid => _auth.currentUser?.uid;

  Future<AppUser?> getCurrentUser() async {
    final uid = currentUid;
    if (uid == null) {
      return null;
    }
    final snapshot = await _users.doc(uid).get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return AppUserFirestoreX.fromFirestoreMap(data, id: snapshot.id);
  }

  Future<List<AppUser>> getShootrs() async {
    final snapshot = await _users
        .where('role', isEqualTo: UserRole.shootr.name)
        .where('accountStatus', isEqualTo: AccountStatus.active.name)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    return snapshot.docs
        .map(
          (doc) => AppUserFirestoreX.fromFirestoreMap(doc.data(), id: doc.id),
        )
        .toList();
  }

  Future<List<AppUser>> getShootrsForAdmin() async {
    final snapshot = await _users
        .where('role', isEqualTo: UserRole.shootr.name)
        .limit(300)
        .get();
    final shootrs = snapshot.docs
        .map(
          (doc) => AppUserFirestoreX.fromFirestoreMap(doc.data(), id: doc.id),
        )
        .toList();
    shootrs.sort((a, b) => b.activeSince.compareTo(a.activeSince));
    return shootrs;
  }

  Future<List<AppUser>> getClientsForAdmin() async {
    final snapshot = await _users
        .where('role', isEqualTo: UserRole.client.name)
        .limit(100)
        .get();
    final clients = snapshot.docs
        .map(
          (doc) => AppUserFirestoreX.fromFirestoreMap(doc.data(), id: doc.id),
        )
        .toList();
    clients.sort((a, b) => b.activeSince.compareTo(a.activeSince));
    return clients;
  }

  Future<List<AppUser>> getAllUsersForAdmin() async {
    final snapshot = await _users.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map(
          (doc) => AppUserFirestoreX.fromFirestoreMap(doc.data(), id: doc.id),
        )
        .toList();
  }

  Future<void> upsertUser(AppUser user) async {
    await _users
        .doc(user.id)
        .set(user.toFirestoreMap(), SetOptions(merge: true));
  }

  Future<void> saveCurrentFcmToken() async {
    final uid = currentUid;
    if (uid == null) {
      return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      return;
    }
    await _users.doc(uid).set(<String, dynamic>{
      'fcmTokens': FieldValue.arrayUnion(<String>[token]),
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteUser(String userId) async {
    await _users.doc(userId).delete();
  }
}
