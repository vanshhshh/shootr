import 'package:flutter_test/flutter_test.dart';
import 'package:shootr/shared/models/booking.dart';
import 'package:shootr/shared/models/shootr_package.dart';

void main() {
  group('Booking lifecycle', () {
    test('calculates total after platform fee, tax, and credits', () {
      final booking = _booking(
        baseAmount: 1000,
        platformFee: 50,
        taxAmount: 180,
        creditsUsed: 100,
      );

      expect(booking.totalAmount, 1130);
    });

    test(
      'copyWith updates status and payment fields without losing identity',
      () {
        final booking = _booking();
        final updated = booking.copyWith(
          status: BookingStatus.completed,
          paymentStatus: PaymentStatus.refunded,
        );

        expect(updated.id, booking.id);
        expect(updated.clientId, booking.clientId);
        expect(updated.status, BookingStatus.completed);
        expect(updated.paymentStatus, PaymentStatus.refunded);
      },
    );
  });
}

Booking _booking({
  double baseAmount = 1999,
  double platformFee = 100,
  double taxAmount = 378,
  int creditsUsed = 0,
}) {
  return Booking(
    id: 'booking_test',
    clientId: 'client_test',
    clientName: 'Client',
    shootrId: 'shootr_test',
    shootrName: 'Shootr',
    packageType: ShootrPackageType.basic,
    scheduledAt: DateTime(2026, 5, 20),
    durationHours: 1,
    location: const AppLocation(
      address: 'Bandra West',
      city: 'Mumbai',
      latitude: 19.0596,
      longitude: 72.8295,
    ),
    eventType: 'Product',
    stylePreference: 'Cinematic',
    musicPreference: 'Trending',
    reelsNeeded: 1,
    aspectRatio: '9:16',
    baseAmount: baseAmount,
    platformFee: platformFee,
    taxAmount: taxAmount,
    status: BookingStatus.confirmed,
    createdAt: DateTime(2026, 5, 19),
    qrPayload: 'TEST',
    creditsUsed: creditsUsed,
  );
}
