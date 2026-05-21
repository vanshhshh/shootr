import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

import '../../../app/constants/app_colors.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/marketplace_catalog.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_glow_button.dart';

class ClientVaultScreen extends ConsumerStatefulWidget {
  const ClientVaultScreen({super.key});

  @override
  ConsumerState<ClientVaultScreen> createState() => _ClientVaultScreenState();
}

class _ClientVaultScreenState extends ConsumerState<ClientVaultScreen> {
  String? _selectedShootrId;
  String? _selectedCategoryId;
  _VaultDateRange _dateRange = _VaultDateRange.all;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const AppScaffold(
        title: 'Shootr Vault',
        child: EmptyStateView(
          title: 'Sign in required',
          subtitle: 'Log in to view and manage your delivered reels.',
        ),
      );
    }

    final reels = user.deliveredReels;
    final shootrOptions = <String, String>{};
    for (final reel in reels) {
      shootrOptions[reel.shootrId] = reel.shootrName;
    }

    final filtered = reels.where((reel) {
      final byShootr = _selectedShootrId == null || reel.shootrId == _selectedShootrId;
      final byCategory = _selectedCategoryId == null || reel.categoryId == _selectedCategoryId;
      final byDate = switch (_dateRange) {
        _VaultDateRange.all => true,
        _VaultDateRange.last30Days =>
          reel.deliveredAt.isAfter(DateTime.now().subtract(const Duration(days: 30))),
        _VaultDateRange.last90Days =>
          reel.deliveredAt.isAfter(DateTime.now().subtract(const Duration(days: 90))),
      };
      return byShootr && byCategory && byDate;
    }).toList()
      ..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));

    return AppScaffold(
      title: 'Shootr Vault',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'All delivered reels in one place. Filter, preview, download, and share.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          _buildFilters(shootrOptions),
          const SizedBox(height: 16),
          if (reels.isEmpty)
            const EmptyStateView(
              title: 'No reels delivered yet',
              subtitle: 'Completed bookings will automatically appear in your Shootr Vault.',
            )
          else if (filtered.isEmpty)
            const EmptyStateView(
              title: 'No reels match these filters',
              subtitle: 'Try clearing one or more filters to see your full vault.',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (context, index) {
                final reel = filtered[index];
                return _VaultCard(
                  reel: reel,
                  onTap: () => _openPreview(reel),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFilters(Map<String, String> shootrOptions) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Filters', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _FilterChip(
                label: 'All Shootrs',
                selected: _selectedShootrId == null,
                onTap: () => setState(() => _selectedShootrId = null),
              ),
              ...shootrOptions.entries.map(
                (entry) => _FilterChip(
                  label: entry.value,
                  selected: _selectedShootrId == entry.key,
                  onTap: () => setState(() => _selectedShootrId = entry.key),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _FilterChip(
                label: 'All Categories',
                selected: _selectedCategoryId == null,
                onTap: () => setState(() => _selectedCategoryId = null),
              ),
              ...kMarketplaceCategories
                  .where((item) => item.id != 'other')
                  .map(
                    (category) => _FilterChip(
                      label: category.label,
                      selected: _selectedCategoryId == category.id,
                      onTap: () => setState(() => _selectedCategoryId = category.id),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _VaultDateRange.values
                .map(
                  (range) => _FilterChip(
                    label: range.label,
                    selected: _dateRange == range,
                    onTap: () => setState(() => _dateRange = range),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _openPreview(DeliveredReel reel) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VaultPreviewSheet(reel: reel),
    );
  }
}

class _VaultCard extends StatelessWidget {
  const _VaultCard({
    required this.reel,
    required this.onTap,
  });

  final DeliveredReel reel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: reel.thumbnailUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, _) => Shimmer.fromColors(
                  baseColor: AppColors.surfaceElevated,
                  highlightColor: AppColors.card,
                  child: Container(color: AppColors.surfaceElevated),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.surfaceElevated,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
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
          Text(reel.shootrName, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            AppFormatters.shortDate(reel.deliveredAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _VaultPreviewSheet extends StatefulWidget {
  const _VaultPreviewSheet({required this.reel});

  final DeliveredReel reel;

  @override
  State<_VaultPreviewSheet> createState() => _VaultPreviewSheetState();
}

class _VaultPreviewSheetState extends State<_VaultPreviewSheet> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl))
      ..initialize().then((_) {
        if (!mounted) {
          return;
        }
        _controller
          ..setLooping(true)
          ..play();
        setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.9,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: <Widget>[
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(widget.reel.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                '${widget.reel.shootrName} · ${AppFormatters.dateOnly(widget.reel.deliveredAt)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: _ready ? _controller.value.aspectRatio : 9 / 16,
                  child: _ready
                      ? VideoPlayer(_controller)
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
              const SizedBox(height: 16),
              PrimaryGlowButton(
                label: 'Download',
                onPressed: () => _toast('Download workflow ready for device file permissions wiring.'),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: () => _toast('Instagram share handoff is ready for native integration.'),
                    child: const Text('Share to Instagram'),
                  ),
                  OutlinedButton(
                    onPressed: () => _toast('TikTok share handoff is ready for native integration.'),
                    child: const Text('Share to TikTok'),
                  ),
                  OutlinedButton(
                    onPressed: () => _toast('WhatsApp share handoff is ready for native integration.'),
                    child: const Text('Share to WhatsApp'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _VaultDateRange { all, last30Days, last90Days }

extension on _VaultDateRange {
  String get label => switch (this) {
        _VaultDateRange.all => 'All Time',
        _VaultDateRange.last30Days => 'Last 30 Days',
        _VaultDateRange.last90Days => 'Last 90 Days',
      };
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Text(label),
      selectedColor: AppColors.primary.withValues(alpha: 0.16),
      backgroundColor: AppColors.surfaceElevated,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.stroke),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
