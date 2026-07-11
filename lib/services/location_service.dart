import 'package:geolocator/geolocator.dart';

import '../models/models.dart';

/// Service responsible for requesting and reading the device's location.
class LocationService {
  /// Creates a [LocationService].
  const LocationService();

  /// Requests location permission and returns the resulting permission status.
  ///
  /// Throws an exception if location services are disabled.
  Future<LocationPermission> requestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  /// Returns the current device location.
  ///
  /// Call [requestPermission] before invoking this method.
  /// Throws an exception if permission is denied or location is unavailable.
  Future<Location> getCurrentLocation() async {
    final permission = await requestPermission();

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permissions are denied.');
    }

    final position = await Geolocator.getCurrentPosition();

    return Location(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  /// Streams location updates as the device moves.
  ///
  /// Throws an exception if permission is denied.
  Stream<Location> getLocationStream({
    LocationAccuracy desiredAccuracy = LocationAccuracy.high,
    int distanceFilterMeters = 10,
  }) async* {
    final permission = await requestPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are denied.');
    }

    yield* Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: desiredAccuracy,
        distanceFilter: distanceFilterMeters,
      ),
    ).map(
      (position) => Location(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }
}
