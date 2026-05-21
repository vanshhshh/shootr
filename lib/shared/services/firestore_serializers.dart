import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_overview.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/chat_message.dart';
import '../models/marketplace_catalog.dart';
import '../models/shootr_package.dart';

DateTime _dateFrom(dynamic value, {DateTime? fallback}) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
  }
  return fallback ?? DateTime.now();
}

double _doubleFrom(dynamic value, [double fallback = 0]) {
  return (value as num?)?.toDouble() ?? fallback;
}

int _intFrom(dynamic value, [int fallback = 0]) {
  return (value as num?)?.toInt() ?? fallback;
}

List<String> _stringListFrom(dynamic value) {
  if (value is Iterable) {
    return value.map((item) => item.toString()).toList();
  }
  return const <String>[];
}

Map<String, dynamic> _mapFrom(dynamic value) {
  return (value as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
}

T _enumFrom<T extends Enum>(List<T> values, dynamic value, T fallback) {
  return values.firstWhere(
    (item) => item.name == value || item.toString().split('.').last == value,
    orElse: () => fallback,
  );
}

extension ShootrPackageFirestoreX on ShootrPackage {
  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'type': type.name,
      'title': title,
      'description': description,
      'price': price,
      'isAddon': isAddon,
      'inclusions': inclusions,
      'requiresDrone': requiresDrone,
    };
  }

  static ShootrPackage fromFirestoreMap(Map<String, dynamic> map) {
    return ShootrPackage(
      type: _enumFrom(
        ShootrPackageType.values,
        map['type'],
        ShootrPackageType.basic,
      ),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: _doubleFrom(map['price']),
      isAddon: map['isAddon'] as bool? ?? false,
      inclusions: _stringListFrom(map['inclusions']),
      requiresDrone: map['requiresDrone'] as bool? ?? false,
    );
  }
}

extension BookingFirestoreX on Booking {
  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      ...toMap(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  static Booking fromFirestoreMap(Map<String, dynamic> map, {String? id}) {
    final normalized = <String, dynamic>{
      ...map,
      if (id != null && (map['id'] as String? ?? '').isEmpty) 'id': id,
      'scheduledAt': _dateFrom(map['scheduledAt']).toIso8601String(),
      'createdAt': _dateFrom(map['createdAt']).toIso8601String(),
    };
    return Booking.fromMap(normalized);
  }
}

extension ChatMessageFirestoreX on ChatMessage {
  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'id': id,
      'bookingId': bookingId,
      'senderId': senderId,
      'senderName': senderName,
      'body': body,
      'sentAt': sentAt.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
    };
  }

  static ChatMessage fromFirestoreMap(Map<String, dynamic> map, {String? id}) {
    return ChatMessage(
      id: id ?? map['id'] as String? ?? '',
      bookingId: map['bookingId'] as String? ?? '',
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      body: map['body'] as String? ?? '',
      sentAt: _dateFrom(map['sentAt']),
      type: _enumFrom(
        ChatMessageType.values,
        map['type'],
        ChatMessageType.text,
      ),
      isRead: map['isRead'] as bool? ?? false,
    );
  }
}

extension AppNotificationFirestoreX on AppNotification {
  Map<String, dynamic> toFirestoreMap({String? targetUserId}) {
    return <String, dynamic>{
      'id': id,
      ...targetUserId == null
          ? const <String, dynamic>{}
          : <String, dynamic>{'targetUserId': targetUserId},
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'targetRole': targetRole.name,
      'read': read,
    };
  }

  static AppNotification fromFirestoreMap(
    Map<String, dynamic> map, {
    String? id,
  }) {
    return AppNotification(
      id: id ?? map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt: _dateFrom(map['createdAt']),
      targetRole: _enumFrom(
        UserRole.values,
        map['targetRole'],
        UserRole.client,
      ),
      read: map['read'] as bool? ?? false,
    );
  }
}

