import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';
import '../models/app_user.dart';
import 'firestore_paths.dart';
import 'firestore_serializers.dart';

class FirestoreNotificationService {
  FirestoreNotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(FirestoreCollections.notifications);

  Future<List<AppNotification>> getNotificationsForUser(AppUser user) async {
    final roleSnapshot = await _notifications
        .where('targetRole', isEqualTo: user.role.name)
        .orderBy('createdAt', descending: true)
        .limit(80)
        .get();

    final userSnapshot = await _notifications
        .where('targetUserId', isEqualTo: user.id)
        .orderBy('createdAt', descending: true)
        .limit(80)
        .get();

    final byId = <String, AppNotification>{};
    for (final notification in <AppNotification>[
      ..._notificationsFrom(roleSnapshot),
      ..._notificationsFrom(userSnapshot),
    ]) {
      byId[notification.id] = notification;
    }
    final notifications = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  }

  Future<void> createNotification(
    AppNotification notification, {
    String? targetUserId,
  }) async {
    await _notifications
        .doc(notification.id)
        .set(
          notification.toFirestoreMap(targetUserId: targetUserId),
          SetOptions(merge: true),
        );
  }

  Future<void> markRead(String notificationId) async {
    await _notifications.doc(notificationId).set(<String, dynamic>{
      'read': true,
    }, SetOptions(merge: true));
  }

  List<AppNotification> _notificationsFrom(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs
        .map(
          (doc) => AppNotificationFirestoreX.fromFirestoreMap(
            doc.data(),
            id: doc.id,
          ),
        )
        .toList();
  }
}
