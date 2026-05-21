import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_overview.dart';
import '../models/shootr_package.dart';
import 'firestore_paths.dart';
import 'firestore_serializers.dart';

class FirestoreMarketplaceService {
  FirestoreMarketplaceService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<ShootrPackage>> getPackages() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.packages)
        .orderBy('price')
        .get();
    return snapshot.docs
        .map((doc) => ShootrPackageFirestoreX.fromFirestoreMap(doc.data()))
        .toList();
  }

  Future<AdminOverview?> getAdminOverview() async {
    final snapshot = await _firestore
        .collection(FirestoreCollections.adminOverview)
        .doc('summary')
        .get();
    final data = snapshot.data();
    if (data == null) {
      return null;
    }
    return AdminOverviewFirestoreX.fromFirestoreMap(data);
  }
}
