import 'package:geolocator/geolocator.dart';

import '../models/models.dart';

class LocationService {

  const LocationService();

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
