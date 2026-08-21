import '../models/location.dart';
import '../models/nearby_place.dart';
import '../models/parking_spot.dart';
import 'helpers.dart';

/// Enriches a list of [NearbyPlace] results into [ParkingSpot] objects
/// with estimated price and computed distance from a given [destination].
///
/// Real Google Places fields (name, location, rating, photos, hours) are
/// passed through. Price is estimated because the API does not provide it.
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

/// Enriches a single [NearbyPlace] into a [ParkingSpot].
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

// ---------------------------------------------------------------------------
// Price estimation (deterministic — Google Places does not return
// parking prices). Label as "Est." in the UI.
// ---------------------------------------------------------------------------

/// Estimates parking price per hour (RM) from place name, vicinity, and
/// a deterministic seed derived from [placeId].
double _estimateParkingPrice(String name, String? vicinity, String placeId) {
  final searchText = '${name.toLowerCase()} ${vicinity?.toLowerCase() ?? ''}';

  // Free parking indicators.
  if (searchText.contains('free') || searchText.contains('percuma')) {
    return 0.0;
  }

  // Premium areas — KL Sentral, KLCC, Bukit Bintang, Pavilion.
  if (searchText.contains('kl sentral') ||
      searchText.contains('klcc') ||
      searchText.contains('bukit bintang') ||
      searchText.contains('pavilion') ||
      searchText.contains('suria')) {
    return _seededPrice(placeId, 3.0, 5.0);
  }

  // Mall / shopping complex parking.
  if (searchText.contains('mall') ||
      searchText.contains('shopping') ||
      searchText.contains('plaza')) {
    return _seededPrice(placeId, 2.0, 4.0);
  }

  // Street / DBKL roadside parking.
  if (searchText.contains('street') ||
      searchText.contains('jalan') ||
      searchText.contains('roadside') ||
      searchText.contains('dbkl') ||
      searchText.contains('mbsa') ||
      searchText.contains('mpkj')) {
    return _seededPrice(placeId, 0.50, 2.0);
  }

  // Open-air / uncovered lots.
  if (searchText.contains('open') ||
      searchText.contains('outdoor') ||
      searchText.contains('surface')) {
    return _seededPrice(placeId, 1.0, 2.5);
  }

  // Default — covered / multi-storey.
  return _seededPrice(placeId, 1.50, 3.50);
}

/// Returns a deterministic price in [min, max] range seeded by [placeId].
double _seededPrice(String placeId, double min, double max) {
  final hash = placeId.hashCode;
  final fraction = (hash.abs() % 100) / 100.0;
  final raw = min + fraction * (max - min);
  // Round to nearest 0.50.
  return (raw * 2).roundToDouble() / 2;
}

/// Checks whether a parking spot is likely free based on its name.
bool isLikelyFreeParking(String name) {
  final lower = name.toLowerCase();
  return lower.contains('free') || lower.contains('percuma');
}
