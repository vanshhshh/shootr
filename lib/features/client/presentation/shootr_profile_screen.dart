import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/network_avatar.dart';
import '../../../shared/widgets/primary_glow_button.dart';

class ShootrPublicProfileScreen extends ConsumerWidget {
  const ShootrPublicProfileScreen({required this.shootrId, super.key});

  final String shootrId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final matches = state.shootrs.where((item) => item.id == shootrId).toList();
    final shootr = matches.isEmpty ? null : matches.first;
    final coverImage = shootr?.portfolio.isNotEmpty == true
        ? shootr!.portfolio.first
        : 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f';

    if (shootr == null) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: EmptyStateView(
              title: 'Shootr not found',
              subtitle: 'This creator may have gone offline or been removed.',
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: PrimaryGlowButton(
          label: 'Request Shoot',
          onPressed: () => context.push(AppRoutes.bookingFlow),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radius),
            child: Stack(
              children: <Widget>[
                Image.network(
                  coverImage,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: NetworkAvatar(
                    imageUrl: shootr.photoUrl,
                    radius: 36,
                    heroTag: 'shootr-${shootr.id}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  shootr.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (shootr.verified)
                Chip(
                  avatar: const Icon(
                    Icons.verified,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  label: const Text('Verified'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${shootr.rating}★ (${shootr.reviewCount})  •  ${shootr.distanceKm} km  •  ${shootr.city}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 6),
          Text('Active since ${AppFormatters.activeSince(shootr.activeSince)}'),
          const SizedBox(height: 16),
          GlassCard(
            child: Row(
              children: <Widget>[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: shootr.availableNow
                        ? AppColors.success
                        : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  shootr.availableNow
                      ? 'Available Now'
                      : 'Next available: 7:00 PM',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Bio', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text(shootr.bio, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
          Text('Portfolio', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shootr.portfolio.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radius),
              child: Image.network(shootr.portfolio[index], fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: _StatTile(
                  label: 'Total shoots',
                  value: '${shootr.totalShoots}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Reels delivered',
                  value: '${shootr.reelsDelivered}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  label: 'Repeat clients',
                  value: '${shootr.repeatClients}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Reviews', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...shootr.reviews.map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('${review.authorName}  •  ${review.rating}★'),
                    const SizedBox(height: 8),
                    Text(
                      review.comment,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Packages', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...state.packages.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            item.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppFormatters.currency(item.price, city: shootr.city),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Report received. Support will review this profile.',
                ),
              ),
            ),
            icon: const Icon(Icons.flag_outlined, color: AppColors.error),
            label: const Text('Report user'),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
