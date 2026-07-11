import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

/// A geographic location with optional address metadata.
///
/// Used across the app to represent origins, destinations, stops, and
/// current user positions.
@JsonSerializable()
class Location {
  /// Creates a [Location].
  const Location({
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeId,
  });

  /// Creates a [Location] from a JSON map.
  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  /// Latitude in decimal degrees.
  final double latitude;

  /// Longitude in decimal degrees.
  final double longitude;

  /// Human-readable address or name for this location.
  final String? address;

  /// Google Places place ID, if available.
  final String? placeId;

  /// Converts this [Location] to a JSON map.
  Map<String, dynamic> toJson() => _$LocationToJson(this);
}