extension AppUserFirestoreX on AppUser {
  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'id': id,
      'role': role.name,
      'name': name,
      'phone': phone,
      'city': city,
      'state': state,
      'country': country.name,
      'photoUrl': photoUrl,
      'activeSince': activeSince.toIso8601String(),
      'createdAt': activeSince.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'accountStatus': accountStatus.name,
      'address': address,
      'pinCode': pinCode,
      'gender': gender.name,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'rating': rating,
      'reviewCount': reviewCount,
      'bio': bio,
      'hourlyRate': hourlyRate,
      'distanceKm': distanceKm,
      'verified': verified,
      'backgroundVerified': backgroundVerified,
      'availableNow': availableNow,
      'online': online,
      'portfolio': portfolio,
      'reviews': reviews.map((item) => item.toFirestoreMap()).toList(),
      'badges': badges,
      'deviceModel': deviceModel,
      'deviceType': deviceType.name,
      'deviceTier': deviceTier.name,
      'deviceCameraSpec': deviceCameraSpec,
      'availability': availability,
      'todayAvailability': todayAvailability,
      'nextAvailableSlot': nextAvailableSlot,
      'onDemandMode': onDemandMode,
      'payoutDetails': payoutDetails,
      'upiId': upiId,
      'bankName': bankName,
      'ifscCode': ifscCode,
      'totalShoots': totalShoots,
      'reelsDelivered': reelsDelivered,
      'repeatClients': repeatClients,
      'completionRate': completionRate,
      'responseRate': responseRate,
      'onTimeRate': onTimeRate,
      'avgResponseMinutes': avgResponseMinutes,
      'walletBalance': walletBalance,
      'creditsBalance': creditsBalance,
      'totalSpent': totalSpent,
      'totalEarned': totalEarned,
      'referralCode': referralCode,
      'savedShootrIds': savedShootrIds,
      'deliveredReels': deliveredReels
          .map((item) => item.toFirestoreMap())
          .toList(),
      'walletTransactions': walletTransactions
          .map((item) => item.toFirestoreMap())
          .toList(),
      'notificationPreferences': notificationPreferences.toFirestoreMap(),
      'specialisationIds': specialisationIds,
      'latitude': latitude,
      'longitude': longitude,
      'operatingRadiusKm': operatingRadiusKm,
      'hasDrone': hasDrone,
      'level': level.name,
      'identityStatus': identityStatus.name,
      'deviceVerificationStatus': deviceVerificationStatus.name,
      'passActive': passActive,
      'passPlan': passPlan,
      'referredUsers': referredUsers,
    };
  }

  static AppUser fromFirestoreMap(Map<String, dynamic> map, {String? id}) {
    final reviews = (map['reviews'] as Iterable? ?? const <dynamic>[])
        .map((item) => ReviewFirestoreX.fromFirestoreMap(_mapFrom(item)))
        .toList();
    final deliveredReels =
        (map['deliveredReels'] as Iterable? ?? const <dynamic>[])
            .map(
              (item) =>
                  DeliveredReelFirestoreX.fromFirestoreMap(_mapFrom(item)),
            )
            .toList();
    final walletTransactions =
        (map['walletTransactions'] as Iterable? ?? const <dynamic>[])
            .map(
              (item) =>
                  WalletTransactionFirestoreX.fromFirestoreMap(_mapFrom(item)),
            )
            .toList();

    return AppUser(
      id: id ?? map['id'] as String? ?? '',
      role: _enumFrom(UserRole.values, map['role'], UserRole.client),
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      city: map['city'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      activeSince: _dateFrom(map['activeSince'] ?? map['createdAt']),
      state: map['state'] as String? ?? '',
      country: _enumFrom(AppCountry.values, map['country'], AppCountry.india),
      accountStatus: _enumFrom(
        AccountStatus.values,
        map['accountStatus'],
        AccountStatus.active,
      ),
      address: map['address'] as String? ?? '',
      pinCode: map['pinCode'] as String? ?? '',
      gender: _enumFrom(
        UserGender.values,
        map['gender'],
        UserGender.preferNotToSay,
      ),
      dateOfBirth: map['dateOfBirth'] == null
          ? null
          : _dateFrom(map['dateOfBirth']),
      rating: _doubleFrom(map['rating']),
      reviewCount: _intFrom(map['reviewCount']),
      bio: map['bio'] as String? ?? '',
      hourlyRate: _doubleFrom(map['hourlyRate']),
      distanceKm: _doubleFrom(map['distanceKm']),
      verified: map['verified'] as bool? ?? false,
      backgroundVerified: map['backgroundVerified'] as bool? ?? false,
      availableNow: map['availableNow'] as bool? ?? false,
      online: map['online'] as bool? ?? false,
      portfolio: _stringListFrom(map['portfolio']),
      reviews: reviews,
      badges: _stringListFrom(map['badges']),
      deviceModel: map['deviceModel'] as String?,
      deviceType: _enumFrom(
        DeviceType.values,
        map['deviceType'],
        DeviceType.other,
      ),
      deviceTier: _enumFrom(
        DeviceTier.values,
        map['deviceTier'],
        DeviceTier.waitlist,
      ),
      deviceCameraSpec: map['deviceCameraSpec'] as String? ?? '',
      availability: _stringListFrom(map['availability']),
      todayAvailability:
          map['todayAvailability'] as String? ?? '10:00 AM - 8:00 PM',
      nextAvailableSlot:
          map['nextAvailableSlot'] as String? ?? 'Tomorrow 10:00 AM',
      onDemandMode: map['onDemandMode'] as bool? ?? false,
      payoutDetails: map['payoutDetails'] as String?,
      upiId: map['upiId'] as String? ?? '',
      bankName: map['bankName'] as String? ?? '',
      ifscCode: map['ifscCode'] as String? ?? '',
      totalShoots: _intFrom(map['totalShoots']),
      reelsDelivered: _intFrom(map['reelsDelivered']),
      repeatClients: _intFrom(map['repeatClients']),
      completionRate: _doubleFrom(map['completionRate']),
      responseRate: _doubleFrom(map['responseRate']),
      onTimeRate: _doubleFrom(map['onTimeRate']),
      avgResponseMinutes: _intFrom(map['avgResponseMinutes']),
      walletBalance: _doubleFrom(map['walletBalance']),
      creditsBalance: _intFrom(map['creditsBalance']),
      totalSpent: _doubleFrom(map['totalSpent']),
      totalEarned: _doubleFrom(map['totalEarned']),
      referralCode: map['referralCode'] as String? ?? '',
      savedShootrIds: _stringListFrom(map['savedShootrIds']),
      deliveredReels: deliveredReels,
      walletTransactions: walletTransactions,
      notificationPreferences:
          NotificationPreferencesFirestoreX.fromFirestoreMap(
            _mapFrom(map['notificationPreferences']),
          ),
      specialisationIds: _stringListFrom(map['specialisationIds']),
      latitude: _doubleFrom(map['latitude']),
      longitude: _doubleFrom(map['longitude']),
      operatingRadiusKm: _intFrom(map['operatingRadiusKm'], 10),
      hasDrone: map['hasDrone'] as bool? ?? false,
      level: _enumFrom(ShootrLevel.values, map['level'], ShootrLevel.rookie),
      identityStatus: _enumFrom(
        VerificationStatus.values,
        map['identityStatus'],
        VerificationStatus.pending,
      ),
      deviceVerificationStatus: _enumFrom(
        VerificationStatus.values,
        map['deviceVerificationStatus'],
        VerificationStatus.pending,
      ),
      passActive: map['passActive'] as bool? ?? false,
      passPlan: map['passPlan'] as String? ?? 'Starter',
      referredUsers: _intFrom(map['referredUsers']),
    );
  }
}

