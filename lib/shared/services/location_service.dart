import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/booking.dart';
import '../models/marketplace_catalog.dart';

class LocationService {
  Future<AppLocation> getCurrentLocationIndiaOnly() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Turn on location services to find nearby Shootrs.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception('Location permission is needed to show nearby Shootrs.');
    }

    final position = await Geolocator.getCurrentPosition();
    return locationFromCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
      fallbackCity: 'Mumbai',
      fallbackAddress: 'Current location',
    );
  }

  Future<AppLocation> locationFromCoordinates({
    required double latitude,
    required double longitude,
    required String fallbackCity,
    required String fallbackAddress,
  }) async {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    final place = placemarks.isEmpty ? null : placemarks.first;
    final countryName = place?.country ?? 'India';
    if (countryName.toLowerCase() != 'india') {
      throw Exception('Client bookings are currently available only in India.');
    }

    final city = place?.locality ?? place?.subAdministrativeArea ?? fallbackCity;
    final state = place?.administrativeArea ?? '';
    final address = <String>[
      if (place?.name != null) place!.name!,
      if (place?.subLocality != null) place!.subLocality!,
      city,
    ].where((item) => item.trim().isNotEmpty).join(', ');

    return AppLocation(
      address: address.isEmpty ? fallbackAddress : address,
      city: city,
      state: state,
      country: AppCountry.india,
      latitude: latitude,
      longitude: longitude,
      placeLabel: city,
    );
  }

  Future<List<AppLocation>> searchIndiaLocations(String query) async {
    if (query.trim().length < 2) {
      return const <AppLocation>[];
    }

    final matches = <AppLocation>[];
    for (final region in kIndiaRegions) {
      for (final city in region.cities) {
        final label = '$city, ${region.name}';
        if (label.toLowerCase().contains(query.toLowerCase())) {
          matches.add(
            AppLocation(
              address: label,
              city: city,
              state: region.name,
              country: AppCountry.india,
              latitude: 0,
              longitude: 0,
              placeLabel: city,
            ),
          );
        }
      }
    }
    return matches.take(12).toList();
  }

  double distanceInKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    final meters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return meters / 1000;
  }
}
