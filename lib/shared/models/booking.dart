import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'marketplace_catalog.dart';
import 'shootr_package.dart';

enum BookingStatus {
  pending,
  confirmed,
  active,
  editing,
  delivered,
  completed,
  cancelled,
}

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
    BookingStatus.pending => 'Finding Shootr',
    BookingStatus.confirmed => 'Confirmed',
    BookingStatus.active => 'Active',
    BookingStatus.editing => 'Editing',
    BookingStatus.delivered => 'Delivered',
    BookingStatus.completed => 'Completed',
    BookingStatus.cancelled => 'Cancelled',
  };
}

enum PaymentStatus { pending, paid, cashAtShoot, refunded, partialRefund }

enum RefundStatus { none, pending, approved, partial, rejected }

class AppLocation {
  const AppLocation({
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.state = '',
    this.country = AppCountry.india,
    this.landmark = '',
    this.instructions = '',
    this.placeLabel = '',
  });

  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final String state;
  final AppCountry country;
  final String landmark;
  final String instructions;
  final String placeLabel;

  LatLng get latLng => LatLng(latitude, longitude);

  String get primaryLabel => placeLabel.isEmpty ? city : placeLabel;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'state': state,
      'country': country.name,
      'landmark': landmark,
      'instructions': instructions,
      'placeLabel': placeLabel,
    };
  }

  factory AppLocation.fromMap(Map<String, dynamic> map) {
    return AppLocation(
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
      state: map['state'] as String? ?? '',
      country: AppCountry.values.firstWhere(
        (item) => item.name == map['country'],
        orElse: () => AppCountry.india,
      ),
      landmark: map['landmark'] as String? ?? '',
      instructions: map['instructions'] as String? ?? '',
      placeLabel: map['placeLabel'] as String? ?? '',
    );
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.shootrId,
    required this.shootrName,
    required this.packageType,
    required this.scheduledAt,
    required this.durationHours,
    required this.location,
    required this.eventType,
    required this.stylePreference,
    required this.musicPreference,
    required this.reelsNeeded,
    required this.aspectRatio,
    required this.baseAmount,
    required this.platformFee,
    required this.taxAmount,
    required this.status,
    required this.createdAt,
    required this.qrPayload,
    this.categoryId = 'other',
    this.mood = '',
    this.referenceLink = '',
    this.notes = '',
    this.paymentMethod = 'UPI',
    this.paymentStatus = PaymentStatus.paid,
    this.refundStatus = RefundStatus.none,
    this.promoCode = '',
    this.creditsUsed = 0,
    this.etaMinutes = 5,
    this.trackEnabled = true,
    this.liveLatitude,
    this.liveLongitude,
  });

  final String id;
  final String clientId;
  final String clientName;
  final String shootrId;
  final String shootrName;
  final ShootrPackageType packageType;
  final DateTime scheduledAt;
  final double durationHours;
  final AppLocation location;
  final String categoryId;
  final String eventType;
  final String stylePreference;
  final String mood;
  final String musicPreference;
  final int reelsNeeded;
  final String aspectRatio;
  final String referenceLink;
  final double baseAmount;
  final double platformFee;
  final double taxAmount;
  final BookingStatus status;
  final DateTime createdAt;
  final String qrPayload;
  final String notes;
  final String paymentMethod;
  final PaymentStatus paymentStatus;
  final RefundStatus refundStatus;
  final String promoCode;
  final int creditsUsed;
  final int etaMinutes;
  final bool trackEnabled;
  final double? liveLatitude;
  final double? liveLongitude;

  double get totalAmount => baseAmount + platformFee + taxAmount - creditsUsed;

  bool get isAssigned => shootrId.trim().isNotEmpty;

  String get assigneeLabel => isAssigned ? shootrName : 'Finding Shootr';

  LatLng get liveLatLng => LatLng(
    liveLatitude ?? location.latitude,
    liveLongitude ?? location.longitude,
  );

  Booking copyWith({
    String? shootrId,
    String? shootrName,
    BookingStatus? status,
    int? etaMinutes,
    String? notes,
    DateTime? scheduledAt,
    RefundStatus? refundStatus,
    PaymentStatus? paymentStatus,
    double? liveLatitude,
    double? liveLongitude,
  }) {
    return Booking(
      id: id,
      clientId: clientId,
      clientName: clientName,
      shootrId: shootrId ?? this.shootrId,
      shootrName: shootrName ?? this.shootrName,
      packageType: packageType,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationHours: durationHours,
      location: location,
      categoryId: categoryId,
      eventType: eventType,
      stylePreference: stylePreference,
      mood: mood,
      musicPreference: musicPreference,
      reelsNeeded: reelsNeeded,
      aspectRatio: aspectRatio,
      referenceLink: referenceLink,
      baseAmount: baseAmount,
      platformFee: platformFee,
      taxAmount: taxAmount,
      status: status ?? this.status,
      createdAt: createdAt,
      qrPayload: qrPayload,
      notes: notes ?? this.notes,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      refundStatus: refundStatus ?? this.refundStatus,
      promoCode: promoCode,
      creditsUsed: creditsUsed,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      trackEnabled: trackEnabled,
      liveLatitude: liveLatitude ?? this.liveLatitude,
      liveLongitude: liveLongitude ?? this.liveLongitude,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'clientId': clientId,
      'clientName': clientName,
      'shootrId': shootrId,
      'shootrName': shootrName,
      'packageType': packageType.name,
      'scheduledAt': scheduledAt.toIso8601String(),
      'durationHours': durationHours,
      'location': location.toMap(),
      'categoryId': categoryId,
      'eventType': eventType,
      'stylePreference': stylePreference,
      'mood': mood,
      'musicPreference': musicPreference,
      'reelsNeeded': reelsNeeded,
      'aspectRatio': aspectRatio,
      'referenceLink': referenceLink,
      'baseAmount': baseAmount,
      'platformFee': platformFee,
      'taxAmount': taxAmount,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'qrPayload': qrPayload,
      'notes': notes,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus.name,
      'refundStatus': refundStatus.name,
      'promoCode': promoCode,
      'creditsUsed': creditsUsed,
      'etaMinutes': etaMinutes,
      'trackEnabled': trackEnabled,
      'liveLatitude': liveLatitude,
      'liveLongitude': liveLongitude,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as String? ?? '',
      clientId: map['clientId'] as String? ?? '',
      clientName: map['clientName'] as String? ?? '',
      shootrId: map['shootrId'] as String? ?? '',
      shootrName: map['shootrName'] as String? ?? '',
      packageType: ShootrPackageType.values.firstWhere(
        (item) => item.name == map['packageType'],
        orElse: () => ShootrPackageType.basic,
      ),
      scheduledAt:
          DateTime.tryParse(map['scheduledAt'] as String? ?? '') ??
          DateTime.now(),
      durationHours: (map['durationHours'] as num?)?.toDouble() ?? 1,
      location: AppLocation.fromMap(
        (map['location'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      categoryId: map['categoryId'] as String? ?? 'other',
      eventType: map['eventType'] as String? ?? '',
      stylePreference: map['stylePreference'] as String? ?? '',
      mood: map['mood'] as String? ?? '',
      musicPreference: map['musicPreference'] as String? ?? '',
      reelsNeeded: map['reelsNeeded'] as int? ?? 1,
      aspectRatio: map['aspectRatio'] as String? ?? '9:16',
      referenceLink: map['referenceLink'] as String? ?? '',
      baseAmount: (map['baseAmount'] as num?)?.toDouble() ?? 0,
      platformFee: (map['platformFee'] as num?)?.toDouble() ?? 0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0,
      status: BookingStatus.values.firstWhere(
        (item) => item.name == map['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      qrPayload: map['qrPayload'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      paymentMethod: map['paymentMethod'] as String? ?? 'UPI',
      paymentStatus: PaymentStatus.values.firstWhere(
        (item) => item.name == map['paymentStatus'],
        orElse: () => PaymentStatus.paid,
      ),
      refundStatus: RefundStatus.values.firstWhere(
        (item) => item.name == map['refundStatus'],
        orElse: () => RefundStatus.none,
      ),
      promoCode: map['promoCode'] as String? ?? '',
      creditsUsed: map['creditsUsed'] as int? ?? 0,
      etaMinutes: map['etaMinutes'] as int? ?? 5,
      trackEnabled: map['trackEnabled'] as bool? ?? true,
      liveLatitude: (map['liveLatitude'] as num?)?.toDouble(),
      liveLongitude: (map['liveLongitude'] as num?)?.toDouble(),
    );
  }
}
