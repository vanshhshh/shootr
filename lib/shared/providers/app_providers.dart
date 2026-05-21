import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' show Provider;
import 'package:flutter_riverpod/legacy.dart';

import '../../app/constants/app_constants.dart';
import '../models/admin_overview.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/chat_message.dart';
import '../models/marketplace_catalog.dart';
import '../models/shootr_package.dart';
import '../services/admin_bootstrap_service.dart';
import '../services/backend_api_service.dart';
import '../services/local_cache_service.dart';
import '../services/location_service.dart';
import '../services/cloudinary_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_booking_service.dart';
import '../services/firestore_chat_service.dart';
import '../services/firestore_marketplace_service.dart';
import '../services/firestore_notification_service.dart';
import '../services/firestore_serializers.dart';
import '../services/firestore_user_service.dart';
import '../services/mock_marketplace_service.dart';
import '../services/payment_service.dart';

class SearchFilters {
  const SearchFilters({
    this.query = '',
    this.minPrice = 500,
    this.maxPrice = 10000,
    this.minRating = 0,
    this.availableNowOnly = false,
    this.deviceTypes = const <DeviceType>{},
    this.radiusKm,
    this.categoryIds = const <String>{},
    this.preferredGender = PreferredGender.any,
    this.sort = ShootrSortOption.nearest,
  });

  final String query;
  final double minPrice;
  final double maxPrice;
  final double minRating;
  final bool availableNowOnly;
  final Set<DeviceType> deviceTypes;
  final double? radiusKm;
  final Set<String> categoryIds;
  final PreferredGender preferredGender;
  final ShootrSortOption sort;

  SearchFilters copyWith({
    String? query,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? availableNowOnly,
    Set<DeviceType>? deviceTypes,
    double? radiusKm,
    bool clearRadius = false,
    Set<String>? categoryIds,
    PreferredGender? preferredGender,
    ShootrSortOption? sort,
  }) {
    return SearchFilters(
      query: query ?? this.query,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      availableNowOnly: availableNowOnly ?? this.availableNowOnly,
      deviceTypes: deviceTypes ?? this.deviceTypes,
      radiusKm: clearRadius ? null : radiusKm ?? this.radiusKm,
      categoryIds: categoryIds ?? this.categoryIds,
      preferredGender: preferredGender ?? this.preferredGender,
      sort: sort ?? this.sort,
    );
  }
}

class AppState {
  const AppState({
    required this.initialized,
    required this.isLoading,
    required this.selectedRole,
    required this.packages,
    required this.shootrs,
    required this.clients,
    required this.bookings,
    required this.notifications,
    required this.chatThreads,
    required this.adminOverview,
    required this.searchFilters,
    required this.recentLocations,
    required this.liveShootrLocations,
    this.currentUser,
    this.pendingPhoneNumber = '',
    this.pendingCountryCode = '+91',
    this.onboardingSeen = false,
    this.isShootrOnline = false,
    this.errorMessage,
    this.otpAttempts = 0,
    this.selectedLocation,
    this.selectedCategoryId,
    this.clientSearchMapView = false,
    this.isOffline = false,
  });

  final bool initialized;
  final bool isLoading;
  final UserRole selectedRole;
  final List<ShootrPackage> packages;
  final List<AppUser> shootrs;
  final List<AppUser> clients;
  final List<Booking> bookings;
  final List<AppNotification> notifications;
  final Map<String, List<ChatMessage>> chatThreads;
  final AdminOverview adminOverview;
  final SearchFilters searchFilters;
  final List<AppLocation> recentLocations;
  final Map<String, AppLocation> liveShootrLocations;
  final AppUser? currentUser;
  final String pendingPhoneNumber;
  final String pendingCountryCode;
  final bool onboardingSeen;
  final bool isShootrOnline;
  final String? errorMessage;
  final int otpAttempts;
  final AppLocation? selectedLocation;
  final String? selectedCategoryId;
  final bool clientSearchMapView;
  final bool isOffline;

  factory AppState.initial() {
    return const AppState(
      initialized: false,
      isLoading: false,
      selectedRole: UserRole.client,
      packages: <ShootrPackage>[],
      shootrs: <AppUser>[],
      clients: <AppUser>[],
      bookings: <Booking>[],
      notifications: <AppNotification>[],
      chatThreads: <String, List<ChatMessage>>{},
      adminOverview: AdminOverview(
        bookingsToday: 0,
        bookingsThisWeek: 0,
        bookingsThisMonth: 0,
        revenueToday: 0,
        revenueWeek: 0,
        revenueMonth: 0,
        activeShootrsOnline: 0,
        newClientSignups: 0,
        newShootrSignups: 0,
        pendingApprovals: 0,
        cityMetrics: <CityMetric>[],
        revenueTrend: <RevenuePoint>[],
      ),
      searchFilters: SearchFilters(),
      recentLocations: <AppLocation>[],
      liveShootrLocations: <String, AppLocation>{},
    );
  }

