import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_constants.dart';
import '../../../shared/models/marketplace_catalog.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/section_header.dart';
import 'client_components.dart';

class ClientSearchScreen extends ConsumerStatefulWidget {
  const ClientSearchScreen({super.key});

  @override
  ConsumerState<ClientSearchScreen> createState() => _ClientSearchScreenState();
}

class _ClientSearchScreenState extends ConsumerState<ClientSearchScreen> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final query = ref.read(appControllerProvider).searchFilters.query;
    _searchController = TextEditingController(text: query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(appControllerProvider.notifier).updateSearchQuery(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final filters = state.searchFilters;
    final results = ref.watch(filteredShootrsProvider);
    final selectedLocation = state.selectedLocation;

    final markers = results
        .where((shootr) => shootr.latitude != 0 && shootr.longitude != 0)
        .map(
          (shootr) => Marker(
            markerId: MarkerId(shootr.id),
            position: LatLng(shootr.latitude, shootr.longitude),
            infoWindow: InfoWindow(title: shootr.name, snippet: shootr.city),
          ),
        )
        .toSet();

    return RefreshIndicator(
      onRefresh: () async => ref.read(appControllerProvider.notifier).retryInitialization(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
          Text('Search Shootrs', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onQueryChanged,
                  decoration: InputDecoration(
                    labelText: 'Search by name, specialisation, or city',
                    prefixIcon: Icon(PhosphorIcons.magnifyingGlass()),
                    suffixIcon: IconButton(
                      onPressed: () {
                        _searchController.clear();
                        ref.read(appControllerProvider.notifier).updateSearchQuery('');
                      },
                      icon: Icon(PhosphorIcons.x()),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () => _openFilterSheet(context, filters),
                icon: Icon(PhosphorIcons.slidersHorizontal()),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => ref.read(appControllerProvider.notifier).toggleSearchMapView(),
                icon: Icon(
                  state.clientSearchMapView
                      ? PhosphorIcons.listBullets()
                      : PhosphorIcons.mapTrifold(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _FilterChip(
                label: filters.sort.label,
                icon: PhosphorIcons.arrowsDownUp(),
              ),
              _FilterChip(
                label: filters.availableNowOnly ? 'Available Now' : 'Any availability',
                icon: PhosphorIcons.lightning(),
              ),
              _FilterChip(
                label: filters.preferredGender.label,
                icon: PhosphorIcons.shieldCheck(),
              ),
              if (filters.radiusKm != null)
                _FilterChip(
                  label: '${filters.radiusKm!.toInt()} km radius',
                  icon: PhosphorIcons.navigationArrow(),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (state.clientSearchMapView)
            SizedBox(
              height: 340,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radius),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      selectedLocation?.latitude ?? 19.0596,
                      selectedLocation?.longitude ?? 72.8295,
                    ),
                    zoom: 12,
                  ),
                  markers: markers,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
              ),
            )
          else ...<Widget>[
            const SectionHeader(
              title: 'Results',
              subtitle: 'Real-time matches near your selected location',
            ),
            const SizedBox(height: 14),
            if (results.isEmpty)
              const EmptyStateView(
                title: 'No results found',
                subtitle: 'Try a broader price range, fewer filters, or a nearby city.',
              )
            else
              ...results.map(
                (shootr) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShootrSummaryCard(
                    shootr: shootr,
                    isSaved: state.currentUser?.savedShootrIds.contains(shootr.id) ?? false,
                    onSaveToggle: () =>
                        ref.read(appControllerProvider.notifier).toggleSavedShootr(shootr.id),
                    showPortfolioPreview: true,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _openFilterSheet(BuildContext context, SearchFilters current) async {
    SearchFilters draft = current;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Filters',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            draft = const SearchFilters();
                            setModalState(() {});
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Price Range', style: Theme.of(context).textTheme.titleMedium),
                    RangeSlider(
                      values: RangeValues(draft.minPrice, draft.maxPrice),
                      min: 500,
                      max: 10000,
                      divisions: 19,
                      labels: RangeLabels(
                        '₹${draft.minPrice.toInt()}',
                        '₹${draft.maxPrice.toInt()}',
                      ),
                      onChanged: (values) {
                        draft = draft.copyWith(
                          minPrice: values.start,
                          maxPrice: values.end,
                        );
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    Text('Rating', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: <double>[3, 4, 4.5]
                          .map(
                            (value) => ChoiceChip(
                              selected: draft.minRating == value,
                              label: Text('${value.toString()}★+'),
                              onSelected: (_) {
                                draft = draft.copyWith(minRating: value);
                                setModalState(() {});
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile.adaptive(
                      value: draft.availableNowOnly,
                      onChanged: (value) {
                        draft = draft.copyWith(availableNowOnly: value);
                        setModalState(() {});
                      },
                      title: const Text('Available Now'),
                    ),
                    const SizedBox(height: 8),
                    Text('Device Type', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: DeviceType.values
                          .where((type) => type != DeviceType.other)
                          .map(
                            (type) => FilterChip(
                              selected: draft.deviceTypes.contains(type),
                              label: Text(type.label),
                              onSelected: (selected) {
                                final next = <DeviceType>{...draft.deviceTypes};
                                if (selected) {
                                  next.add(type);
                                } else {
                                  next.remove(type);
                                }
                                draft = draft.copyWith(deviceTypes: next);
                                setModalState(() {});
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    Text('Distance Radius', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: <double?>[1, 5, 10, 25, null]
                          .map(
                            (radius) => ChoiceChip(
                              selected: draft.radiusKm == radius,
                              label: Text(radius == null ? 'Any' : '${radius.toInt()} km'),
                              onSelected: (_) {
                                draft = radius == null
                                    ? draft.copyWith(clearRadius: true)
                                    : draft.copyWith(radiusKm: radius);
                                setModalState(() {});
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    Text('Preferred Gender', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: PreferredGender.values
                          .map(
                            (gender) => ChoiceChip(
                              selected: draft.preferredGender == gender,
                              label: Text(gender.label),
                              onSelected: (_) {
                                draft = draft.copyWith(preferredGender: gender);
                                setModalState(() {});
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    Text('Category', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kMarketplaceCategories
                          .map(
                            (category) => FilterChip(
                              selected: draft.categoryIds.contains(category.id),
                              label: Text(category.label),
                              onSelected: (selected) {
                                final next = <String>{...draft.categoryIds};
                                if (selected) {
                                  next.add(category.id);
                                } else {
                                  next.remove(category.id);
                                }
                                draft = draft.copyWith(categoryIds: next);
                                setModalState(() {});
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 14),
                    Text('Sort By', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ShootrSortOption>(
                      initialValue: draft.sort,
                      items: ShootrSortOption.values
                          .map(
                            (option) => DropdownMenuItem<ShootrSortOption>(
                              value: option,
                              child: Text(option.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          draft = draft.copyWith(sort: value);
                          setModalState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ref.read(appControllerProvider.notifier).updateSearchFilters(draft);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
