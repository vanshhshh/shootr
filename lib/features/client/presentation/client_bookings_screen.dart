import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/shootr_package.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/services/payment_service.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/network_avatar.dart';
import 'client_components.dart';

class ClientBookingsScreen extends ConsumerWidget {
  const ClientBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final bookings = ref
        .watch(appControllerProvider)
        .bookings
        .where(
          (booking) =>
              booking.clientId == currentUser?.id || currentUser == null,
        )
        .toList();

    List<Booking> byStatus(List<BookingStatus> statuses) =>
        bookings.where((booking) => statuses.contains(booking.status)).toList();

    return DefaultTabController(
      length: 4,
      child: RefreshIndicator(
        onRefresh: () async =>
            ref.read(appControllerProvider.notifier).retryInitialization(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'My Bookings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              const TabBar(
                isScrollable: true,
                tabs: <Tab>[
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Cancelled'),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    _BookingTabList(
                      bookings: byStatus(<BookingStatus>[
                        BookingStatus.pending,
                        BookingStatus.confirmed,
                      ]),
                      emptyTitle: 'No upcoming shoots',
                      emptySubtitle:
                          'Your confirmed bookings will appear here.',
                    ),
                    _BookingTabList(
                      bookings: byStatus(<BookingStatus>[
                        BookingStatus.active,
                        BookingStatus.editing,
                      ]),
                      emptyTitle: 'No active shoots',
                      emptySubtitle:
                          'Live shoots in progress will show up here.',
                    ),
                    _BookingTabList(
                      bookings: byStatus(<BookingStatus>[
                        BookingStatus.completed,
                        BookingStatus.delivered,
                      ]),
                      emptyTitle: 'Nothing completed yet',
                      emptySubtitle:
                          'Delivered reels and completed shoots will appear here.',
                    ),
                    _BookingTabList(
                      bookings: byStatus(<BookingStatus>[
                        BookingStatus.cancelled,
                      ]),
                      emptyTitle: 'No cancelled bookings',
                      emptySubtitle:
                          'If a booking gets cancelled, you will see it here.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingTabList extends ConsumerWidget {
  const _BookingTabList({
    required this.bookings,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  final List<Booking> bookings;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shootrs = ref.watch(appControllerProvider).shootrs;

    if (bookings.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: EmptyStateView(title: emptyTitle, subtitle: emptySubtitle),
        ),
      );
    }

    return ListView.separated(
      itemCount: bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final shootr = shootrs
            .where((item) => item.id == booking.shootrId)
            .firstOrNull;
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  NetworkAvatar(
                    imageUrl:
                        shootr?.photoUrl ??
                        'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
                    radius: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          booking.assigneeLabel,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${AppFormatters.dateTime(booking.scheduledAt)}\n${booking.location.address}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  BookingStatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Text(booking.packageType.label),
                  const Spacer(),
                  Text(
                    AppFormatters.currency(
                      booking.totalAmount,
                      city: booking.location.city,
                      country: booking.location.country,
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _actionsForBooking(context, ref, booking),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _actionsForBooking(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) {
    switch (booking.status) {
      case BookingStatus.pending:
        return <Widget>[
          _ActionButton(
            label: 'View Status',
            icon: PhosphorIcons.clockCountdown(),
            onTap: () =>
                context.push('${AppRoutes.liveTracking}/${booking.id}'),
          ),
          _ActionButton(
            label: 'Cancel',
            icon: PhosphorIcons.xCircle(),
            onTap: () => ref
                .read(appControllerProvider.notifier)
                .updateBookingStatus(booking.id, BookingStatus.cancelled),
          ),
        ];
      case BookingStatus.confirmed:
        return <Widget>[
          if (booking.paymentStatus == PaymentStatus.pending)
            _ActionButton(
              label: 'Pay Now',
              icon: PhosphorIcons.creditCard(),
              onTap: () => _payForBooking(context, ref, booking),
            ),
          _ActionButton(
            label: 'Track',
            icon: PhosphorIcons.mapPin(),
            onTap: () =>
                context.push('${AppRoutes.liveTracking}/${booking.id}'),
          ),
          _ActionButton(
            label: 'Cancel',
            icon: PhosphorIcons.xCircle(),
            onTap: () => ref
                .read(appControllerProvider.notifier)
                .updateBookingStatus(booking.id, BookingStatus.cancelled),
          ),
          _ActionButton(
            label: 'Message Shootr',
            icon: PhosphorIcons.chatCircleDots(),
            onTap: () => context.push('${AppRoutes.chatThread}/${booking.id}'),
          ),
        ];
      case BookingStatus.active:
      case BookingStatus.editing:
        return <Widget>[
          _ActionButton(
            label: 'Live Track',
            icon: PhosphorIcons.mapTrifold(),
            onTap: () =>
                context.push('${AppRoutes.liveTracking}/${booking.id}'),
          ),
          _ActionButton(
            label: 'Extend Time',
            icon: PhosphorIcons.clockClockwise(),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Extension request noted. Chat with your Shootr to confirm timing.',
                ),
              ),
            ),
          ),
          _ActionButton(
            label: 'Message',
            icon: PhosphorIcons.chatCircleDots(),
            onTap: () => context.push('${AppRoutes.chatThread}/${booking.id}'),
          ),
        ];
      case BookingStatus.delivered:
      case BookingStatus.completed:
        return <Widget>[
          _ActionButton(
            label: 'Download Reel',
            icon: PhosphorIcons.downloadSimple(),
            onTap: () =>
                context.push('${AppRoutes.reelDelivery}/${booking.id}'),
          ),
          _ActionButton(
            label: 'Rate Shootr',
            icon: PhosphorIcons.star(),
            onTap: () =>
                context.push('${AppRoutes.reelDelivery}/${booking.id}'),
          ),
          _ActionButton(
            label: 'Book Again',
            icon: PhosphorIcons.arrowClockwise(),
            onTap: () => context.push(AppRoutes.bookingFlow),
          ),
        ];
      case BookingStatus.cancelled:
        return <Widget>[
          _ActionButton(
            label: 'Rebook',
            icon: PhosphorIcons.arrowClockwise(),
            onTap: () => context.push(AppRoutes.bookingFlow),
          ),
          _ActionButton(
            label: 'See Refund Status',
            icon: PhosphorIcons.receipt(),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Refund status: ${booking.refundStatus.name.replaceAll('_', ' ')}',
                ),
              ),
            ),
          ),
        ];
    }
  }

  Future<void> _payForBooking(
    BuildContext context,
    WidgetRef ref,
    Booking booking,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      return;
    }
    try {
      final result = await ref
          .read(paymentServiceProvider)
          .beginCheckout(
            PaymentRequest(
              amount: booking.totalAmount,
              currency: 'INR',
              description:
                  '${booking.packageType.label} shoot with ${booking.shootrName}',
              city: booking.location.city,
              bookingId: booking.id,
              customerName: user.name,
              customerContact: user.phone,
            ),
          );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Payment verified. Your booking is confirmed.'
                : result.message ?? 'Payment could not be completed.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

extension _FirstOrNullX<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
