import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/network_avatar.dart';
import '../../../shared/widgets/primary_glow_button.dart';
import '../../../shared/widgets/section_header.dart';
import 'client_components.dart';

class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final state = ref.watch(appControllerProvider);
    final savedShootrs = state.shootrs
        .where((shootr) => user?.savedShootrIds.contains(shootr.id) ?? false)
        .toList();

    if (user == null) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: EmptyStateView(
          title: 'Profile unavailable',
          subtitle: 'Sign in to manage your Shootr profile and bookings.',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        GlassCard(
          child: Row(
            children: <Widget>[
              GestureDetector(
                onTap: () => _openEditProfileSheet(context, ref, user),
                child: NetworkAvatar(imageUrl: user.photoUrl, radius: 36),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.phone,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.city}, ${user.state}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _openEditProfileSheet(context, ref, user),
                icon: Icon(PhosphorIcons.pencilSimpleLine()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _ProfileNavTile(
          title: 'My Bookings',
          subtitle: 'View upcoming, active, completed and cancelled shoots',
          icon: PhosphorIcons.calendarCheck(),
          onTap: () => context.go(AppRoutes.clientBookings),
        ),
        const SizedBox(height: 12),
        _ProfileNavTile(
          title: 'Shootr Vault',
          subtitle: 'Play, download, and share all delivered reels',
          icon: PhosphorIcons.filmStrip(),
          onTap: () => context.go(AppRoutes.clientVault),
        ),
        const SizedBox(height: 12),
        const SectionHeader(
          title: 'Vault Preview',
          subtitle: 'Latest delivered reels',
        ),
        const SizedBox(height: 12),
        if (user.deliveredReels.isEmpty)
          const EmptyStateView(
            title: 'Your vault is empty',
            subtitle: 'Delivered reels will be saved here automatically.',
          )
        else
          SizedBox(
            height: 220,
            child: GridView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: user.deliveredReels.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) =>
                  VaultReelTile(reel: user.deliveredReels[index]),
            ),
          ),
        const SizedBox(height: 18),
        const SectionHeader(title: 'Saved Shootrs'),
        const SizedBox(height: 12),
        if (savedShootrs.isEmpty)
          const EmptyStateView(
            title: 'No saved Shootrs yet',
            subtitle: 'Tap the heart on a Shootr card to save them for later.',
          )
        else
          ...savedShootrs
              .take(2)
              .map(
                (shootr) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ShootrSummaryCard(
                    shootr: shootr,
                    isSaved: true,
                    onSaveToggle: () => ref
                        .read(appControllerProvider.notifier)
                        .toggleSavedShootr(shootr.id),
                  ),
                ),
              ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Shootr Credits',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                '${user.creditsBalance} credits',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                'Every ₹100 spent = 10 credits. Credits expire after 6 months.',
              ),
              const SizedBox(height: 12),
              ...user.walletTransactions
                  .take(3)
                  .map(
                    (transaction) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(transaction.title),
                                Text(
                                  transaction.subtitle,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${transaction.isCredit ? '+' : '-'}${transaction.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: transaction.isCredit
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Referral', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Invite friends, earn ₹500 each'),
              const SizedBox(height: 8),
              Text('Your code: ${user.referralCode}'),
              const SizedBox(height: 12),
              PrimaryGlowButton(
                label: 'Share referral code',
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text: 'Use my Shootr code ${user.referralCode}',
                    ),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Referral code copied.')),
                    );
                  }
                },
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
                'Shootr Pass',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                user.passActive
                    ? 'Active • ${user.passPlan}'
                    : 'No active subscription',
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Shootr Pass management is coming soon.'),
                  ),
                ),
                child: Text(
                  user.passActive ? 'Manage Pass' : 'Upgrade to Shootr Pass',
                ),
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
                'Notifications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _NotificationSwitch(
                title: 'Booking updates',
                value: user.notificationPreferences.bookingUpdates,
                onChanged: (value) => ref
                    .read(appControllerProvider.notifier)
                    .updateNotificationPreferences(
                      user.notificationPreferences.copyWith(
                        bookingUpdates: value,
                      ),
                    ),
              ),
              _NotificationSwitch(
                title: 'Promos',
                value: user.notificationPreferences.promos,
                onChanged: (value) => ref
                    .read(appControllerProvider.notifier)
                    .updateNotificationPreferences(
                      user.notificationPreferences.copyWith(promos: value),
                    ),
              ),
              _NotificationSwitch(
                title: 'Reminders',
                value: user.notificationPreferences.reminders,
                onChanged: (value) => ref
                    .read(appControllerProvider.notifier)
                    .updateNotificationPreferences(
                      user.notificationPreferences.copyWith(reminders: value),
                    ),
              ),
              _NotificationSwitch(
                title: 'Messages',
                value: user.notificationPreferences.messages,
                onChanged: (value) => ref
                    .read(appControllerProvider.notifier)
                    .updateNotificationPreferences(
                      user.notificationPreferences.copyWith(messages: value),
                    ),
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
                'Help & Support',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const _FaqTile(
                title: 'How long does reel delivery take?',
                body:
                    'Most reels are delivered within 24 hours unless the package says otherwise.',
              ),
              const _FaqTile(
                title: 'Can I request changes?',
                body:
                    'Yes. Every booking includes one free revision request after delivery.',
              ),
              const _FaqTile(
                title: 'How do credits work?',
                body:
                    'Credits are earned on every completed payment and can be redeemed at checkout.',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'WhatsApp support opening is ready for API wiring.',
                      ),
                    ),
                  );
                },
                icon: Icon(PhosphorIcons.whatsappLogo()),
                label: const Text('Chat with us'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ProfileNavTile(
          title: 'Privacy Policy',
          subtitle: 'Review our privacy commitments',
          icon: PhosphorIcons.lock(),
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _ProfileNavTile(
          title: 'Terms & Conditions',
          subtitle: 'Booking, delivery, and cancellation rules',
          icon: PhosphorIcons.fileText(),
          onTap: () {},
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => _confirmLogout(context, ref),
          child: const Text('Logout'),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => _confirmDelete(context, ref),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Delete Account'),
        ),
      ],
    );
  }

  Future<void> _openEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final nameController = TextEditingController(text: user.name);
    final cityController = TextEditingController(text: user.city);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Edit Profile',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cityController,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                const SizedBox(height: 16),
                PrimaryGlowButton(
                  label: 'Save Changes',
                  onPressed: () {
                    ref
                        .read(appControllerProvider.notifier)
                        .completeClientProfile(
                          name: nameController.text.trim(),
                          city: cityController.text.trim(),
                          photoUrl: user.photoUrl,
                        );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Do you want to log out from this device?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Logout'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && context.mounted) {
      ref.read(appControllerProvider.notifier).logout();
      context.go(AppRoutes.roleSelection);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text(
          'This action is permanent. Your profile, saved Shootrs, and credits access will be removed.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(appControllerProvider.notifier).deleteCurrentAccount();
              Navigator.pop(context);
              context.go(AppRoutes.roleSelection);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ProfileNavTile extends StatelessWidget {
  const _ProfileNavTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Icon(PhosphorIcons.caretRight()),
        ],
      ),
    );
  }
}

class _NotificationSwitch extends StatelessWidget {
  const _NotificationSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      activeThumbColor: AppColors.primary,
      activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 10),
      title: Text(title),
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
