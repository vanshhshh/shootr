import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/marketplace_catalog.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/network_avatar.dart';
import '../../../shared/widgets/primary_glow_button.dart';

IconData categoryIcon(String iconKey) {
  return switch (iconKey) {
    'forkKnife' => PhosphorIcons.forkKnife(),
    'rings' => PhosphorIcons.diamondsFour(),
    'cake' => PhosphorIcons.cake(),
    'rocket' => PhosphorIcons.rocketLaunch(),
    'buildings' => PhosphorIcons.buildings(),
    'graduationCap' => PhosphorIcons.graduationCap(),
    'package' => PhosphorIcons.package(),
    'sparkle' => PhosphorIcons.sparkle(),
    'barbell' => PhosphorIcons.barbell(),
    'musicNotes' => PhosphorIcons.musicNotes(),
    'houseLine' => PhosphorIcons.houseLine(),
    'pawPrint' => PhosphorIcons.pawPrint(),
    'gameController' => PhosphorIcons.gameController(),
    'bowlFood' => PhosphorIcons.bowlFood(),
    'baby' => PhosphorIcons.baby(),
    'camera' => PhosphorIcons.camera(),
    _ => PhosphorIcons.plusCircle(),
  };
}

class ShootrCategoryTile extends StatelessWidget {
  const ShootrCategoryTile({
    required this.category,
    super.key,
    this.selected = false,
    this.onTap,
  });

  final MarketplaceCategory category;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      borderColor: selected
          ? AppColors.primary.withValues(alpha: 0.7)
          : AppColors.glass,
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 80,
        height: 90,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.16)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: selected
                    ? const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x5500FF85),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ]
                    : const <BoxShadow>[],
              ),
              child: Center(
                child: Icon(
                  categoryIcon(category.iconKey),
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              category.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShootrSummaryCard extends StatelessWidget {
  const ShootrSummaryCard({
    required this.shootr,
    super.key,
    this.showPortfolioPreview = false,
    this.isSaved = false,
    this.onSaveToggle,
    this.onBookNow,
  });

  final AppUser shootr;
  final bool showPortfolioPreview;
  final bool isSaved;
  final VoidCallback? onSaveToggle;
  final VoidCallback? onBookNow;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () =>
          context.push('${AppRoutes.shootrPublicProfile}/${shootr.id}'),
      borderColor: shootr.availableNow
          ? AppColors.primary.withValues(alpha: 0.45)
          : AppColors.glass,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              NetworkAvatar(
                imageUrl: shootr.photoUrl,
                radius: 30,
                heroTag: 'shootr-${shootr.id}',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            shootr.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (shootr.verified)
                          Icon(
                            PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
                            color: AppColors.primary,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Icon(
                          PhosphorIcons.star(PhosphorIconsStyle.fill),
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          shootr.rating.toStringAsFixed(1),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppFormatters.distanceKm(shootr.distanceKm),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onSaveToggle,
                icon: Icon(
                  isSaved
                      ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                      : PhosphorIcons.heart(),
                  color: isSaved ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _TagChip(label: shootr.deviceType.label),
              _TagChip(label: shootr.deviceTier.label),
              _TagChip(label: shootr.level.label),
              _AvailabilityPill(isAvailable: shootr.availableNow),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            shootr.bio,
            maxLines: showPortfolioPreview ? 3 : 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (showPortfolioPreview && shootr.portfolio.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    shootr.portfolio[index],
                    width: 84,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemCount: shootr.portfolio.length.clamp(0, 3),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Text(
                '${AppFormatters.currency(shootr.hourlyRate, city: shootr.city, country: shootr.country)}/hr',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
              ),
              const Spacer(),
              PrimaryGlowButton(
                label: 'Request Shoot',
                onPressed:
                    onBookNow ?? () => context.push(AppRoutes.bookingFlow),
                isExpanded: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BookingStatusBadge extends StatelessWidget {
  const BookingStatusBadge({required this.status, super.key});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      BookingStatus.confirmed || BookingStatus.pending => AppColors.success,
      BookingStatus.active || BookingStatus.editing => const Color(0xFF4FA3FF),
      BookingStatus.completed ||
      BookingStatus.delivered => AppColors.textSecondary,
      BookingStatus.cancelled => AppColors.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class VaultReelTile extends StatelessWidget {
  const VaultReelTile({required this.reel, super.key});

  final DeliveredReel reel;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                reel.thumbnailUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            reel.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            AppFormatters.shortDate(reel.deliveredAt),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class ReviewComposerCard extends StatelessWidget {
  const ReviewComposerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
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
            itemBuilder: (context, index) =>
                const Icon(Icons.star_rounded, color: AppColors.primary),
            onRatingUpdate: (_) {},
          ),
          const SizedBox(height: 12),
          const TextField(
            maxLines: 3,
            decoration: InputDecoration(labelText: 'Write a review'),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final color = isAvailable ? AppColors.success : AppColors.textSecondary;
    final label = isAvailable ? 'Available Now' : 'Busy';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
