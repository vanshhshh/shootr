import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/marketplace_catalog.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/flow_guide_card.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import '../../../shared/widgets/section_header.dart';
import 'client_components.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final shootrs = ref.watch(nearbyShootrsProvider);
    final selectedLocation = state.selectedLocation;
    final savedIds = state.currentUser?.savedShootrIds ?? const <String>[];

    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: SkeletonList(items: 5),
      );
    }

    if (state.errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: ErrorStateView(
          message: state.errorMessage!,
          onRetry: ref.read(appControllerProvider.notifier).retryInitialization,
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(appControllerProvider.notifier).detectClientLocation();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassCard(
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    useSafeArea: true,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const _LocationPickerSheet(),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(PhosphorIcons.mapPin(), color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              selectedLocation?.city ?? 'Choose your city',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              selectedLocation?.address ??
                                  'Tap to change city or use current location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        PhosphorIcons.caretDown(),
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                onPressed: () => context.push(AppRoutes.notifications),
                icon: Icon(PhosphorIcons.bell()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _HeroCard(locationLabel: selectedLocation?.city ?? 'your city'),
          const SizedBox(height: 18),
          GlassCard(
            onTap: () => context.go(AppRoutes.clientSearch),
            child: Row(
              children: <Widget>[
                Icon(
                  PhosphorIcons.magnifyingGlass(),
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search by city, style, or event',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Icon(PhosphorIcons.caretRight()),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            borderColor: AppColors.primary.withValues(alpha: 0.25),
            child: Text(
              '70,000+ reels - 4.8 rating - 10+ cities',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 26),
          const SectionHeader(
            title: 'Choose a shoot type',
            subtitle: 'Tap one to see matching Shootrs',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 198,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: kMarketplaceCategories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                final category = kMarketplaceCategories[index];
                return ShootrCategoryTile(
                  category: category,
                  selected: state.selectedCategoryId == category.id,
                  onTap: () {
                    ref
                        .read(appControllerProvider.notifier)
                        .selectClientCategory(category.id);
                    ref
                        .read(appControllerProvider.notifier)
                        .updateSearchFilters(
                          state.searchFilters.copyWith(
                            categoryIds: <String>{category.id},
                          ),
                        );
                    context.push(AppRoutes.bookingFlow);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'Nearby Shootrs',
            subtitle:
                'Profiles are for discovery. Booking requests are assigned automatically.',
          ),
          const SizedBox(height: 14),
          if (shootrs.isEmpty)
            GlassCard(
              child: Column(
                children: <Widget>[
                  Icon(
                    PhosphorIcons.bellRinging(),
                    size: 34,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No Shootrs nearby right now.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll notify you when one comes online.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  PrimaryGlowButton(
                    label: 'Notify me',
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Notifications are on. We will surface new Shootrs as they come online.',
                        ),
                      ),
                    ),
                    isExpanded: false,
                  ),
                ],
              ),
            )
          else
            Column(
              children: shootrs
                  .map(
                    (shootr) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ShootrSummaryCard(
                        shootr: shootr,
                        isSaved: savedIds.contains(shootr.id),
                        onSaveToggle: () => ref
                            .read(appControllerProvider.notifier)
                            .toggleSavedShootr(shootr.id),
                      ),
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 28),
          FlowGuideCard(
            title: 'How booking works',
            subtitle: 'Three simple steps from search to delivery.',
            steps: const <FlowGuideStep>[
              FlowGuideStep(
                title: 'Choose a shoot',
                subtitle: 'Pick the event type and location.',
                icon: Icons.category_outlined,
              ),
              FlowGuideStep(
                title: 'Get matched',
                subtitle: 'Available Shootrs accept requests in real time.',
                icon: Icons.calendar_month_outlined,
              ),
              FlowGuideStep(
                title: 'Pay and track',
                subtitle: 'Confirm, chat, and collect reels in Vault.',
                icon: Icons.map_outlined,
              ),
            ],
            actionLabel: 'Request a shoot',
            onAction: () => context.push(AppRoutes.bookingFlow),
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: 'Packages'),
          const SizedBox(height: 14),
          ...state.packages.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (item.inclusions.isNotEmpty) ...<Widget>[
                            const SizedBox(height: 10),
                            ...item.inclusions
                                .take(3)
                                .map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text('- $line'),
                                  ),
                                ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppFormatters.currency(
                        item.price,
                        city: selectedLocation?.city ?? 'Mumbai',
                      ),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 260.ms),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.locationLabel});

  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.primary.withValues(alpha: 0.32),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Available in $locationLabel',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Book a reel shoot near you',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Choose a verified Shootr, pay, and track the shoot from one place.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Icon(PhosphorIcons.clockCountdown(), color: AppColors.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Most bookings take less than 2 minutes to set up'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationPickerSheet extends ConsumerStatefulWidget {
  const _LocationPickerSheet();

  @override
  ConsumerState<_LocationPickerSheet> createState() =>
      _LocationPickerSheetState();
}

class _LocationPickerSheetState extends ConsumerState<_LocationPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<AppLocation> _suggestions = <AppLocation>[];
  bool _isSearching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _isSearching = true);
      final service = ref.read(locationServiceProvider);
      final suggestions = await service.searchIndiaLocations(query);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Choose location',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(PhosphorIcons.x()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            onChanged: _search,
            decoration: InputDecoration(
              labelText: 'Search city or locality',
              prefixIcon: Icon(PhosphorIcons.magnifyingGlass()),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(appControllerProvider.notifier)
                        .detectClientLocation();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: Icon(PhosphorIcons.navigationArrow()),
                  label: const Text('Use current location'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final selected = state.selectedLocation;
                    if (selected != null) {
                      ref
                          .read(appControllerProvider.notifier)
                          .setSelectedLocation(selected);
                    }
                    Navigator.of(context).pop();
                  },
                  icon: Icon(PhosphorIcons.mapPinLine()),
                  label: const Text('Keep current city'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            const LinearProgressIndicator(color: AppColors.primary),
          if (_suggestions.isNotEmpty) ...<Widget>[
            Text(
              'Search results',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ..._suggestions.map(
              (location) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(PhosphorIcons.mapPin()),
                title: Text(location.city),
                subtitle: Text('${location.city}, ${location.state}'),
                onTap: () async {
                  await ref
                      .read(appControllerProvider.notifier)
                      .setSelectedLocation(location);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'Recent locations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (state.recentLocations.isEmpty)
            const Text('No recent locations yet')
          else
            ...state.recentLocations.map(
              (location) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(PhosphorIcons.clockCounterClockwise()),
                title: Text(location.city),
                subtitle: Text(location.address),
                onTap: () async {
                  await ref
                      .read(appControllerProvider.notifier)
                      .setSelectedLocation(location);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}
