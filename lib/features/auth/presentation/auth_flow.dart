import 'dart:async';
import 'dart:math' as math;

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
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/network_avatar.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import 'shootr_onboarding_screen.dart';

String homeRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.client:
      return AppRoutes.clientHome;
    case UserRole.shootr:
      return AppRoutes.shootrHome;
    case UserRole.admin:
      return AppRoutes.admin;
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2500), _navigate);
  }

  void _navigate() {
    if (!mounted) {
      return;
    }

    final state = ref.read(appControllerProvider);
    if (state.currentUser != null) {
      context.go(homeRouteForRole(state.selectedRole));
      return;
    }

    if (state.onboardingSeen) {
      context.go(AppRoutes.roleSelection);
      return;
    }

    context.go(AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.1,
            colors: <Color>[
              Color(0xFF163426),
              AppColors.background,
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x6600FF85),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'S',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.05, 1.05),
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 28),
              Text('Shootr', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 12),
              SizedBox(
                width: 160,
                height: 120,
                child: Lottie.network(
                  AppConstants.splashLottieUrl,
                  repeat: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  final List<({String title, String subtitle, IconData icon})>
  _slides = <({String title, String subtitle, IconData icon})>[
    (
      title: 'Book a Pro Reel in 10 Minutes',
      subtitle:
          'Choose a package, pick a time, and get matched with a nearby Shootr.',
      icon: PhosphorIcons.deviceMobileCamera(PhosphorIconsStyle.duotone),
    ),
    (
      title: 'Certified iPhone Creators Near You',
      subtitle:
          'Search by city, package, style, and real-time availability on the map.',
      icon: PhosphorIcons.mapPinArea(PhosphorIconsStyle.duotone),
    ),
    (
      title: 'Earn Money With Your iPhone',
      subtitle:
          'Shootrs accept bookings, upload reels, and cash out with payout tracking.',
      icon: PhosphorIcons.coins(PhosphorIconsStyle.duotone),
    ),
  ];

  void _next() {
    if (_index == _slides.length - 1) {
      ref.read(appControllerProvider.notifier).markOnboardingSeen();
      context.go(AppRoutes.roleSelection);
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () {
                    ref
                        .read(appControllerProvider.notifier)
                        .markOnboardingSeen();
                    context.go(AppRoutes.roleSelection);
                  },
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        GlassCard(
                              padding: const EdgeInsets.all(26),
                              child: SizedBox(
                                height: 310,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppConstants.radius,
                                    ),
                                    gradient: LinearGradient(
                                      colors: <Color>[
                                        AppColors.primary.withValues(
                                          alpha: 0.18,
                                        ),
                                        Colors.white.withValues(alpha: 0.02),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Center(
                                    child: CircleAvatar(
                                      radius: 62,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      child: PhosphorIcon(
                                        slide.icon,
                                        size: 68,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(duration: 350.ms)
                            .slideY(begin: 0.08),
                        const SizedBox(height: 36),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _index == index ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _index == index
                          ? AppColors.primary
                          : AppColors.textSecondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryGlowButton(
                label: _index == _slides.length - 1 ? 'Get Started' : 'Next',
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 20),
          Text(
            'What do you want to do?',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Choose one path to continue. Use phone for bookings or email for admin access.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _RoleCard(
            icon: PhosphorIcons.camera(PhosphorIconsStyle.duotone),
            title: 'Book a Shootr',
            subtitle: 'Find a verified creator and book a reel shoot.',
            onTap: () {
              ref
                  .read(appControllerProvider.notifier)
                  .selectRole(UserRole.client);
              context.go(AppRoutes.phoneEntry);
            },
          ),
          const SizedBox(height: 16),
          _RoleCard(
            icon: PhosphorIcons.videoCamera(PhosphorIconsStyle.duotone),
            title: 'Become a Shootr',
            subtitle: 'Accept bookings, upload reels, and track earnings.',
            onTap: () {
              ref
                  .read(appControllerProvider.notifier)
                  .selectRole(UserRole.shootr);
              context.go(AppRoutes.phoneEntry);
            },
          ),
          const SizedBox(height: 16),
          _RoleCard(
            icon: PhosphorIcons.shieldCheck(PhosphorIconsStyle.duotone),
            title: 'Admin console',
            subtitle: 'Sign in with the approved admin email.',
            onTap: () {
              ref
                  .read(appControllerProvider.notifier)
                  .selectRole(UserRole.admin);
              context.go(AppRoutes.emailAuth);
            },
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: () => context.go(AppRoutes.emailAuth),
              child: const Text('Sign in with email'),
            ),
          ),
        ],
      ),
    );
  }
}

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _countryCode = '+91';
  bool _isSubmitting = false;

  static const List<({String label, String code})> _countries =
      <({String label, String code})>[
        (label: 'India', code: '+91'),
        (label: 'UAE', code: '+971'),
        (label: 'USA', code: '+1'),
      ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    final sent = await ref
        .read(appControllerProvider.notifier)
        .sendPhoneOtp(
          countryCode: _countryCode,
          phoneNumber: _phoneController.text.trim(),
        );
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (sent) {
        context.go(AppRoutes.otp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(appControllerProvider).errorMessage;

    return AppScaffold(
      title: 'Continue with phone',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Enter your number. We will send a 6-digit OTP.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _countryCode,
              dropdownColor: AppColors.surfaceElevated,
              items: _countries
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.code,
                      child: Text('${item.label}  ${item.code}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _countryCode = value!),
              decoration: const InputDecoration(labelText: 'Country'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '98765 43210',
              ),
              validator: (value) {
                final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                if (digits.length < 8 || digits.length > 12) {
                  return 'Enter a valid phone number.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            PrimaryGlowButton(
              label: 'Send code',
              onPressed: _submit,
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => context.go(AppRoutes.emailAuth),
                child: const Text('Use email login'),
              ),
            ),
            if (error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(error, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 16),
            Text.rich(
              TextSpan(
                text: 'By continuing you agree to our ',
                style: Theme.of(context).textTheme.bodyMedium,
                children: const <TextSpan>[
                  TextSpan(text: 'Terms'),
                  TextSpan(text: ' and '),
                  TextSpan(text: 'Privacy Policy'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmailAuthScreen extends ConsumerStatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  ConsumerState<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends ConsumerState<EmailAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isCreateMode = false;
  bool _isSubmitting = false;
  bool _resetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _resetSent = false;
    });

    final controller = ref.read(appControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final selectedRole = ref.read(appControllerProvider).selectedRole;

    if (_isCreateMode) {
      final created = await controller.createEmailAccount(
        email: email,
        password: password,
      );
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      if (!created) {
        return;
      }
      if (selectedRole == UserRole.admin) {
        final adminUser = await controller.bootstrapAdminAccount();
        if (!mounted) {
          return;
        }
        if (adminUser != null) {
          context.go(AppRoutes.admin);
        }
        return;
      }
      context.go(
        selectedRole == UserRole.shootr
            ? AppRoutes.shootrProfileSetup
            : AppRoutes.clientProfileSetup,
      );
      return;
    }

    final existingUser = await controller.signInWithEmail(
      email: email,
      password: password,
    );
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
    if (existingUser != null) {
      context.go(homeRouteForRole(existingUser.role));
      return;
    }

    if (selectedRole == UserRole.admin) {
      final adminUser = await controller.bootstrapAdminAccount();
      if (!mounted) {
        return;
      }
      if (adminUser != null) {
        context.go(AppRoutes.admin);
      }
      return;
    }

    if (controller.hasAuthenticatedFirebaseUser &&
        selectedRole != UserRole.admin) {
      context.go(
        selectedRole == UserRole.shootr
            ? AppRoutes.shootrProfileSetup
            : AppRoutes.clientProfileSetup,
      );
    }
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      return;
    }
    final sent = await ref
        .read(appControllerProvider.notifier)
        .sendPasswordResetEmail(email);
    if (mounted) {
      setState(() => _resetSent = sent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final isAdmin = state.selectedRole == UserRole.admin;
    final error = state.errorMessage;

    return AppScaffold(
      title: isAdmin ? 'Admin email' : 'Email login',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              isAdmin
                  ? 'Use the approved admin email. First time here? Choose Create.'
                  : 'Sign in or create an account with email and password.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            SegmentedButton<bool>(
              segments: const <ButtonSegment<bool>>[
                ButtonSegment<bool>(value: false, label: Text('Sign in')),
                ButtonSegment<bool>(value: true, label: Text('Create')),
              ],
              selected: <bool>{_isCreateMode},
              onSelectionChanged: _isSubmitting
                  ? null
                  : (values) => setState(() => _isCreateMode = values.first),
            ),
            const SizedBox(height: 22),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'name@email.com',
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (!email.contains('@') || !email.contains('.')) {
                  return 'Enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              autofillHints: const <String>[AutofillHints.password],
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) {
                if ((value ?? '').length < 6) {
                  return 'Password must be at least 6 characters.';
                }
                return null;
              },
            ),
            if (_isCreateMode) ...<Widget>[
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            PrimaryGlowButton(
              label: _isCreateMode ? 'Create account' : 'Sign in',
              onPressed: _submit,
              isLoading: _isSubmitting || state.isLoading,
            ),
            if (!_isCreateMode) ...<Widget>[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _sendResetLink,
                  child: Text(
                    _resetSent ? 'Reset link sent' : 'Forgot password',
                  ),
                ),
              ),
            ],
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => context.go(AppRoutes.phoneEntry),
                child: const Text('Use phone instead'),
              ),
            ),
            if (error != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(error, style: const TextStyle(color: AppColors.error)),
            ],
          ],
        ),
      ),
    );
  }
}

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List<TextEditingController>.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List<FocusNode>.generate(
    6,
    (_) => FocusNode(),
  );
  late final AnimationController _shakeController;
  Timer? _timer;
  int _seconds = 60;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focus in _focusNodes) {
      focus.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        return;
      }
      if (_seconds == 0) {
        timer.cancel();
      } else {
        setState(() => _seconds -= 1);
      }
    });
  }

  Future<void> _verify() async {
    final otp = _controllers.map((controller) => controller.text).join();
    if (otp.length != 6) {
      return;
    }

    setState(() => _isVerifying = true);
    final isValid = await ref
        .read(appControllerProvider.notifier)
        .verifyOtp(otp);
    if (!mounted) {
      return;
    }
    setState(() => _isVerifying = false);

    if (!isValid) {
      _shakeController.forward(from: 0);
      return;
    }

    final existingUser = await ref
        .read(appControllerProvider.notifier)
        .loadSignedInProfile();
    if (!mounted) {
      return;
    }
    if (existingUser != null) {
      context.go(homeRouteForRole(existingUser.role));
      return;
    }

    final role = ref.read(appControllerProvider).selectedRole;
    context.go(
      role == UserRole.client
          ? AppRoutes.clientProfileSetup
          : AppRoutes.shootrProfileSetup,
    );
  }

  Future<void> _resendOtp() async {
    final state = ref.read(appControllerProvider);
    if (state.pendingPhoneNumber.trim().isEmpty) {
      context.go(AppRoutes.phoneEntry);
      return;
    }
    setState(() => _isVerifying = true);
    final sent = await ref
        .read(appControllerProvider.notifier)
        .sendPhoneOtp(
          countryCode: state.pendingCountryCode,
          phoneNumber: state.pendingPhoneNumber,
        );
    if (!mounted) {
      return;
    }
    setState(() => _isVerifying = false);
    if (sent) {
      _startTimer();
    }
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      final pasted = value.replaceAll(RegExp(r'\D'), '');
      if (pasted.length == 6) {
        for (var i = 0; i < 6; i++) {
          _controllers[i].text = pasted[i];
        }
        _verify();
      }
      return;
    }

    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }

    if (index == 5 && value.isNotEmpty) {
      _verify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(appControllerProvider).errorMessage;

    return AppScaffold(
      title: 'Enter OTP',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Enter the 6-digit code we sent to your phone.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final offset =
                  math.sin(_shakeController.value * math.pi * 8) * 10;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Row(
              children: List<Widget>.generate(6, (index) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(counterText: ''),
                      onChanged: (value) => _onChanged(index, value),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (error != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(error, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 22),
          PrimaryGlowButton(
            label: 'Verify code',
            onPressed: _verify,
            isLoading: _isVerifying,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: _seconds == 0 && !_isVerifying ? _resendOtp : null,
              child: Text(
                _seconds == 0 ? 'Resend OTP' : 'Resend OTP in ${_seconds}s',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.primary.withValues(alpha: 0.22),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: PhosphorIcon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}

class ClientProfileSetupScreen extends ConsumerStatefulWidget {
  const ClientProfileSetupScreen({super.key});

  @override
  ConsumerState<ClientProfileSetupScreen> createState() =>
      _ClientProfileSetupScreenState();
}

class _ClientProfileSetupScreenState
    extends ConsumerState<ClientProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedCity = AppConstants.supportedCities.first;
  String? _photoPath;
  bool _isSubmitting = false;
  bool _isUploadingPhoto = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1600,
    );
    if (file == null || !mounted) {
      return;
    }

    setState(() => _isUploadingPhoto = true);
    try {
      final uploaded = await ref
          .read(cloudinaryServiceProvider)
          .uploadFile(
            file: file,
            folder: 'shootr/client-profiles',
            tags: const <String>['shootr', 'client-profile'],
          );
      if (mounted) {
        setState(() => _photoPath = uploaded.secureUrl);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    ref
        .read(appControllerProvider.notifier)
        .completeClientProfile(
          name: _nameController.text.trim(),
          city: _selectedCity,
          photoUrl:
              _photoPath ??
              'https://images.unsplash.com/photo-1527980965255-d3b416303d12',
        );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isSubmitting = false);
      context.go(AppRoutes.clientHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profile Setup',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: _photoPath == null
                    ? CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.12,
                        ),
                        child: _isUploadingPhoto
                            ? const CircularProgressIndicator()
                            : const Icon(Icons.add_a_photo_outlined),
                      )
                    : NetworkAvatar(imageUrl: _photoPath!, radius: 42),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (value) => (value == null || value.trim().length < 2)
                  ? 'Enter your full name.'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              dropdownColor: AppColors.surfaceElevated,
              items: AppConstants.supportedCities
                  .map(
                    (city) => DropdownMenuItem<String>(
                      value: city,
                      child: Text(city),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedCity = value!),
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 24),
            PrimaryGlowButton(
              label: 'Let\'s Go',
              onPressed: _isUploadingPhoto ? null : _submit,
              isLoading: _isSubmitting || _isUploadingPhoto,
            ),
          ],
        ),
      ),
    );
  }
}

class ShootrProfileSetupScreen extends StatelessWidget {
  const ShootrProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => const ShootrOnboardingScreen();
}
