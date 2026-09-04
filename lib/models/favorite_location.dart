import 'package:json_annotation/json_annotation.dart';

import 'location.dart';

part 'favorite_location.g.dart';

enum FavoriteLocationType {

  custom,
}

@JsonSerializable()
class FavoriteLocation {

  const FavoriteLocation({
    required this.id,
    required this.type,
    required this.label,
    required this.location,
  });

  factory FavoriteLocation.fromJson(Map<String, dynamic> json) =>
      _$FavoriteLocationFromJson(json);

  final String id;

  final FavoriteLocationType type;

  final String label;

  final Location location;

  Map<String, dynamic> toJson() => _$FavoriteLocationToJson(this);

  FavoriteLocation copyWith({
    String? label,
    Location? location,
  }) {
    return FavoriteLocation(
      id: id,
      type: type,
      label: label ?? this.label,
      location: location ?? this.location,
    );
  }
}
