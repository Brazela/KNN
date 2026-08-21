/// An enriched parking spot wrapping Google Places data with estimated
/// price and computed distance from the destination.
///
/// Real data comes from Google Places API: name, location, rating, photos,
/// opening hours. Price is estimated because the API doesn't provide it.
class ParkingSpot {
  /// Creates a [ParkingSpot].
  const ParkingSpot({
    required this.placeId,
    required this.name,
    this.vicinity,
    this.rating = 0.0,
    this.userRatingsTotal = 0,
    required this.latitude,
    required this.longitude,
    required this.distanceFromDestinationMeters,
    required this.estimatedPricePerHour,
    this.photoUrls = const [],
    this.openNow,
    this.weekdayDescriptions,
  });

  /// Unique Google Places ID.
  final String placeId;

  /// Display name of the parking location.
  final String name;

  /// Short address snippet (e.g. "Jalan Ampang, Kuala Lumpur").
  final String? vicinity;

  /// Average user rating (0.0–5.0).
  final double rating;

  /// Total number of user ratings.
  final int userRatingsTotal;

  /// Latitude in decimal degrees.
  final double latitude;

  /// Longitude in decimal degrees.
  final double longitude;

  /// Straight-line distance from the search destination in metres.
  final int distanceFromDestinationMeters;

  /// Estimated parking price in RM per hour.
  ///
  /// This is a heuristic estimate — Google Places does not provide actual
  /// parking prices. Values are deterministic per placeId.
  final double estimatedPricePerHour;

  /// Photo image URLs fetched from Google Places (up to 3).
  final List<String> photoUrls;

  /// Whether the spot is currently open (from Google Places).
  final bool? openNow;

  /// Human-readable weekday descriptions from Google Places.
  final List<String>? weekdayDescriptions;

  /// Whether this parking spot is estimated to be free.
  bool get isFree => estimatedPricePerHour == 0.0;

  /// Returns the first available photo URL, or `null`.
  String? get firstPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  /// Creates a copy of this [ParkingSpot] with the given fields replaced.
  ParkingSpot copyWith({
    String? placeId,
    String? name,
    String? vicinity,
    double? rating,
    int? userRatingsTotal,
    double? latitude,
    double? longitude,
    int? distanceFromDestinationMeters,
    double? estimatedPricePerHour,
    List<String>? photoUrls,
    bool? openNow,
    List<String>? weekdayDescriptions,
    bool clearPhotoUrls = false,
    bool clearOpenNow = false,
    bool clearWeekdayDescriptions = false,
  }) {
    return ParkingSpot(
      placeId: placeId ?? this.placeId,
      name: name ?? this.name,
      vicinity: vicinity ?? this.vicinity,
      rating: rating ?? this.rating,
      userRatingsTotal: userRatingsTotal ?? this.userRatingsTotal,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceFromDestinationMeters:
          distanceFromDestinationMeters ?? this.distanceFromDestinationMeters,
      estimatedPricePerHour:
          estimatedPricePerHour ?? this.estimatedPricePerHour,
      photoUrls: clearPhotoUrls ? const [] : (photoUrls ?? this.photoUrls),
      openNow: clearOpenNow ? null : (openNow ?? this.openNow),
      weekdayDescriptions: clearWeekdayDescriptions
          ? null
          : (weekdayDescriptions ?? this.weekdayDescriptions),
    );
  }

  /// Returns a formatted distance string, e.g. "200m" or "1.2km".
  String get formattedDistance {
    if (distanceFromDestinationMeters < 1000) {
      return '${distanceFromDestinationMeters}m';
    }
    return '${(distanceFromDestinationMeters / 1000).toStringAsFixed(1)}km';
  }

  /// Returns a formatted price string, e.g. "RM 2.00/hr" or "Free".
  String get formattedPrice {
    if (estimatedPricePerHour == 0.0) return 'Free';
    return 'RM ${estimatedPricePerHour.toStringAsFixed(2)}/hr';
  }

  /// Returns the display name, trimmed to a reasonable length.
  String get displayName {
    if (name.length <= 32) return name;
    return '${name.substring(0, 29)}…';
  }

  /// A short summary of opening hours suitable for display.
  /// Returns e.g. "Open now" or "Closed now" or the first weekday line.
  String? get hoursSummary {
    if (openNow == true) return 'Open now';
    if (openNow == false) return 'Closed now';
    if (weekdayDescriptions != null && weekdayDescriptions!.isNotEmpty) {
      return weekdayDescriptions!.first;
    }
    return null;
  }
}
