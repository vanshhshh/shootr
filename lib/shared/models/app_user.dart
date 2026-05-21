import 'marketplace_catalog.dart';

enum UserRole { client, shootr, admin }

extension UserRoleX on UserRole {
  String get label => switch (this) {
    UserRole.client => 'Client',
    UserRole.shootr => 'Shootr',
    UserRole.admin => 'Admin',
  };
}

enum AccountStatus {
  active,
  pendingReview,
  flagged,
  warned,
  suspended,
  rejected,
  banned,
}

extension AccountStatusX on AccountStatus {
  String get label => switch (this) {
    AccountStatus.active => 'Active',
    AccountStatus.pendingReview => 'Pending Review',
    AccountStatus.flagged => 'Flagged',
    AccountStatus.warned => 'Warned',
    AccountStatus.suspended => 'Suspended',
    AccountStatus.rejected => 'Rejected',
    AccountStatus.banned => 'Banned',
  };
}

class Review {
  const Review({
    required this.id,
    required this.authorName,
    required this.authorPhoto,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.reply,
    this.authorCity = '',
    this.authorAccountAgeDays = 180,
  });

  final String id;
  final String authorName;
  final String authorPhoto;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? reply;
  final String authorCity;
  final int authorAccountAgeDays;

  Review copyWith({String? reply, String? comment, double? rating}) {
    return Review(
      id: id,
      authorName: authorName,
      authorPhoto: authorPhoto,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt,
      reply: reply ?? this.reply,
      authorCity: authorCity,
      authorAccountAgeDays: authorAccountAgeDays,
    );
  }
}

class DeliveredReel {
  const DeliveredReel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.bookingId,
    required this.categoryId,
    required this.shootrId,
    required this.shootrName,
    required this.deliveredAt,
  });

  final String id;
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final String bookingId;
  final String categoryId;
  final String shootrId;
  final String shootrName;
  final DateTime deliveredAt;
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.createdAt,
    required this.isCredit,
  });

  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime createdAt;
  final bool isCredit;
}

class NotificationPreferences {
  const NotificationPreferences({
    this.bookingUpdates = true,
    this.promos = true,
    this.reminders = true,
    this.messages = true,
    this.safety = true,
    this.payouts = true,
  });

  final bool bookingUpdates;
  final bool promos;
  final bool reminders;
  final bool messages;
  final bool safety;
  final bool payouts;

