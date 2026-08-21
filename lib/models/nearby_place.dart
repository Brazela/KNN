import 'package:json_annotation/json_annotation.dart';

import '../utils/constants.dart';

part 'nearby_place.g.dart';

/// A place returned by the Google Places Nearby Search API.
///
/// Includes rating, location, and category information used by the
/// [PopularPlacesWidget] to display curated nearby points of interest.
@JsonSerializable(fieldRename: FieldRename.snake)
class NearbyPlace {
  /// Creates a [NearbyPlace].
  const NearbyPlace({
    required this.placeId,
    required this.name,
    this.vicinity,
    this.rating = 0.0,
    this.userRatingsTotal = 0,
    required this.latitude,
    required this.longitude,
    this.types = const [],
    this.icon,
    this.photoUrls = const [],
    this.openNow,
    this.weekdayDescriptions,
  });

  /// Creates a [NearbyPlace] from a JSON map.
  factory NearbyPlace.fromJson(Map<String, dynamic> json) =>
      _$NearbyPlaceFromJson(json);

  /// Unique Google Places ID.
  final String placeId;

  /// Display name of the place.
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

  /// Google Places type tags (e.g. `["restaurant", "food", "point_of_interest"]`).
  final List<String> types;

  /// URL to the Google-provided category icon.
  final String? icon;

  /// Photo image URLs fetched from Google Places (up to 3).
  final List<String> photoUrls;

  /// Whether the place is currently open (from `currentOpeningHours`).
  final bool? openNow;

  /// Human-readable weekday descriptions, e.g.
  /// `["Monday: 9:00 AM – 9:00 PM", ...]`.
  final List<String>? weekdayDescriptions;

  /// Converts this [NearbyPlace] to a JSON map.
  Map<String, dynamic> toJson() => _$NearbyPlaceToJson(this);

  /// Builds a Google Places photo URL from a photo resource name.
  static String buildPhotoUrl(String photoName, {int maxWidth = 400}) {
    return 'https://places.googleapis.com/v1/$photoName/media'
        '?key=${GoogleMapsConfig.apiKey}&maxWidthPx=$maxWidth';
  }

  /// Returns the first available photo URL, or `null`.
  String? get firstPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  /// A short summary of opening hours suitable for display.
  String? get hoursSummary {
    if (openNow == true) return 'Open now';
    if (openNow == false) return 'Closed now';
    return null;
  }

  /// The first weekday description, or `null`.
  String? get hoursDetail =>
      (weekdayDescriptions != null && weekdayDescriptions!.isNotEmpty)
          ? weekdayDescriptions!.first
          : null;
}
