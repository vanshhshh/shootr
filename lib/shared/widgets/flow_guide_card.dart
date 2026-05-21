import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import 'glass_card.dart';
import 'primary_glow_button.dart';

class FlowGuideStep {
  const FlowGuideStep({
    required this.title,
    required this.subtitle,
    this.icon = Icons.check_circle_outline_rounded,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class FlowGuideCard extends StatelessWidget {
  const FlowGuideCard({
    required this.title,
    required this.subtitle,
    required this.steps,
    super.key,
    this.actionLabel,
    this.onAction,
    this.accentColor = AppColors.primary,
  });

  final String title;
  final String subtitle;
  final List<FlowGuideStep> steps;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderColor: accentColor.withValues(alpha: 0.38),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          ...steps.asMap().entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == steps.length - 1 ? 0 : 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.32),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        entry.value.icon,
                        size: 18,
                        color: accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          entry.value.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entry.value.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...<Widget>[
            const SizedBox(height: 16),
            SizedBox(
              width: 210,
              child: PrimaryGlowButton(
                label: actionLabel!,
                onPressed: onAction,
                isExpanded: false,
              ),
            ),
          ],
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