extension ReviewFirestoreX on Review {
  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'id': id,
      'authorName': authorName,
      'authorPhoto': authorPhoto,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'reply': reply,
      'authorCity': authorCity,
      'authorAccountAgeDays': authorAccountAgeDays,
    };
  }

  static Review fromFirestoreMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as String? ?? '',
      authorName: map['authorName'] as String? ?? '',
      authorPhoto: map['authorPhoto'] as String? ?? '',
      rating: _doubleFrom(map['rating']),
      comment: map['comment'] as String? ?? '',
      createdAt: _dateFrom(map['createdAt']),
      reply: map['reply'] as String?,
      authorCity: map['authorCity'] as String? ?? '',
      authorAccountAgeDays: _intFrom(map['authorAccountAgeDays'], 180),
    );
  }
}

extension DeliveredReelFirestoreX on DeliveredReel {
  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'bookingId': bookingId,
      'categoryId': categoryId,
      'shootrId': shootrId,
      'shootrName': shootrName,
      'deliveredAt': deliveredAt.toIso8601String(),
    };
  }

  static DeliveredReel fromFirestoreMap(Map<String, dynamic> map) {
    return DeliveredReel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      thumbnailUrl: map['thumbnailUrl'] as String? ?? '',
      videoUrl: map['videoUrl'] as String? ?? '',
      bookingId: map['bookingId'] as String? ?? '',
      categoryId: map['categoryId'] as String? ?? 'other',
      shootrId: map['shootrId'] as String? ?? '',
      shootrName: map['shootrName'] as String? ?? '',
      deliveredAt: _dateFrom(map['deliveredAt']),
    );
  }
}

