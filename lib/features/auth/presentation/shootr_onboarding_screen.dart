import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/marketplace_catalog.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_glow_button.dart';

class ShootrOnboardingScreen extends ConsumerStatefulWidget {
  const ShootrOnboardingScreen({super.key});

  @override
  ConsumerState<ShootrOnboardingScreen> createState() =>
      _ShootrOnboardingScreenState();
}

class _ShootrOnboardingScreenState
    extends ConsumerState<ShootrOnboardingScreen> {
  static const List<String> _steps = <String>[
    'Phone',
    'Identity',
    'Device',
    'Basic Info',
    'Location',
    'Bio',
    'Specialisations',
    'Portfolio',
    'Pricing',
    'Bank & UPI',
    'Availability',
    'Review',
  ];

  int _currentStep = 0;
  bool _submitted = false;
  bool _isSubmitting = false;
  bool _isUploadingMedia = false;
  bool _consentGiven = false;
  bool _onDemandMode = false;
  bool _hasDrone = false;
  String _selectedGender = UserGender.preferNotToSay.label;
  String _selectedState = kIndiaRegions.first.name;
  String _selectedCity = kIndiaRegions.first.cities.first;
  int _radiusKm = 5;
  String _selectedDeviceModel = kApprovedDevices.first.model;
  String _selectedVacationLabel = 'No vacation dates set';
  double _hourlyRate = DeviceTier.premium.defaultRate;
  final Set<String> _selectedCategoryIds = <String>{'restaurant'};
  final List<String> _portfolioUrls = <String>[
    'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f',
  ];
  final Map<String, bool> _dayEnabled = <String, bool>{};
  final Map<String, String> _dayStart = <String, String>{};
  final Map<String, String> _dayEnd = <String, String>{};

  late final TextEditingController _aadhaarController;
  late final TextEditingController _dobController;
  late final TextEditingController _imeiController;
  late final TextEditingController _waitlistEmailController;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _pinController;
  late final TextEditingController _bioController;
  late final TextEditingController _upiController;
  late final TextEditingController _accountNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _confirmAccountController;
  late final TextEditingController _ifscController;
  late final TextEditingController _bankNameController;
  String? _profilePhotoUrl;
  String? _aadhaarFrontUrl;
  String? _aadhaarBackUrl;

  @override
  void initState() {
    super.initState();
    _aadhaarController = TextEditingController();
    _dobController = TextEditingController();
    _imeiController = TextEditingController();
    _waitlistEmailController = TextEditingController();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _pinController = TextEditingController();
    _bioController = TextEditingController();
    _upiController = TextEditingController();
    _accountNameController = TextEditingController();
    _accountNumberController = TextEditingController();
    _confirmAccountController = TextEditingController();
    _ifscController = TextEditingController();
    _bankNameController = TextEditingController();
    for (final day in _weekdays) {
      _dayEnabled[day] = day != 'Sunday';
      _dayStart[day] = '10:00 AM';
      _dayEnd[day] = '08:00 PM';
    }
    _syncPricingToTier();
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _dobController.dispose();
    _imeiController.dispose();
    _waitlistEmailController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _pinController.dispose();
    _bioController.dispose();
    _upiController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _confirmAccountController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  static const List<String> _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  ApprovedDevice? get _selectedDevice =>
      findApprovedDevice(_selectedDeviceModel);

  DeviceTier get _deviceTier => _selectedDevice?.tier ?? DeviceTier.waitlist;

  bool get _isDeviceSupported => _selectedDevice != null;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final phone =
        '${appState.pendingCountryCode} ${appState.pendingPhoneNumber}'.trim();
    final averageRate = _recommendedRate(appState.shootrs);

    if (_submitted) {
      return _UnderReviewScreen(
        onContinue: () => context.go(AppRoutes.shootrHome),
      );
    }

    return AppScaffold(
      title: 'Shootr Setup',
      bottomNavigationBar: _OnboardingBottomBar(
        stepLabel: 'Step ${_currentStep + 1} of ${_steps.length}',
        primaryLabel: _currentStep == _steps.length - 1
            ? 'Submit for Review'
            : 'Continue',
        canGoBack: _currentStep > 0,
        isSubmitting: _isSubmitting || _isUploadingMedia,
        onBack: _currentStep > 0
            ? () => setState(() => _currentStep -= 1)
            : null,
        onPrimary: () => _handlePrimaryAction(phone, averageRate),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SetupHeader(
            title: _steps[_currentStep],
            subtitle:
                'Build a premium Shootr profile that clients can trust at first glance.',
            currentStep: _currentStep,
            steps: _steps,
          ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.04, end: 0),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: 240.ms,
            child: switch (_currentStep) {
              0 => _buildPhoneStep(phone),
              1 => _buildIdentityStep(),
              2 => _buildDeviceStep(),
              3 => _buildBasicInfoStep(),
              4 => _buildLocationStep(),
              5 => _buildBioStep(),
              6 => _buildSpecialisationsStep(),
              7 => _buildPortfolioStep(),
              8 => _buildPricingStep(averageRate),
              9 => _buildBankStep(),
              10 => _buildAvailabilityStep(),
              _ => _buildReviewStep(phone, averageRate),
            },
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildPhoneStep(String phone) {
    return Column(
      key: const ValueKey<String>('phone-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Phone verification is complete',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'We use this number for bookings, payout alerts, and safety communication.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        GlassCard(
          borderColor: AppColors.primary.withValues(alpha: 0.4),
          child: Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                child: Icon(
                  PhosphorIcons.deviceMobileCamera(),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(phone, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Verified and ready for onboarding',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(
                PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityStep() {
    final age = _selectedDob == null ? null : _ageFromDob(_selectedDob!);
    return Column(
      key: const ValueKey<String>('identity-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Verify your identity',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'We verify your age to ensure all Shootrs are 18 or above. Aadhaar details are encrypted and never stored in plain text.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _aadhaarController,
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final raw = value.replaceAll(RegExp(r'\D'), '');
            final digits = raw.length > 12
                ? raw.substring(0, 12).split('')
                : raw.split('');
            final formatted = <String>[];
            for (var i = 0; i < digits.length; i++) {
              if (i != 0 && i % 4 == 0) {
                formatted.add(' ');
              }
              formatted.add(digits[i]);
            }
            final next = formatted.join();
            if (next != value) {
              _aadhaarController.value = TextEditingValue(
                text: next,
                selection: TextSelection.collapsed(offset: next.length),
              );
            }
          },
          decoration: _inputDecoration('Aadhaar number', 'XXXX XXXX XXXX'),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _UploadTile(
                label: 'Aadhaar front',
                fileLabel: _aadhaarFrontUrl == null
                    ? 'Upload front image'
                    : 'Front uploaded',
                onTap: () => setState(
                  () => _aadhaarFrontUrl =
                      'https://images.unsplash.com/photo-1516321318423-f06f85e504b3',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UploadTile(
                label: 'Aadhaar back',
                fileLabel: _aadhaarBackUrl == null
                    ? 'Upload back image'
                    : 'Back uploaded',
                onTap: () => setState(
                  () => _aadhaarBackUrl =
                      'https://images.unsplash.com/photo-1488590528505-98d2b5aba04b',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _dobController,
          readOnly: true,
          onTap: _pickDob,
          decoration: _inputDecoration('Date of birth', 'YYYY-MM-DD'),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _consentGiven,
          onChanged: (value) => setState(() => _consentGiven = value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: const Text(
            'I consent to age verification using my Aadhaar card',
          ),
        ),
        if (age != null) ...<Widget>[
          const SizedBox(height: 12),
          GlassCard(
            borderColor: age >= 18
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.error.withValues(alpha: 0.35),
            child: Text(
              age >= 18
                  ? 'Age verified: $age years old. Verification status will be marked pending for admin review.'
                  : 'Sorry, you must be 18 or older to become a Shootr.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: age >= 18 ? AppColors.textPrimary : AppColors.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDeviceStep() {
    return Column(
      key: const ValueKey<String>('device-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Verify your device',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Only verified devices can accept bookings. Your device tier determines your pricing range.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedDeviceModel,
          dropdownColor: AppColors.surfaceElevated,
          items:
              <String>[
                    ...kApprovedDevices.map((item) => item.model),
                    'My device is not listed',
                  ]
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
          onChanged: (value) => setState(() {
            _selectedDeviceModel = value!;
            _syncPricingToTier();
          }),
          decoration: _inputDecoration('Detected device', 'Choose your device'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _imeiController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(
            'IMEI / verification number',
            'Enter device IMEI',
          ),
        ),
        const SizedBox(height: 12),
        if (_isDeviceSupported)
          GlassCard(
            borderColor: AppColors.primary.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _selectedDevice!.model,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '${_selectedDevice!.cameraSpec} · ${_selectedDevice!.type.label}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                _TierBadge(tier: _deviceTier),
              ],
            ),
          )
        else ...<Widget>[
          GlassCard(
            borderColor: AppColors.error.withValues(alpha: 0.35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Your device is not currently supported.',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 6),
                Text(
                  'We are constantly adding new devices. Join the waitlist and we will notify you when yours is approved.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _waitlistEmailController,
                  decoration: _inputDecoration(
                    'Waitlist email',
                    'name@email.com',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      key: const ValueKey<String>('basic-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Basic profile info',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'This is the profile clients will see when they choose who to book.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Center(
          child: InkWell(
            onTap: _pickProfilePhoto,
            borderRadius: BorderRadius.circular(999),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: _profilePhotoUrl == null
                  ? null
                  : NetworkImage(_profilePhotoUrl!),
              child: _isUploadingMedia
                  ? const CircularProgressIndicator()
                  : _profilePhotoUrl == null
                  ? Icon(PhosphorIcons.cameraPlus(), color: AppColors.primary)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _nameController,
          decoration: _inputDecoration('Full name', 'Enter your full name'),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: UserGender.values
              .map(
                (item) => _ChoicePill(
                  label: item.label,
                  selected: _selectedGender == item.label,
                  onTap: () => setState(() => _selectedGender = item.label),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _dobController,
          readOnly: true,
          onTap: _pickDob,
          decoration: _inputDecoration(
            'Date of birth',
            'Must match Aadhaar age',
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStep() {
    final region = kIndiaRegions.firstWhere(
      (item) => item.name == _selectedState,
      orElse: () => kIndiaRegions.first,
    );
    final cityLocation = _coordinatesForCity(_selectedCity);
    return Column(
      key: const ValueKey<String>('location-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Location', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Shootr onboarding is currently locked to India. Choose your state, city, and travel radius.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          readOnly: true,
          decoration: _inputDecoration(
            'Country',
            'India',
          ).copyWith(hintText: 'India'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedState,
          dropdownColor: AppColors.surfaceElevated,
          items: kIndiaRegions
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item.name,
                  child: Text(item.name),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() {
            _selectedState = value!;
            _selectedCity = kIndiaRegions
                .firstWhere((item) => item.name == value)
                .cities
                .first;
          }),
          decoration: _inputDecoration('State / UT', 'Choose your state'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _selectedCity,
          dropdownColor: AppColors.surfaceElevated,
          items: region.cities
              .map(
                (item) =>
                    DropdownMenuItem<String>(value: item, child: Text(item)),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedCity = value!),
          decoration: _inputDecoration('City', 'Choose your city'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          decoration: _inputDecoration(
            'Home address',
            'Street, area, landmark',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration('PIN code', '6-digit PIN'),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              <int>[2, 5, 10, 20]
                  .map(
                    (value) => _ChoicePill(
                      label: '${value}km',
                      selected: _radiusKm == value,
                      onTap: () => setState(() => _radiusKm = value),
                    ),
                  )
                  .toList()
                ..add(
                  _ChoicePill(
                    label: 'Any',
                    selected: _radiusKm == 50,
                    onTap: () => setState(() => _radiusKm = 50),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Row(
            children: <Widget>[
              Icon(PhosphorIcons.mapPin(), color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Map preview: ${cityLocation.city}, ${cityLocation.state} · ${cityLocation.latitude.toStringAsFixed(4)}, ${cityLocation.longitude.toStringAsFixed(4)}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBioStep() {
    return Column(
      key: const ValueKey<String>('bio-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Tell clients about yourself',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'No minimum and no maximum. Say enough for clients to understand your style and strengths.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _bioController,
          minLines: 6,
          maxLines: 8,
          decoration: _inputDecoration(
            'Bio',
            'Hi! I am a full-time content creator specialising in restaurant reels and brand shoots...',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${_bioController.text.length} characters',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSpecialisationsStep() {
    return Column(
      key: const ValueKey<String>('specialisations-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Specialisations',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Select at least one category. These tags shape your search ranking and booking relevance.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: kMarketplaceCategories
              .map(
                (item) => _ChoicePill(
                  label: item.label,
                  selected: _selectedCategoryIds.contains(item.id),
                  onTap: () => setState(() {
                    if (_selectedCategoryIds.contains(item.id)) {
                      _selectedCategoryIds.remove(item.id);
                    } else {
                      _selectedCategoryIds.add(item.id);
                    }
                  }),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPortfolioStep() {
    return Column(
      key: const ValueKey<String>('portfolio-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Portfolio upload',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Your portfolio is your first impression. Upload your best work. Minimum 1 item, maximum 10 items.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount:
              _portfolioUrls.length +
              (_portfolioUrls.length < AppConstants.maxPortfolioItems ? 1 : 0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.08,
          ),
          itemBuilder: (context, index) {
            if (index == _portfolioUrls.length) {
              return GlassCard(
                onTap: _addPortfolioItem,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (_isUploadingMedia)
                      const CircularProgressIndicator()
                    else
                      Icon(
                        PhosphorIcons.plusCircle(),
                        color: AppColors.primary,
                        size: 32,
                      ),
                    const SizedBox(height: 10),
                    Text(_isUploadingMedia ? 'Uploading...' : 'Add file'),
                  ],
                ),
              );
            }
            final url = _portfolioUrls[index];
            return Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radius),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: InkWell(
                    onTap: () => setState(() => _portfolioUrls.removeAt(index)),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black87,
                      child: Icon(
                        PhosphorIcons.x(),
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: const Text('32MB · 00:18'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPricingStep(double averageRate) {
    return Column(
      key: const ValueKey<String>('pricing-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Pricing setup',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Your device tier sets the allowed pricing range. You can fine-tune your hourly rate within that band.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _TierBadge(tier: _deviceTier),
              const SizedBox(height: 10),
              Text(
                'Recommended price for your area: ${AppFormatters.currency(averageRate, country: AppCountry.india)}/hr',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              Slider(
                value: _hourlyRate.clamp(
                  _deviceTier.minRate,
                  _deviceTier.maxRate,
                ),
                min: _deviceTier.minRate,
                max: _deviceTier.maxRate == 0 ? 100 : _deviceTier.maxRate,
                divisions: ((_deviceTier.maxRate - _deviceTier.minRate) / 100)
                    .round()
                    .clamp(1, 40),
                activeColor: AppColors.primary,
                onChanged: _deviceTier == DeviceTier.waitlist
                    ? null
                    : (value) => setState(() => _hourlyRate = value),
              ),
              Text(
                'Hourly rate: ${AppFormatters.currency(_hourlyRate, country: AppCountry.india)}/hr',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: _hasDrone,
                onChanged: (value) => setState(() => _hasDrone = value),
                contentPadding: EdgeInsets.zero,
                title: const Text('I also offer drone shoots'),
                subtitle: const Text(
                  'Enables the drone add-on on your profile',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankStep() {
    return Column(
      key: const ValueKey<String>('bank-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Bank & UPI details',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Your earnings are transferred within 24 hours of booking completion. Data is encrypted and never shared with clients.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _upiController,
          decoration: _inputDecoration('UPI ID', 'name@bank'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _accountNameController,
          decoration: _inputDecoration(
            'Account holder name',
            'Name as per bank account',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _accountNumberController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(
            'Account number',
            'Enter account number',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmAccountController,
          keyboardType: TextInputType.number,
          decoration: _inputDecoration(
            'Confirm account number',
            'Re-enter account number',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ifscController,
          onChanged: (value) {
            final next = value.toUpperCase();
            if (next != value) {
              _ifscController.value = TextEditingValue(
                text: next,
                selection: TextSelection.collapsed(offset: next.length),
              );
            }
            if (next.startsWith('HDFC')) {
              _bankNameController.text = 'HDFC Bank';
            } else if (next.startsWith('ICIC')) {
              _bankNameController.text = 'ICICI Bank';
            } else if (next.startsWith('SBIN')) {
              _bankNameController.text = 'State Bank of India';
            }
          },
          decoration: _inputDecoration('IFSC code', 'Auto-detects bank name'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bankNameController,
          decoration: _inputDecoration(
            'Bank name',
            'Auto-filled when IFSC is recognised',
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityStep() {
    return Column(
      key: const ValueKey<String>('availability-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Availability setup',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Set your weekly working hours, one-tap presets, on-demand mode, and holiday dates.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _ChoicePill(
              label: 'Weekdays Only',
              selected: false,
              onTap: () => setState(() {
                for (final day in _weekdays) {
                  _dayEnabled[day] = day != 'Saturday' && day != 'Sunday';
                }
              }),
            ),
            _ChoicePill(
              label: 'Weekends Only',
              selected: false,
              onTap: () => setState(() {
                for (final day in _weekdays) {
                  _dayEnabled[day] = day == 'Saturday' || day == 'Sunday';
                }
              }),
            ),
            _ChoicePill(
              label: 'All Week',
              selected: false,
              onTap: () => setState(() {
                for (final day in _weekdays) {
                  _dayEnabled[day] = true;
                }
              }),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._weekdays.map(
          (day) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          day,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_dayStart[day]} - ${_dayEnd[day]}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _dayEnabled[day] ?? false,
                    activeTrackColor: AppColors.primary,
                    activeThumbColor: Colors.black,
                    onChanged: (value) =>
                        setState(() => _dayEnabled[day] = value),
                  ),
                ],
              ),
            ),
          ),
        ),
        SwitchListTile(
          value: _onDemandMode,
          onChanged: (value) => setState(() => _onDemandMode = value),
          contentPadding: EdgeInsets.zero,
          title: const Text('On-demand mode'),
          subtitle: const Text('Accept bookings outside your set hours'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickVacation,
          icon: Icon(PhosphorIcons.calendar()),
          label: Text(_selectedVacationLabel),
        ),
      ],
    );
  }

  Widget _buildReviewStep(String phone, double averageRate) {
    return Column(
      key: const ValueKey<String>('review-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Review & submit',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Estimated review time is 24-48 hours. Once approved, you will receive a notification and can start accepting bookings.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Summary', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _ReviewRow(label: 'Phone', value: phone),
              _ReviewRow(
                label: 'Aadhaar hash',
                value: _aadhaarController.text
                    .trim()
                    .hashCode
                    .abs()
                    .toRadixString(16),
              ),
              _ReviewRow(label: 'Device', value: _selectedDeviceModel),
              _ReviewRow(label: 'Tier', value: _deviceTier.label),
              _ReviewRow(label: 'Name', value: _nameController.text.trim()),
              _ReviewRow(
                label: 'Location',
                value: '$_selectedCity, $_selectedState',
              ),
              _ReviewRow(
                label: 'Specialisations',
                value: _selectedCategoryIds
                    .map(
                      (id) => kMarketplaceCategories
                          .firstWhere((item) => item.id == id)
                          .label,
                    )
                    .join(', '),
              ),
              _ReviewRow(
                label: 'Portfolio items',
                value: '${_portfolioUrls.length} uploaded',
              ),
              _ReviewRow(
                label: 'Hourly rate',
                value:
                    '${AppFormatters.currency(_hourlyRate, country: AppCountry.india)}/hr',
              ),
              _ReviewRow(
                label: 'Recommended area rate',
                value:
                    '${AppFormatters.currency(averageRate, country: AppCountry.india)}/hr',
              ),
              _ReviewRow(
                label: 'Payout',
                value: _upiController.text.trim().isNotEmpty
                    ? _upiController.text.trim()
                    : _bankNameController.text.trim().ifEmpty(
                        'Bank details added',
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handlePrimaryAction(String phone, double averageRate) async {
    if (_isUploadingMedia) {
      _showSnack('Wait for the media upload to finish.');
      return;
    }
    if (!_validateStep()) {
      return;
    }
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep += 1);
      return;
    }

    final dob = _selectedDob;
    final device = _selectedDevice;
    if (dob == null || device == null) {
      _showSnack(
        'Complete your identity and device verification before submitting.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final coordinates = _coordinatesForCity(_selectedCity);
      final payoutDetails = <String>[
        if (_upiController.text.trim().isNotEmpty)
          'UPI: ${_upiController.text.trim()}',
        if (_accountNumberController.text.trim().isNotEmpty)
          'Bank: ${_bankNameController.text.trim().ifEmpty('Bank pending')}',
      ].join(' | ');
      ref
          .read(appControllerProvider.notifier)
          .submitShootrProfile(
            name: _nameController.text.trim(),
            city: _selectedCity,
            stateName: _selectedState,
            photoUrl:
                _profilePhotoUrl ??
                'https://images.unsplash.com/photo-1521119989659-a83eee488004',
            deviceModel: device.model,
            deviceType: device.type,
            deviceTier: device.tier,
            deviceCameraSpec: device.cameraSpec,
            bio: _bioController.text.trim(),
            portfolio: _portfolioUrls,
            availability: _availabilitySummary(),
            todayAvailability: _todayAvailabilityLabel(),
            country: AppCountry.india,
            address: _addressController.text.trim(),
            pinCode: _pinController.text.trim(),
            gender: _selectedGenderEnum,
            dateOfBirth: dob,
            payoutDetails: payoutDetails,
            upiId: _upiController.text.trim(),
            bankName: _bankNameController.text.trim(),
            ifscCode: _ifscController.text.trim(),
            hourlyRate: _hourlyRate,
            specialisationIds: _selectedCategoryIds.toList(),
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            operatingRadiusKm: _radiusKm,
            onDemandMode: _onDemandMode,
            hasDrone: _hasDrone,
            identityStatus: VerificationStatus.pending,
            deviceVerificationStatus: VerificationStatus.pending,
          );
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitted = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSnack(
          'We could not submit your profile right now. Please try again.',
        );
      }
    }
  }

  bool _validateStep() {
    switch (_currentStep) {
      case 1:
        if (_aadhaarController.text.replaceAll(' ', '').length != 12) {
          _showSnack('Enter a valid 12-digit Aadhaar number.');
          return false;
        }
        if (_aadhaarFrontUrl == null || _aadhaarBackUrl == null) {
          _showSnack('Upload both Aadhaar images to continue.');
          return false;
        }
        if (!_consentGiven) {
          _showSnack('Consent is required for age verification.');
          return false;
        }
        if (_selectedDob == null || _ageFromDob(_selectedDob!) < 18) {
          _showSnack('Sorry, you must be 18 or older to become a Shootr.');
          return false;
        }
        return true;
      case 2:
        if (_imeiController.text.trim().length < 10) {
          _showSnack('Enter a valid IMEI or device verification number.');
          return false;
        }
        if (!_isDeviceSupported) {
          _showSnack(
            'This device is not yet supported. Join the waitlist instead.',
          );
          return false;
        }
        return true;
      case 3:
        if (_nameController.text.trim().length < 2 ||
            _profilePhotoUrl == null) {
          _showSnack('Add your name and profile photo to continue.');
          return false;
        }
        if (_selectedDob == null) {
          _showSnack('Date of birth is required.');
          return false;
        }
        return true;
      case 4:
        if (_addressController.text.trim().isEmpty ||
            _pinController.text.trim().length != 6) {
          _showSnack('Add your full address and a valid 6-digit PIN code.');
          return false;
        }
        return true;
      case 6:
        if (_selectedCategoryIds.isEmpty) {
          _showSnack('Select at least one specialisation.');
          return false;
        }
        return true;
      case 7:
        if (_portfolioUrls.isEmpty) {
          _showSnack('Upload at least one portfolio item.');
          return false;
        }
        return true;
      case 9:
        final hasUpi = RegExp(
          r'^[\w.\-]{2,}@[a-zA-Z]{2,}$',
        ).hasMatch(_upiController.text.trim());
        final hasBank =
            _accountNameController.text.trim().isNotEmpty &&
            _accountNumberController.text.trim().isNotEmpty &&
            _accountNumberController.text.trim() ==
                _confirmAccountController.text.trim() &&
            _ifscController.text.trim().length >= 8;
        if (!hasUpi && !hasBank) {
          _showSnack('Add a valid UPI ID or complete bank details.');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  DateTime? get _selectedDob {
    if (_dobController.text.trim().isEmpty) {
      return null;
    }
    try {
      final parts = _dobController.text.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  int _ageFromDob(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    final hadBirthday =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);
    if (!hadBirthday) {
      age -= 1;
    }
    return age;
  }

  UserGender get _selectedGenderEnum {
    for (final item in UserGender.values) {
      if (item.label == _selectedGender) {
        return item;
      }
    }
    return UserGender.preferNotToSay;
  }

  void _syncPricingToTier() {
    _hourlyRate = _deviceTier.defaultRate;
  }

  double _recommendedRate(List<AppUser> shootrs) {
    final matching = shootrs
        .where((item) => item.city == _selectedCity)
        .toList();
    if (matching.isEmpty) {
      return _deviceTier.defaultRate;
    }
    final total = matching.fold<double>(
      0,
      (sum, item) => sum + item.hourlyRate,
    );
    return total / matching.length;
  }

  AppLocation _coordinatesForCity(String city) {
    switch (city) {
      case 'Bengaluru':
        return const AppLocation(
          address: 'Bengaluru',
          city: 'Bengaluru',
          latitude: 12.9716,
          longitude: 77.5946,
          state: 'Karnataka',
        );
      case 'Hyderabad':
        return const AppLocation(
          address: 'Hyderabad',
          city: 'Hyderabad',
          latitude: 17.3850,
          longitude: 78.4867,
          state: 'Telangana',
        );
      case 'Delhi':
      case 'New Delhi':
        return const AppLocation(
          address: 'New Delhi',
          city: 'New Delhi',
          latitude: 28.6139,
          longitude: 77.2090,
          state: 'Delhi',
        );
      case 'Mumbai':
      default:
        return const AppLocation(
          address: 'Mumbai',
          city: 'Mumbai',
          latitude: 19.0760,
          longitude: 72.8777,
          state: 'Maharashtra',
        );
    }
  }

  List<String> _availabilitySummary() {
    final active = <String>[];
    for (final day in _weekdays) {
      if (_dayEnabled[day] == true) {
        active.add('$day ${_dayStart[day]}-${_dayEnd[day]}');
      }
    }
    return active;
  }

  String _todayAvailabilityLabel() {
    for (final day in _weekdays) {
      if (_dayEnabled[day] == true) {
        return '${_dayStart[day]} - ${_dayEnd[day]}';
      }
    }
    return 'Unavailable';
  }

  Future<void> _pickDob() async {
    final value = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1950, 1, 1),
      lastDate: DateTime.now(),
    );
    if (value != null && mounted) {
      setState(() {
        _dobController.text =
            '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickProfilePhoto() async {
    await _pickAndUploadImage(
      folder: 'shootr/shootr-profiles',
      tags: const <String>['shootr', 'shootr-profile'],
      onUploaded: (url) => _profilePhotoUrl = url,
    );
  }

  Future<void> _addPortfolioItem() async {
    if (_portfolioUrls.length >= AppConstants.maxPortfolioItems) {
      _showSnack('Portfolio limit reached.');
      return;
    }
    await _pickAndUploadImage(
      folder: 'shootr/portfolios',
      tags: const <String>['shootr', 'portfolio'],
      onUploaded: (url) => _portfolioUrls.add(url),
    );
  }

  Future<void> _pickAndUploadImage({
    required String folder,
    required List<String> tags,
    required void Function(String url) onUploaded,
  }) async {
    if (_isUploadingMedia) {
      return;
    }
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (file == null || !mounted) {
      return;
    }

    setState(() => _isUploadingMedia = true);
    try {
      final uploaded = await ref
          .read(cloudinaryServiceProvider)
          .uploadFile(file: file, folder: folder, tags: tags);
      if (mounted) {
        setState(() => onUploaded(uploaded.secureUrl));
      }
    } catch (error) {
      if (mounted) {
        _showSnack(error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingMedia = false);
      }
    }
  }

  Future<void> _pickVacation() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (range != null && mounted) {
      setState(() {
        _selectedVacationLabel =
            '${range.start.day}/${range.start.month} - ${range.end.day}/${range.end.month}';
      });
    }
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

  InputDecoration _inputDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
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
}

class _OnboardingBottomBar extends StatelessWidget {
  const _OnboardingBottomBar({
    required this.stepLabel,
    required this.primaryLabel,
    required this.canGoBack,
    required this.isSubmitting,
    required this.onPrimary,
    this.onBack,
  });

  final String stepLabel;
  final String primaryLabel;
  final bool canGoBack;
  final bool isSubmitting;
  final VoidCallback onPrimary;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: GlassCard(
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                stepLabel,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.primary),
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

class _SetupHeader extends StatelessWidget {
  const _SetupHeader({
    required this.title,
    required this.subtitle,
    required this.currentStep,
    required this.steps,
  });

  final String title;
  final String subtitle;
  final int currentStep;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.primary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 14),
          Row(
            children: List<Widget>.generate(
              steps.length,
              (index) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == steps.length - 1 ? 0 : 6,
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
        ],
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.55)
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

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.label,
    required this.fileLabel,
    required this.onTap,
  });

  final String label;
  final String fileLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Icon(PhosphorIcons.uploadSimple(), color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fileLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final DeviceTier tier;

  @override
  Widget build(BuildContext context) {
    final label = switch (tier) {
      DeviceTier.premium => 'Premium',
      DeviceTier.professional => 'Professional',
      DeviceTier.standard => 'Standard',
      DeviceTier.waitlist => 'Waitlist',
    };
    final medal = switch (tier) {
      DeviceTier.premium => 'Tier 1',
      DeviceTier.professional => 'Tier 2',
      DeviceTier.standard => 'Tier 3',
      DeviceTier.waitlist => 'Waitlist',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Text(
        '$medal · $label',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

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
            width: 120,
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

class _UnderReviewScreen extends StatelessWidget {
  const _UnderReviewScreen({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: 220,
            child: Lottie.network(AppConstants.successLottieUrl, repeat: true),
          ),
          const SizedBox(height: 12),
          Text(
            'Profile Under Review',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Estimated review time: 24-48 hours. You will receive a notification once approved.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                Text('What happens next'),
                SizedBox(height: 8),
                Text('1. Our team verifies your identity and device.'),
                SizedBox(height: 4),
                Text('2. We review your portfolio and pricing.'),
                SizedBox(height: 4),
                Text(
                  '3. Once approved, you can go online and accept bookings.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryGlowButton(label: 'Go to Shootr Home', onPressed: onContinue),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
