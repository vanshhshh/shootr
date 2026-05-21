import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/constants/app_colors.dart';
import 'glass_card.dart';
import 'primary_glow_button.dart';

class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.items = 4});

  final int items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surfaceElevated,
          highlightColor: AppColors.card,
          child: const GlassCard(
            child: SizedBox(
              height: 92,
              child: Row(
                children: <Widget>[
                  CircleAvatar(radius: 28, backgroundColor: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DecoratedBox(
                          decoration: BoxDecoration(color: Colors.white),
                          child: SizedBox(height: 14, width: 140),
                        ),
                        SizedBox(height: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(color: Colors.white),
                          child: SizedBox(height: 12, width: 90),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.title,
    required this.subtitle,
    super.key,
    this.actionLabel,
    this.onAction,
    this.icon = Icons.auto_awesome_outlined,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: <Widget>[
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 18),
              PrimaryGlowButton(
                label: actionLabel!,
                onPressed: onAction,
                isExpanded: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      title: 'Something went wrong',
      subtitle: message,
      actionLabel: 'Retry',
      onAction: onRetry,
      icon: Icons.warning_amber_rounded,
    );
  }
}
