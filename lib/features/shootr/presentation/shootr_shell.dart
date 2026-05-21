import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/marketplace_catalog.dart';
import '../../../shared/models/shootr_package.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/flow_guide_card.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/network_avatar.dart';
import '../../../shared/widgets/primary_glow_button.dart';

class ShootrShell extends StatelessWidget {
  const ShootrShell({
    required this.currentLocation,
    required this.child,
    super.key,
  });

  final String currentLocation;
  final Widget child;

  int get _currentIndex {
    if (currentLocation.startsWith(AppRoutes.shootrRequests)) {
      return 1;
    }
    if (currentLocation.startsWith(AppRoutes.shootrActive)) {
      return 2;
    }
    if (currentLocation.startsWith(AppRoutes.shootrEarnings)) {
      return 3;
    }
    if (currentLocation.startsWith(AppRoutes.shootrProfile)) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    const routes = <String>[
      AppRoutes.shootrHome,
      AppRoutes.shootrRequests,
      AppRoutes.shootrActive,
      AppRoutes.shootrEarnings,
      AppRoutes.shootrProfile,
    ];

    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF101010),
              AppColors.background,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(child: child),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.18),
        destinations: const <NavigationDestination>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.notifications_active_outlined),
            label: 'Requests',
          ),
          NavigationDestination(
            icon: Icon(Icons.flash_on_outlined),
            label: 'Active',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Earnings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (index) => context.go(routes[index]),
      ),
    );
  }
}

class ShootrHomeScreen extends ConsumerStatefulWidget {
  const ShootrHomeScreen({super.key});

  @override
  ConsumerState<ShootrHomeScreen> createState() => _ShootrHomeScreenState();
}