extension WalletTransactionFirestoreX on WalletTransaction {
  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'isCredit': isCredit,
    };
  }

  static WalletTransaction fromFirestoreMap(Map<String, dynamic> map) {
    return WalletTransaction(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      amount: _doubleFrom(map['amount']),
      createdAt: _dateFrom(map['createdAt']),
      isCredit: map['isCredit'] as bool? ?? false,
    );
  }
}

extension NotificationPreferencesFirestoreX on NotificationPreferences {
  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'bookingUpdates': bookingUpdates,
      'promos': promos,
      'reminders': reminders,
      'messages': messages,
      'safety': safety,
      'payouts': payouts,
    };
  }

  static NotificationPreferences fromFirestoreMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      bookingUpdates: map['bookingUpdates'] as bool? ?? true,
      promos: map['promos'] as bool? ?? true,
      reminders: map['reminders'] as bool? ?? true,
      messages: map['messages'] as bool? ?? true,
      safety: map['safety'] as bool? ?? true,
      payouts: map['payouts'] as bool? ?? true,
    );
  }
}

extension AdminOverviewFirestoreX on AdminOverview {
  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'bookingsToday': bookingsToday,
      'bookingsThisWeek': bookingsThisWeek,
      'bookingsThisMonth': bookingsThisMonth,
      'revenueToday': revenueToday,
      'revenueWeek': revenueWeek,
      'revenueMonth': revenueMonth,
      'activeShootrsOnline': activeShootrsOnline,
      'newClientSignups': newClientSignups,
      'newShootrSignups': newShootrSignups,
      'pendingApprovals': pendingApprovals,
      'cityMetrics': cityMetrics.map((item) => item.toFirestoreMap()).toList(),
      'revenueTrend': revenueTrend
          .map((item) => item.toFirestoreMap())
          .toList(),
    };
  }

  static AdminOverview fromFirestoreMap(Map<String, dynamic> map) {
    return AdminOverview(
      bookingsToday: _intFrom(map['bookingsToday']),
      bookingsThisWeek: _intFrom(map['bookingsThisWeek']),
      bookingsThisMonth: _intFrom(map['bookingsThisMonth']),
      revenueToday: _doubleFrom(map['revenueToday']),
      revenueWeek: _doubleFrom(map['revenueWeek']),
      revenueMonth: _doubleFrom(map['revenueMonth']),
      activeShootrsOnline: _intFrom(map['activeShootrsOnline']),
      newClientSignups: _intFrom(map['newClientSignups']),
      newShootrSignups: _intFrom(map['newShootrSignups']),
      pendingApprovals: _intFrom(map['pendingApprovals']),
      cityMetrics: (map['cityMetrics'] as Iterable? ?? const <dynamic>[])
          .map((item) => CityMetricFirestoreX.fromFirestoreMap(_mapFrom(item)))
          .toList(),
      revenueTrend: (map['revenueTrend'] as Iterable? ?? const <dynamic>[])
          .map(
            (item) => RevenuePointFirestoreX.fromFirestoreMap(_mapFrom(item)),
          )
          .toList(),
    );
  }
}

extension CityMetricFirestoreX on CityMetric {
  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'city': city,
      'bookings': bookings,
      'revenue': revenue,
      'activeShootrs': activeShootrs,
    };
  }

  static CityMetric fromFirestoreMap(Map<String, dynamic> map) {
    return CityMetric(
      city: map['city'] as String? ?? '',
      bookings: _intFrom(map['bookings']),
      revenue: _doubleFrom(map['revenue']),
      activeShootrs: _intFrom(map['activeShootrs']),
    );
  }
}

extension RevenuePointFirestoreX on RevenuePoint {
  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{'dayLabel': dayLabel, 'value': value};
  }

  static RevenuePoint fromFirestoreMap(Map<String, dynamic> map) {
    return RevenuePoint(
      dayLabel: map['dayLabel'] as String? ?? '',
      value: _doubleFrom(map['value']),
    );
  }
}
