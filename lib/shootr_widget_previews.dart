import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'app/constants/app_colors.dart';
import 'app/theme/app_theme.dart';
import 'features/client/presentation/client_components.dart';
import 'shared/models/marketplace_catalog.dart';
import 'shared/widgets/flow_guide_card.dart';
import 'shared/widgets/glass_card.dart';
import 'shared/widgets/primary_glow_button.dart';
import 'shared/widgets/section_header.dart';

@Preview(
  group: 'Shootr UI',
  name: 'Auth choices',
  size: Size(390, 720),
  brightness: Brightness.dark,
)
Widget authChoicesPreview() {
  return const _PreviewShell(child: _AuthChoicesPreview());
}

@Preview(
  group: 'Shootr UI',
  name: 'Client home essentials',
  size: Size(390, 780),
  brightness: Brightness.dark,
)
Widget clientHomeEssentialsPreview() {
  return const _PreviewShell(child: _ClientHomeEssentialsPreview());
}

class _PreviewShell extends StatelessWidget {
  const _PreviewShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFF101010),
                AppColors.background,
                Color(0xFF040404),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthChoicesPreview extends StatelessWidget {
  const _AuthChoicesPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
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
        const _PreviewRoleCard(
          icon: Icons.camera_alt_outlined,
          title: 'Book a Shootr',
          subtitle: 'Find a verified creator and book a reel shoot.',
        ),
        SizedBox(height: 14),
        const _PreviewRoleCard(
          icon: Icons.videocam_outlined,
          title: 'Become a Shootr',
          subtitle: 'Accept bookings, upload reels, and track earnings.',
        ),
        SizedBox(height: 14),
        const _PreviewRoleCard(
          icon: Icons.admin_panel_settings_outlined,
          title: 'Admin console',
          subtitle: 'Sign in with the approved admin email.',
        ),
      ],
    );
  }
}

class _PreviewRoleCard extends StatelessWidget {
  const _PreviewRoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: AppColors.primary.withValues(alpha: 0.22),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Icon(icon, color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 14),
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
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _ClientHomeEssentialsPreview extends StatelessWidget {
  const _ClientHomeEssentialsPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GlassCard(
          borderColor: AppColors.primary.withValues(alpha: 0.32),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Available in Mumbai',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Book a reel shoot near you',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Choose a verified Shootr, pay, and track the shoot from one place.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              const PrimaryGlowButton(label: 'Find a Shootr', onPressed: null),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Row(
            children: <Widget>[
              Icon(Icons.search_rounded, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search by city, style, or event',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionHeader(
          title: 'Choose a shoot type',
          subtitle: 'Tap one to see matching Shootrs',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: kMarketplaceCategories
              .take(6)
              .map(
                (category) => ShootrCategoryTile(
                  category: category,
                  selected: category == kMarketplaceCategories.first,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 22),
        const FlowGuideCard(
          title: 'How booking works',
          subtitle: 'Three simple steps from search to delivery.',
          steps: <FlowGuideStep>[
            FlowGuideStep(
              title: 'Choose a shoot',
              subtitle: 'Pick the event type and location.',
              icon: Icons.category_outlined,
            ),
            FlowGuideStep(
              title: 'Pick a Shootr',
              subtitle: 'Compare nearby creators and packages.',
              icon: Icons.person_search_outlined,
            ),
            FlowGuideStep(
              title: 'Pay and track',
              subtitle: 'Confirm, chat, and collect reels in Vault.',
              icon: Icons.payments_outlined,
            ),
          ],
        ),
      ],
    );
  }
}
