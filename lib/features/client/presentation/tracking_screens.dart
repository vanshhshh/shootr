import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart' as lottie;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/shootr_package.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/network_avatar.dart';
import '../../../shared/widgets/primary_glow_button.dart';

Booking? _findBooking(WidgetRef ref, String bookingId) {
  final matches = ref
      .watch(appControllerProvider)
      .bookings
      .where((item) => item.id == bookingId)
      .toList();
  return matches.isEmpty ? null : matches.first;
}

class BookingConfirmationScreen extends ConsumerWidget {
  const BookingConfirmationScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = _findBooking(ref, bookingId);
    if (booking == null) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: EmptyStateView(
              title: 'Booking missing',
              subtitle:
                  'We could not find this booking. Please refresh your list.',
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      title: booking.isAssigned ? 'Booking Confirmed' : 'Request Sent',
      child: Column(
        children: <Widget>[
          SizedBox(
            width: 150,
            height: 150,
            child: lottie.Lottie.network(
              AppConstants.successLottieUrl,
              repeat: false,
            ),
          ),
          Text(
            booking.isAssigned ? 'You are all set' : 'Finding your Shootr',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text('Booking ID: ${booking.id}'),
          const SizedBox(height: 18),
          GlassCard(
            child: Column(
              children: <Widget>[
                QrImageView(
                  data: booking.qrPayload,
                  size: 180,
                  eyeStyle: const QrEyeStyle(color: Colors.white),
                  dataModuleStyle: const QrDataModuleStyle(color: Colors.white),
                ),
                const SizedBox(height: 14),
                Text(
                  booking.isAssigned
                      ? '${booking.shootrName} - ETA ${booking.etaMinutes} mins'
                      : 'Available Shootrs can accept this request now',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(AppFormatters.dateTime(booking.scheduledAt)),
                const SizedBox(height: 4),
                Text(booking.location.address, textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryGlowButton(
            label: booking.isAssigned ? 'Live Tracking' : 'View Status',
            onPressed: () =>
                context.push('${AppRoutes.liveTracking}/${booking.id}'),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text:
                            '${booking.eventType} on ${AppFormatters.dateTime(booking.scheduledAt)} at ${booking.location.address}',
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Calendar details copied.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Add to Calendar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: 'Shootr booking ${booking.id}'),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Booking details copied.'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LiveTrackingScreen extends ConsumerWidget {
  const LiveTrackingScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = _findBooking(ref, bookingId);
    if (booking == null) {
      return const Scaffold(body: Center(child: Text('Booking not found')));
    }

    if (!booking.isAssigned) {
      return AppScaffold(
        title: 'Finding Shootr',
        child: EmptyStateView(
          title: 'Waiting for acceptance',
          subtitle:
              'Your request is visible to eligible Shootrs. This screen will update once someone accepts.',
          actionLabel: 'Back to bookings',
          onAction: () => context.go(AppRoutes.clientBookings),
          icon: Icons.hourglass_top_rounded,
        ),
      );
    }

    return AppScaffold(
      title: 'Live Tracking',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 320,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radius),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: booking.location.latLng,
                  zoom: 13,
                ),
                markers: <Marker>{
                  Marker(
                    markerId: const MarkerId('shootr'),
                    position: booking.location.latLng,
                    infoWindow: InfoWindow(title: booking.shootrName),
                  ),
                },
              ),
            ),
          ),
          const SizedBox(height: 18),
          GlassCard(
            child: Row(
              children: <Widget>[
                const NetworkAvatar(
                  imageUrl:
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
                  radius: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        booking.shootrName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text('Shootr is ${booking.etaMinutes} mins away'),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: booking.shootrName.isEmpty
                      ? null
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Call workflow is coming soon. Use chat for now.',
                            ),
                          ),
                        ),
                  icon: const Icon(Icons.call_outlined),
                ),
                IconButton(
                  onPressed: () =>
                      context.push('${AppRoutes.chatThread}/${booking.id}'),
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'ETA Countdown',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${booking.etaMinutes}:00',
                  style: Theme.of(
                    context,
                  ).textTheme.displayMedium?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                const Text('Push notification: "Shootr is 5 mins away"'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveShootScreen extends ConsumerStatefulWidget {
  const ActiveShootScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<ActiveShootScreen> createState() => _ActiveShootScreenState();
}

class _ActiveShootScreenState extends ConsumerState<ActiveShootScreen> {
  Timer? _timer;
  Duration _elapsed = const Duration(minutes: 17);
  bool _arrived = true;
  bool _started = true;
  bool _editing = false;
  bool _delivered = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed += const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = _findBooking(ref, widget.bookingId);
    if (booking == null) {
      return const Scaffold(body: Center(child: Text('Booking not found')));
    }

    final mm = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return AppScaffold(
      title: 'Active Shoot',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GlassCard(
            borderColor: AppColors.primary.withValues(alpha: 0.24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Shoot timer',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '$mm:$ss',
                  style: Theme.of(
                    context,
                  ).textTheme.displayMedium?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              children: <Widget>[
                CheckboxListTile(
                  value: _arrived,
                  onChanged: (value) =>
                      setState(() => _arrived = value ?? false),
                  title: const Text('Arrived at location'),
                ),
                CheckboxListTile(
                  value: _started,
                  onChanged: (value) =>
                      setState(() => _started = value ?? false),
                  title: const Text('Shoot started'),
                ),
                CheckboxListTile(
                  value: _editing,
                  onChanged: (value) =>
                      setState(() => _editing = value ?? false),
                  title: const Text('Editing in progress'),
                ),
                CheckboxListTile(
                  value: _delivered,
                  onChanged: (value) =>
                      setState(() => _delivered = value ?? false),
                  title: const Text('Reel delivered'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Package reminders',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${booking.packageType.label}  •  ${booking.reelsNeeded} reels',
                ),
                const SizedBox(height: 4),
                Text(
                  'Style: ${booking.stylePreference}  •  Music: ${booking.musicPreference}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: PrimaryGlowButton(
                  label: 'Request Extension',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Extension request noted. Confirm timing in chat.',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmSos(booking.id),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                  child: const Text('SOS'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () =>
                context.push('${AppRoutes.chatThread}/${booking.id}'),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Chat with Shootr'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSos(String bookingId) async {
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Are you sure you want to trigger an SOS alert?',
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: callEmergencyContact,
                        onChanged: (value) => setDialogState(
                          () => callEmergencyContact = value ?? false,
                        ),
                        title: const Text('Call emergency contact'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text('Cancel'),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
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

    if (!confirmed || !mounted) {
      return;
    }

    ref
        .read(appControllerProvider.notifier)
        .sendSafetyAlert(
          bookingId: bookingId,
          triggeredBy: UserRole.client,
          callEmergencyContact: callEmergencyContact,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('SOS alert sent. Support has been notified.'),
      ),
    );
  }
}

class ReelDeliveryScreen extends ConsumerStatefulWidget {
  const ReelDeliveryScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<ReelDeliveryScreen> createState() => _ReelDeliveryScreenState();
}

class _ReelDeliveryScreenState extends ConsumerState<ReelDeliveryScreen> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(
            Uri.parse(
              'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
            ),
          )
          ..initialize().then((_) {
            if (mounted) {
              setState(() {});
              _controller
                ..setLooping(true)
                ..play();
            }
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = _findBooking(ref, widget.bookingId);
    if (booking == null) {
      return const Scaffold(body: Center(child: Text('Booking not found')));
    }

    return AppScaffold(
      title: 'Your Reel is Ready',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Your Reel is Ready!',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radius),
            child: AspectRatio(
              aspectRatio: _controller.value.isInitialized
                  ? _controller.value.aspectRatio
                  : 9 / 16,
              child: _controller.value.isInitialized
                  ? VideoPlayer(_controller)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: PrimaryGlowButton(
                  label: 'Download',
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Download will be enabled after device file permissions are wired.',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share to Reels is coming soon.'),
                    ),
                  ),
                  child: const Text('Share to Reels'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Request Revision',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('1 free revision included with this booking.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Revision request sent to support.'),
                    ),
                  ),
                  child: const Text('Ask for revision'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Rate your Shootr',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                RatingBar.builder(
                  initialRating: 5,
                  minRating: 1,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemBuilder: (_, _) =>
                      const Icon(Icons.star, color: AppColors.primary),
                  onRatingUpdate: (_) {},
                ),
                const SizedBox(height: 12),
                const TextField(
                  maxLines: 3,
                  decoration: InputDecoration(labelText: 'Write a review'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
