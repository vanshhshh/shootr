import 'package:flutter_test/flutter_test.dart';
import 'package:shootr/shared/models/app_user.dart';
import 'package:shootr/shared/models/marketplace_catalog.dart';
import 'package:shootr/shared/models/shootr_package.dart';
import 'package:shootr/shared/services/firestore_serializers.dart';

void main() {
  group('Firestore serializers', () {
    test('serializes and parses packages', () {
      const package = ShootrPackage(
        type: ShootrPackageType.pro,
        title: 'Pro',
        description: '2 reels',
        price: 3499,
        inclusions: <String>['2 reels', 'Colour grade'],
      );

      final parsed = ShootrPackageFirestoreX.fromFirestoreMap(
        package.toFirestoreMap(),
      );

      expect(parsed.type, ShootrPackageType.pro);
      expect(parsed.price, 3499);
      expect(parsed.inclusions, contains('Colour grade'));
    });

    test('keeps user role and admin-sensitive status explicit', () {
      final user = AppUser(
        id: 'shootr_test',
        role: UserRole.shootr,
        name: 'Rhea',
        phone: '+919999999999',
        city: 'Mumbai',
        photoUrl: 'https://example.com/rhea.jpg',
        activeSince: DateTime(2026, 5, 19),
        accountStatus: AccountStatus.pendingReview,
        deviceType: DeviceType.iphone,
        deviceTier: DeviceTier.premium,
      );

      final map = user.toFirestoreMap();
      final parsed = AppUserFirestoreX.fromFirestoreMap(map, id: user.id);

      expect(map['role'], 'shootr');
      expect(map['accountStatus'], 'pendingReview');
      expect(parsed.role, UserRole.shootr);
      expect(parsed.accountStatus, AccountStatus.pendingReview);
    });
  });
}
