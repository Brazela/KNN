import 'package:json_annotation/json_annotation.dart';

part 'location.g.dart';

@JsonSerializable()
class Location {

  const Location({
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeId,
  });

  factory Location.fromJson(Map<String, dynamic> json) =>
      _$LocationFromJson(json);

  final double latitude;

  final double longitude;

  final String? address;

  final String? placeId;

  Map<String, dynamic> toJson() => _$LocationToJson(this);
}
