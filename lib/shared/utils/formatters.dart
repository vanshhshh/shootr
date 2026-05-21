import 'package:intl/intl.dart';

import '../../app/constants/app_constants.dart';
import '../models/marketplace_catalog.dart';

class AppFormatters {
  const AppFormatters._();

  static String currency(
    double amount, {
    String city = 'Mumbai',
    AppCountry? country,
  }) {
    final resolvedCountry = country ?? _countryForCity(city);
    final symbol = resolvedCountry.symbol;
    final decimals = resolvedCountry == AppCountry.india ? 0 : 2;
    return NumberFormat.currency(symbol: symbol, decimalDigits: decimals)
        .format(amount);
  }

  static String compactCurrency(
    double amount, {
    String city = 'Mumbai',
    AppCountry? country,
  }) {
    final resolvedCountry = country ?? _countryForCity(city);
    final symbol = resolvedCountry.symbol;
    return NumberFormat.compactCurrency(symbol: symbol).format(amount);
  }

  static String shortDate(DateTime value) => DateFormat('dd MMM').format(value);

  static String dateTime(DateTime value) =>
      DateFormat('EEE, dd MMM • hh:mm a').format(value);

  static String dateOnly(DateTime value) => DateFormat('dd MMM yyyy').format(value);

  static String activeSince(DateTime value) => DateFormat('MMM yyyy').format(value);

  static String time(DateTime value) => DateFormat('hh:mm a').format(value);

  static String percent(double value) => '${value.toStringAsFixed(1)}%';

  static String fileLimit() => '${AppConstants.maxReelUploadMb}MB max';

  static String distanceKm(double value) => '${value.toStringAsFixed(1)} km away';

  static AppCountry _countryForCity(String city) {
    switch (city) {
      case 'Dubai':
      case 'Abu Dhabi':
        return AppCountry.uae;
      case 'New York':
      case 'Los Angeles':
        return AppCountry.usa;
      default:
        return AppCountry.india;
    }
  }
}
