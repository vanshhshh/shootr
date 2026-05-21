import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'admin_management_views.dart';
import '../../../app/constants/app_colors.dart';
import '../../../shared/models/admin_overview.dart';
import '../../../shared/models/app_user.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/marketplace_catalog.dart';
import '../../../shared/models/shootr_package.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/primary_glow_button.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  static const _labels = <String>[
    'Dashboard',
    'Shootrs',
    'Clients',
    'Bookings',
    'Pricing',
    'Analytics',
    'Cities',
    'Notify',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final overview = state.adminOverview;
    final currentUser = state.currentUser;

    if (currentUser?.role != UserRole.admin) {
      return const Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFF111111),
                AppColors.background,
                Colors.black,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: EmptyStateView(
                title: 'Admin access required',
                subtitle:
                    'Only accounts with role=admin can access the Shootr control panel.',
              ),
            ),
          ),
        ),
      );
    }

    Widget body = switch (_index) {
      0 => _DashboardView(overview: overview),
      1 => const ShootrsAdminView(),
      2 => const ClientsAdminView(),
      3 => const BookingsAdminView(),
      4 => const PricingAdminView(),
      5 => _AnalyticsHubView(),
      6 => _CitiesAdminView(),
      _ => const NotificationsAdminView(),
    };

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF111111),
              AppColors.background,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 900;
              if (!wide) {
                return Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: <Widget>[
                          Text(
                            'Shootr Admin',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Marketplace control room',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: body),
                    NavigationBar(
                      selectedIndex: _index,
                      backgroundColor: AppColors.surface,
                      onDestinationSelected: (value) =>
                          setState(() => _index = value),
                      destinations: _labels
                          .map(
                            (label) => NavigationDestination(
                              icon: const Icon(Icons.dashboard_outlined),
                              label: label,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (value) =>
                        setState(() => _index = value),
                    backgroundColor: AppColors.surface,
                    labelType: NavigationRailLabelType.all,
                    destinations: _labels
                        .map(
                          (label) => NavigationRailDestination(
                            icon: const Icon(Icons.dashboard_outlined),
                            label: Text(label),
                          ),
                        )
                        .toList(),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardView extends ConsumerWidget {
  const _DashboardView({required this.overview});

  final AdminOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final bookingsByCategory = <String, int>{};
    for (final booking in state.bookings) {
      bookingsByCategory[booking.categoryId] =
          (bookingsByCategory[booking.categoryId] ?? 0) + 1;
    }
    final sortedCategories = bookingsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final recentActivity = <String>[
      ...state.bookings
          .take(5)
          .map(
            (item) =>
                'Booking ${item.id} · ${item.clientName} → ${item.shootrName}',
          ),
      ...state.shootrs.take(3).map((item) => 'Shootr signup · ${item.name}'),
      ...state.clients.take(2).map((item) => 'Client signup · ${item.name}'),
    ].take(10).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text(
          'Platform Dashboard',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            _MetricCard(
              label: 'Bookings today',
              value: '${overview.bookingsToday}',
            ),
            _MetricCard(
              label: 'Revenue today',
              value: AppFormatters.currency(overview.revenueToday),
            ),
            _MetricCard(
              label: 'Shootrs online',
              value: '${overview.activeShootrsOnline}',
            ),
            _MetricCard(
              label: 'New signups',
              value: '${overview.newClientSignups + overview.newShootrSignups}',
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (overview.pendingApprovals > 0)
          GlassCard(
            borderColor: AppColors.warning.withValues(alpha: 0.25),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.pending_actions_outlined,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${overview.pendingApprovals} Shootrs are waiting for approval.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 12),
                const PrimaryGlowButton(
                  label: 'Review',
                  onPressed: null,
                  isExpanded: false,
                ),
              ],
            ),
          ),
        if (overview.pendingApprovals > 0) const SizedBox(height: 18),
        SizedBox(
          height: 260,
          child: GlassCard(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: <LineChartBarData>[
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    spots: [
                      for (var i = 0; i < overview.revenueTrend.length; i++)
                        FlSpot(i.toDouble(), overview.revenueTrend[i].value),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 260,
          child: GlassCard(
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 ||
                            index >= sortedCategories.length.clamp(0, 5)) {
                          return const SizedBox.shrink();
                        }
                        final raw = sortedCategories[index].key;
                        final label = kMarketplaceCategories
                            .firstWhere(
                              (item) => item.id == raw,
                              orElse: () => const MarketplaceCategory(
                                id: 'other',
                                label: 'Other',
                                emoji: '',
                                iconKey: 'plusCircle',
                              ),
                            )
                            .label;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(label.split(' ').first),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: <BarChartGroupData>[
                  for (var i = 0; i < sortedCategories.take(5).length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: <BarChartRodData>[
                        BarChartRodData(
                          toY: sortedCategories[i].value.toDouble(),
                          color: AppColors.primary,
                          width: 20,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'City-wise breakdown',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...overview.cityMetrics.map<Widget>(
          (city) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          city.city,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${city.bookings} bookings  •  ${city.activeShootrs} active Shootrs',
                        ),
                      ],
                    ),
                  ),
                  Text(AppFormatters.currency(city.revenue)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Recent activity', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...recentActivity.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.bolt_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _ShootrsAdminView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shootrs = ref.watch(appControllerProvider).shootrs;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text(
          'Shootr Management',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        ...shootrs.map(
          (shootr) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          shootr.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Chip(label: Text(shootr.verified ? 'Active' : 'Pending')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${shootr.city}  •  ${shootr.iphoneModel ?? 'Unknown device'}',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      const PrimaryGlowButton(
                        label: 'Use detailed view',
                        onPressed: null,
                        isExpanded: false,
                      ),
                      const OutlinedButton(
                        onPressed: null,
                        child: Text('Reject'),
                      ),
                      const OutlinedButton(
                        onPressed: null,
                        child: Text('Suspend'),
                      ),
                      const OutlinedButton(
                        onPressed: null,
                        child: Text('Notify'),
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
}

// ignore: unused_element
class _ClientsAdminView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(appControllerProvider).clients;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text(
          'Client Management',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        ...clients.map(
          (client) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          client.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text('${client.city}  •  ${client.phone}'),
                      ],
                    ),
                  ),
                  const OutlinedButton(onPressed: null, child: Text('Flag')),
                  const SizedBox(width: 8),
                  const OutlinedButton(onPressed: null, child: Text('Refund')),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _BookingsAdminView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(appControllerProvider).bookings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text(
          'Booking Management',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: const <Widget>[
            Chip(label: Text('Mumbai')),
            Chip(label: Text('Confirmed')),
            Chip(label: Text('This week')),
            Chip(label: Text('Pro')),
          ],
        ),
        const SizedBox(height: 16),
        ...bookings.map(
          (booking) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    booking.id,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  Text('${booking.clientName} → ${booking.shootrName}'),
                  const SizedBox(height: 4),
                  Text(
                    '${booking.location.city}  •  ${booking.status.label}  •  ${booking.packageType.label}',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: <Widget>[
                      const OutlinedButton(
                        onPressed: null,
                        child: Text('Create manual'),
                      ),
                      const OutlinedButton(
                        onPressed: null,
                        child: Text('Resolve dispute'),
                      ),
                      const OutlinedButton(
                        onPressed: null,
                        child: Text('Approve refund'),
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
}

// ignore: unused_element
class _PricingAdminView extends StatefulWidget {
  @override
  State<_PricingAdminView> createState() => _PricingAdminViewState();
}

class _PricingAdminViewState extends State<_PricingAdminView> {
  double _platformFee = 5;
  bool _surge = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text(
          'Pricing Management',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Platform fee',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
        const SizedBox(height: 16),
        GlassCard(
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Surge pricing',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enable peak-hour and event-based dynamic pricing.',
                    ),
                  ],
                ),
              ),
              Switch(
                value: _surge,
                activeThumbColor: AppColors.primary,
                onChanged: (value) => setState(() => _surge = value),
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
                'City package prices',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Mumbai  •  Basic ₹1,999  •  Pro ₹3,499  •  Luxe ₹5,999',
              ),
              const SizedBox(height: 6),
              const Text(
                'Dubai  •  Basic AED 199  •  Pro AED 349  •  Luxe AED 599',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const PrimaryGlowButton(label: 'Create promo code', onPressed: null),
      ],
    );
  }
}

// ignore: unused_element
class _AnalyticsAdminView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text(
          'Analytics & Cities',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Most booked use cases'),
              SizedBox(height: 8),
              Text('Restaurant, Weddings, Brand Launches'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Top performing Shootrs',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...state.shootrs
                  .take(3)
                  .map(
                    (shootr) => Text('${shootr.name}  •  ${shootr.rating}★'),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Booking funnel'),
              SizedBox(height: 8),
              Text('Discovery → Profile → Checkout → Paid → Completed'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('City management'),
              SizedBox(height: 8),
              Text(
                'Add cities, mark coming-soon markets, and assign managers.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalyticsHubView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final categoryCounts = <String, int>{};
    for (final booking in state.bookings) {
      categoryCounts[booking.categoryId] =
          (categoryCounts[booking.categoryId] ?? 0) + 1;
    }
    final topShootrs = <AppUser>[...state.shootrs]
      ..sort((a, b) => b.totalEarned.compareTo(a.totalEarned));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text('Analytics', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 260,
          child: GlassCard(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: categoryCounts.entries
                    .take(5)
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) {
                      final colors = <Color>[
                        AppColors.primary,
                        const Color(0xFF4FA3FF),
                        const Color(0xFFFFC857),
                        const Color(0xFFFF6B6B),
                        const Color(0xFF7EE081),
                      ];
                      final label = kMarketplaceCategories
                          .firstWhere(
                            (item) => item.id == entry.value.key,
                            orElse: () => const MarketplaceCategory(
                              id: 'other',
                              label: 'Other',
                              emoji: '',
                              iconKey: 'plusCircle',
                            ),
                          )
                          .label;
                      return PieChartSectionData(
                        color: colors[entry.key % colors.length],
                        value: entry.value.value.toDouble(),
                        title: label.split(' ').first,
                        radius: 64,
                        titleStyle: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Top 10 Shootrs by revenue',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...topShootrs
                  .take(10)
                  .map(
                    (shootr) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: <Widget>[
                          Expanded(child: Text(shootr.name)),
                          Text(
                            AppFormatters.currency(
                              shootr.totalEarned,
                              country: shootr.country,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Retention snapshot',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Client repeat booking rate: ${(state.clients.where((item) => item.totalSpent > 0).length / (state.clients.isEmpty ? 1 : state.clients.length) * 100).toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 4),
              Text(
                'Shootr 30-day retention: ${(state.shootrs.where((item) => item.totalShoots > 0).length / (state.shootrs.isEmpty ? 1 : state.shootrs.length) * 100).toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 4),
              const Text(
                'Booking funnel: Discovery → Profile → Checkout → Paid → Completed',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CitiesAdminView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cities = ref.watch(appControllerProvider).adminOverview.cityMetrics;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text(
          'City Management',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        ...cities.map(
          (city) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          city.city,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      _AdminTag(
                        label: city.activeShootrs > 20
                            ? 'Active'
                            : 'Coming Soon',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${city.activeShootrs} Shootrs · ${city.bookings} bookings · ${AppFormatters.currency(city.revenue)} revenue',
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Add new city'),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'City name')),
              SizedBox(height: 10),
              TextField(decoration: InputDecoration(labelText: 'Country')),
              SizedBox(height: 10),
              TextField(decoration: InputDecoration(labelText: 'State')),
              SizedBox(height: 10),
              TextField(decoration: InputDecoration(labelText: 'Launch date')),
              SizedBox(height: 16),
              PrimaryGlowButton(label: 'Add city', onPressed: null),
            ],
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _NotificationsAdminView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(appControllerProvider).notifications;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: <Widget>[
        Text(
          'Notifications Center',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Send push notification'),
              SizedBox(height: 12),
              TextField(decoration: InputDecoration(labelText: 'Audience')),
              SizedBox(height: 10),
              TextField(decoration: InputDecoration(labelText: 'Title')),
              SizedBox(height: 10),
              TextField(decoration: InputDecoration(labelText: 'Body')),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: 'Optional deep link'),
              ),
              SizedBox(height: 16),
              PrimaryGlowButton(
                label: 'Schedule notification',
                onPressed: null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Sent history', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...notifications
            .take(10)
            .map(
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
                            Text(item.body),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const _AdminTag(label: '98% delivery'),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _AdminTag extends StatelessWidget {
  const _AdminTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: 6),
            Text(label),
          ],
        ),
      ),
    );
  }
}