  AppState copyWith({
    bool? initialized,
    bool? isLoading,
    UserRole? selectedRole,
    List<ShootrPackage>? packages,
    List<AppUser>? shootrs,
    List<AppUser>? clients,
    List<Booking>? bookings,
    List<AppNotification>? notifications,
    Map<String, List<ChatMessage>>? chatThreads,
    AdminOverview? adminOverview,
    SearchFilters? searchFilters,
    List<AppLocation>? recentLocations,
    Map<String, AppLocation>? liveShootrLocations,
    AppUser? currentUser,
    bool clearCurrentUser = false,
    String? pendingPhoneNumber,
    String? pendingCountryCode,
    bool? onboardingSeen,
    bool? isShootrOnline,
    String? errorMessage,
    bool clearError = false,
    int? otpAttempts,
    AppLocation? selectedLocation,
    bool clearSelectedLocation = false,
    String? selectedCategoryId,
    bool clearSelectedCategory = false,
    bool? clientSearchMapView,
    bool? isOffline,
  }) {
    return AppState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      selectedRole: selectedRole ?? this.selectedRole,
      packages: packages ?? this.packages,
      shootrs: shootrs ?? this.shootrs,
      clients: clients ?? this.clients,
      bookings: bookings ?? this.bookings,
      notifications: notifications ?? this.notifications,
      chatThreads: chatThreads ?? this.chatThreads,
      adminOverview: adminOverview ?? this.adminOverview,
      searchFilters: searchFilters ?? this.searchFilters,
      recentLocations: recentLocations ?? this.recentLocations,
      liveShootrLocations: liveShootrLocations ?? this.liveShootrLocations,
      currentUser: clearCurrentUser ? null : currentUser ?? this.currentUser,
      pendingPhoneNumber: pendingPhoneNumber ?? this.pendingPhoneNumber,
      pendingCountryCode: pendingCountryCode ?? this.pendingCountryCode,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      isShootrOnline: isShootrOnline ?? this.isShootrOnline,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      otpAttempts: otpAttempts ?? this.otpAttempts,
      selectedLocation: clearSelectedLocation
          ? null
          : selectedLocation ?? this.selectedLocation,
      selectedCategoryId: clearSelectedCategory
          ? null
          : selectedCategoryId ?? this.selectedCategoryId,
      clientSearchMapView: clientSearchMapView ?? this.clientSearchMapView,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

final mockMarketplaceServiceProvider = Provider<MockMarketplaceService>(
  (ref) => const MockMarketplaceService(),
);

final localCacheServiceProvider = Provider<LocalCacheService>(
  (ref) => LocalCacheService(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

final cloudinaryServiceProvider = Provider<CloudinaryService>(
  (ref) => const CloudinaryService(),
);

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>(
  (ref) => FirebaseAuthService(),
);

final backendApiServiceProvider = Provider<BackendApiService>((ref) {
  final service = BackendApiService();
  ref.onDispose(service.dispose);
  return service;
});

final adminBootstrapServiceProvider = Provider<AdminBootstrapService>(
  (ref) => AdminBootstrapService(backend: ref.watch(backendApiServiceProvider)),
);

final firestoreUserServiceProvider = Provider<FirestoreUserService>(
  (ref) => FirestoreUserService(),
);

final firestoreBookingServiceProvider = Provider<FirestoreBookingService>(
  (ref) => FirestoreBookingService(),
);

final firestoreChatServiceProvider = Provider<FirestoreChatService>(
  (ref) => FirestoreChatService(),
);

final firestoreNotificationServiceProvider =
    Provider<FirestoreNotificationService>(
      (ref) => FirestoreNotificationService(),
    );

final firestoreMarketplaceServiceProvider =
    Provider<FirestoreMarketplaceService>(
      (ref) => FirestoreMarketplaceService(),
    );

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final service = PaymentService(backend: ref.watch(backendApiServiceProvider));
  ref.onDispose(service.dispose);
  return service;
});

final appControllerProvider = StateNotifierProvider<AppController, AppState>((
  ref,
) {
  return AppController(
    service: ref.watch(mockMarketplaceServiceProvider),
    cacheService: ref.watch(localCacheServiceProvider),
    locationService: ref.watch(locationServiceProvider),
    authService: ref.watch(firebaseAuthServiceProvider),
    adminBootstrapService: ref.watch(adminBootstrapServiceProvider),
    backendService: ref.watch(backendApiServiceProvider),
    userService: ref.watch(firestoreUserServiceProvider),
    bookingService: ref.watch(firestoreBookingServiceProvider),
    chatService: ref.watch(firestoreChatServiceProvider),
    notificationService: ref.watch(firestoreNotificationServiceProvider),
    marketplaceService: ref.watch(firestoreMarketplaceServiceProvider),
  );
});

final currentUserProvider = Provider<AppUser?>(
  (ref) => ref.watch(appControllerProvider).currentUser,
);

final selectedLocationProvider = Provider<AppLocation?>(
  (ref) => ref.watch(appControllerProvider).selectedLocation,
);

final nearbyShootrsProvider = Provider<List<AppUser>>((ref) {
  final state = ref.watch(appControllerProvider);
  final locationService = ref.watch(locationServiceProvider);
  final selectedLocation = state.selectedLocation;

  final withDistances = state.shootrs.map((shootr) {
    if (selectedLocation == null ||
        shootr.latitude == 0 ||
        shootr.longitude == 0 ||
        selectedLocation.latitude == 0 ||
        selectedLocation.longitude == 0) {
      return shootr;
    }

    final distance = locationService.distanceInKm(
      startLatitude: selectedLocation.latitude,
      startLongitude: selectedLocation.longitude,
      endLatitude: shootr.latitude,
      endLongitude: shootr.longitude,
    );
    return shootr.copyWith(distanceKm: distance);
  }).toList();

  final cityFiltered = selectedLocation == null
      ? withDistances
      : withDistances
            .where((shootr) => shootr.city == selectedLocation.city)
            .toList();

  final onlineFiltered = cityFiltered
      .where((shootr) => shootr.online || shootr.availableNow)
      .toList();
  onlineFiltered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return onlineFiltered;
});

final filteredShootrsProvider = Provider<List<AppUser>>((ref) {
  final state = ref.watch(appControllerProvider);
  final filters = state.searchFilters;
  int levelWeight(AppUser user) {
    return switch (user.level) {
      ShootrLevel.master => 4,
      ShootrLevel.elite => 3,
      ShootrLevel.pro => 2,
      ShootrLevel.rookie => 1,
    };
  }

  final items = ref.watch(nearbyShootrsProvider).where((shootr) {
    final query = filters.query.trim().toLowerCase();
    final textMatches =
        query.isEmpty ||
        shootr.name.toLowerCase().contains(query) ||
        shootr.city.toLowerCase().contains(query) ||
        shootr.bio.toLowerCase().contains(query) ||
        shootr.specialisationIds.any((item) => item.contains(query));
    final priceMatches =
        shootr.hourlyRate >= filters.minPrice &&
        shootr.hourlyRate <= filters.maxPrice;
    final ratingMatches = shootr.rating >= filters.minRating;
    final availableMatches = !filters.availableNowOnly || shootr.availableNow;
    final deviceMatches =
        filters.deviceTypes.isEmpty ||
        filters.deviceTypes.contains(shootr.deviceType);
    final radiusMatches =
        filters.radiusKm == null || shootr.distanceKm <= filters.radiusKm!;
    final categoryMatches =
        filters.categoryIds.isEmpty ||
        shootr.specialisationIds.any(filters.categoryIds.contains);
    final genderMatches =
        filters.preferredGender == PreferredGender.any ||
        shootr.gender.label == filters.preferredGender.label;
    return textMatches &&
        priceMatches &&
        ratingMatches &&
        availableMatches &&
        deviceMatches &&
        radiusMatches &&
        categoryMatches &&
        genderMatches;
  }).toList();

  switch (filters.sort) {
    case ShootrSortOption.nearest:
      items.sort((a, b) {
        final byDistance = a.distanceKm.compareTo(b.distanceKm);
        if (byDistance != 0) {
          return byDistance;
        }
        return levelWeight(b).compareTo(levelWeight(a));
      });
    case ShootrSortOption.topRated:
      items.sort((a, b) {
        final byRating = b.rating.compareTo(a.rating);
        if (byRating != 0) {
          return byRating;
        }
        return levelWeight(b).compareTo(levelWeight(a));
      });
    case ShootrSortOption.priceLowToHigh:
      items.sort((a, b) {
        final byPrice = a.hourlyRate.compareTo(b.hourlyRate);
        if (byPrice != 0) {
          return byPrice;
        }
        return levelWeight(b).compareTo(levelWeight(a));
      });
    case ShootrSortOption.priceHighToLow:
      items.sort((a, b) {
        final byPrice = b.hourlyRate.compareTo(a.hourlyRate);
        if (byPrice != 0) {
          return byPrice;
        }
        return levelWeight(b).compareTo(levelWeight(a));
      });
    case ShootrSortOption.mostBooked:
      items.sort((a, b) {
        final byShoots = b.totalShoots.compareTo(a.totalShoots);
        if (byShoots != 0) {
          return byShoots;
        }
        return levelWeight(b).compareTo(levelWeight(a));
      });
  }
  return items;
});

final unreadNotificationsProvider = Provider<int>((ref) {
  final state = ref.watch(appControllerProvider);
  return state.notifications.where((item) => !item.read).length;
});

class AppController extends StateNotifier<AppState> {
  AppController({
    required MockMarketplaceService service,
    required LocalCacheService cacheService,
    required LocationService locationService,
    required FirebaseAuthService authService,
    required AdminBootstrapService adminBootstrapService,
    required BackendApiService backendService,
    required FirestoreUserService userService,
    required FirestoreBookingService bookingService,
    required FirestoreChatService chatService,
    required FirestoreNotificationService notificationService,
    required FirestoreMarketplaceService marketplaceService,
  }) : _service = service,
       _cacheService = cacheService,
       _locationService = locationService,
       _authService = authService,
       _adminBootstrapService = adminBootstrapService,
       _backendService = backendService,
       _userService = userService,
       _bookingService = bookingService,
       _chatService = chatService,
       _notificationService = notificationService,
       _marketplaceService = marketplaceService,
       super(AppState.initial()) {
    initialize();
  }

  final MockMarketplaceService _service;
  final LocalCacheService _cacheService;
  final LocationService _locationService;
  final FirebaseAuthService _authService;
  final AdminBootstrapService _adminBootstrapService;
  final BackendApiService _backendService;
  final FirestoreUserService _userService;
  final FirestoreBookingService _bookingService;
  final FirestoreChatService _chatService;
  final FirestoreNotificationService _notificationService;
  final FirestoreMarketplaceService _marketplaceService;
  Timer? _liveTimer;
  StreamSubscription<List<Booking>>? _bookingSubscription;

  bool get hasAuthenticatedFirebaseUser => _authService.currentUid != null;

  Future<void> initialize() async {
    if (state.initialized) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final seedBundle = _service.bootstrap();
      final remoteBundle = await _tryLoadFirestoreBundle(seedBundle);
      final bundle = remoteBundle.bundle;
      final cachedCompleted = await _cacheService.getCompletedBookings();
      final cachedLocation = await _cacheService.getSelectedLocation();
      final cachedRecentLocations = await _cacheService.getRecentLocations();
      final cachedSavedShootrs = await _cacheService.getSavedShootrs();
      final cachedNotificationPrefs = await _cacheService
          .getNotificationPreferences();

      final mergedBookings = <Booking>[
        ...bundle.bookings,
        ...cachedCompleted.where(
          (cached) => bundle.bookings.every((item) => item.id != cached.id),
        ),
      ];

      final clients = bundle.clients
          .map(
            (client) =>
                client.id == 'client_1' ||
                    client.id == remoteBundle.currentUser?.id
                ? client.copyWith(
                    savedShootrIds: cachedSavedShootrs,
                    notificationPreferences: cachedNotificationPrefs,
                  )
                : client,
          )
          .toList();

      final selectedLocation =
          cachedLocation ??
          _locationFromUser(
            remoteBundle.currentUser ??
                (clients.isEmpty ? null : clients.first),
          );

      state = state.copyWith(
        initialized: true,
        isLoading: false,
        packages: bundle.packages,
        shootrs: bundle.shootrs,
        clients: clients,
        bookings: mergedBookings,
        notifications: bundle.notifications,
        chatThreads: bundle.chatThreads,
        adminOverview: bundle.adminOverview,
        currentUser: remoteBundle.currentUser,
        selectedRole: remoteBundle.currentUser?.role,
        selectedLocation: selectedLocation,
        recentLocations: cachedRecentLocations,
        isOffline: !remoteBundle.loadedFromFirestore,
      );
      if (remoteBundle.currentUser != null) {
        unawaited(_userService.saveCurrentFcmToken());
        _startBookingRealtime(remoteBundle.currentUser!);
      }
      _startLiveTracking();
    } catch (_) {
      state = state.copyWith(
        initialized: true,
        isLoading: false,
        errorMessage: 'Unable to load Shootr right now. Please retry.',
      );
    }
  }

  Future<
    ({BootstrapBundle bundle, AppUser? currentUser, bool loadedFromFirestore})
  >
  _tryLoadFirestoreBundle(BootstrapBundle seedBundle) async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) {
        return (
          bundle: seedBundle,
          currentUser: null,
          loadedFromFirestore: false,
        );
      }