class _ShootrHomeScreenState extends ConsumerState<ShootrHomeScreen> {
  bool _showMonthly = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final shootr = state.currentUser?.role == UserRole.shootr
        ? state.currentUser
        : null;
    final currencyCountry = shootr?.country ?? AppCountry.india;
    final grossEarnings = state.bookings.fold<double>(
      0,
      (sum, booking) => sum + booking.baseAmount,
    );
    final platformFees = state.bookings.fold<double>(
      0,
      (sum, booking) => sum + booking.platformFee,
    );
    final taxes = state.bookings.fold<double>(
      0,
      (sum, booking) => sum + booking.taxAmount,
    );
    final weeklyNet = (grossEarnings - platformFees - taxes)
        .clamp(0.0, double.infinity)
        .toDouble();
    final monthlyNet = weeklyNet * 4.2;
    final todaysNet = weeklyNet / 7;
    final activeBookings = state.bookings
        .where(
          (booking) =>
              booking.shootrId == shootr?.id &&
              booking.status == BookingStatus.active,
        )
        .toList();
    String? latestLevelUpMessage;
    for (final item in state.notifications) {
      if (item.targetRole == UserRole.shootr &&
          item.title.startsWith('Level Up!')) {
        latestLevelUpMessage = item.body;
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Ready to Shoot, ${shootr?.name.split(' ').first ?? 'Creator'}?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Switch.adaptive(
              value: state.isShootrOnline,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
              onChanged: (_) =>
                  ref.read(appControllerProvider.notifier).toggleShootrOnline(),
            ),
          ],
        ),
        const SizedBox(height: 18),
        FlowGuideCard(
          title: 'Daily Operating Flow',
          subtitle:
              'Keep this loop simple to improve response rate and on-time score.',
          steps: const <FlowGuideStep>[
            FlowGuideStep(
              title: '1. Go online',
              subtitle:
                  'Enable availability so nearby clients can discover you.',
              icon: Icons.toggle_on_rounded,
            ),
            FlowGuideStep(
              title: '2. Accept requests',
              subtitle:
                  'Review client brief quickly and accept suitable bookings.',
              icon: Icons.notifications_active_outlined,
            ),
            FlowGuideStep(
              title: '3. Shoot + update status',
              subtitle:
                  'Use Active tab to keep progress transparent for client and support.',
              icon: Icons.video_camera_back_outlined,
            ),
            FlowGuideStep(
              title: '4. Upload reel + complete',
              subtitle:
                  'Deliver on time to grow repeat clients and level up faster.',
              icon: Icons.upload_file_outlined,
            ),
          ],
          actionLabel: 'Open Requests',
          onAction: () => context.go(AppRoutes.shootrRequests),
        ),
        const SizedBox(height: 16),
        GlassCard(
          borderColor: AppColors.primary.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Today\'s earnings',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _HomeChip(
                    label: 'Week',
                    selected: !_showMonthly,
                    onTap: () => setState(() => _showMonthly = false),
                  ),
                  const SizedBox(width: 8),
                  _HomeChip(
                    label: 'Month',
                    selected: _showMonthly,
                    onTap: () => setState(() => _showMonthly = true),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                AppFormatters.currency(todaysNet, country: currencyCountry),
                style: Theme.of(
                  context,
                ).textTheme.displayMedium?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                _showMonthly
                    ? 'Monthly projection: ${AppFormatters.currency(monthlyNet, country: currencyCountry)}'
                    : 'Weekly net: ${AppFormatters.currency(weeklyNet, country: currencyCountry)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Breakdown',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _EarningsRow(
                      label: 'Gross',
                      value: AppFormatters.currency(
                        grossEarnings,
                        country: currencyCountry,
                      ),
                    ),
                    _EarningsRow(
                      label: 'Platform fee deducted',
                      value: AppFormatters.currency(
                        platformFees,
                        country: currencyCountry,
                      ),
                    ),
                    _EarningsRow(
                      label: '${currencyCountry.taxLabel} deducted',
                      value: AppFormatters.currency(
                        taxes,
                        country: currencyCountry,
                      ),
                    ),
                    _EarningsRow(
                      label: 'Net earnings',
                      value: AppFormatters.currency(
                        weeklyNet,
                        country: currencyCountry,
                      ),
                      emphasize: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          borderColor: state.isShootrOnline
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.glass,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Availability today',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'You\'re available ${shootr?.todayAvailability ?? '10:00 AM - 08:00 PM'} today',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                state.isShootrOnline
                    ? 'You are live for instant bookings right now.'
                    : 'Next available slot: ${shootr?.nextAvailableSlot ?? 'Tomorrow 10:00 AM'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          context.push(AppRoutes.shootrAvailability),
                      child: const Text('Quick Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: state.isShootrOnline
                          ? () => ref
                                .read(appControllerProvider.notifier)
                                .toggleShootrOnline()
                          : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Set as Busy for Today'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (latestLevelUpMessage != null) ...<Widget>[
          GlassCard(
            borderColor: AppColors.primary.withValues(alpha: 0.35),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 68,
                  height: 68,
                  child: lottie.Lottie.network(
                    AppConstants.successLottieUrl,
                    repeat: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Level Up',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        latestLevelUpMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (state.bookings
            .where(
              (booking) =>
                  booking.status == BookingStatus.pending &&
                  booking.shootrId.isEmpty &&
                  (shootr?.specialisationIds.contains(booking.categoryId) ??
                      true) &&
                  (shootr == null || booking.location.city == shootr.city),
            )
            .isNotEmpty)
          GlassCard(
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Incoming booking request waiting for response',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRoutes.shootrRequests),
                  child: const Text('View'),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _MiniMetric(
                title: 'Today',
                value: '${activeBookings.length} shoots',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniMetric(title: 'This week', value: '11 shoots'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniMetric(
                title: 'Total earned',
                value: AppFormatters.currency(
                  weeklyNet,
                  country: currencyCountry,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Upcoming bookings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...state.bookings
            .where((booking) => booking.shootrId == shootr?.id)
            .take(3)
            .map(
              (booking) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        booking.clientName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${booking.packageType.label} - ${AppFormatters.dateTime(booking.scheduledAt)}',
                      ),
                      const SizedBox(height: 4),
                      Text(booking.location.address),
                    ],
                  ),
                ),
              ),
            ),
        const SizedBox(height: 18),
        Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.push(AppRoutes.shootrAvailability),
                child: const Text('Set availability'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go(AppRoutes.shootrEarnings),
                child: const Text('View earnings'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.go(AppRoutes.shootrProfile),
                child: const Text('Portfolio'),
              ),
            ),
          ],
        ),
        if (shootr?.badges.contains('Pending Review') ?? false) ...<Widget>[
          const SizedBox(height: 16),
          const EmptyStateView(
            title: 'Application in review',
            subtitle:
                'Admins will verify your portfolio and payout details before you go live.',
          ),
        ],
      ],
    );
  }
}

