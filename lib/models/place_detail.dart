import 'package:json_annotation/json_annotation.dart';

part 'place_detail.g.dart';

/// Detailed location information returned by Google Places Details API.
@JsonSerializable(fieldRename: FieldRename.snake)
class PlaceDetail {
  /// Creates a [PlaceDetail].
  const PlaceDetail({
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.name,
  });

  /// Creates a [PlaceDetail] from a JSON map.
  factory PlaceDetail.fromJson(Map<String, dynamic> json) =>
      _$PlaceDetailFromJson(json);

  /// Unique Google Places ID.
  final String placeId;

  /// Place latitude.
  final double latitude;

  /// Place longitude.
  final double longitude;

  /// Full formatted address.
  final String formattedAddress;

  /// Human-readable place name.
  final String? name;

  /// Converts this [PlaceDetail] to a JSON map.
  Map<String, dynamic> toJson() => _$PlaceDetailToJson(this);
}
