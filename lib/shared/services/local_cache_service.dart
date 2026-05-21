import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/booking.dart';

class LocalCacheService {
  static const String _completedBookingsKey = 'completed_bookings_cache';
  static const String _selectedLocationKey = 'selected_location_cache';
  static const String _recentLocationsKey = 'recent_locations_cache';
  static const String _savedShootrsKey = 'saved_shootrs_cache';

  Future<void> cacheCompletedBookings(List<Booking> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = bookings.map((booking) => booking.toMap()).toList();
    await prefs.setString(_completedBookingsKey, jsonEncode(encoded));
  }

  Future<List<Booking>> getCompletedBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_completedBookingsKey);
    if (raw == null || raw.isEmpty) {
      return const <Booking>[];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Booking.fromMap((item as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> cacheSelectedLocation(AppLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedLocationKey, jsonEncode(location.toMap()));
  }

  Future<AppLocation?> getSelectedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_selectedLocationKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return AppLocation.fromMap((jsonDecode(raw) as Map).cast<String, dynamic>());
  }

  Future<void> cacheRecentLocations(List<AppLocation> locations) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = locations.map((item) => item.toMap()).toList();
    await prefs.setString(_recentLocationsKey, jsonEncode(encoded));
  }

  Future<List<AppLocation>> getRecentLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentLocationsKey);
    if (raw == null || raw.isEmpty) {
      return const <AppLocation>[];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => AppLocation.fromMap((item as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> cacheSavedShootrs(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedShootrsKey, ids);
  }

  Future<List<String>> getSavedShootrs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedShootrsKey) ?? const <String>[];
  }

  Future<void> cacheNotificationPreferences(NotificationPreferences prefsData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_booking_updates', prefsData.bookingUpdates);
    await prefs.setBool('notif_promos', prefsData.promos);
    await prefs.setBool('notif_reminders', prefsData.reminders);
    await prefs.setBool('notif_messages', prefsData.messages);
    await prefs.setBool('notif_safety', prefsData.safety);
    await prefs.setBool('notif_payouts', prefsData.payouts);
  }

  Future<NotificationPreferences> getNotificationPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      bookingUpdates: prefs.getBool('notif_booking_updates') ?? true,
      promos: prefs.getBool('notif_promos') ?? true,
      reminders: prefs.getBool('notif_reminders') ?? true,
      messages: prefs.getBool('notif_messages') ?? true,
      safety: prefs.getBool('notif_safety') ?? true,
      payouts: prefs.getBool('notif_payouts') ?? true,
    );
  }
}