  NotificationPreferences copyWith({
    bool? bookingUpdates,
    bool? promos,
    bool? reminders,
    bool? messages,
    bool? safety,
    bool? payouts,
  }) {
    return NotificationPreferences(
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      promos: promos ?? this.promos,
      reminders: reminders ?? this.reminders,
      messages: messages ?? this.messages,
      safety: safety ?? this.safety,
      payouts: payouts ?? this.payouts,
    );
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.role,
    required this.name,
    required this.phone,
    required this.city,
    required this.photoUrl,
    required this.activeSince,
    this.state = '',
    this.country = AppCountry.india,
    this.accountStatus = AccountStatus.active,
    this.address = '',
    this.pinCode = '',
    this.gender = UserGender.preferNotToSay,
    this.dateOfBirth,
    this.rating = 0,
    this.reviewCount = 0,
    this.bio = '',
    this.hourlyRate = 0,
    this.distanceKm = 0,
    this.verified = false,
    this.backgroundVerified = false,
    this.availableNow = false,
    this.online = false,
    this.portfolio = const <String>[],
    this.reviews = const <Review>[],
    this.badges = const <String>[],
    this.deviceModel,
    this.deviceType = DeviceType.other,
    this.deviceTier = DeviceTier.waitlist,
    this.deviceCameraSpec = '',
    this.availability = const <String>[],
    this.todayAvailability = '10:00 AM - 8:00 PM',
    this.nextAvailableSlot = 'Tomorrow 10:00 AM',
    this.onDemandMode = false,
    this.payoutDetails,
    this.upiId = '',
    this.bankName = '',
    this.ifscCode = '',
    this.totalShoots = 0,
    this.reelsDelivered = 0,
    this.repeatClients = 0,
    this.completionRate = 0,
    this.responseRate = 0,
    this.onTimeRate = 0,
    this.avgResponseMinutes = 0,
    this.walletBalance = 0,
    this.creditsBalance = 0,
    this.totalSpent = 0,
    this.totalEarned = 0,
    this.referralCode = '',
    this.savedShootrIds = const <String>[],
    this.deliveredReels = const <DeliveredReel>[],
    this.walletTransactions = const <WalletTransaction>[],
    this.notificationPreferences = const NotificationPreferences(),
    this.specialisationIds = const <String>[],
    this.latitude = 0,
    this.longitude = 0,
    this.operatingRadiusKm = 10,
    this.hasDrone = false,
    this.level = ShootrLevel.rookie,
    this.identityStatus = VerificationStatus.pending,
    this.deviceVerificationStatus = VerificationStatus.pending,
    this.passActive = false,
    this.passPlan = 'Starter',
    this.referredUsers = 0,
  });

  final String id;
  final UserRole role;
  final String name;
  final String phone;
  final String city;
  final String photoUrl;
  final DateTime activeSince;
  final String state;
  final AppCountry country;
  final AccountStatus accountStatus;
  final String address;
  final String pinCode;
  final UserGender gender;
  final DateTime? dateOfBirth;
  final double rating;
  final int reviewCount;
  final String bio;
  final double hourlyRate;
  final double distanceKm;
  final bool verified;
  final bool backgroundVerified;
  final bool availableNow;
  final bool online;
  final List<String> portfolio;
  final List<Review> reviews;
  final List<String> badges;
  final String? deviceModel;
  final DeviceType deviceType;
  final DeviceTier deviceTier;
  final String deviceCameraSpec;
  final List<String> availability;
  final String todayAvailability;
  final String nextAvailableSlot;
  final bool onDemandMode;
  final String? payoutDetails;
  final String upiId;
  final String bankName;
  final String ifscCode;
  final int totalShoots;
  final int reelsDelivered;
  final int repeatClients;
  final double completionRate;
  final double responseRate;
  final double onTimeRate;
  final int avgResponseMinutes;
  final double walletBalance;
  final int creditsBalance;
  final double totalSpent;
  final double totalEarned;
  final String referralCode;
  final List<String> savedShootrIds;
  final List<DeliveredReel> deliveredReels;
  final List<WalletTransaction> walletTransactions;
  final NotificationPreferences notificationPreferences;
  final List<String> specialisationIds;
  final double latitude;
  final double longitude;
  final int operatingRadiusKm;
  final bool hasDrone;
  final ShootrLevel level;
  final VerificationStatus identityStatus;
  final VerificationStatus deviceVerificationStatus;
  final bool passActive;
  final String passPlan;
  final int referredUsers;

  String? get iphoneModel => deviceModel;

  AppUser copyWith({
    String? id,
    String? name,
    String? phone,
    String? city,
    String? photoUrl,
    String? state,
    AppCountry? country,
    AccountStatus? accountStatus,
    String? address,
    String? pinCode,
    UserGender? gender,
    DateTime? dateOfBirth,
    String? bio,
    double? rating,
    int? reviewCount,
    double? hourlyRate,
    double? distanceKm,
    bool? verified,
    bool? backgroundVerified,
    bool? availableNow,
    bool? online,
    List<String>? portfolio,
    List<Review>? reviews,
    List<String>? badges,
    String? deviceModel,
    DeviceType? deviceType,
    DeviceTier? deviceTier,
    String? deviceCameraSpec,
    List<String>? availability,
    String? todayAvailability,
    String? nextAvailableSlot,
    bool? onDemandMode,
    String? payoutDetails,
    String? upiId,
    String? bankName,
    String? ifscCode,
    int? totalShoots,
    int? reelsDelivered,
    int? repeatClients,
    double? completionRate,
    double? responseRate,
    double? onTimeRate,
    int? avgResponseMinutes,
    double? walletBalance,
    int? creditsBalance,
    double? totalSpent,
    double? totalEarned,
    String? referralCode,
    List<String>? savedShootrIds,
    List<DeliveredReel>? deliveredReels,
    List<WalletTransaction>? walletTransactions,
    NotificationPreferences? notificationPreferences,
    List<String>? specialisationIds,
    double? latitude,
    double? longitude,
    int? operatingRadiusKm,
    bool? hasDrone,
    ShootrLevel? level,
    VerificationStatus? identityStatus,
    VerificationStatus? deviceVerificationStatus,
    bool? passActive,
    String? passPlan,
    int? referredUsers,
  }) {
    return AppUser(
      id: id ?? this.id,
      role: role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      photoUrl: photoUrl ?? this.photoUrl,
      activeSince: activeSince,
      state: state ?? this.state,
      country: country ?? this.country,
      accountStatus: accountStatus ?? this.accountStatus,
      address: address ?? this.address,
      pinCode: pinCode ?? this.pinCode,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      bio: bio ?? this.bio,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      distanceKm: distanceKm ?? this.distanceKm,
      verified: verified ?? this.verified,
      backgroundVerified: backgroundVerified ?? this.backgroundVerified,
      availableNow: availableNow ?? this.availableNow,
      online: online ?? this.online,
      portfolio: portfolio ?? this.portfolio,
      reviews: reviews ?? this.reviews,
      badges: badges ?? this.badges,
      deviceModel: deviceModel ?? this.deviceModel,
      deviceType: deviceType ?? this.deviceType,
      deviceTier: deviceTier ?? this.deviceTier,
      deviceCameraSpec: deviceCameraSpec ?? this.deviceCameraSpec,
      availability: availability ?? this.availability,
      todayAvailability: todayAvailability ?? this.todayAvailability,
      nextAvailableSlot: nextAvailableSlot ?? this.nextAvailableSlot,
      onDemandMode: onDemandMode ?? this.onDemandMode,
      payoutDetails: payoutDetails ?? this.payoutDetails,
      upiId: upiId ?? this.upiId,
      bankName: bankName ?? this.bankName,
      ifscCode: ifscCode ?? this.ifscCode,
      totalShoots: totalShoots ?? this.totalShoots,
      reelsDelivered: reelsDelivered ?? this.reelsDelivered,
      repeatClients: repeatClients ?? this.repeatClients,
      completionRate: completionRate ?? this.completionRate,
      responseRate: responseRate ?? this.responseRate,
      onTimeRate: onTimeRate ?? this.onTimeRate,
      avgResponseMinutes: avgResponseMinutes ?? this.avgResponseMinutes,
      walletBalance: walletBalance ?? this.walletBalance,
      creditsBalance: creditsBalance ?? this.creditsBalance,
      totalSpent: totalSpent ?? this.totalSpent,
      totalEarned: totalEarned ?? this.totalEarned,
      referralCode: referralCode ?? this.referralCode,
      savedShootrIds: savedShootrIds ?? this.savedShootrIds,
      deliveredReels: deliveredReels ?? this.deliveredReels,
      walletTransactions: walletTransactions ?? this.walletTransactions,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      specialisationIds: specialisationIds ?? this.specialisationIds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      operatingRadiusKm: operatingRadiusKm ?? this.operatingRadiusKm,
      hasDrone: hasDrone ?? this.hasDrone,
      level: level ?? this.level,
      identityStatus: identityStatus ?? this.identityStatus,
      deviceVerificationStatus:
          deviceVerificationStatus ?? this.deviceVerificationStatus,
      passActive: passActive ?? this.passActive,
      passPlan: passPlan ?? this.passPlan,
      referredUsers: referredUsers ?? this.referredUsers,
    );
  }
}
