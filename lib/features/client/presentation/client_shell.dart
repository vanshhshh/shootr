import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/network_avatar.dart';

class ClientShell extends StatelessWidget {
  const ClientShell({
    required this.currentLocation,
    required this.child,
    super.key,
  });

  final String currentLocation;
  final Widget child;

  int get _currentIndex {
    if (currentLocation.startsWith(AppRoutes.clientSearch)) {
      return 1;
    }
    if (currentLocation.startsWith(AppRoutes.clientBookings)) {
      return 2;
    }
    if (currentLocation.startsWith(AppRoutes.clientChat)) {
      return 3;
    }
    if (currentLocation.startsWith(AppRoutes.clientProfile)) {
      return 4;
    }
    if (currentLocation.startsWith(AppRoutes.clientVault)) {
      return 4;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    const routes = <String>[
      AppRoutes.clientHome,
      AppRoutes.clientSearch,
      AppRoutes.clientBookings,
      AppRoutes.clientChat,
      AppRoutes.clientProfile,
    ];

    return Scaffold(
      extendBody: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF111111),
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
        destinations: <NavigationDestination>[
          NavigationDestination(icon: Icon(PhosphorIcons.house()), label: 'Home'),
          NavigationDestination(icon: Icon(PhosphorIcons.magnifyingGlass()), label: 'Search'),
          NavigationDestination(icon: Icon(PhosphorIcons.calendarCheck()), label: 'Bookings'),
          NavigationDestination(icon: Icon(PhosphorIcons.chatCircleDots()), label: 'Chat'),
          NavigationDestination(icon: Icon(PhosphorIcons.userCircle()), label: 'Profile'),
        ],
        onDestinationSelected: (index) => context.go(routes[index]),
      ),
    );
  }
}

class ClientChatHubScreen extends ConsumerWidget {
  const ClientChatHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final bookings = state.bookings.take(6).toList();

    return RefreshIndicator(
      onRefresh: () async => ref.read(appControllerProvider.notifier).retryInitialization(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
          Text('Chats', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          if (bookings.isEmpty)
            const EmptyStateView(
              title: 'No chats yet',
              subtitle: 'Your booking conversations will appear here after confirmation.',
            )
          else
            ...bookings.map(
              (booking) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  onTap: () => context.push('${AppRoutes.chatThread}/${booking.id}'),
                  child: Row(
                    children: <Widget>[
                      NetworkAvatar(
                        imageUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              booking.shootrName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.chatThreads[booking.id]?.last.body ??
                                  'Start the conversation',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Icon(PhosphorIcons.caretRight()),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