class ShootrRequestsScreen extends ConsumerWidget {
  const ShootrRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shootr = ref.watch(currentUserProvider);
    final requests = ref
        .watch(appControllerProvider)
        .bookings
        .where(
          (booking) =>
              booking.status == BookingStatus.pending &&
              booking.shootrId.isEmpty &&
              (shootr?.specialisationIds.contains(booking.categoryId) ??
                  true) &&
              (shootr == null || booking.location.city == shootr.city),
        )
        .toList();
    final currencyCountry = shootr?.country ?? AppCountry.india;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text(
          'Incoming Requests',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        if (requests.isEmpty)
          const EmptyStateView(
            title: 'No incoming requests',
            subtitle: 'New client booking requests will appear here instantly.',
          )
        else
          ...requests.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GlassCard(
                borderColor: AppColors.primary.withValues(alpha: 0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                booking.clientName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${booking.eventType} - ${booking.location.city}',
                              ),
                            ],
                          ),
                        ),
                        Text(
                          AppFormatters.currency(
                            booking.baseAmount,
                            country: currencyCountry,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Special notes: ${booking.notes.isEmpty ? 'No special notes' : booking.notes}',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: PrimaryGlowButton(
                            label: 'Accept',
                            onPressed: () async {
                              final accepted = await ref
                                  .read(appControllerProvider.notifier)
                                  .acceptBookingRequest(booking.id);
                              if (context.mounted) {
                                if (accepted) {
                                  context.go(AppRoutes.shootrActive);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'This request is no longer available.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Skipped. The request remains open for other Shootrs.',
                                    ),
                                  ),
                                ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Decline'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class ShootrActiveBookingsScreen extends ConsumerWidget {
  const ShootrActiveBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shootr = ref.watch(currentUserProvider);
    final activeBookings = ref
        .watch(appControllerProvider)
        .bookings
        .where(
          (booking) =>
              booking.shootrId == shootr?.id &&
              (booking.status == BookingStatus.confirmed ||
                  booking.status == BookingStatus.active),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text(
          'Active Bookings',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        if (activeBookings.isEmpty)
          const EmptyStateView(
            title: 'No active bookings',
            subtitle: 'Accepted jobs will move here once you are on the shoot.',
          )
        else
          ...activeBookings.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      booking.clientName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(booking.location.address),
                    const SizedBox(height: 6),
                    Text(
                      'Style: ${booking.stylePreference}  •  ${booking.reelsNeeded} reels',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Mood: ${booking.mood}  •  Music: ${booking.musicPreference}',
                    ),
                    if (booking.referenceLink.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text('Reference: ${booking.referenceLink}'),
                    ],
                    if (booking.notes.trim().isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text('Brief: ${booking.notes}'),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: booking.location.address),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Address copied for navigation.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Navigate'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => context.push(
                            '${AppRoutes.shootrUpload}/${booking.id}',
                          ),
                          icon: const Icon(Icons.upload_file_outlined),
                          label: const Text('Upload reel'),
                        ),
                        PrimaryGlowButton(
                          label: booking.status == BookingStatus.confirmed
                              ? 'Start shoot'
                              : 'Mark complete',
                          onPressed: () => ref
                              .read(appControllerProvider.notifier)
                              .updateBookingStatus(
                                booking.id,
                                booking.status == BookingStatus.confirmed
                                    ? BookingStatus.active
                                    : BookingStatus.completed,
                              ),
                          isExpanded: false,
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            bool callEmergencyContact = false;
                            final confirmed =
                                await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) {
                                    return StatefulBuilder(
                                      builder: (context, setDialogState) {
                                        return AlertDialog(
                                          backgroundColor: AppColors.surface,
                                          title: const Text('Emergency SOS'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              const Text(
                                                'Trigger SOS for this active booking?',
                                              ),
                                              const SizedBox(height: 12),
                                              CheckboxListTile(
                                                value: callEmergencyContact,
                                                onChanged: (value) =>
                                                    setDialogState(
                                                      () =>
                                                          callEmergencyContact =
                                                              value ?? false,
                                                    ),
                                                title: const Text(
                                                  'Call emergency contact',
                                                ),
                                                contentPadding: EdgeInsets.zero,
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                              ),
                                            ],
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                dialogContext,
                                              ).pop(false),
                                              child: const Text('Cancel'),
                                            ),
                                            OutlinedButton(
                                              onPressed: () => Navigator.of(
                                                dialogContext,
                                              ).pop(true),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.error,
                                              ),
                                              child: const Text('Trigger SOS'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ) ??
                                false;
                            if (!confirmed || !context.mounted) {
                              return;
                            }
                            ref
                                .read(appControllerProvider.notifier)
                                .sendSafetyAlert(
                                  bookingId: booking.id,
                                  triggeredBy: UserRole.shootr,
                                  callEmergencyContact: callEmergencyContact,
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'SOS alert sent. Support has been notified.',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.sos_outlined),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          label: const Text('SOS'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final balance = state.currentUser?.walletBalance ?? 18340;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        GlassCard(
          borderColor: AppColors.primary.withValues(alpha: 0.24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Withdrawable balance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                AppFormatters.currency(balance),
                style: Theme.of(
                  context,
                ).textTheme.displayMedium?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              PrimaryGlowButton(
                label: 'Withdraw',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Withdrawals are coming soon after payout verification.',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 260,
          child: GlassCard(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = <String>[
                          'M',
                          'T',
                          'W',
                          'T',
                          'F',
                          'S',
                          'S',
                        ];
                        return Text(labels[value.toInt()]);
                      },
                    ),
                  ),
                ),
                barGroups: <BarChartGroupData>[
                  for (
                    var i = 0;
                    i < state.adminOverview.revenueTrend.length;
                    i++
                  )
                    BarChartGroupData(
                      x: i,
                      barRods: <BarChartRodData>[
                        BarChartRodData(
                          toY: state.adminOverview.revenueTrend[i].value,
                          color: AppColors.primary,
                          width: 18,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Transactions', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...state.bookings.map(
          (booking) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          booking.id,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(AppFormatters.dateTime(booking.createdAt)),
                      ],
                    ),
                  ),
                  Text(AppFormatters.currency(booking.baseAmount * 0.72)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ShootrProfileScreen extends ConsumerWidget {
  const ShootrProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shootr = ref.watch(currentUserProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        GlassCard(
          child: Row(
            children: <Widget>[
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: shootr == null
                    ? null
                    : () => _showShootrPhotoPicker(context, ref, shootr),
                child: NetworkAvatar(
                  imageUrl:
                      shootr?.photoUrl ??
                      'https://images.unsplash.com/photo-1521119989659-a83eee488004',
                  radius: 34,
                  heroTag: shootr == null ? null : 'shootr-${shootr.id}',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      shootr?.name ?? 'Shootr',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(shootr?.bio ?? 'Complete your creator profile'),
                  ],
                ),
              ),
              TextButton(
                onPressed: shootr == null
                    ? null
                    : () => _showShootrCoreEditor(context, ref, shootr),
                child: const Text('Edit'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (shootr != null)
          GlassCard(
            borderColor: AppColors.primary.withValues(alpha: 0.22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _StatusPill(
                      label: shootr.level.label,
                      color: AppColors.primary,
                    ),
                    _StatusPill(
                      label: 'Aadhaar ${shootr.identityStatus.label}',
                      color:
                          shootr.identityStatus == VerificationStatus.verified
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    _StatusPill(
                      label: 'Device ${shootr.deviceVerificationStatus.label}',
                      color:
                          shootr.deviceVerificationStatus ==
                              VerificationStatus.verified
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push(
                          '${AppRoutes.shootrPublicProfile}/${shootr.id}',
                        ),
                        child: const Text('Preview Public Profile'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push(AppRoutes.shootrReviews),
                        child: const Text('Reviews'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _MiniMetric(
                title: 'Completion',
                value: AppFormatters.percent(shootr?.completionRate ?? 100),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniMetric(
                title: 'Avg rating',
                value: '${shootr?.rating ?? 0} rating',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniMetric(
                title: 'Response',
                value: '${shootr?.avgResponseMinutes ?? 0}m',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (shootr?.badges ?? const <String>['Pending Review'])
                .map((badge) => Chip(label: Text(badge)))
                .toList(),
          ),
        ),
        const SizedBox(height: 16),
        if (shootr != null)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Specialisations',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _showShootrCoreEditor(context, ref, shootr),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: shootr.specialisationIds
                      .map(
                        (id) => _StatusPill(
                          label: kMarketplaceCategories
                              .firstWhere(
                                (item) => item.id == id,
                                orElse: () => const MarketplaceCategory(
                                  id: 'other',
                                  label: 'Other',
                                  emoji: '',
                                  iconKey: 'plusCircle',
                                ),
                              )
                              .label,
                          color: AppColors.primary,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (shootr != null)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Portfolio',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _appendShootrPortfolio(context, ref, shootr),
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 104,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: shootr.portfolio.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => Stack(
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radius,
                          ),
                          child: Image.network(
                            shootr.portfolio[index],
                            width: 116,
                            height: 104,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: InkWell(
                            onTap: () =>
                                _removeShootrPortfolioItem(ref, shootr, index),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black87,
                              child: Icon(
                                PhosphorIcons.x(),
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (shootr != null)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Pricing',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _showShootrPricingEditor(context, ref, shootr),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${AppFormatters.currency(shootr.hourlyRate, country: shootr.country)}/hr',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Allowed range: ${AppFormatters.currency(shootr.deviceTier.minRate, country: shootr.country)} - ${AppFormatters.currency(shootr.deviceTier.maxRate, country: shootr.country)}',
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (shootr != null)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Availability',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _showShootrAvailabilityEditor(context, ref, shootr),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Today: ${shootr.todayAvailability}'),
                const SizedBox(height: 4),
                Text('Next available: ${shootr.nextAvailableSlot}'),
                const SizedBox(height: 4),
                Text(
                  shootr.onDemandMode
                      ? 'On-demand mode enabled'
                      : 'On-demand mode disabled',
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (shootr != null)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Bank & UPI',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          _showShootrPayoutEditor(context, ref, shootr),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('UPI: ${shootr.upiId.ifEmpty('Not added')}'),
                const SizedBox(height: 4),
                Text('Bank: ${shootr.bankName.ifEmpty('Not added')}'),
                const SizedBox(height: 4),
                Text(
                  'IFSC: ${shootr.ifscCode.ifEmpty('Pending verification')}',
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        if (shootr != null)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Settings', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: shootr.notificationPreferences.bookingUpdates,
                  onChanged: (value) => ref
                      .read(appControllerProvider.notifier)
                      .updateNotificationPreferences(
                        shootr.notificationPreferences.copyWith(
                          bookingUpdates: value,
                        ),
                      ),
                  title: const Text('Booking updates'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: shootr.notificationPreferences.messages,
                  onChanged: (value) => ref
                      .read(appControllerProvider.notifier)
                      .updateNotificationPreferences(
                        shootr.notificationPreferences.copyWith(
                          messages: value,
                        ),
                      ),
                  title: const Text('Messages'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: shootr.notificationPreferences.payouts,
                  onChanged: (value) => ref
                      .read(appControllerProvider.notifier)
                      .updateNotificationPreferences(
                        shootr.notificationPreferences.copyWith(payouts: value),
                      ),
                  title: const Text('Payout alerts'),
                ),
                _SettingsAction(
                  label: 'Privacy',
                  onTap: () => _showShootrInfoDialog(
                    context,
                    'Privacy',
                    'Sensitive documents and payout data are restricted to admins in this preview build.',
                  ),
                ),
                _SettingsAction(
                  label: 'Language',
                  trailing: 'English',
                  onTap: () => _showShootrInfoDialog(
                    context,
                    'Language',
                    'Hindi and more local languages can be added next.',
                  ),
                ),
                _SettingsAction(
                  label: 'Help',
                  onTap: () => _showShootrInfoDialog(
                    context,
                    'Help',
                    'Support chat and FAQ flows can plug in here.',
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => context.push(AppRoutes.shootrReviews),
          child: const Text('View reviews'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _showShootrInfoDialog(
            context,
            'Certification status',
            shootr == null
                ? 'No Shootr profile loaded.'
                : 'Aadhaar: ${shootr.identityStatus.label}\nDevice: ${shootr.deviceVerificationStatus.label}\nBackground check: ${shootr.backgroundVerified ? 'Verified' : 'Pending'}',
          ),
          child: const Text('Certification status'),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Refer a Shootr, earn Rs 1,000',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('Referral code: ${shootr?.referralCode ?? 'SHOOTR1000'}'),
              const SizedBox(height: 4),
              Text('Referred users: ${shootr?.referredUsers ?? 0}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            ref.read(appControllerProvider.notifier).logout();
            context.go(AppRoutes.roleSelection);
          },
          child: const Text('Logout'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _confirmShootrDelete(context, ref),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Delete account'),
        ),
      ],
    );
  }
}

Future<void> _showShootrPhotoPicker(
  BuildContext context,
  WidgetRef ref,
  AppUser shootr,
) async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 88,
    maxWidth: 1800,
  );
  if (file == null || !context.mounted) {
    return;
  }

  try {
    final uploaded = await ref
        .read(cloudinaryServiceProvider)
        .uploadFile(
          file: file,
          folder: 'shootr/shootr-profiles',
          tags: const <String>['shootr', 'shootr-profile'],
        );
    ref
        .read(appControllerProvider.notifier)
        .updateShootrProfile(photoUrl: uploaded.secureUrl);
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

Future<void> _showShootrCoreEditor(
  BuildContext context,
  WidgetRef ref,
  AppUser shootr,
) async {
  final nameController = TextEditingController(text: shootr.name);
  final bioController = TextEditingController(text: shootr.bio);
  final selected = <String>{...shootr.specialisationIds};
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Text(
                'Edit profile',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bioController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kMarketplaceCategories
                    .map(
                      (item) => _StatusPill(
                        label: item.label,
                        color: selected.contains(item.id)
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        onTap: () => setModalState(() {
                          if (selected.contains(item.id)) {
                            selected.remove(item.id);
                          } else {
                            selected.add(item.id);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              PrimaryGlowButton(
                label: 'Save',
                onPressed: () {
                  ref
                      .read(appControllerProvider.notifier)
                      .updateShootrProfile(
                        name: nameController.text.trim(),
                        bio: bioController.text.trim(),
                        specialisationIds: selected.toList(),
                      );
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _appendShootrPortfolio(
  BuildContext context,
  WidgetRef ref,
  AppUser shootr,
) async {
  if (shootr.portfolio.length >= AppConstants.maxPortfolioItems) {
    return;
  }
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 88,
    maxWidth: 1800,
  );
  if (file == null || !context.mounted) {
    return;
  }

  try {
    final uploaded = await ref
        .read(cloudinaryServiceProvider)
        .uploadFile(
          file: file,
          folder: 'shootr/portfolios',
          tags: const <String>['shootr', 'portfolio'],
        );
    ref
        .read(appControllerProvider.notifier)
        .updateShootrProfile(
          portfolio: <String>[...shootr.portfolio, uploaded.secureUrl],
        );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

void _removeShootrPortfolioItem(WidgetRef ref, AppUser shootr, int index) {
  final next = <String>[...shootr.portfolio]..removeAt(index);
  ref.read(appControllerProvider.notifier).updateShootrProfile(portfolio: next);
}

Future<void> _showShootrPricingEditor(
  BuildContext context,
  WidgetRef ref,
  AppUser shootr,
) async {
  var rate = shootr.hourlyRate;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Edit pricing',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 14),
              Slider(
                value: rate
                    .clamp(shootr.deviceTier.minRate, shootr.deviceTier.maxRate)
                    .toDouble(),
                min: shootr.deviceTier.minRate,
                max: shootr.deviceTier.maxRate,
                divisions:
                    ((shootr.deviceTier.maxRate - shootr.deviceTier.minRate) /
                            100)
                        .round()
                        .clamp(1, 40),
                activeColor: AppColors.primary,
                onChanged: (value) => setModalState(() => rate = value),
              ),
              Text(
                '${AppFormatters.currency(rate, country: shootr.country)}/hr',
              ),
              const SizedBox(height: 16),
              PrimaryGlowButton(
                label: 'Save pricing',
                onPressed: () {
                  ref
                      .read(appControllerProvider.notifier)
                      .updateShootrProfile(hourlyRate: rate);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _showShootrAvailabilityEditor(
  BuildContext context,
  WidgetRef ref,
  AppUser shootr,
) async {
  final todayController = TextEditingController(text: shootr.todayAvailability);
  final nextController = TextEditingController(text: shootr.nextAvailableSlot);
  var onDemand = shootr.onDemandMode;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Text(
                'Edit availability',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: todayController,
                decoration: const InputDecoration(
                  labelText: 'Today availability',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nextController,
                decoration: const InputDecoration(
                  labelText: 'Next available slot',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: onDemand,
                onChanged: (value) => setModalState(() => onDemand = value),
                title: const Text('On-demand mode'),
              ),
              const SizedBox(height: 12),
              PrimaryGlowButton(
                label: 'Save availability',
                onPressed: () {
                  ref
                      .read(appControllerProvider.notifier)
                      .updateShootrProfile(
                        todayAvailability: todayController.text.trim(),
                        nextAvailableSlot: nextController.text.trim(),
                        onDemandMode: onDemand,
                      );
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _showShootrPayoutEditor(
  BuildContext context,
  WidgetRef ref,
  AppUser shootr,
) async {
  final upiController = TextEditingController(text: shootr.upiId);
  final bankController = TextEditingController(text: shootr.bankName);
  final ifscController = TextEditingController(text: shootr.ifscCode);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Text(
              'Edit bank & UPI',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: upiController,
              decoration: const InputDecoration(labelText: 'UPI ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bankController,
              decoration: const InputDecoration(labelText: 'Bank name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ifscController,
              decoration: const InputDecoration(labelText: 'IFSC code'),
            ),
            const SizedBox(height: 16),
            PrimaryGlowButton(
              label: 'Save payout details',
              onPressed: () {
                ref
                    .read(appControllerProvider.notifier)
                    .updateShootrProfile(
                      upiId: upiController.text.trim(),
                      bankName: bankController.text.trim(),
                      ifscCode: ifscController.text.trim(),
                      badges: <String>[
                        ...shootr.badges.where(
                          (item) => item != 'Payout Re-verification Pending',
                        ),
                        'Payout Re-verification Pending',
                      ],
                    );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _showShootrInfoDialog(
  BuildContext context,
  String title,
  String message,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

Future<void> _confirmShootrDelete(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Delete account'),
      content: const Text(
        'This removes your Shootr account from this preview app. Are you sure?',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Delete', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    ref.read(appControllerProvider.notifier).deleteCurrentAccount();
    context.go(AppRoutes.roleSelection);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color, this.onTap});

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color == AppColors.textPrimary
                ? AppColors.textPrimary
                : color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (trailing != null) ...<Widget>[
            Text(trailing!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 8),
          ],
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(title, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _HomeChip extends StatelessWidget {
  const _HomeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.45)
                : AppColors.glass,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EarningsRow extends StatelessWidget {
  const _EarningsRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: emphasize
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style:
                (emphasize
                        ? Theme.of(context).textTheme.titleMedium
                        : Theme.of(context).textTheme.bodyMedium)
                    ?.copyWith(
                      color: emphasize
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
          ),
        ],
      ),
    );
  }
}

class AvailabilityManagementScreen extends ConsumerStatefulWidget {
  const AvailabilityManagementScreen({super.key});

  @override
  ConsumerState<AvailabilityManagementScreen> createState() =>
      _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState
    extends ConsumerState<AvailabilityManagementScreen> {
  final Map<String, bool> _allDay = <String, bool>{
    'Mon': true,
    'Tue': true,
    'Wed': false,
    'Thu': true,
    'Fri': true,
    'Sat': true,
    'Sun': false,
  };
  bool _onDemand = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF101010),
              AppColors.background,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: <Widget>[
              Text(
                'Availability',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              ..._allDay.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            entry.key,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const Text('Available all day'),
                        const SizedBox(width: 10),
                        Switch(
                          value: entry.value,
                          activeThumbColor: AppColors.primary,
                          onChanged: (value) =>
                              setState(() => _allDay[entry.key] = value),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'On-demand mode',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Accept immediate bookings whenever you go online.',
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _onDemand,
                      activeThumbColor: AppColors.primary,
                      onChanged: (value) => setState(() => _onDemand = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryGlowButton(
                label: 'Save availability',
                onPressed: () {
                  final availableDays = _allDay.entries
                      .where((entry) => entry.value)
                      .map((entry) => entry.key)
                      .toList();
                  ref
                      .read(appControllerProvider.notifier)
                      .updateShootrProfile(
                        availability: availableDays,
                        todayAvailability: availableDays.isEmpty
                            ? 'Unavailable today'
                            : 'Available all day',
                        nextAvailableSlot: availableDays.isEmpty
                            ? 'Set availability'
                            : '${availableDays.first} all day',
                        onDemandMode: _onDemand,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Availability saved.')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showReviewReplySheet(
  BuildContext context,
  WidgetRef ref,
  Review review,
) async {
  final controller = TextEditingController(text: review.reply ?? '');
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Text(
              'Reply to review',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              minLines: 4,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: 'Reply',
                hintText: 'Thank the client and respond professionally.',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryGlowButton(
              label: 'Save reply',
              onPressed: () {
                ref
                    .read(appControllerProvider.notifier)
                    .replyToShootrReview(
                      reviewId: review.id,
                      reply: controller.text.trim(),
                    );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class ShootrReviewsScreen extends ConsumerWidget {
  const ShootrReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(currentUserProvider)?.reviews ?? const <Review>[];
    final average = reviews.isEmpty
        ? 0.0
        : reviews.fold<double>(0, (sum, item) => sum + item.rating) /
              reviews.length;
    final distribution = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in reviews) {
      final bucket = review.rating.round().clamp(1, 5);
      distribution[bucket] = (distribution[bucket] ?? 0) + 1;
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF101010),
              AppColors.background,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: <Widget>[
              Text(
                'Client Reviews',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              GlassCard(
                borderColor: AppColors.primary.withValues(alpha: 0.2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Overall rating',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${average.toStringAsFixed(1)} rating',
                      style: Theme.of(context).textTheme.displayMedium
                          ?.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text('${reviews.length} reviews total'),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) =>
                                    Text('${value.toInt()} star'),
                              ),
                            ),
                          ),
                          barGroups: <BarChartGroupData>[
                            for (var i = 1; i <= 5; i++)
                              BarChartGroupData(
                                x: i,
                                barRods: <BarChartRodData>[
                                  BarChartRodData(
                                    toY: (distribution[i] ?? 0).toDouble(),
                                    color: AppColors.primary,
                                    width: 18,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (reviews.isEmpty)
                const EmptyStateView(
                  title: 'No reviews yet',
                  subtitle:
                      'Client ratings will appear here after your first completed booking.',
                )
              else
                ...reviews.map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${review.authorName} - ${review.rating} rating',
                          ),
                          const SizedBox(height: 8),
                          Text(review.comment),
                          if (review.reply != null &&
                              review.reply!.trim().isNotEmpty) ...<Widget>[
                            const SizedBox(height: 12),
                            GlassCard(
                              padding: const EdgeInsets.all(12),
                              borderColor: AppColors.primary.withValues(
                                alpha: 0.18,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Your reply',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: AppColors.primary),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(review.reply!),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () =>
                                _showReviewReplySheet(context, ref, review),
                            child: Text(
                              review.reply == null ? 'Reply' : 'Edit reply',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReelUploadScreen extends ConsumerStatefulWidget {
  const ReelUploadScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<ReelUploadScreen> createState() => _ReelUploadScreenState();
}

class _ReelUploadScreenState extends ConsumerState<ReelUploadScreen> {
  final TextEditingController _captionController = TextEditingController();
  XFile? _selectedVideo;
  bool _isUploading = false;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(ImageSource source) async {
    final file = await ImagePicker().pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 5),
    );
    if (file != null && mounted) {
      setState(() => _selectedVideo = file);
    }
  }

  Future<void> _uploadReel(Booking booking) async {
    final file = _selectedVideo;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a reel video first.')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      final uploaded = await ref
          .read(cloudinaryServiceProvider)
          .uploadFile(
            file: file,
            folder: 'shootr/reels',
            tags: <String>['shootr', 'reel', booking.id],
          );
      final title = _captionController.text.trim().isEmpty
          ? '${booking.eventType} Reel'
          : _captionController.text.trim();

      await ref
          .read(appControllerProvider.notifier)
          .completeBookingWithReel(
            bookingId: booking.id,
            title: title,
            videoUrl: uploaded.secureUrl,
            thumbnailUrl: uploaded.thumbnailUrl(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reel uploaded and delivered.')),
        );
        context.go(AppRoutes.shootrActive);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = ref
        .watch(appControllerProvider)
        .bookings
        .where((item) => item.id == widget.bookingId)
        .toList();
    final selectedBooking = booking.isEmpty ? null : booking.first;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF101010),
              AppColors.background,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: <Widget>[
              Text(
                'Upload Reel',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              if (booking.isNotEmpty)
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        booking.first.clientName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(AppFormatters.fileLimit()),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _captionController,
                decoration: InputDecoration(labelText: 'Caption / title'),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : () => _pickVideo(ImageSource.gallery),
                      icon: const Icon(Icons.video_library_outlined),
                      label: const Text('Upload from gallery'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploading
                          ? null
                          : () => _pickVideo(ImageSource.camera),
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('Record now'),
                    ),
                  ),
                ],
              ),
              if (_selectedVideo != null) ...<Widget>[
                const SizedBox(height: 16),
                GlassCard(
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.movie_creation_outlined,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedVideo!.name,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              PrimaryGlowButton(
                label: 'Compress & Upload',
                isLoading: _isUploading,
                onPressed: selectedBooking == null || _selectedVideo == null
                    ? null
                    : () => _uploadReel(selectedBooking),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
