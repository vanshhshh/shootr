import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/booking.dart';
import '../models/chat_message.dart';
import 'firestore_paths.dart';
import 'firestore_serializers.dart';

class FirestoreChatService {
  FirestoreChatService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _threads =>
      _firestore.collection(FirestoreCollections.chatThreads);

  Future<Map<String, List<ChatMessage>>> getThreadsForBookings(
    List<Booking> bookings,
  ) async {
    final threads = <String, List<ChatMessage>>{};
    for (final booking in bookings.take(30)) {
      final snapshot = await _threads
          .doc(booking.id)
          .collection(FirestoreCollections.messages)
          .orderBy('sentAt')
          .limit(100)
          .get();
      threads[booking.id] = snapshot.docs
          .map(
            (doc) =>
                ChatMessageFirestoreX.fromFirestoreMap(doc.data(), id: doc.id),
          )
          .toList();
    }
    return threads;
  }

  Future<void> sendMessage(ChatMessage message) async {
    final thread = _threads.doc(message.bookingId);
    await thread.set(<String, dynamic>{
      'bookingId': message.bookingId,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
    await thread
        .collection(FirestoreCollections.messages)
        .doc(message.id)
        .set(message.toFirestoreMap(), SetOptions(merge: true));
  }
}
