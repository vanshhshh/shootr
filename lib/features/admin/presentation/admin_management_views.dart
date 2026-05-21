import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/constants/app_colors.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/marketplace_catalog.dart';
import '../../../shared/models/shootr_package.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_glow_button.dart';

class ShootrsAdminView extends ConsumerStatefulWidget {
  const ShootrsAdminView({super.key});

  @override
  ConsumerState<ShootrsAdminView> createState() => _ShootrsAdminViewState();
}

class _ShootrsAdminViewState extends ConsumerState<ShootrsAdminView> {
  AccountStatus? _statusFilter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);

    if (appState.isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: const <Widget>[SkeletonList(items: 5)],
      );
    }

    if (appState.errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: <Widget>[
          ErrorStateView(
            message: appState.errorMessage!,
            onRetry: ref.read(appControllerProvider.notifier).retryInitialization,
          ),
        ],
      );
    }

    final shootrs = appState.shootrs.where((shootr) {
      final query = _query.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          shootr.name.toLowerCase().contains(query) ||
          shootr.city.toLowerCase().contains(query) ||
          shootr.phone.toLowerCase().contains(query);
      final matchesStatus = _statusFilter == null || shootr.accountStatus == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList()
      ..sort((a, b) {
        if (a.accountStatus == AccountStatus.pendingReview &&
            b.accountStatus != AccountStatus.pendingReview) {
          return -1;
        }
        if (b.accountStatus == AccountStatus.pendingReview &&
            a.accountStatus != AccountStatus.pendingReview) {
          return 1;
        }
        return b.totalShoots.compareTo(a.totalShoots);
      });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text('Shootr Management', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Review applications, verify quality, and moderate creator accounts.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Search by name, city, or phone',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              AdminFilterChip(
                label: 'All',
                selected: _statusFilter == null,
                onTap: () => setState(() => _statusFilter = null),
              ),
              for (final status in <AccountStatus>[
                AccountStatus.pendingReview,
                AccountStatus.active,
                AccountStatus.suspended,
                AccountStatus.rejected,
                AccountStatus.banned,
              ])
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: AdminFilterChip(
                    label: status.label,
                    selected: _statusFilter == status,
                    onTap: () => setState(() => _statusFilter = status),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (shootrs.isEmpty)
          const EmptyStateView(
            title: 'No Shootrs match these filters',
            subtitle: 'Try a broader search or switch back to all statuses.',
            icon: Icons.manage_search_rounded,
          )
        else
          ...shootrs.map(
            (shootr) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AdminAvatar(imageUrl: shootr.photoUrl),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(shootr.name, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                '${shootr.city} · ${shootr.phone}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  AdminTag(label: shootr.deviceTier.label),
                                  AdminTag(label: shootr.deviceModel ?? 'Device pending'),
                                  AdminTag(label: '${shootr.rating.toStringAsFixed(1)}★'),
                                  AdminTag(label: '${shootr.totalShoots} shoots'),
                                  AdminTag(
                                    label: AppFormatters.compactCurrency(
                                      shootr.totalEarned,
                                      country: shootr.country,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        AdminStatusPill(
                          label: shootr.accountStatus.label,
                          color: accountStatusColor(shootr.accountStatus),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: () => _showShootrDetails(shootr, appState),
                          child: const Text('View details'),
                        ),
                        if (shootr.accountStatus != AccountStatus.active)
                          PrimaryGlowButton(
                            label: 'Approve',
                            onPressed: () => _applyShootrStatus(shootr, AccountStatus.active),
                            isExpanded: false,
                          ),
                        if (shootr.accountStatus == AccountStatus.active)
                          OutlinedButton(
                            onPressed: () => _applyShootrStatus(
                              shootr,
                              AccountStatus.suspended,
                              requiresReason: true,
                            ),
                            child: const Text('Suspend'),
                          ),
                        OutlinedButton(
                          onPressed: () => showAdminNotificationComposer(
                            context: context,
                            ref: ref,
                            targetRole: UserRole.shootr,
                            recipientName: shootr.name,
                            fallbackTitle: 'Shootr update',
                            fallbackBody:
                                'Please check your Shootr dashboard for the latest account update.',
                          ),
                          child: const Text('Notify'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _applyShootrStatus(
    AppUser shootr,
    AccountStatus status, {
    bool requiresReason = false,
  }) async {
    var reason = '';
    if (requiresReason) {
      final enteredReason = await showAdminReasonDialog(
        context: context,
        title: '${status.label} ${shootr.name}',
        hintText: 'Enter a reason for ${status.label.toLowerCase()}',
      );
      if (enteredReason == null) {
        return;
      }
      reason = enteredReason;
    }

    ref.read(appControllerProvider.notifier).updateShootrAdminStatus(
          shootrId: shootr.id,
          status: status,
          reason: reason,
        );

    if (!mounted) {
      return;
    }
    showAdminFeedback(context, '${shootr.name} marked as ${status.label}.');
  }

  Future<void> _showShootrDetails(AppUser shootr, AppState appState) async {
    final bookings = appState.bookings.where((item) => item.shootrId == shootr.id).toList();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const BottomSheetHandle(),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AdminAvatar(imageUrl: shootr.photoUrl, radius: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(shootr.name, style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 4),
                              Text(
                                '${shootr.city} · ${shootr.phone}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  AdminStatusPill(
                                    label: shootr.accountStatus.label,
                                    color: accountStatusColor(shootr.accountStatus),
                                  ),
                                  AdminTag(label: shootr.level.label),
                                  AdminTag(label: shootr.deviceTier.label),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AdminSectionCard(
                      title: 'Profile',
                      child: Column(
                        children: <Widget>[
                          AdminInfoRow(label: 'Device', value: shootr.deviceModel ?? 'Pending'),
                          AdminInfoRow(
                            label: 'Camera',
                            value: shootr.deviceCameraSpec.ifEmpty('Awaiting verification'),
                          ),
                          AdminInfoRow(label: 'Aadhaar status', value: shootr.identityStatus.label),
                          AdminInfoRow(
                            label: 'Device verification',
                            value: shootr.deviceVerificationStatus.label,
                          ),
                          AdminInfoRow(
                            label: 'Pricing',
                            value: AppFormatters.currency(shootr.hourlyRate, country: shootr.country),
                          ),
                          AdminInfoRow(
                            label: 'Bio',
                            value: shootr.bio.ifEmpty('No bio provided yet.'),
                            isMultiline: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AdminSectionCard(
                      title: 'Specialisations',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: shootr.specialisationIds.isEmpty
                            ? const <Widget>[Text('No specialisations selected yet.')]
                            : shootr.specialisationIds
                                .map((item) => AdminTag(label: categoryLabel(item)))
                                .toList(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AdminSectionCard(
                      title: 'Portfolio',
                      child: shootr.portfolio.isEmpty
                          ? const Text('Portfolio not uploaded yet.')
                          : SizedBox(
                              height: 96,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: shootr.portfolio.length,
                                separatorBuilder: (_, _) => const SizedBox(width: 10),
                                itemBuilder: (context, index) =>
                                    AdminMediaTile(imageUrl: shootr.portfolio[index]),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    AdminSectionCard(
                      title: 'Earnings summary',
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: <Widget>[
                          MiniMetricCard(
                            label: 'Total earned',
                            value: AppFormatters.compactCurrency(
                              shootr.totalEarned,
                              country: shootr.country,
                            ),
                          ),
                          MiniMetricCard(label: 'Total shoots', value: '${shootr.totalShoots}'),
                          MiniMetricCard(
                            label: 'Completion',
                            value: AppFormatters.percent(shootr.completionRate),
                          ),
                          MiniMetricCard(
                            label: 'On-time',
                            value: AppFormatters.percent(shootr.onTimeRate),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AdminSectionCard(
                      title: 'Booking history',
                      child: bookings.isEmpty
                          ? const Text('No bookings yet.')
                          : Column(
                              children: bookings
                                  .map(
                                    (booking) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: AdminSimpleListTile(
                                        title: booking.id,
                                        subtitle:
                                            '${booking.clientName} · ${booking.status.label} · ${AppFormatters.dateTime(booking.scheduledAt)}',
                                        trailing: AppFormatters.currency(booking.totalAmount),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    AdminSectionCard(
                      title: 'Reviews',
                      child: shootr.reviews.isEmpty
                          ? const Text('No reviews yet.')
                          : Column(
                              children: shootr.reviews
                                  .map(
                                    (review) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: AdminSimpleListTile(
                                        title: '${review.authorName} · ${review.rating.toStringAsFixed(1)}★',
                                        subtitle: review.comment,
                                        trailing: AppFormatters.shortDate(review.createdAt),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        if (shootr.accountStatus != AccountStatus.active)
                          PrimaryGlowButton(
                            label: 'Approve',
                            onPressed: () async {
                              Navigator.pop(sheetContext);
                              await _applyShootrStatus(shootr, AccountStatus.active);
                            },
                            isExpanded: false,
                          ),
                        OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            await _applyShootrStatus(
                              shootr,
                              AccountStatus.rejected,
                              requiresReason: true,
                            );
                          },
                          child: const Text('Reject'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            await _applyShootrStatus(
                              shootr,
                              AccountStatus.suspended,
                              requiresReason: true,
                            );
                          },
                          child: const Text('Suspend'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            await _applyShootrStatus(
                              shootr,
                              AccountStatus.banned,
                              requiresReason: true,
                            );
                          },
                          child: const Text('Ban'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            showAdminNotificationComposer(
                              context: context,
                              ref: ref,
                              targetRole: UserRole.shootr,
                              recipientName: shootr.name,
                              fallbackTitle: 'Shootr update',
                              fallbackBody:
                                  'Please check your Shootr dashboard for the latest account update.',
                            );
                          },
                          child: const Text('Send notification'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ClientsAdminView extends ConsumerStatefulWidget {
  const ClientsAdminView({super.key});

  @override
  ConsumerState<ClientsAdminView> createState() => _ClientsAdminViewState();
}

class _ClientsAdminViewState extends ConsumerState<ClientsAdminView> {
  AccountStatus? _statusFilter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);

    if (appState.isLoading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: const <Widget>[SkeletonList(items: 4)],
      );
    }

    final clients = appState.clients.where((client) {
      final query = _query.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          client.name.toLowerCase().contains(query) ||
          client.city.toLowerCase().contains(query) ||
          client.phone.toLowerCase().contains(query);
      final matchesStatus = _statusFilter == null || client.accountStatus == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList()
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text('Client Management', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Inspect booking history, wallet health, and account safety actions.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Search by name, city, or phone',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              AdminFilterChip(
                label: 'All',
                selected: _statusFilter == null,
                onTap: () => setState(() => _statusFilter = null),
              ),
              for (final status in <AccountStatus>[
                AccountStatus.active,
                AccountStatus.flagged,
                AccountStatus.warned,
                AccountStatus.banned,
              ])
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: AdminFilterChip(
                    label: status.label,
                    selected: _statusFilter == status,
                    onTap: () => setState(() => _statusFilter = status),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (clients.isEmpty)
          const EmptyStateView(
            title: 'No clients found',
            subtitle: 'Try a different search or filter combination.',
            icon: Icons.people_alt_outlined,
          )
        else
          ...clients.map(
            (client) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AdminAvatar(imageUrl: client.photoUrl),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(client.name, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                '${client.city} · ${client.phone}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  AdminTag(
                                    label:
                                        '${appState.bookings.where((item) => item.clientId == client.id).length} bookings',
                                  ),
                                  AdminTag(label: AppFormatters.currency(client.totalSpent)),
                                  AdminTag(label: '${client.creditsBalance} credits'),
                                  AdminTag(label: client.referralCode.ifEmpty('No referral code')),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        AdminStatusPill(
                          label: client.accountStatus.label,
                          color: accountStatusColor(client.accountStatus),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: () => _showClientDetails(client, appState),
                          child: const Text('View details'),
                        ),
                        OutlinedButton(
                          onPressed: () => _applyClientStatus(
                            client,
                            AccountStatus.warned,
                            requiresReason: true,
                          ),
                          child: const Text('Warn'),
                        ),
                        OutlinedButton(
                          onPressed: () => _applyClientStatus(
                            client,
                            AccountStatus.banned,
                            requiresReason: true,
                          ),
                          child: const Text('Ban'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _applyClientStatus(
    AppUser client,
    AccountStatus status, {
    bool requiresReason = false,
  }) async {
    var reason = '';
    if (requiresReason) {
      final enteredReason = await showAdminReasonDialog(
        context: context,
        title: '${status.label} ${client.name}',
        hintText: 'Enter a reason for ${status.label.toLowerCase()}',
      );
      if (enteredReason == null) {
        return;
      }
      reason = enteredReason;
    }

    ref.read(appControllerProvider.notifier).updateClientAdminStatus(
          clientId: client.id,
          status: status,
          reason: reason,
        );

    if (!mounted) {
      return;
    }
    showAdminFeedback(context, '${client.name} marked as ${status.label}.');
  }

  Future<void> _showClientDetails(AppUser client, AppState appState) async {
    final bookings = appState.bookings.where((item) => item.clientId == client.id).toList();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const BottomSheetHandle(),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AdminAvatar(imageUrl: client.photoUrl, radius: 36),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(client.name, style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 4),
                              Text(
                                '${client.city} · ${client.phone}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 10),
                              AdminStatusPill(
                                label: client.accountStatus.label,
                                color: accountStatusColor(client.accountStatus),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AdminSectionCard(
                      title: 'Profile info',
                      child: Column(
                        children: <Widget>[
                          AdminInfoRow(label: 'Referral code', value: client.referralCode.ifEmpty('Not assigned')),
                          AdminInfoRow(label: 'Credits balance', value: '${client.creditsBalance}'),
                          AdminInfoRow(
                            label: 'Wallet balance',
                            value: AppFormatters.currency(client.walletBalance, country: client.country),
                          ),
                          AdminInfoRow(
                            label: 'Total spent',
                            value: AppFormatters.currency(client.totalSpent, country: client.country),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AdminSectionCard(
                      title: 'Booking history',
                      child: bookings.isEmpty
                          ? const Text('No bookings yet.')
                          : Column(
                              children: bookings
                                  .map(
                                    (booking) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: AdminSimpleListTile(
                                        title: booking.id,
                                        subtitle:
                                            '${booking.shootrName} · ${booking.status.label} · ${AppFormatters.dateTime(booking.scheduledAt)}',
                                        trailing: AppFormatters.currency(booking.totalAmount),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    AdminSectionCard(
                      title: 'Wallet & credits',
                      child: client.walletTransactions.isEmpty
                          ? const Text('No wallet transactions yet.')
                          : Column(
                              children: client.walletTransactions
                                  .map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: AdminSimpleListTile(
                                        title: item.title,
                                        subtitle: '${item.subtitle} · ${AppFormatters.shortDate(item.createdAt)}',
                                        trailing: item.isCredit
                                            ? '+${item.amount.toStringAsFixed(0)}'
                                            : '-${item.amount.toStringAsFixed(0)}',
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 12),
                    AdminSectionCard(
                      title: 'Reviews given',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Reviews submitted: ${client.reviewCount}'),
                          const SizedBox(height: 4),
                          Text('Average rating given: ${client.rating.toStringAsFixed(1)}★'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            await _applyClientStatus(
                              client,
                              AccountStatus.flagged,
                              requiresReason: true,
                            );
                          },
                          child: const Text('Flag'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            await _applyClientStatus(
                              client,
                              AccountStatus.warned,
                              requiresReason: true,
                            );
                          },
                          child: const Text('Warn'),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(sheetContext);
                            await _applyClientStatus(
                              client,
                              AccountStatus.banned,
                              requiresReason: true,
                            );
                          },
                          child: const Text('Ban'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            showAdminNotificationComposer(
                              context: context,
                              ref: ref,
                              targetRole: UserRole.client,
                              recipientName: client.name,
                              fallbackTitle: 'Shootr account update',
                              fallbackBody: 'Please review the latest update in your Shootr account.',
                            );
                          },
                          child: const Text('Notify'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BookingsAdminView extends ConsumerStatefulWidget {
  const BookingsAdminView({super.key});

  @override
  ConsumerState<BookingsAdminView> createState() => _BookingsAdminViewState();
}

class _BookingsAdminViewState extends ConsumerState<BookingsAdminView> {
  BookingStatus? _statusFilter;
  String? _cityFilter;
  ShootrPackageType? _packageFilter;
  AdminDateRange _dateRange = AdminDateRange.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appControllerProvider);
    final cities = appState.bookings.map((item) => item.location.city).toSet().toList()..sort();

    final bookings = appState.bookings.where((booking) {
      final query = _query.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          booking.id.toLowerCase().contains(query) ||
          booking.clientName.toLowerCase().contains(query) ||
          booking.shootrName.toLowerCase().contains(query);
      final matchesStatus = _statusFilter == null || booking.status == _statusFilter;
      final matchesCity = _cityFilter == null || booking.location.city == _cityFilter;
      final matchesPackage = _packageFilter == null || booking.packageType == _packageFilter;
      final matchesDate = switch (_dateRange) {
        AdminDateRange.all => true,
        AdminDateRange.today => isSameDate(booking.scheduledAt, DateTime.now()),
        AdminDateRange.week => booking.scheduledAt.isAfter(DateTime.now().subtract(const Duration(days: 7))),
        AdminDateRange.month => booking.scheduledAt.isAfter(DateTime.now().subtract(const Duration(days: 30))),
      };
      return matchesQuery && matchesStatus && matchesCity && matchesPackage && matchesDate;
    }).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text('Booking Management', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Filter by lifecycle, inspect transcripts, and resolve disputes or refunds.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            hintText: 'Search by booking ID, client, or Shootr',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            AdminFilterChip(
              label: 'All statuses',
              selected: _statusFilter == null,
              onTap: () => setState(() => _statusFilter = null),
            ),
            for (final status in BookingStatus.values)
              AdminFilterChip(
                label: status.label,
                selected: _statusFilter == status,
                onTap: () => setState(() => _statusFilter = status),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            AdminFilterChip(
              label: 'All cities',
              selected: _cityFilter == null,
              onTap: () => setState(() => _cityFilter = null),
            ),
            for (final city in cities)
              AdminFilterChip(
                label: city,
                selected: _cityFilter == city,
                onTap: () => setState(() => _cityFilter = city),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            AdminFilterChip(
              label: 'All packages',
              selected: _packageFilter == null,
              onTap: () => setState(() => _packageFilter = null),
            ),
            for (final package in ShootrPackageType.values)
              AdminFilterChip(
                label: package.label,
                selected: _packageFilter == package,
                onTap: () => setState(() => _packageFilter = package),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final range in AdminDateRange.values)
              AdminFilterChip(
                label: range.label,
                selected: _dateRange == range,
                onTap: () => setState(() => _dateRange = range),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (bookings.isEmpty)
          const EmptyStateView(
            title: 'No bookings found',
            subtitle: 'Adjust the filters to widen the result set.',
            icon: Icons.receipt_long_outlined,
          )
        else
          ...bookings.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(booking.id, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 4),
                              Text(
                                '${booking.clientName} → ${booking.shootrName}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <Widget>[
                                  AdminTag(label: categoryLabel(booking.categoryId)),
                                  AdminTag(label: booking.location.city),
                                  AdminTag(label: booking.packageType.label),
                                  AdminTag(label: AppFormatters.dateTime(booking.scheduledAt)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            AdminStatusPill(
                              label: booking.status.label,
                              color: bookingStatusColor(booking.status),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppFormatters.currency(booking.totalAmount),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        OutlinedButton(
                          onPressed: () => _showBookingDetails(booking, appState),
                          child: const Text('View details'),
                        ),
                        if (booking.refundStatus == RefundStatus.pending)
                          PrimaryGlowButton(
                            label: 'Resolve refund',
                            onPressed: () => _showBookingDetails(booking, appState),
                            isExpanded: false,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showBookingDetails(Booking booking, AppState appState) async {
    final notesController = TextEditingController();
    final reel = findDeliveredReel(appState, booking.id);
    var issueType = 'Refund';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.92,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const BottomSheetHandle(),
                        const SizedBox(height: 18),
                        Text(booking.id, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          '${booking.clientName} → ${booking.shootrName}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        AdminSectionCard(
                          title: 'Booking info',
                          child: Column(
                            children: <Widget>[
                              AdminInfoRow(label: 'Category', value: categoryLabel(booking.categoryId)),
                              AdminInfoRow(label: 'Package', value: booking.packageType.label),
                              AdminInfoRow(label: 'Schedule', value: AppFormatters.dateTime(booking.scheduledAt)),
                              AdminInfoRow(label: 'Location', value: booking.location.address, isMultiline: true),
                              AdminInfoRow(label: 'Status', value: booking.status.label),
                              AdminInfoRow(label: 'Payment', value: booking.paymentMethod),
                              AdminInfoRow(label: 'Refund', value: booking.refundStatus.name.replaceAll('_', ' ')),
                              AdminInfoRow(label: 'Notes', value: booking.notes.ifEmpty('No notes'), isMultiline: true),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AdminSectionCard(
                          title: 'Payment breakdown',
                          child: Column(
                            children: <Widget>[
                              AdminInfoRow(label: 'Base', value: AppFormatters.currency(booking.baseAmount)),
                              AdminInfoRow(label: 'Platform fee', value: AppFormatters.currency(booking.platformFee)),
                              AdminInfoRow(label: 'Tax', value: AppFormatters.currency(booking.taxAmount)),
                              AdminInfoRow(label: 'Credits used', value: '${booking.creditsUsed}'),
                              AdminInfoRow(label: 'Total', value: AppFormatters.currency(booking.totalAmount)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        AdminSectionCard(
                          title: 'Chat transcript',
                          child: (appState.chatThreads[booking.id] ?? const <dynamic>[])
                                  .isEmpty
                              ? const Text('No chat messages yet.')
                              : Column(
                                  children: (appState.chatThreads[booking.id] ?? const <dynamic>[])
                                      .map<Widget>(
                                        (message) => Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: AdminSimpleListTile(
                                            title: message.senderName,
                                            subtitle:
                                                '${message.body} · ${AppFormatters.time(message.sentAt)}',
                                            trailing: message.type.name,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                        ),
                        const SizedBox(height: 12),
                        AdminSectionCard(
                          title: 'Delivered reel',
                          child: reel == null
                              ? const Text('No reel delivered for this booking yet.')
                              : Row(
                                  children: <Widget>[
                                    AdminMediaTile(imageUrl: reel.thumbnailUrl, size: 88),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(reel.title, style: Theme.of(context).textTheme.titleMedium),
                                          const SizedBox(height: 6),
                                          Text('Delivered ${AppFormatters.shortDate(reel.deliveredAt)}'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 12),
                        AdminSectionCard(
                          title: 'Dispute & refund panel',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: <String>['Refund', 'Quality', 'Delay', 'Safety', 'No-show']
                                    .map(
                                      (item) => AdminFilterChip(
                                        label: item,
                                        selected: issueType == item,
                                        onTap: () => setModalState(() => issueType = item),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: notesController,
                                minLines: 3,
                                maxLines: 5,
                                decoration: const InputDecoration(
                                  labelText: 'Resolution notes',
                                  hintText: 'Enter the admin resolution and next steps',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: <Widget>[
                                  OutlinedButton(
                                    onPressed: () async {
                                      await ref.read(appControllerProvider.notifier).resolveBookingIssue(
                                            bookingId: booking.id,
                                            issueType: issueType,
                                            refundStatus: RefundStatus.rejected,
                                            paymentStatus: booking.paymentStatus,
                                            resolutionNote: notesController.text.trim(),
                                          );
                                      if (!sheetContext.mounted || !context.mounted) {
                                        return;
                                      }
                                      Navigator.of(sheetContext).pop();
                                      showAdminFeedback(context, 'Issue marked as rejected.');
                                    },
                                    child: const Text('Reject'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () async {
                                      await ref.read(appControllerProvider.notifier).resolveBookingIssue(
                                            bookingId: booking.id,
                                            issueType: issueType,
                                            refundStatus: RefundStatus.partial,
                                            paymentStatus: PaymentStatus.partialRefund,
                                            resolutionNote: notesController.text.trim(),
                                          );
                                      if (!sheetContext.mounted || !context.mounted) {
                                        return;
                                      }
                                      Navigator.of(sheetContext).pop();
                                      showAdminFeedback(context, 'Partial refund approved.');
                                    },
                                    child: const Text('Partial refund'),
                                  ),
                                  PrimaryGlowButton(
                                    label: 'Approve refund',
                                    onPressed: () async {
                                      await ref.read(appControllerProvider.notifier).resolveBookingIssue(
                                            bookingId: booking.id,
                                            issueType: issueType,
                                            refundStatus: RefundStatus.approved,
                                            paymentStatus: PaymentStatus.refunded,
                                            resolutionNote: notesController.text.trim(),
                                          );
                                      if (!sheetContext.mounted || !context.mounted) {
                                        return;
                                      }
                                      Navigator.of(sheetContext).pop();
                                      showAdminFeedback(context, 'Refund approved.');
                                    },
                                    isExpanded: false,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    notesController.dispose();
  }
}

class PricingAdminView extends StatefulWidget {
  const PricingAdminView({super.key});

  @override
  State<PricingAdminView> createState() => _PricingAdminViewState();
}

class _PricingAdminViewState extends State<PricingAdminView> {
  double _platformFee = 5;
  bool _surge = true;
  double _surgeMultiplier = 1.5;
  bool _indiaTax = true;
  bool _uaeTax = true;
  bool _usaTax = true;
  final List<CityPricing> _cityPricing = <CityPricing>[
    const CityPricing(city: 'Mumbai', country: AppCountry.india, basic: 1999, pro: 3499, luxe: 5999),
    const CityPricing(city: 'Delhi', country: AppCountry.india, basic: 1899, pro: 3299, luxe: 5799),
    const CityPricing(city: 'Dubai', country: AppCountry.uae, basic: 199, pro: 349, luxe: 599),
    const CityPricing(city: 'New York', country: AppCountry.usa, basic: 49, pro: 89, luxe: 149),
  ];
  final List<PromoCodeDraft> _promoCodes = <PromoCodeDraft>[
    PromoCodeDraft(
      code: 'LAUNCH10',
      discountPercent: 10,
      maxUses: 500,
      used: 132,
      minBookingValue: 1999,
      expiryDate: DateTime.now().add(const Duration(days: 30)),
      active: true,
    ),
    PromoCodeDraft(
      code: 'WEEKEND15',
      discountPercent: 15,
      maxUses: 250,
      used: 94,
      minBookingValue: 3499,
      expiryDate: DateTime.now().add(const Duration(days: 14)),
      active: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text('Pricing Management', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Control fees, taxes, city pricing, surge settings, and promo code behaviour.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Platform fee', style: Theme.of(context).textTheme.titleLarge),
              Slider(
                value: _platformFee,
                min: 1,
                max: 12,
                divisions: 11,
                label: '${_platformFee.toStringAsFixed(0)}%',
                onChanged: (value) => setState(() => _platformFee = value),
              ),
              Text('Current fee: ${_platformFee.toStringAsFixed(0)}%'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Taxes by country', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _indiaTax,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                title: const Text('India GST'),
                onChanged: (value) => setState(() => _indiaTax = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _uaeTax,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                title: const Text('UAE VAT'),
                onChanged: (value) => setState(() => _uaeTax = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _usaTax,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                title: const Text('USA Tax'),
                onChanged: (value) => setState(() => _usaTax = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Surge pricing', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        const Text('Enable peak-hour and event-based dynamic pricing.'),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _surge,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.35),
                    onChanged: (value) => setState(() => _surge = value),
                  ),
                ],
              ),
              if (_surge) ...<Widget>[
                const SizedBox(height: 12),
                Text('Multiplier', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <double>[1.2, 1.5, 2]
                      .map(
                        (value) => AdminFilterChip(
                          label: '${value.toStringAsFixed(1)}x',
                          selected: _surgeMultiplier == value,
                          onTap: () => setState(() => _surgeMultiplier = value),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                const Text('Active hours: 06:00 PM – 11:00 PM'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('City-wise base pricing', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ..._cityPricing.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(entry.value.city, style: Theme.of(context).textTheme.titleLarge),
                      ),
                      AdminTag(label: entry.value.country.label),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Basic ${AppFormatters.currency(entry.value.basic, country: entry.value.country)} · '
                    'Pro ${AppFormatters.currency(entry.value.pro, country: entry.value.country)} · '
                    'Luxe ${AppFormatters.currency(entry.value.luxe, country: entry.value.country)}',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => _editCityPricing(entry.key),
                    child: const Text('Edit city pricing'),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: Text('Promo codes', style: Theme.of(context).textTheme.titleLarge),
            ),
            PrimaryGlowButton(
              label: 'Create promo code',
              onPressed: _createPromoCode,
              isExpanded: false,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._promoCodes.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(entry.value.code, style: Theme.of(context).textTheme.titleLarge),
                      ),
                      AdminStatusPill(
                        label: entry.value.active ? 'Active' : 'Paused',
                        color: entry.value.active ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${entry.value.discountPercent}% off · ${entry.value.used}/${entry.value.maxUses} uses · '
                    'Min ${AppFormatters.currency(entry.value.minBookingValue)}',
                  ),
                  const SizedBox(height: 4),
                  Text('Expires ${AppFormatters.dateOnly(entry.value.expiryDate)}'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _promoCodes[entry.key] =
                            entry.value.copyWith(active: !entry.value.active);
                      });
                    },
                    child: Text(entry.value.active ? 'Pause' : 'Activate'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editCityPricing(int index) async {
    var draft = _cityPricing[index];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Edit ${draft.city}', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    Text('Basic', style: Theme.of(context).textTheme.titleMedium),
                    Slider(
                      value: draft.basic,
                      min: draft.country == AppCountry.india ? 999 : 29,
                      max: draft.country == AppCountry.india ? 7999 : 299,
                      divisions: 40,
                      label: AppFormatters.currency(draft.basic, country: draft.country),
                      onChanged: (value) => setModalState(() => draft = draft.copyWith(basic: value)),
                    ),
                    Text('Pro', style: Theme.of(context).textTheme.titleMedium),
                    Slider(
                      value: draft.pro,
                      min: draft.country == AppCountry.india ? 1999 : 49,
                      max: draft.country == AppCountry.india ? 9999 : 399,
                      divisions: 40,
                      label: AppFormatters.currency(draft.pro, country: draft.country),
                      onChanged: (value) => setModalState(() => draft = draft.copyWith(pro: value)),
                    ),
                    Text('Luxe', style: Theme.of(context).textTheme.titleMedium),
                    Slider(
                      value: draft.luxe,
                      min: draft.country == AppCountry.india ? 2999 : 79,
                      max: draft.country == AppCountry.india ? 12999 : 499,
                      divisions: 40,
                      label: AppFormatters.currency(draft.luxe, country: draft.country),
                      onChanged: (value) => setModalState(() => draft = draft.copyWith(luxe: value)),
                    ),
                    const SizedBox(height: 12),
                    PrimaryGlowButton(
                      label: 'Save city pricing',
                      onPressed: () {
                        setState(() => _cityPricing[index] = draft);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createPromoCode() async {
    final codeController = TextEditingController();
    final discountController = TextEditingController(text: '10');
    final maxUsesController = TextEditingController(text: '100');
    final minBookingController = TextEditingController(text: '1999');
    var expiryDate = DateTime.now().add(const Duration(days: 30));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Create promo code', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(labelText: 'Code'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: discountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Discount %'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: maxUsesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max uses'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: minBookingController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Minimum booking value'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDate: expiryDate,
                        );
                        if (pickedDate != null) {
                          setModalState(() => expiryDate = pickedDate);
                        }
                      },
                      child: Text('Expiry: ${AppFormatters.dateOnly(expiryDate)}'),
                    ),
                    const SizedBox(height: 16),
                    PrimaryGlowButton(
                      label: 'Save promo code',
                      onPressed: () {
                        setState(() {
                          _promoCodes.insert(
                            0,
                            PromoCodeDraft(
                              code: codeController.text.trim().toUpperCase().ifEmpty('NEWCODE'),
                              discountPercent: int.tryParse(discountController.text.trim()) ?? 10,
                              maxUses: int.tryParse(maxUsesController.text.trim()) ?? 100,
                              used: 0,
                              minBookingValue:
                                  double.tryParse(minBookingController.text.trim()) ?? 1999,
                              expiryDate: expiryDate,
                              active: true,
                            ),
                          );
                        });
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    codeController.dispose();
    discountController.dispose();
    maxUsesController.dispose();
    minBookingController.dispose();
  }
}

class NotificationsAdminView extends ConsumerStatefulWidget {
  const NotificationsAdminView({super.key});

  @override
  ConsumerState<NotificationsAdminView> createState() => _NotificationsAdminViewState();
}

class _NotificationsAdminViewState extends ConsumerState<NotificationsAdminView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _deepLinkController = TextEditingController();
  NotificationAudience _audience = NotificationAudience.allUsers;
  DateTime? _scheduledAt;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _deepLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(appControllerProvider).notifications;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text('Notifications Center', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Broadcast product updates, market nudges, and urgent account communication.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Send push notification', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: NotificationAudience.values
                    .map(
                      (audience) => AdminFilterChip(
                        label: audience.label,
                        selected: _audience == audience,
                        onTap: () => setState(() => _audience = audience),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _bodyController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Body'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _deepLinkController,
                decoration: const InputDecoration(labelText: 'Optional deep link'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _pickSchedule,
                child: Text(
                  _scheduledAt == null
                      ? 'Schedule for later'
                      : 'Scheduled: ${AppFormatters.dateTime(_scheduledAt!)}',
                ),
              ),
              const SizedBox(height: 16),
              PrimaryGlowButton(
                label: _scheduledAt == null ? 'Send now' : 'Queue notification',
                onPressed: _sendNotification,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Sent history', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (notifications.isEmpty)
          const EmptyStateView(
            title: 'No notifications yet',
            subtitle: 'Campaigns and account messages will appear here once sent.',
            icon: Icons.notifications_off_outlined,
          )
        else
          ...notifications.take(12).map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.primary.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text(item.body),
                          const SizedBox(height: 8),
                          Text(
                            '${item.targetRole.label} · ${AppFormatters.dateTime(item.createdAt)}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const AdminTag(label: '98% delivery'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _scheduledAt ?? DateTime.now(),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? DateTime.now()),
    );
    if (time == null || !mounted) {
      return;
    }

    setState(() {
      _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _sendNotification() {
    final title = _titleController.text.trim().ifEmpty('Shootr update');
    final body = _bodyController.text.trim().ifEmpty('There is a new update waiting for you.');
    final deepLink = _deepLinkController.text.trim();
    final composedBody = deepLink.isEmpty ? body : '$body\nDeep link: $deepLink';
    final controller = ref.read(appControllerProvider.notifier);

    final roles = switch (_audience) {
      NotificationAudience.allUsers => <UserRole>[
          UserRole.client,
          UserRole.shootr,
          UserRole.admin,
        ],
      NotificationAudience.clients => <UserRole>[UserRole.client],
      NotificationAudience.shootrs => <UserRole>[UserRole.shootr],
      NotificationAudience.admins => <UserRole>[UserRole.admin],
    };

    for (final role in roles) {
      controller.sendAdminNotification(
        targetRole: role,
        title: title,
        body: composedBody,
      );
    }

    showAdminFeedback(
      context,
      _scheduledAt == null
          ? 'Notification sent to ${_audience.label.toLowerCase()}.'
          : 'Notification queued for ${AppFormatters.dateTime(_scheduledAt!)}.',
    );

    setState(() {
      _titleController.clear();
      _bodyController.clear();
      _deepLinkController.clear();
      _scheduledAt = null;
    });
  }
}

void showAdminFeedback(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<String?> showAdminReasonDialog({
  required BuildContext context,
  required String title,
  required String hintText,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(hintText: hintText),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          PrimaryGlowButton(
            label: 'Save reason',
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            isExpanded: false,
          ),
        ],
      );
    },
  );
  controller.dispose();
  return result;
}

Future<void> showAdminNotificationComposer({
  required BuildContext context,
  required WidgetRef ref,
  required UserRole targetRole,
  required String recipientName,
  required String fallbackTitle,
  required String fallbackBody,
}) async {
  final titleController = TextEditingController(text: 'Update for $recipientName');
  final bodyController = TextEditingController();

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
        ),
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Send notification', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Body'),
              ),
              const SizedBox(height: 16),
              PrimaryGlowButton(
                label: 'Send now',
                onPressed: () {
                  ref.read(appControllerProvider.notifier).sendAdminNotification(
                        targetRole: targetRole,
                        title: titleController.text.trim().ifEmpty(fallbackTitle),
                        body: bodyController.text.trim().ifEmpty(fallbackBody),
                      );
                  Navigator.pop(sheetContext);
                  showAdminFeedback(context, 'Notification queued.');
                },
              ),
            ],
          ),
        ),
      );
    },
  );

  titleController.dispose();
  bodyController.dispose();
}

Color accountStatusColor(AccountStatus status) {
  return switch (status) {
    AccountStatus.active => AppColors.primary,
    AccountStatus.pendingReview => AppColors.warning,
    AccountStatus.flagged => const Color(0xFFFF9F43),
    AccountStatus.warned => const Color(0xFFFFC857),
    AccountStatus.suspended => const Color(0xFFFF6B6B),
    AccountStatus.rejected => const Color(0xFFFF6B6B),
    AccountStatus.banned => AppColors.error,
  };
}

Color bookingStatusColor(BookingStatus status) {
  return switch (status) {
    BookingStatus.pending => AppColors.warning,
    BookingStatus.confirmed => AppColors.primary,
    BookingStatus.active => const Color(0xFF4FA3FF),
    BookingStatus.editing => const Color(0xFFFFC857),
    BookingStatus.delivered => const Color(0xFF7EE081),
    BookingStatus.completed => AppColors.textSecondary,
    BookingStatus.cancelled => AppColors.error,
  };
}

String categoryLabel(String categoryId) {
  return kMarketplaceCategories
      .firstWhere(
        (item) => item.id == categoryId,
        orElse: () => const MarketplaceCategory(
          id: 'other',
          label: 'Other',
          emoji: '',
          iconKey: 'plusCircle',
        ),
      )
      .label;
}

bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DeliveredReel? findDeliveredReel(AppState state, String bookingId) {
  for (final client in state.clients) {
    for (final reel in client.deliveredReels) {
      if (reel.bookingId == bookingId) {
        return reel;
      }
    }
  }
  return null;
}

enum AdminDateRange { all, today, week, month }

extension AdminDateRangeX on AdminDateRange {
  String get label => switch (this) {
        AdminDateRange.all => 'All time',
        AdminDateRange.today => 'Today',
        AdminDateRange.week => 'Last 7 days',
        AdminDateRange.month => 'Last 30 days',
      };
}

enum NotificationAudience { allUsers, clients, shootrs, admins }

extension NotificationAudienceX on NotificationAudience {
  String get label => switch (this) {
        NotificationAudience.allUsers => 'All users',
        NotificationAudience.clients => 'All clients',
        NotificationAudience.shootrs => 'All Shootrs',
        NotificationAudience.admins => 'Admins',
      };
}

class CityPricing {
  const CityPricing({
    required this.city,
    required this.country,
    required this.basic,
    required this.pro,
    required this.luxe,
  });

  final String city;
  final AppCountry country;
  final double basic;
  final double pro;
  final double luxe;

  CityPricing copyWith({
    double? basic,
    double? pro,
    double? luxe,
  }) {
    return CityPricing(
      city: city,
      country: country,
      basic: basic ?? this.basic,
      pro: pro ?? this.pro,
      luxe: luxe ?? this.luxe,
    );
  }
}

class PromoCodeDraft {
  const PromoCodeDraft({
    required this.code,
    required this.discountPercent,
    required this.maxUses,
    required this.used,
    required this.minBookingValue,
    required this.expiryDate,
    required this.active,
  });

  final String code;
  final int discountPercent;
  final int maxUses;
  final int used;
  final double minBookingValue;
  final DateTime expiryDate;
  final bool active;

  PromoCodeDraft copyWith({bool? active}) {
    return PromoCodeDraft(
      code: code,
      discountPercent: discountPercent,
      maxUses: maxUses,
      used: used,
      minBookingValue: minBookingValue,
      expiryDate: expiryDate,
      active: active ?? this.active,
    );
  }
}

class AdminFilterChip extends StatelessWidget {
  const AdminFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary.withValues(alpha: 0.18),
      backgroundColor: AppColors.surfaceElevated,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.stroke),
      labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
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

class AdminTag extends StatelessWidget {
  const AdminTag({
    required this.label,
    super.key,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class AdminAvatar extends StatelessWidget {
  const AdminAvatar({
    required this.imageUrl,
    this.radius = 28,
    super.key,
  });

  final String imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, _) => Shimmer.fromColors(
          baseColor: AppColors.surfaceElevated,
          highlightColor: AppColors.card,
          child: Container(width: size, height: size, color: AppColors.surfaceElevated),
        ),
        errorWidget: (context, _, _) => Container(
          width: size,
          height: size,
          color: AppColors.surfaceElevated,
          alignment: Alignment.center,
          child: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: radius),
        ),
      ),
    );
  }
}

class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class AdminInfoRow extends StatelessWidget {
  const AdminInfoRow({
    required this.label,
    required this.value,
    this.isMultiline = false,
    super.key,
  });

  final String label;
  final String value;
  final bool isMultiline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 128,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSimpleListTile extends StatelessWidget {
  const AdminSimpleListTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            trailing,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class AdminMediaTile extends StatelessWidget {
  const AdminMediaTile({
    required this.imageUrl,
    this.size = 96,
    super.key,
  });

  final String imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, _) => Shimmer.fromColors(
          baseColor: AppColors.surfaceElevated,
          highlightColor: AppColors.card,
          child: Container(width: size, height: size, color: AppColors.surfaceElevated),
        ),
        errorWidget: (context, _, _) => Container(
          width: size,
          height: size,
          color: AppColors.surfaceElevated,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

class MiniMetricCard extends StatelessWidget {
  const MiniMetricCard({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 52,
        height: 5,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

extension StringFallbackX on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
