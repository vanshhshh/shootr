import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/flow_guide_card.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import 'client_components.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({super.key});

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  static const List<String> _stepTitles = <String>[
    'Shoot type',
    'Package',
    'Schedule',
    'Location',
    'Brief',
    'Review',
  ];

  static const List<String> _styles = <String>[
    'Cinematic',
    'Trendy',
    'Minimal',
    'Aesthetic',
    'Raw',
    'Custom',
  ];

  static const List<String> _moods = <String>[
    'Energetic',
    'Calm',
    'Romantic',
    'Professional',
    'Fun',
    'Dark & Moody',
  ];

  static const List<String> _music = <String>[
    'Trending Bollywood',
    'International Pop',
    'Instrumental',
    'Client\'s choice',
  ];

  static const List<String> _ratios = <String>[
    '9:16 Reels',
    '1:1 Feed',
    '16:9 YouTube',
  ];

  static const List<String> _payments = <String>[
    'UPI',
    'Card',
    'Net banking',
    'Pay at shoot',
  ];

  static const List<({String hint, String action, IconData icon})> _stepGuides =
      <({String hint, String action, IconData icon})>[
        (
          hint: 'Tell us what you want to shoot.',
          action: 'Tap the category closest to your event.',
          icon: Icons.category_outlined,
        ),
        (
          hint: 'Choose how much coverage you need.',
          action: 'Select the package that fits your reel plan.',
          icon: Icons.shopping_bag_outlined,
        ),
        (
          hint: 'Set the shoot date and time.',
          action: 'Pick a slot and total hours.',
          icon: Icons.event_available_outlined,
        ),
        (
          hint: 'Confirm where the Shootr should arrive.',
          action: 'Search the address or use your current location.',
          icon: Icons.location_on_outlined,
        ),
        (
          hint: 'Share the creative direction.',
          action: 'Choose style, mood, music, and reels needed.',
          icon: Icons.description_outlined,
        ),
        (
          hint: 'Check everything before confirming.',
          action: 'Review details, add promo, and choose payment.',
          icon: Icons.payments_outlined,
        ),
      ];

  int _currentStep = 0;
  String? _selectedCategoryId;
  ShootrPackageType _selectedPackageType = ShootrPackageType.basic;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  DateTime? _selectedTime;
  int _durationHours = 1;
  AppLocation? _selectedLocation;
  String _selectedStyle = '';
  String _selectedMood = _moods.first;
  String _selectedMusic = _music.first;
  int _reelsNeeded = 1;
  String _selectedRatio = _ratios.first;
  String _selectedPayment = _payments.first;
  bool _applyCredits = false;
  bool _isSubmitting = false;
  List<AppLocation> _locationResults = const <AppLocation>[];
  Timer? _locationDebounce;

  late final TextEditingController _customCategoryController;
  late final TextEditingController _addressController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _instructionsController;
  late final TextEditingController _referenceController;
  late final TextEditingController _specialInstructionsController;
  late final TextEditingController _promoController;
  late final TextEditingController _customDurationController;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = ref.read(appControllerProvider).selectedCategoryId;
    _customCategoryController = TextEditingController();
    _addressController = TextEditingController();
    _landmarkController = TextEditingController();
    _instructionsController = TextEditingController();
    _referenceController = TextEditingController();
    _specialInstructionsController = TextEditingController();
    _promoController = TextEditingController();
    _customDurationController = TextEditingController();
  }

  @override
  void dispose() {
    _locationDebounce?.cancel();
    _customCategoryController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _instructionsController.dispose();
    _referenceController.dispose();
    _specialInstructionsController.dispose();
    _promoController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final currentUser = ref.watch(currentUserProvider);
    final availablePackages = _availablePackages(state.packages);
    final selectedPackage = availablePackages.firstWhere(
      (item) => item.type == _selectedPackageType,
      orElse: () => availablePackages.first,
    );
    final location = _selectedLocation ?? state.selectedLocation;
    final currentGuide = _stepGuides[_currentStep];

    if (_selectedLocation == null && location != null) {
      _selectedLocation = location;
      _addressController.text = location.address;
    }

    if (state.isLoading && state.packages.isEmpty) {
      return const AppScaffold(
        title: 'Request a shoot',
        child: SkeletonList(items: 5),
      );
    }
    if (state.errorMessage != null && state.packages.isEmpty) {
      return AppScaffold(
        title: 'Request a shoot',
        child: ErrorStateView(
          message: state.errorMessage!,
          onRetry: () =>
              ref.read(appControllerProvider.notifier).retryInitialization(),
        ),
      );
    }

    return AppScaffold(
      title: 'Request a shoot',
      bottomNavigationBar: _BottomBar(
        totalLabel: AppFormatters.currency(
          _totalAmount(selectedPackage, location, currentUser),
          country: location?.country ?? AppCountry.india,
        ),
        canGoBack: _currentStep > 0,
        isSubmitting: _isSubmitting,
        primaryLabel: _currentStep == _stepTitles.length - 1
            ? 'Send request'
            : 'Next',
        onBack: _currentStep > 0
            ? () => setState(() => _currentStep -= 1)
            : null,
        onPrimary: () =>
            _handlePrimaryAction(selectedPackage, location, currentUser),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _HeaderCard(
            title: _stepTitles[_currentStep],
            currentStep: _currentStep,
            stepTitles: _stepTitles,
            categoryLabel: _selectedCategory?.label ?? 'Choose a category',
            locationLabel: location?.primaryLabel ?? 'Set location',
          ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0),
          const SizedBox(height: 14),
          FlowGuideCard(
            title: 'This step',
            subtitle: currentGuide.hint,
            steps: <FlowGuideStep>[
              FlowGuideStep(
                title: 'Do this',
                subtitle: currentGuide.action,
                icon: currentGuide.icon,
              ),
            ],
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: 240.ms,
            child: switch (_currentStep) {
              0 => _buildCategoryStep(context),
              1 => _buildPackageStep(context, availablePackages),
              2 => _buildScheduleStep(context, selectedPackage),
              3 => _buildLocationStep(context, state),
              4 => _buildBriefStep(context),
              _ => _buildReviewStep(
                context,
                selectedPackage,
                currentUser,
                location,
              ),
            },
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  MarketplaceCategory? get _selectedCategory {
    for (final item in kMarketplaceCategories) {
      if (item.id == _selectedCategoryId) {
        return item;
      }
    }
    return null;
  }

  List<ShootrPackage> _availablePackages(List<ShootrPackage> packages) {
    final standard = packages
        .where((item) => item.type != ShootrPackageType.drone)
        .toList();
    final resolved = standard.isNotEmpty
        ? standard
        : const <ShootrPackage>[
            ShootrPackage(
              type: ShootrPackageType.basic,
              title: 'Basic',
              description: '1 reel, standard edit',
              price: 1999,
              inclusions: <String>['1 reel', 'Standard edit'],
            ),
            ShootrPackage(
              type: ShootrPackageType.pro,
              title: 'Pro',
              description: '2 reels, colour graded, trending audio',
              price: 3499,
              inclusions: <String>[
                '2 reels',
                'Colour grading',
                'Trending audio',
              ],
            ),
            ShootrPackage(
              type: ShootrPackageType.luxe,
              title: 'Luxe',
              description: '3 reels, cinematic grade, custom music',
              price: 5999,
              inclusions: <String>[
                '3 reels',
                'Cinematic grade',
                'Custom music',
              ],
            ),
          ];
    return resolved;
  }

  double _resolvedDuration() {
    if (_durationHours == 0) {
      return double.tryParse(_customDurationController.text.trim()) ?? 1;
    }
    return _durationHours.toDouble();
  }

  double _subtotal(ShootrPackage package) =>
      package.price * _resolvedDuration();

  double _promoDiscount(double subtotal) {
    final code = _promoController.text.trim().toUpperCase();
    if (code == 'LAUNCH10') {
      return subtotal * 0.1;
    }
    if (code == 'NEW500') {
      return 500;
    }
    return 0;
  }

  int _creditsDiscount(AppUser? currentUser) {
    if (!_applyCredits || currentUser == null) {
      return 0;
    }
    return currentUser.creditsBalance ~/ 10;
  }

  double _taxRate(AppCountry country) {
    switch (country) {
      case AppCountry.india:
        return 0.18;
      case AppCountry.uae:
        return 0.05;
      case AppCountry.usa:
        return 0.08;
    }
  }

  double _totalAmount(
    ShootrPackage package,
    AppLocation? location,
    AppUser? currentUser,
  ) {
    final subtotal = _subtotal(package);
    final promo = _promoDiscount(subtotal).clamp(0.0, subtotal).toDouble();
    final discounted = subtotal - promo;
    final fee = discounted * AppConstants.platformFeePercent;
    final tax = discounted * _taxRate(location?.country ?? AppCountry.india);
    return (discounted + fee + tax - _creditsDiscount(currentUser))
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  Future<void> _handlePrimaryAction(
    ShootrPackage package,
    AppLocation? location,
    AppUser? currentUser,
  ) async {
    if (_currentStep < _stepTitles.length - 1) {
      if (_validateStep()) {
        setState(() => _currentStep += 1);
      }
      return;
    }
    if (!_validateStep() || location == null || currentUser == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final subtotal = _subtotal(package);
      final promo = _promoDiscount(subtotal).clamp(0.0, subtotal).toDouble();
      final discounted = subtotal - promo;
      final fee = discounted * AppConstants.platformFeePercent;
      final tax = discounted * _taxRate(location.country);
      final total = (discounted + fee + tax - _creditsDiscount(currentUser))
          .clamp(0.0, double.infinity)
          .toDouble();
      final booking = Booking(
        id: 'booking_${DateTime.now().microsecondsSinceEpoch}',
        clientId: currentUser.id,
        clientName: currentUser.name,
        shootrId: '',
        shootrName: '',
        packageType: package.type,
        scheduledAt: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime?.hour ?? 10,
          _selectedTime?.minute ?? 0,
        ),
        durationHours: _resolvedDuration(),
        location: AppLocation(
          address: _addressController.text.trim().isEmpty
              ? location.address
              : _addressController.text.trim(),
          city: location.city,
          state: location.state,
          country: location.country,
          latitude: location.latitude,
          longitude: location.longitude,
          landmark: _landmarkController.text.trim(),
          instructions: _instructionsController.text.trim(),
          placeLabel: location.primaryLabel,
        ),
        categoryId: _selectedCategoryId ?? 'other',
        eventType: _selectedCategoryId == 'other'
            ? _customCategoryController.text.trim()
            : (_selectedCategory?.label ?? 'Custom shoot'),
        stylePreference: _selectedStyle,
        mood: _selectedMood,
        musicPreference: _selectedMusic,
        reelsNeeded: _reelsNeeded,
        aspectRatio: _selectedRatio,
        referenceLink: _referenceController.text.trim(),
        baseAmount: discounted,
        platformFee: fee,
        taxAmount: tax,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        qrPayload: 'SHOOTR-${DateTime.now().millisecondsSinceEpoch}',
        notes: _specialInstructionsController.text.trim(),
        paymentMethod: _selectedPayment,
        paymentStatus: _selectedPayment == 'Pay at shoot'
            ? PaymentStatus.cashAtShoot
            : PaymentStatus.pending,
        promoCode: _promoController.text.trim().toUpperCase(),
        creditsUsed: _creditsDiscount(currentUser),
        etaMinutes: 8,
        trackEnabled: true,
      );
      if (_selectedPayment != 'Pay at shoot' && total <= 0) {
        _showSnack('Choose Pay at shoot for zero-amount bookings.');
        return;
      }
      await ref.read(appControllerProvider.notifier).createBooking(booking);
      if (!mounted) {
        return;
      }
      context.go('${AppRoutes.bookingConfirmation}/${booking.id}');
    } catch (_) {
      if (mounted) {
        _showSnack(
          'We could not confirm your booking right now. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _validateStep() {
    switch (_currentStep) {
      case 0:
        if (_selectedCategoryId == null) {
          _showSnack('Choose a category to continue.');
          return false;
        }
        if (_selectedCategoryId == 'other' &&
            _customCategoryController.text.trim().isEmpty) {
          _showSnack('Add a custom category for your shoot.');
          return false;
        }
        return true;
      case 2:
        if (_selectedTime == null) {
          _showSnack('Pick a time slot to continue.');
          return false;
        }
        if (_durationHours == 0 &&
            (double.tryParse(_customDurationController.text.trim()) ?? 0) <=
                0) {
          _showSnack('Enter a valid custom duration.');
          return false;
        }
        return true;
      case 3:
        if ((_selectedLocation ?? ref.read(selectedLocationProvider)) == null) {
          _showSnack('Set your location to continue.');
          return false;
        }
        return true;
      case 4:
        if (_selectedStyle.isEmpty) {
          _showSnack('Choose a style preference to continue.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  Future<void> _searchLocations(String query) async {
    _locationDebounce?.cancel();
    _locationDebounce = Timer(const Duration(milliseconds: 250), () async {
      if (query.trim().length < 2) {
        if (mounted) {
          setState(() => _locationResults = const <AppLocation>[]);
        }
        return;
      }
      final results = await ref
          .read(locationServiceProvider)
          .searchIndiaLocations(query);
      if (mounted) {
        setState(() => _locationResults = results);
      }
    });
  }

  List<DateTime> _timeSlots() {
    final slots = <DateTime>[];
    for (var hour = 7; hour <= 21; hour++) {
      slots.add(
        DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          hour,
        ),
      );
      if (hour != 21) {
        slots.add(
          DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            hour,
            30,
          ),
        );
      }
    }
    return slots;
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radius),
        borderSide: BorderSide(color: AppColors.glass),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radius),
        borderSide: BorderSide(color: AppColors.glass),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.radius),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildCategoryStep(BuildContext context) {
    return Column(
      key: const ValueKey<String>('category-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'What are we shooting?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Pick the closest category. Choose Other if it does not fit.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kMarketplaceCategories
              .map(
                (item) => ShootrCategoryTile(
                  category: item,
                  selected: _selectedCategoryId == item.id,
                  onTap: () => setState(() => _selectedCategoryId = item.id),
                ),
              )
              .toList(),
        ),
        if (_selectedCategoryId == 'other') ...<Widget>[
          const SizedBox(height: 16),
          TextField(
            controller: _customCategoryController,
            decoration: _inputDecoration(
              label: 'Custom category',
              hint: 'Tell us what this shoot is for',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPackageStep(BuildContext context, List<ShootrPackage> packages) {
    return Column(
      key: const ValueKey<String>('package-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Select package',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the package that fits your shoot. Price updates with duration.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        ...packages
            .where((item) => item.type != ShootrPackageType.drone)
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _SelectableCard(
                  selected: _selectedPackageType == item.type,
                  onTap: () => setState(() => _selectedPackageType = item.type),
                  title: item.title,
                  subtitle: item.description,
                  priceLabel:
                      '${AppFormatters.currency(item.price, country: AppCountry.india)}/hr',
                  bullets: item.inclusions,
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildScheduleStep(BuildContext context, ShootrPackage package) {
    return Column(
      key: const ValueKey<String>('schedule-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Date, time and duration',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Pick your preferred slot. Available Shootrs will see the request instantly.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 120)),
            onDateChanged: (date) => setState(() => _selectedDate = date),
          ),
        ),
        const SizedBox(height: 16),
        Text('Time slots', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _timeSlots()
              .map(
                (slot) => _MiniChip(
                  label: AppFormatters.time(slot),
                  selected:
                      _selectedTime?.hour == slot.hour &&
                      _selectedTime?.minute == slot.minute,
                  onTap: () => setState(() => _selectedTime = slot),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Text('Duration', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _MiniChip(
              label: '1 hr',
              selected: _durationHours == 1,
              onTap: () => setState(() => _durationHours = 1),
            ),
            _MiniChip(
              label: '2 hr',
              selected: _durationHours == 2,
              onTap: () => setState(() => _durationHours = 2),
            ),
            _MiniChip(
              label: '3 hr',
              selected: _durationHours == 3,
              onTap: () => setState(() => _durationHours = 3),
            ),
            _MiniChip(
              label: 'Custom',
              selected: _durationHours == 0,
              onTap: () => setState(() => _durationHours = 0),
            ),
          ],
        ),
        if (_durationHours == 0) ...<Widget>[
          const SizedBox(height: 14),
          TextField(
            controller: _customDurationController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(
              label: 'Custom hours',
              hint: 'For example 2.5',
            ),
          ),
        ],
        const SizedBox(height: 16),
        GlassCard(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Estimated base subtotal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                AppFormatters.currency(
                  _subtotal(package),
                  country: AppCountry.india,
                ),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStep(BuildContext context, AppState state) {
    final location = _selectedLocation ?? state.selectedLocation;
    final markers = <Marker>{
      if (location != null)
        Marker(
          markerId: const MarkerId('booking-location'),
          position: LatLng(location.latitude, location.longitude),
          draggable: true,
          onDragEnd: (value) => setState(
            () => _selectedLocation = AppLocation(
              address: _addressController.text.trim().isEmpty
                  ? location.address
                  : _addressController.text.trim(),
              city: location.city,
              state: location.state,
              country: location.country,
              latitude: value.latitude,
              longitude: value.longitude,
              placeLabel: location.primaryLabel,
            ),
          ),
        ),
    };
    return Column(
      key: const ValueKey<String>('location-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Shoot location',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Search an address, use your current location, or tap the map.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _addressController,
                onChanged: _searchLocations,
                decoration: _inputDecoration(
                  label: 'Address search',
                  hint: 'Search city or locality',
                  suffixIcon: Icon(
                    PhosphorIcons.magnifyingGlass(),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            PrimaryGlowButton(
              label: 'Use current',
              isExpanded: false,
              onPressed: () async {
                await ref
                    .read(appControllerProvider.notifier)
                    .detectClientLocation();
                final current = ref.read(selectedLocationProvider);
                if (mounted && current != null) {
                  setState(() {
                    _selectedLocation = current;
                    _addressController.text = current.address;
                    _locationResults = const <AppLocation>[];
                  });
                }
              },
            ),
          ],
        ),
        if (_locationResults.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          GlassCard(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _locationResults.length,
              separatorBuilder: (_, _) =>
                  Divider(color: AppColors.glass, height: 1),
              itemBuilder: (context, index) {
                final item = _locationResults[index];
                return ListTile(
                  onTap: () => setState(() {
                    _selectedLocation = item;
                    _addressController.text = item.address;
                    _locationResults = const <AppLocation>[];
                  }),
                  leading: Icon(
                    PhosphorIcons.mapPin(),
                    color: AppColors.primary,
                  ),
                  title: Text(item.city),
                  subtitle: Text(item.address),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radius),
          child: SizedBox(
            height: 240,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  location?.latitude ?? 19.0760,
                  location?.longitude ?? 72.8777,
                ),
                zoom: location == null ? 10 : 14,
              ),
              markers: markers,
              zoomControlsEnabled: false,
              myLocationEnabled: true,
              onTap: (value) => setState(
                () => _selectedLocation = AppLocation(
                  address: _addressController.text.trim().isEmpty
                      ? (location?.address ?? 'Pinned location')
                      : _addressController.text.trim(),
                  city: location?.city ?? 'Mumbai',
                  state: location?.state ?? 'Maharashtra',
                  country: AppCountry.india,
                  latitude: value.latitude,
                  longitude: value.longitude,
                  placeLabel: location?.primaryLabel ?? 'Pinned location',
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _landmarkController,
          decoration: _inputDecoration(
            label: 'Landmark',
            hint: 'Gate, cafe, mall, or landmark',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _instructionsController,
          minLines: 3,
          maxLines: 4,
          decoration: _inputDecoration(
            label: 'Access instructions',
            hint: 'Parking, lift, dress code, or notes',
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Row(
            children: <Widget>[
              Icon(
                PhosphorIcons.globeHemisphereEast(),
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Client bookings are currently limited to India only.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBriefStep(BuildContext context) {
    final eventType = _selectedCategoryId == 'other'
        ? _customCategoryController.text.trim()
        : (_selectedCategory?.label ?? 'Custom shoot');
    return Column(
      key: const ValueKey<String>('brief-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Pre-shoot brief',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Your Shootr sees this before the shoot.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Row(
            children: <Widget>[
              Icon(PhosphorIcons.sparkle(), color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Event type: ${eventType.trim().isEmpty ? 'Custom shoot' : eventType}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Style preference', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _styles
              .map(
                (item) => _MiniChip(
                  label: item,
                  selected: _selectedStyle == item,
                  onTap: () => setState(() => _selectedStyle = item),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Text('Mood', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _moods
              .map(
                (item) => _MiniChip(
                  label: item,
                  selected: _selectedMood == item,
                  onTap: () => setState(() => _selectedMood = item),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Text('Music preference', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _music
              .map(
                (item) => _MiniChip(
                  label: item,
                  selected: _selectedMusic == item,
                  onTap: () => setState(() => _selectedMusic = item),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Text('Number of reels', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <int>[1, 2, 3, 4]
              .map(
                (item) => _MiniChip(
                  label: item == 4 ? '4+' : '$item',
                  selected: _reelsNeeded == item,
                  onTap: () => setState(() => _reelsNeeded = item),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Text('Aspect ratio', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _ratios
              .map(
                (item) => _MiniChip(
                  label: item,
                  selected: _selectedRatio == item,
                  onTap: () => setState(() => _selectedRatio = item),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _referenceController,
          decoration: _inputDecoration(
            label: 'Reference reel link',
            hint: 'Paste Instagram or YouTube URL',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _specialInstructionsController,
          minLines: 4,
          maxLines: 5,
          decoration: _inputDecoration(
            label: 'Special instructions',
            hint:
                'Add any notes for framing, story beats, timing, or brand direction',
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep(
    BuildContext context,
    ShootrPackage selectedPackage,
    AppUser? currentUser,
    AppLocation? location,
  ) {
    final subtotal = _subtotal(selectedPackage);
    final promo = _promoDiscount(subtotal).clamp(0.0, subtotal).toDouble();
    final discounted = subtotal - promo;
    final fee = discounted * AppConstants.platformFeePercent;
    final tax = discounted * _taxRate(location?.country ?? AppCountry.india);
    final credits = _creditsDiscount(currentUser).toDouble();
    return Column(
      key: const ValueKey<String>('review-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Review request',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Check the brief. Shootrs will see the request and one can accept it in real time.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Booking summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _SummaryRow(
                label: 'Category',
                value:
                    _selectedCategory?.label ??
                    _customCategoryController.text.trim().ifEmpty('Custom'),
              ),
              const _SummaryRow(
                label: 'Shootr',
                value: 'Assigned after acceptance',
              ),
              _SummaryRow(label: 'Package', value: selectedPackage.title),
              _SummaryRow(
                label: 'Date',
                value: AppFormatters.dateOnly(_selectedDate),
              ),
              _SummaryRow(
                label: 'Time',
                value: _selectedTime == null
                    ? 'Not selected'
                    : AppFormatters.time(_selectedTime!),
              ),
              _SummaryRow(
                label: 'Duration',
                value:
                    '${_resolvedDuration().toStringAsFixed(_resolvedDuration().truncateToDouble() == _resolvedDuration() ? 0 : 1)} hr',
              ),
              _SummaryRow(
                label: 'Location',
                value: location?.address ?? 'Not selected',
              ),
              _SummaryRow(
                label: 'Style',
                value: _selectedStyle.ifEmpty('Not selected'),
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
                'Price breakdown',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _PriceLine(
                label: 'Base rate + duration',
                value: AppFormatters.currency(
                  selectedPackage.price * _resolvedDuration(),
                  country: location?.country ?? AppCountry.india,
                ),
              ),
              if (promo > 0)
                _PriceLine(
                  label: 'Promo ${_promoController.text.trim().toUpperCase()}',
                  value:
                      '-${AppFormatters.currency(promo, country: location?.country ?? AppCountry.india)}',
                ),
              _PriceLine(
                label: 'Platform fee (5%)',
                value: AppFormatters.currency(
                  fee,
                  country: location?.country ?? AppCountry.india,
                ),
              ),
              _PriceLine(
                label:
                    '${(location?.country ?? AppCountry.india).taxLabel} (${(_taxRate(location?.country ?? AppCountry.india) * 100).toStringAsFixed(0)}%)',
                value: AppFormatters.currency(
                  tax,
                  country: location?.country ?? AppCountry.india,
                ),
              ),
              if (credits > 0)
                _PriceLine(
                  label: 'Shootr credits',
                  value:
                      '-${AppFormatters.currency(credits, country: location?.country ?? AppCountry.india)}',
                ),
              Divider(color: AppColors.glass, height: 24),
              _PriceLine(
                label: 'Total payable',
                value: AppFormatters.currency(
                  _totalAmount(selectedPackage, location, currentUser),
                  country: location?.country ?? AppCountry.india,
                ),
                emphasize: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _promoController,
          onChanged: (_) => setState(() {}),
          decoration: _inputDecoration(
            label: 'Promo code',
            hint: 'Try LAUNCH10 or NEW500',
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
                      'Shootr credits',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser == null
                          ? 'No credits available'
                          : '${currentUser.creditsBalance} credits available',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '100 credits = ${AppFormatters.currency(10, country: location?.country ?? AppCountry.india)} off',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _applyCredits,
                activeThumbColor: Colors.black,
                activeTrackColor: AppColors.primary,
                onChanged:
                    currentUser == null || currentUser.creditsBalance < 10
                    ? null
                    : (value) => setState(() => _applyCredits = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Payment method', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _payments
              .map(
                (item) => _MiniChip(
                  label: item,
                  selected: _selectedPayment == item,
                  onTap: () => setState(() => _selectedPayment = item),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.totalLabel,
    required this.canGoBack,
    required this.isSubmitting,
    required this.primaryLabel,
    required this.onPrimary,
    this.onBack,
  });

  final String totalLabel;
  final bool canGoBack;
  final bool isSubmitting;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Estimated total',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (canGoBack)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: OutlinedButton(
                  onPressed: isSubmitting ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.glass),
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radius),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
            Expanded(
              child: PrimaryGlowButton(
                label: primaryLabel,
                isLoading: isSubmitting,
                onPressed: onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.title,
    required this.currentStep,
    required this.stepTitles,
    required this.categoryLabel,
    required this.locationLabel,
  });

  final String title;
  final int currentStep;
  final List<String> stepTitles;
  final String categoryLabel;
  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.primary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Step ${currentStep + 1} of ${stepTitles.length}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          Row(
            children: List<Widget>.generate(
              stepTitles.length,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == stepTitles.length - 1 ? 0 : 8,
                  ),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: index <= currentStep
                          ? AppColors.primary
                          : AppColors.glass,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _MetaPill(icon: PhosphorIcons.sparkle(), label: categoryLabel),
              _MetaPill(
                icon: PhosphorIcons.usersThree(),
                label: 'Shootr assigned after acceptance',
              ),
              _MetaPill(icon: PhosphorIcons.mapPin(), label: locationLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.onTap,
    required this.title,
    required this.subtitle,
    required this.priceLabel,
    required this.bullets,
  });

  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String subtitle;
  final String priceLabel;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      borderColor: selected
          ? AppColors.primary.withValues(alpha: 0.55)
          : AppColors.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Text(
                priceLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          ...bullets.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    PhosphorIcons.checkCircle(),
                    color: AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.glass,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.glass),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 190),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.primary)
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: emphasize
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
