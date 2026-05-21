import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/admin_shell.dart';
import '../../features/auth/presentation/auth_flow.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/client/presentation/booking_flow_screen.dart';
import '../../features/client/presentation/client_bookings_screen.dart';
import '../../features/client/presentation/client_home_screen.dart';
import '../../features/client/presentation/client_profile_screen.dart';
import '../../features/client/presentation/client_search_screen.dart';
import '../../features/client/presentation/client_shell.dart';
import '../../features/client/presentation/client_vault_screen.dart';
import '../../features/client/presentation/shootr_profile_screen.dart';
import '../../features/client/presentation/tracking_screens.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/shootr/presentation/shootr_shell.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _fadePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) =>
            _fadePage(state, const OnboardingScreen()),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        pageBuilder: (context, state) =>
            _fadePage(state, const RoleSelectionScreen()),
      ),
      GoRoute(
        path: AppRoutes.phoneEntry,
        pageBuilder: (context, state) =>
            _fadePage(state, const PhoneEntryScreen()),
      ),
      GoRoute(
        path: AppRoutes.emailAuth,
        pageBuilder: (context, state) =>
            _fadePage(state, const EmailAuthScreen()),
      ),
      GoRoute(
        path: AppRoutes.otp,
        pageBuilder: (context, state) =>
            _fadePage(state, const OtpVerificationScreen()),
      ),
      GoRoute(
        path: AppRoutes.clientProfileSetup,
        pageBuilder: (context, state) =>
            _fadePage(state, const ClientProfileSetupScreen()),
      ),
      GoRoute(
        path: AppRoutes.shootrProfileSetup,
        pageBuilder: (context, state) =>
            _fadePage(state, const ShootrProfileSetupScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            ClientShell(currentLocation: state.matchedLocation, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.clientHome,
            pageBuilder: (context, state) =>
                _fadePage(state, const ClientHomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.clientSearch,
            pageBuilder: (context, state) =>
                _fadePage(state, const ClientSearchScreen()),
          ),
          GoRoute(
            path: AppRoutes.clientBookings,
            pageBuilder: (context, state) =>
                _fadePage(state, const ClientBookingsScreen()),
          ),
          GoRoute(
            path: AppRoutes.clientChat,
            pageBuilder: (context, state) =>
                _fadePage(state, const ClientChatHubScreen()),
          ),
          GoRoute(
            path: AppRoutes.clientProfile,
            pageBuilder: (context, state) =>
                _fadePage(state, const ClientProfileScreen()),
          ),
          GoRoute(
            path: AppRoutes.clientVault,
            pageBuilder: (context, state) =>
                _fadePage(state, const ClientVaultScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '${AppRoutes.shootrPublicProfile}/:id',
        pageBuilder: (context, state) => _fadePage(
          state,
          ShootrPublicProfileScreen(shootrId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.bookingFlow,
        pageBuilder: (context, state) =>
            _fadePage(state, const BookingFlowScreen()),
      ),
      GoRoute(
        path: '${AppRoutes.bookingFlow}/:id',
        pageBuilder: (context, state) =>
            _fadePage(state, const BookingFlowScreen()),
      ),
      GoRoute(
        path: '${AppRoutes.bookingConfirmation}/:id',
        pageBuilder: (context, state) => _fadePage(
          state,
          BookingConfirmationScreen(bookingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.liveTracking}/:id',
        pageBuilder: (context, state) => _fadePage(
          state,
          LiveTrackingScreen(bookingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.activeShoot}/:id',
        pageBuilder: (context, state) => _fadePage(
          state,
          ActiveShootScreen(bookingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '${AppRoutes.reelDelivery}/:id',
        pageBuilder: (context, state) => _fadePage(
          state,
          ReelDeliveryScreen(bookingId: state.pathParameters['id']!),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            ShootrShell(currentLocation: state.matchedLocation, child: child),
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.shootrHome,
            pageBuilder: (context, state) =>
                _fadePage(state, const ShootrHomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.shootrRequests,
            pageBuilder: (context, state) =>
                _fadePage(state, const ShootrRequestsScreen()),
          ),
          GoRoute(
            path: AppRoutes.shootrActive,
            pageBuilder: (context, state) =>
                _fadePage(state, const ShootrActiveBookingsScreen()),
          ),
          GoRoute(
            path: AppRoutes.shootrEarnings,
            pageBuilder: (context, state) =>
                _fadePage(state, const EarningsScreen()),
          ),
          GoRoute(
            path: AppRoutes.shootrProfile,
            pageBuilder: (context, state) =>
                _fadePage(state, const ShootrProfileScreen()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.shootrAvailability,
        pageBuilder: (context, state) =>
            _fadePage(state, const AvailabilityManagementScreen()),
      ),
      GoRoute(
        path: AppRoutes.shootrReviews,
        pageBuilder: (context, state) =>
            _fadePage(state, const ShootrReviewsScreen()),
      ),
      GoRoute(
        path: '${AppRoutes.shootrUpload}/:id',
        pageBuilder: (context, state) => _fadePage(
          state,
          ReelUploadScreen(bookingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) =>
            _fadePage(state, const NotificationsScreen()),
      ),
      GoRoute(
        path: '${AppRoutes.chatThread}/:id',
        pageBuilder: (context, state) => _fadePage(
          state,
          ChatThreadScreen(bookingId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.admin,
        pageBuilder: (context, state) => _fadePage(state, const AdminShell()),
      ),
    ],
  );
});

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: 420.ms,
    reverseTransitionDuration: 320.ms,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
