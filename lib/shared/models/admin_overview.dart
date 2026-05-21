class CityMetric {
  const CityMetric({
    required this.city,
    required this.bookings,
    required this.revenue,
    required this.activeShootrs,
  });

  final String city;
  final int bookings;
  final double revenue;
  final int activeShootrs;
}

class RevenuePoint {
  const RevenuePoint({
    required this.dayLabel,
    required this.value,
  });

  final String dayLabel;
  final double value;
}

class AdminOverview {
  const AdminOverview({
    required this.bookingsToday,
    required this.bookingsThisWeek,
    required this.bookingsThisMonth,
    required this.revenueToday,
    required this.revenueWeek,
    required this.revenueMonth,
    required this.activeShootrsOnline,
    required this.newClientSignups,
    required this.newShootrSignups,
    required this.pendingApprovals,
    required this.cityMetrics,
    required this.revenueTrend,
  });

  final int bookingsToday;
  final int bookingsThisWeek;
  final int bookingsThisMonth;
  final double revenueToday;
  final double revenueWeek;
  final double revenueMonth;
  final int activeShootrsOnline;
  final int newClientSignups;
  final int newShootrSignups;
  final int pendingApprovals;
  final List<CityMetric> cityMetrics;
  final List<RevenuePoint> revenueTrend;
}