      final packages = await _marketplaceService.getPackages();
      final shootrs = currentUser.role == UserRole.admin
          ? await _userService.getShootrsForAdmin()
          : await _userService.getShootrs();
      final clients = currentUser.role == UserRole.admin
          ? await _userService.getClientsForAdmin()
          : currentUser.role == UserRole.client
          ? <AppUser>[currentUser]
          : <AppUser>[];
      final bookings = await _bookingService.getBookingsForUser(currentUser);
      final notifications = await _notificationService.getNotificationsForUser(
        currentUser,
      );
      final chatThreads = await _chatService.getThreadsForBookings(bookings);
      final adminOverview = currentUser.role == UserRole.admin
          ? await _marketplaceService.getAdminOverview()
          : null;

      return (
        bundle: BootstrapBundle(
          packages: packages.isEmpty ? seedBundle.packages : packages,
          shootrs: currentUser.role == UserRole.shootr
              ? _upsertUserInList(shootrs, currentUser)
              : shootrs,
          clients: currentUser.role == UserRole.client
              ? _upsertUserInList(clients, currentUser)
              : clients,
          bookings: bookings,
          notifications: notifications,
          chatThreads: chatThreads,
          adminOverview: adminOverview ?? seedBundle.adminOverview,
        ),
        currentUser: currentUser,
        loadedFromFirestore: true,
      );
    } catch (_) {
      return (
        bundle: seedBundle,
        currentUser: null,
        loadedFromFirestore: false,
      );
    }
  }

  Future<AppUser?> _loadSignedInSession() async {
    final seedBundle = _service.bootstrap();
    final remoteBundle = await _tryLoadFirestoreBundle(seedBundle);
    final currentUser = remoteBundle.currentUser;
    if (currentUser == null) {
      return null;
    }

    final bundle = remoteBundle.bundle;
    state = state.copyWith(
      initialized: true,
      isLoading: false,
      packages: bundle.packages,
      shootrs: bundle.shootrs,
      clients: currentUser.role == UserRole.client
          ? _upsertUserInList(bundle.clients, currentUser)
          : bundle.clients,
      bookings: bundle.bookings,
      notifications: bundle.notifications,
      chatThreads: bundle.chatThreads,
      adminOverview: bundle.adminOverview,
      currentUser: currentUser,
      selectedRole: currentUser.role,
      selectedLocation: _locationFromUser(currentUser),
      isOffline: !remoteBundle.loadedFromFirestore,
      clearError: true,
    );
    _startBookingRealtime(currentUser);
    _startLiveTracking();
    unawaited(_userService.saveCurrentFcmToken());
    return currentUser;
  }

  void retryInitialization() {
    _liveTimer?.cancel();
    _bookingSubscription?.cancel();
    state = AppState.initial();
    initialize();
  }

  void markOnboardingSeen() {
    state = state.copyWith(onboardingSeen: true);
  }

  void selectRole(UserRole role) {
    state = state.copyWith(selectedRole: role);
  }

  void updatePendingPhone({
    required String countryCode,
    required String phoneNumber,
  }) {
    state = state.copyWith(
      pendingCountryCode: countryCode,
      pendingPhoneNumber: phoneNumber,
      otpAttempts: 0,
    );
  }

  Future<bool> sendPhoneOtp({
    required String countryCode,
    required String phoneNumber,
  }) async {
    updatePendingPhone(countryCode: countryCode, phoneNumber: phoneNumber);
    state = state.copyWith(clearError: true);
    try {
      await _authService.sendPhoneOtp(
        countryCode: countryCode,
        phoneNumber: phoneNumber,
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        errorMessage: _authErrorMessage(error),
        isOffline: true,
      );
      return false;
    }
  }

  Future<bool> verifyOtp(String otp) async {
    final attempts = state.otpAttempts + 1;
    if (attempts > AppConstants.maxOtpAttempts) {
      state = state.copyWith(
        otpAttempts: attempts,
        errorMessage: 'Too many incorrect attempts. Please request a new OTP.',
      );
      return false;
    }

    try {
      await _authService.verifyPhoneOtp(otp);
      state = state.copyWith(otpAttempts: attempts, clearError: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        otpAttempts: attempts,
        errorMessage: _authErrorMessage(error),
      );
      return false;
    }
  }

  Future<AppUser?> loadSignedInProfile() => _loadSignedInSession();

  Future<bool> createEmailAccount({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.createUserWithEmail(email: email, password: password);
      state = state.copyWith(isLoading: false, clearError: true);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authErrorMessage(error),
      );
      return false;
    }
  }

  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.signInWithEmail(email: email, password: password);
      final user = await _loadSignedInSession();
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage:
              'No Shootr profile found for this email. Create a profile to continue.',
        );
      }
      return user;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authErrorMessage(error),
      );
      return null;
    }
  }

  Future<AppUser?> bootstrapAdminAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final profile = await _adminBootstrapService.bootstrapAdminAccount();
      await _authService.refreshIdToken();
      final user = AppUserFirestoreX.fromFirestoreMap(
        profile,
        id: profile['id'] as String?,
      );
      state = state.copyWith(
        isLoading: false,
        currentUser: user,
        selectedRole: UserRole.admin,
        adminOverview: state.adminOverview,
        clearError: true,
      );
      return await _loadSignedInSession() ?? user;
    } catch (error) {
      return _bootstrapAdminAccountFromEmailFallback(error);
    }
  }

  Future<AppUser?> _bootstrapAdminAccountFromEmailFallback(Object error) async {
    final email = _authService.currentEmail?.trim().toLowerCase() ?? '';
    final uid = _authService.currentUid;
    if (uid == null || email != AppConstants.bootstrapAdminEmail) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _authErrorMessage(error),
      );
      return null;
    }

    final admin = AppUser(
      id: uid,
      role: UserRole.admin,
      name: 'Shootr Admin',
      phone: email,
      city: 'Mumbai',
      state: 'Maharashtra',
      photoUrl: 'https://images.unsplash.com/photo-1560250097-0b93528c311a',
      activeSince: DateTime.now(),
      verified: true,
      backgroundVerified: true,
      identityStatus: VerificationStatus.verified,
      deviceVerificationStatus: VerificationStatus.verified,
    );
    state = state.copyWith(
      isLoading: false,
      currentUser: admin,
      selectedRole: UserRole.admin,
      clearError: true,
    );
    _startBookingRealtime(admin);
    await _tryPersistUser(admin);
    unawaited(_userService.saveCurrentFcmToken());
    return admin;
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(clearError: true);
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (error) {
      state = state.copyWith(errorMessage: _authErrorMessage(error));
      return false;
    }
  }

  Future<void> detectClientLocation() async {
    try {
      final current = await _locationService.getCurrentLocationIndiaOnly();
      await setSelectedLocation(current);
    } catch (error) {
      state = state.copyWith(
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> setSelectedLocation(AppLocation location) async {
    final recent = <AppLocation>[
      location,
      ...state.recentLocations.where(
        (item) => item.address != location.address,
      ),
    ].take(6).toList();

    await _cacheService.cacheSelectedLocation(location);
    await _cacheService.cacheRecentLocations(recent);
    state = state.copyWith(
      selectedLocation: location,
      recentLocations: recent,
      clearError: true,
    );
  }

  void selectClientCategory(String? categoryId) {
    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearSelectedCategory: categoryId == null,
    );
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(
      searchFilters: state.searchFilters.copyWith(query: query),
    );
  }

  void updateSearchFilters(SearchFilters filters) {
    state = state.copyWith(searchFilters: filters);
  }

  void toggleSearchMapView() {
    state = state.copyWith(clientSearchMapView: !state.clientSearchMapView);
  }

  Future<void> toggleSavedShootr(String shootrId) async {
    final currentSaved = <String>[
      ...state.currentUser?.savedShootrIds ?? const <String>[],
    ];
    if (currentSaved.contains(shootrId)) {
      currentSaved.remove(shootrId);
    } else {
      currentSaved.add(shootrId);
    }
    await _cacheService.cacheSavedShootrs(currentSaved);

    final updatedUser = state.currentUser?.copyWith(
      savedShootrIds: currentSaved,
    );
    _replaceCurrentUser(updatedUser);
  }

  Future<void> updateNotificationPreferences(
    NotificationPreferences preferences,
  ) async {
    await _cacheService.cacheNotificationPreferences(preferences);
    final updatedUser = state.currentUser?.copyWith(
      notificationPreferences: preferences,
    );
    _replaceCurrentUser(updatedUser);
  }

  void completeClientProfile({
    required String name,
    required String city,
    required String photoUrl,
  }) {
    final created = _service.createClientProfile(
      name: name,
      phone: _currentAuthContact(),
      city: city,
      photoUrl: photoUrl,
    );
    final client = created.copyWith(
      id: _userService.currentUid ?? created.id,
      savedShootrIds: state.currentUser?.savedShootrIds ?? const <String>[],
      notificationPreferences:
          state.currentUser?.notificationPreferences ??
          const NotificationPreferences(),
    );
    state = state.copyWith(
      currentUser: client,
      clients: _upsertUserInList(state.clients, client),
      selectedRole: UserRole.client,
      clearError: true,
    );
    _startBookingRealtime(client);
    unawaited(_tryPersistUser(client));
    unawaited(_userService.saveCurrentFcmToken());
  }

  void submitShootrProfile({
    required String name,
    required String city,
    required String stateName,
    required String photoUrl,
    required String deviceModel,
    required DeviceType deviceType,
    required DeviceTier deviceTier,
    required String deviceCameraSpec,
    required String bio,
    required List<String> portfolio,
    required List<String> availability,
    required String todayAvailability,
    required AppCountry country,
    required String address,
    required String pinCode,
    required UserGender gender,
    required DateTime dateOfBirth,
    required String payoutDetails,
    required String upiId,
    required String bankName,
    required String ifscCode,
    required double hourlyRate,
    required List<String> specialisationIds,
    required double latitude,
    required double longitude,
    required int operatingRadiusKm,
    required bool onDemandMode,
    required bool hasDrone,
    required VerificationStatus identityStatus,
    required VerificationStatus deviceVerificationStatus,
  }) {
    final created = _service.createShootrProfile(
      name: name,
      phone: _currentAuthContact(),
      city: city,
      stateName: stateName,
      photoUrl: photoUrl,
      deviceModel: deviceModel,
      deviceType: deviceType,
      deviceTier: deviceTier,
      deviceCameraSpec: deviceCameraSpec,
      bio: bio,
      portfolio: portfolio,
      availability: availability,
      todayAvailability: todayAvailability,
      country: country,
      address: address,
      pinCode: pinCode,
      gender: gender,
      dateOfBirth: dateOfBirth,
      payoutDetails: payoutDetails,
      upiId: upiId,
      bankName: bankName,
      ifscCode: ifscCode,
      hourlyRate: hourlyRate,
      specialisationIds: specialisationIds,
      latitude: latitude,
      longitude: longitude,
      operatingRadiusKm: operatingRadiusKm,
      onDemandMode: onDemandMode,
      hasDrone: hasDrone,
      identityStatus: identityStatus,
      deviceVerificationStatus: deviceVerificationStatus,
    );
    final shootr = created.copyWith(id: _userService.currentUid ?? created.id);
    state = state.copyWith(
      currentUser: shootr,
      shootrs: _upsertUserInList(state.shootrs, shootr),
      selectedRole: UserRole.shootr,
      clearError: true,
    );
    _startBookingRealtime(shootr);
    unawaited(_tryPersistUser(shootr));
    unawaited(_userService.saveCurrentFcmToken());
  }

  void updateShootrProfile({
    String? name,
    String? photoUrl,
    String? bio,
    List<String>? portfolio,
    List<String>? badges,
    double? hourlyRate,
    List<String>? specialisationIds,
    List<String>? availability,
    String? todayAvailability,
    String? nextAvailableSlot,
    bool? onDemandMode,
    String? upiId,
    String? bankName,
    String? ifscCode,
    NotificationPreferences? notificationPreferences,
  }) {
    final current = state.currentUser;
    if (current == null || current.role != UserRole.shootr) {
      return;
    }

    final updated = current.copyWith(
      name: name,
      photoUrl: photoUrl,
      bio: bio,
      portfolio: portfolio,
      badges: badges,
      hourlyRate: hourlyRate,
      specialisationIds: specialisationIds,
      availability: availability,
      todayAvailability: todayAvailability,
      nextAvailableSlot: nextAvailableSlot,
      onDemandMode: onDemandMode,
      upiId: upiId,
      bankName: bankName,
      ifscCode: ifscCode,
      notificationPreferences: notificationPreferences,
    );

    _replaceCurrentUser(updated);
  }

  void updateShootrAdminStatus({
    required String shootrId,
    required AccountStatus status,
    String reason = '',
  }) {
    final shootrIndex = state.shootrs.indexWhere((item) => item.id == shootrId);
    if (shootrIndex == -1) {
      return;
    }

    final shootr = state.shootrs[shootrIndex];
    final updated = shootr.copyWith(
      accountStatus: status,
      verified: status == AccountStatus.active,
      online: status == AccountStatus.active ? shootr.online : false,
      availableNow: status == AccountStatus.active
          ? shootr.availableNow
          : false,
      identityStatus: _verificationStatusForStatus(
        status,
        shootr.identityStatus,
      ),
      deviceVerificationStatus: _verificationStatusForStatus(
        status,
        shootr.deviceVerificationStatus,
      ),
      badges: _statusBadges(
        shootr.badges,
        status: status,
        pendingLabel: 'Pending Review',
      ),
    );

    _syncUser(updated);
    _prependNotification(
      targetRole: UserRole.shootr,
      title: 'Account ${status.label}',
      body: reason.trim().isEmpty
          ? '${shootr.name}, your Shootr account is now ${status.label.toLowerCase()}.'
          : '${shootr.name}, your Shootr account is now ${status.label.toLowerCase()}: ${reason.trim()}',
    );
  }

  void updateClientAdminStatus({
    required String clientId,
    required AccountStatus status,
    String reason = '',
  }) {
    final clientIndex = state.clients.indexWhere((item) => item.id == clientId);
    if (clientIndex == -1) {
      return;
    }

    final client = state.clients[clientIndex];
    final updated = client.copyWith(
      accountStatus: status,
      badges: _statusBadges(client.badges, status: status),
    );

    _syncUser(updated);
    _prependNotification(
      targetRole: UserRole.client,
      title: 'Account ${status.label}',
      body: reason.trim().isEmpty
          ? '${client.name}, your Shootr client account is now ${status.label.toLowerCase()}.'
          : '${client.name}, your Shootr client account is now ${status.label.toLowerCase()}: ${reason.trim()}',
    );
  }

  void replyToShootrReview({required String reviewId, required String reply}) {
    final current = state.currentUser;
    if (current == null || current.role != UserRole.shootr) {
      return;
    }

    final updatedReviews = current.reviews
        .map((item) => item.id == reviewId ? item.copyWith(reply: reply) : item)
        .toList();
    _replaceCurrentUser(current.copyWith(reviews: updatedReviews));
  }

  void sendAdminNotification({
    required UserRole targetRole,
    required String title,
    required String body,
  }) {
    _prependNotification(targetRole: targetRole, title: title, body: body);
  }

  void toggleShootrOnline() {
    state = state.copyWith(isShootrOnline: !state.isShootrOnline);
  }

  Future<void> createBooking(Booking booking) async {
    final updatedBookings = <Booking>[booking, ...state.bookings];
    final currentUser = state.currentUser;
    final creditsEarned =
        (booking.totalAmount / 100).floor() *
        AppConstants.creditsPerHundredRupees;
    final updatedUser = currentUser?.copyWith(
      totalSpent: currentUser.totalSpent + booking.totalAmount,
      creditsBalance:
          currentUser.creditsBalance + creditsEarned - booking.creditsUsed,
      walletTransactions: <WalletTransaction>[
        WalletTransaction(
          id: 'txn_${DateTime.now().microsecondsSinceEpoch}',
          title: 'Booking payment',
          subtitle: booking.shootrName.isEmpty
              ? booking.eventType
              : booking.shootrName,
          amount: booking.totalAmount,
          createdAt: DateTime.now(),
          isCredit: false,
        ),
        ...currentUser.walletTransactions,
      ],
    );

    state = state.copyWith(
      bookings: updatedBookings,
      currentUser: updatedUser,
      clearError: true,
    );
    await _tryPersistBooking(booking);
    unawaited(
      _backendService.notifyBookingCreated(booking.id).catchError((_) {}),
    );
    if (updatedUser != null) {
      unawaited(_tryPersistUser(updatedUser));
    }
    await _persistOfflineHistory(updatedBookings);
  }

  Future<bool> acceptBookingRequest(String bookingId) async {
    final shootr = state.currentUser;
    if (shootr == null || shootr.role != UserRole.shootr) {
      return false;
    }

    final bookingIndex = state.bookings.indexWhere(
      (booking) => booking.id == bookingId,
    );
    if (bookingIndex == -1) {
      return false;
    }

    final existing = state.bookings[bookingIndex];
    if (existing.status != BookingStatus.pending ||
        existing.shootrId.isNotEmpty) {
      state = state.copyWith(
        errorMessage: 'This request was already accepted.',
      );
      return false;
    }

    final updated = existing.copyWith(
      status: BookingStatus.confirmed,
      shootrId: shootr.id,
      shootrName: shootr.name,
      etaMinutes: shootr.avgResponseMinutes == 0
          ? 8
          : shootr.avgResponseMinutes,
      liveLatitude: shootr.latitude == 0
          ? existing.location.latitude
          : shootr.latitude,
      liveLongitude: shootr.longitude == 0
          ? existing.location.longitude
          : shootr.longitude,
    );

    final bookings = <Booking>[...state.bookings];
    bookings[bookingIndex] = updated;
    state = state.copyWith(bookings: bookings, clearError: true);

    try {
      final remote = await _bookingService.claimBooking(
        bookingId: bookingId,
        shootr: shootr,
      );
      final refreshed = state.bookings
          .map((booking) => booking.id == bookingId ? remote : booking)
          .toList();
      state = state.copyWith(bookings: refreshed, clearError: true);
      _prependNotification(
        targetRole: UserRole.client,
        title: 'Shootr assigned',
        body: '${shootr.name} accepted your ${existing.eventType} request.',
      );
      unawaited(
        _backendService.notifyBookingAssigned(bookingId).catchError((_) {}),
      );
      return true;
    } catch (error) {
      final reverted = state.bookings
          .map((booking) => booking.id == bookingId ? existing : booking)
          .toList();
      state = state.copyWith(
        bookings: reverted,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    final bookingIndex = state.bookings.indexWhere(
      (booking) => booking.id == bookingId,
    );
    if (bookingIndex == -1) {
      return;
    }

    final existing = state.bookings[bookingIndex];
    final updatedBooking = existing.copyWith(status: status);
    final updatedBookings = <Booking>[...state.bookings];
    updatedBookings[bookingIndex] = updatedBooking;
    state = state.copyWith(bookings: updatedBookings);

    if (existing.status != status && status == BookingStatus.completed) {
      _onBookingCompleted(updatedBooking);
    }

    if (existing.status != status && status == BookingStatus.active) {
      _prependNotification(
        targetRole: UserRole.client,
        title: 'Shootr arrived',
        body:
            '${updatedBooking.shootrName} is now active for booking ${updatedBooking.id}.',
      );
    }

    unawaited(_tryPersistBooking(updatedBooking));
    await _persistOfflineHistory(updatedBookings);
  }

  Future<void> completeBookingWithReel({
    required String bookingId,
    required String title,
    required String videoUrl,
    required String thumbnailUrl,
  }) async {
    final bookingIndex = state.bookings.indexWhere(
      (booking) => booking.id == bookingId,
    );
    if (bookingIndex == -1) {
      return;
    }

    final existing = state.bookings[bookingIndex];
    final updatedBooking = existing.copyWith(status: BookingStatus.completed);
    final updatedBookings = <Booking>[...state.bookings];
    updatedBookings[bookingIndex] = updatedBooking;

    state = state.copyWith(bookings: updatedBookings);
    if (existing.status != BookingStatus.completed) {
      _onBookingCompleted(
        updatedBooking,
        deliveryTitle: title,
        deliveryVideoUrl: videoUrl,
        deliveryThumbnailUrl: thumbnailUrl,
      );
    }
    unawaited(_tryPersistBooking(updatedBooking));
    await _persistOfflineHistory(updatedBookings);
  }

  void sendSafetyAlert({
    required String bookingId,
    required UserRole triggeredBy,
    bool callEmergencyContact = false,
  }) {
    final bookingIndex = state.bookings.indexWhere(
      (item) => item.id == bookingId,
    );
    if (bookingIndex == -1) {
      return;
    }
    final booking = state.bookings[bookingIndex];
    final actor = triggeredBy == UserRole.client ? 'Client' : 'Shootr';
    final recipientRole = triggeredBy == UserRole.client
        ? UserRole.shootr
        : UserRole.client;

    _prependNotification(
      targetRole: UserRole.admin,
      title: 'SOS Alert: $actor',
      body:
          '$actor triggered SOS for ${booking.id} at ${booking.location.address}.',
    );
    _prependNotification(
      targetRole: recipientRole,
      title: 'Safety alert triggered',
      body:
          'An SOS alert was triggered for booking ${booking.id}. Support has been notified.',
    );
    _prependNotification(
      targetRole: triggeredBy,
      title: 'SOS received',
      body: callEmergencyContact
          ? 'Your emergency contact workflow started. Stay safe, help is on the way.'
          : 'Support has been alerted and is reviewing your live location now.',
    );
  }

  Future<void> resolveBookingIssue({
    required String bookingId,
    required String issueType,
    required RefundStatus refundStatus,
    required PaymentStatus paymentStatus,
    String resolutionNote = '',
  }) async {
    Booking? changedBooking;
    final updated = state.bookings.map((booking) {
      if (booking.id != bookingId) {
        return booking;
      }

      final adminNote = resolutionNote.trim();
      final combinedNotes = adminNote.isEmpty
          ? booking.notes
          : '${booking.notes}\n\nAdmin $issueType resolution: $adminNote'
                .trim();
      final resolvedStatus =
          refundStatus == RefundStatus.approved ||
              refundStatus == RefundStatus.partial
          ? BookingStatus.cancelled
          : booking.status;

      changedBooking = booking.copyWith(
        status: resolvedStatus,
        refundStatus: refundStatus,
        paymentStatus: paymentStatus,
        notes: combinedNotes,
      );
      return changedBooking!;
    }).toList();

    state = state.copyWith(bookings: updated);
    if (changedBooking != null) {
      unawaited(_tryPersistBooking(changedBooking!));
    }
    _prependNotification(
      targetRole: UserRole.client,
      title: 'Booking issue updated',
      body:
          '$issueType for $bookingId is now ${refundStatus.name.replaceAll('_', ' ')}.',
    );
    await _persistOfflineHistory(updated);
  }

  Future<void> sendMessage({
    required String bookingId,
    required String senderId,
    required String senderName,
    required String body,
    ChatMessageType type = ChatMessageType.text,
  }) async {
    final updated = <String, List<ChatMessage>>{...state.chatThreads};
    final messages = <ChatMessage>[
      ...updated[bookingId] ?? const <ChatMessage>[],
    ];
    final message = ChatMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      bookingId: bookingId,
      senderId: senderId,
      senderName: senderName,
      body: body,
      sentAt: DateTime.now(),
      type: type,
    );
    messages.add(message);
    updated[bookingId] = messages;
    state = state.copyWith(chatThreads: updated);
    unawaited(_tryPersistMessage(message));
  }

  void markNotificationRead(String notificationId) {
    final updated = state.notifications
        .map(
          (item) =>
              item.id == notificationId ? item.copyWith(read: true) : item,
        )
        .toList();
    state = state.copyWith(notifications: updated);
    unawaited(_tryMarkNotificationRead(notificationId));
  }

  void logout() {
    unawaited(_bookingSubscription?.cancel());
    _bookingSubscription = null;
    state = state.copyWith(
      clearCurrentUser: true,
      selectedRole: UserRole.client,
    );
    unawaited(_authService.signOut());
  }

  void deleteCurrentAccount() {
    final current = state.currentUser;
    if (current == null) {
      return;
    }

    state = state.copyWith(
      clearCurrentUser: true,
      selectedRole: UserRole.client,
      clients: state.clients.where((item) => item.id != current.id).toList(),
      shootrs: state.shootrs.where((item) => item.id != current.id).toList(),
    );
    unawaited(_tryDeleteUser(current.id));
    unawaited(_authService.deleteCurrentUser());
  }

  void _onBookingCompleted(
    Booking booking, {
    String? deliveryTitle,
    String? deliveryVideoUrl,
    String? deliveryThumbnailUrl,
  }) {
    final shootrIndex = state.shootrs.indexWhere(
      (item) => item.id == booking.shootrId,
    );
    if (shootrIndex != -1) {
      final shootr = state.shootrs[shootrIndex];
      final previousLevel = shootr.level;
      final nextTotalShoots = shootr.totalShoots + 1;
      final nextLevel = levelFromShoots(nextTotalShoots);
      final nextWallet =
          (shootr.walletBalance +
                  (booking.baseAmount -
                      booking.platformFee -
                      booking.taxAmount))
              .clamp(0, double.infinity)
              .toDouble();

      final updatedShootr = shootr.copyWith(
        totalShoots: nextTotalShoots,
        reelsDelivered: shootr.reelsDelivered + booking.reelsNeeded,
        totalEarned: shootr.totalEarned + booking.baseAmount,
        walletBalance: nextWallet,
        level: nextLevel,
        badges: _levelBadges(nextLevel, shootr.badges),
      );
      _syncUser(updatedShootr);

      if (nextLevel != previousLevel) {
        _prependNotification(
          targetRole: UserRole.shootr,
          title: 'Level Up! ${nextLevel.label}',
          body:
              'You just moved from ${previousLevel.label} to ${nextLevel.label}. Priority ranking and rate ceiling updated.',
        );
      }
    }

    final clientIndex = state.clients.indexWhere(
      (item) => item.id == booking.clientId,
    );
    if (clientIndex != -1) {
      final client = state.clients[clientIndex];
      if (client.deliveredReels.every((item) => item.bookingId != booking.id)) {
        final shootrPhotoIndex = state.shootrs.indexWhere(
          (item) => item.id == booking.shootrId,
        );
        final shootrPhoto = shootrPhotoIndex == -1
            ? ''
            : state.shootrs[shootrPhotoIndex].photoUrl;
        final thumbnail = shootrPhoto.isNotEmpty
            ? shootrPhoto
            : 'https://images.unsplash.com/photo-1511578314322-379afb476865';
        final delivered = DeliveredReel(
          id: 'reel_${DateTime.now().microsecondsSinceEpoch}',
          title: deliveryTitle?.trim().isNotEmpty == true
              ? deliveryTitle!.trim()
              : '${booking.eventType} Reel',
          thumbnailUrl: deliveryThumbnailUrl?.trim().isNotEmpty == true
              ? deliveryThumbnailUrl!.trim()
              : thumbnail,
          videoUrl: deliveryVideoUrl?.trim().isNotEmpty == true
              ? deliveryVideoUrl!.trim()
              : 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          bookingId: booking.id,
          categoryId: booking.categoryId,
          shootrId: booking.shootrId,
          shootrName: booking.shootrName,
          deliveredAt: DateTime.now(),
        );

        final updatedClient = client.copyWith(
          deliveredReels: <DeliveredReel>[delivered, ...client.deliveredReels],
          walletTransactions: <WalletTransaction>[
            WalletTransaction(
              id: 'txn_${DateTime.now().microsecondsSinceEpoch}',
              title: 'Reel delivered',
              subtitle: booking.shootrName,
              amount: 0,
              createdAt: DateTime.now(),
              isCredit: true,
            ),
            ...client.walletTransactions,
          ],
        );
        _syncUser(updatedClient);
      }
    }

    _prependNotification(
      targetRole: UserRole.client,
      title: 'Reel delivered',
      body:
          'Your booking ${booking.id} is complete. Reel is now in Shootr Vault.',
    );
  }

  void _startLiveTracking() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      final updated = <String, AppLocation>{};
      for (final booking in state.bookings.where((item) => item.trackEnabled)) {
        updated[booking.id] = AppLocation(
          address: booking.location.address,
          city: booking.location.city,
          state: booking.location.state,
          country: booking.location.country,
          latitude: booking.location.latitude + 0.0002,
          longitude: booking.location.longitude + 0.0002,
          placeLabel: booking.location.placeLabel,
        );
      }
      if (updated.isNotEmpty) {
        state = state.copyWith(liveShootrLocations: updated);
      }
    });
  }

  void _startBookingRealtime(AppUser user) {
    unawaited(_bookingSubscription?.cancel());
    _bookingSubscription = _bookingService
        .watchBookingsForUser(user)
        .listen(
          (bookings) {
            state = state.copyWith(bookings: bookings, isOffline: false);
            unawaited(_refreshChatThreads(bookings));
          },
          onError: (_) {
            if (mounted) {
              state = state.copyWith(isOffline: true);
            }
          },
        );
  }

  Future<void> _refreshChatThreads(List<Booking> bookings) async {
    try {
      final threads = await _chatService.getThreadsForBookings(bookings);
      if (mounted) {
        state = state.copyWith(chatThreads: threads);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isOffline: true);
      }
    }
  }

  AppLocation? _locationFromUser(AppUser? user) {
    if (user == null) {
      return null;
    }
    return AppLocation(
      address: user.address.isEmpty ? user.city : user.address,
      city: user.city,
      state: user.state,
      country: user.country,
      latitude: user.latitude,
      longitude: user.longitude,
      placeLabel: user.city,
    );
  }

  String _currentAuthContact() {
    final phone = _authService.currentPhoneNumber;
    if (phone != null && phone.trim().isNotEmpty) {
      return phone.trim();
    }

    final email = _authService.currentEmail;
    if (email != null && email.trim().isNotEmpty) {
      return email.trim();
    }

    final pendingPhone = state.pendingPhoneNumber.trim();
    if (pendingPhone.isEmpty) {
      return '';
    }
    return '${state.pendingCountryCode} $pendingPhone';
  }

  Future<void> _persistOfflineHistory(List<Booking> bookings) async {
    final completed = bookings
        .where((booking) => booking.status == BookingStatus.completed)
        .toList();
    await _cacheService.cacheCompletedBookings(completed);
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _bookingSubscription?.cancel();
    super.dispose();
  }

  void _replaceCurrentUser(AppUser? updatedUser) {
    if (updatedUser == null) {
      return;
    }

    _syncUser(updatedUser, setAsCurrentUser: true);
  }

  void _syncUser(AppUser updatedUser, {bool setAsCurrentUser = false}) {
    final nextCurrentUser =
        setAsCurrentUser || state.currentUser?.id == updatedUser.id
        ? updatedUser
        : state.currentUser;

    state = state.copyWith(
      currentUser: nextCurrentUser,
      clients: updatedUser.role == UserRole.client
          ? _upsertUserInList(state.clients, updatedUser)
          : state.clients,
      shootrs: updatedUser.role == UserRole.shootr
          ? _upsertUserInList(state.shootrs, updatedUser)
          : state.shootrs,
    );
    unawaited(_tryPersistUser(updatedUser));
  }

  void _prependNotification({
    required UserRole targetRole,
    required String title,
    required String body,
  }) {
    final notification = AppNotification(
      id: 'ntf_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      body: body,
      createdAt: DateTime.now(),
      targetRole: targetRole,
    );

    state = state.copyWith(
      notifications: <AppNotification>[notification, ...state.notifications],
    );
    unawaited(_tryPersistNotification(notification));
  }

  List<AppUser> _upsertUserInList(List<AppUser> users, AppUser updatedUser) {
    var found = false;
    final updated = users.map((user) {
      if (user.id == updatedUser.id) {
        found = true;
        return updatedUser;
      }
      return user;
    }).toList();
    if (!found) {
      updated.add(updatedUser);
    }
    return updated;
  }

  Future<void> _tryPersistUser(AppUser user) async {
    try {
      await _userService.upsertUser(user);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isOffline: true);
      }
    }
  }

  Future<void> _tryDeleteUser(String userId) async {
    try {
      await _userService.deleteUser(userId);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isOffline: true);
      }
    }
  }

  Future<void> _tryPersistBooking(Booking booking) async {
    try {
      await _bookingService.upsertBooking(booking);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isOffline: true);
      }
    }
  }

  Future<void> _tryPersistMessage(ChatMessage message) async {
    try {
      await _chatService.sendMessage(message);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isOffline: true);
      }
    }
  }

  Future<void> _tryPersistNotification(AppNotification notification) async {
    try {
      await _notificationService.createNotification(notification);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isOffline: true);
      }
    }
  }

  Future<void> _tryMarkNotificationRead(String notificationId) async {
    try {
      await _notificationService.markRead(notificationId);
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isOffline: true);
      }
    }
  }

  String _authErrorMessage(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '');
    if (message.contains('invalid-verification-code')) {
      return 'That OTP did not match. Please try again.';
    }
    if (message.contains('missing-verification-id')) {
      return 'Please request a new OTP first.';
    }
    if (message.contains('too-many-requests')) {
      return 'Too many OTP attempts. Please try again later.';
    }
    if (message.contains('quota-exceeded')) {
      return 'OTP quota is temporarily exhausted. Please try again later.';
    }
    return message.replaceFirst(RegExp(r'^\[firebase_auth/.*?\]\s*'), '');
  }

  VerificationStatus _verificationStatusForStatus(
    AccountStatus status,
    VerificationStatus current,
  ) {
    switch (status) {
      case AccountStatus.active:
        return VerificationStatus.verified;
      case AccountStatus.pendingReview:
        return VerificationStatus.pending;
      case AccountStatus.suspended:
      case AccountStatus.banned:
        return VerificationStatus.suspended;
      case AccountStatus.rejected:
        return VerificationStatus.rejected;
      case AccountStatus.flagged:
      case AccountStatus.warned:
        return current;
    }
  }

  List<String> _statusBadges(
    List<String> currentBadges, {
    required AccountStatus status,
    String pendingLabel = 'Pending',
  }) {
    final nextBadges = currentBadges
        .where(
          (badge) => !<String>{
            'Pending',
            'Pending Review',
            'Flagged',
            'Warned',
            'Suspended',
            'Rejected',
            'Banned',
          }.contains(badge),
        )
        .toList();

    switch (status) {
      case AccountStatus.pendingReview:
        nextBadges.insert(0, pendingLabel);
        return nextBadges;
      case AccountStatus.flagged:
        nextBadges.insert(0, 'Flagged');
        return nextBadges;
      case AccountStatus.warned:
        nextBadges.insert(0, 'Warned');
        return nextBadges;
      case AccountStatus.suspended:
        nextBadges.insert(0, 'Suspended');
        return nextBadges;
      case AccountStatus.rejected:
        nextBadges.insert(0, 'Rejected');
        return nextBadges;
      case AccountStatus.banned:
        nextBadges.insert(0, 'Banned');
        return nextBadges;
      case AccountStatus.active:
        return nextBadges;
    }
  }

  List<String> _levelBadges(ShootrLevel level, List<String> badges) {
    final next = badges
        .where(
          (badge) => !<String>{
            ShootrLevel.rookie.label,
            ShootrLevel.pro.label,
            ShootrLevel.elite.label,
            ShootrLevel.master.label,
          }.contains(badge),
        )
        .toList();
    next.insert(0, level.label);
    return next;
  }
}
