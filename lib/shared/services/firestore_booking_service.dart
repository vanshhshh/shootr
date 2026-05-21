import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/booking.dart';
import 'firestore_paths.dart';
import 'firestore_serializers.dart';

class FirestoreBookingService {
  FirestoreBookingService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection(FirestoreCollections.bookings);

  Future<List<Booking>> getBookingsForUser(AppUser user) async {
    if (user.role == UserRole.admin) {
      final snapshot = await _bookings
          .orderBy('scheduledAt', descending: true)
          .limit(150)
          .get();
      return _bookingsFrom(snapshot);
    }

    final clientSnapshot = await _bookings
        .where('clientId', isEqualTo: user.id)
        .orderBy('scheduledAt', descending: true)
        .limit(100)
        .get();

    final shootrSnapshot = await _bookings
        .where('shootrId', isEqualTo: user.id)
        .limit(100)
        .get();
    final openSnapshot = user.role == UserRole.shootr
        ? await _bookings
              .where('status', isEqualTo: BookingStatus.pending.name)
              .where('shootrId', isEqualTo: '')
              .limit(100)
              .get()
        : null;

    final byId = <String, Booking>{};
    for (final booking in <Booking>[
      ..._bookingsFrom(clientSnapshot),
      ..._bookingsFrom(shootrSnapshot),
      if (openSnapshot != null) ..._bookingsFrom(openSnapshot),
    ]) {
      byId[booking.id] = booking;
    }
    final bookings = byId.values.toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return bookings;
  }

  Stream<List<Booking>> watchBookingsForUser(AppUser user) {
    if (user.role == UserRole.admin) {
      return _bookings
          .orderBy('scheduledAt', descending: true)
          .limit(150)
          .snapshots()
          .map(_bookingsFrom);
    }

    if (user.role == UserRole.client) {
      return _bookings
          .where('clientId', isEqualTo: user.id)
          .orderBy('scheduledAt', descending: true)
          .limit(100)
          .snapshots()
          .map(_bookingsFrom);
    }

    final assigned = <String, Booking>{};
    final open = <String, Booking>{};
    late final StreamController<List<Booking>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? assignedSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? openSub;

    void emit() {
      final bookings = <String, Booking>{...open, ...assigned}.values.toList()
        ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      if (!controller.isClosed) {
        controller.add(bookings);
      }
    }

    controller = StreamController<List<Booking>>(
      onListen: () {
        assignedSub = _bookings
            .where('shootrId', isEqualTo: user.id)
            .limit(100)
            .snapshots()
            .listen((snapshot) {
              assigned
                ..clear()
                ..addEntries(
                  _bookingsFrom(
                    snapshot,
                  ).map((booking) => MapEntry(booking.id, booking)),
                );
              emit();
            }, onError: controller.addError);
        openSub = _bookings
            .where('status', isEqualTo: BookingStatus.pending.name)
            .where('shootrId', isEqualTo: '')
            .limit(100)
            .snapshots()
            .listen((snapshot) {
              open
                ..clear()
                ..addEntries(
                  _bookingsFrom(
                    snapshot,
                  ).map((booking) => MapEntry(booking.id, booking)),
                );
              emit();
            }, onError: controller.addError);
      },
      onCancel: () async {
        await assignedSub?.cancel();
        await openSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> upsertBooking(Booking booking) async {
    await _bookings
        .doc(booking.id)
        .set(booking.toFirestoreMap(), SetOptions(merge: true));
  }

  Future<void> updateBooking(Booking booking) async {
    await upsertBooking(booking);
  }

  Future<void> updateStatus(String bookingId, BookingStatus status) async {
    await _bookings.doc(bookingId).set(<String, dynamic>{
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));
  }

  Future<Booking> claimBooking({
    required String bookingId,
    required AppUser shootr,
  }) async {
    final ref = _bookings.doc(bookingId);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null) {
        throw StateError('Booking was not found.');
      }
      final booking = BookingFirestoreX.fromFirestoreMap(data, id: snapshot.id);
      if (booking.status != BookingStatus.pending ||
          booking.shootrId.isNotEmpty) {
        throw StateError('This booking has already been accepted.');
      }
      final updated = booking.copyWith(
        status: BookingStatus.confirmed,
        shootrId: shootr.id,
        shootrName: shootr.name,
        etaMinutes: shootr.avgResponseMinutes == 0
            ? 8
            : shootr.avgResponseMinutes,
        liveLatitude: shootr.latitude == 0
            ? booking.location.latitude
            : shootr.latitude,
        liveLongitude: shootr.longitude == 0
            ? booking.location.longitude
            : shootr.longitude,
      );
      transaction.update(ref, <String, dynamic>{
        'status': updated.status.name,
        'shootrId': updated.shootrId,
        'shootrName': updated.shootrName,
        'etaMinutes': updated.etaMinutes,
        'liveLatitude': updated.liveLatitude,
        'liveLongitude': updated.liveLongitude,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      return updated;
    });
  }

  List<Booking> _bookingsFrom(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map(
          (doc) => BookingFirestoreX.fromFirestoreMap(doc.data(), id: doc.id),
        )
        .toList();
  }
}
