import '../models/location.dart';
import '../models/nearby_place.dart';
import '../models/parking_spot.dart';
import 'helpers.dart';

List<ParkingSpot> enrichParkingSpots(
  List<NearbyPlace> places,
  Location destination,
) {
  return places
      .map((place) => _enrichSingle(place, destination))
      .toList()
    ..sort((a, b) => a.distanceFromDestinationMeters
        .compareTo(b.distanceFromDestinationMeters));
}

ParkingSpot _enrichSingle(NearbyPlace place, Location destination) {
  final distKm = calculateDistance(
    destination.latitude,
    destination.longitude,
    place.latitude,
    place.longitude,
  );

  final price = _estimateParkingPrice(
    place.name,
    place.vicinity,
    place.placeId,
  );

  return ParkingSpot(
    placeId: place.placeId,
    name: place.name,
    vicinity: place.vicinity,
    rating: place.rating,
    userRatingsTotal: place.userRatingsTotal,
    latitude: place.latitude,
    longitude: place.longitude,
    distanceFromDestinationMeters: (distKm * 1000).round(),
    estimatedPricePerHour: price,
    photoUrls: place.photoUrls,
    openNow: place.openNow,
    weekdayDescriptions: place.weekdayDescriptions,
  );
}

double _estimateParkingPrice(String name, String? vicinity, String placeId) {
  final searchText = '${name.toLowerCase()} ${vicinity?.toLowerCase() ?? ''}';

  if (searchText.contains('free') || searchText.contains('percuma')) {
    return 0.0;
  }

  if (searchText.contains('kl sentral') ||
      searchText.contains('klcc') ||
      searchText.contains('bukit bintang') ||
      searchText.contains('pavilion') ||
      searchText.contains('suria')) {
    return _seededPrice(placeId, 3.0, 5.0);
  }

  if (searchText.contains('mall') ||
      searchText.contains('shopping') ||
      searchText.contains('plaza')) {
    return _seededPrice(placeId, 2.0, 4.0);
  }

  if (searchText.contains('street') ||
      searchText.contains('jalan') ||
      searchText.contains('roadside') ||
      searchText.contains('dbkl') ||
      searchText.contains('mbsa') ||
      searchText.contains('mpkj')) {
    return _seededPrice(placeId, 0.50, 2.0);
  }

  if (searchText.contains('open') ||
      searchText.contains('outdoor') ||
      searchText.contains('surface')) {
    return _seededPrice(placeId, 1.0, 2.5);
  }

  return _seededPrice(placeId, 1.50, 3.50);
}

double _seededPrice(String placeId, double min, double max) {
  final hash = placeId.hashCode;
  final fraction = (hash.abs() % 100) / 100.0;
  final raw = min + fraction * (max - min);

  return (raw * 2).roundToDouble() / 2;
}

bool isLikelyFreeParking(String name) {
  final lower = name.toLowerCase();
  return lower.contains('free') || lower.contains('percuma');
}
