import 'package:json_annotation/json_annotation.dart';

part 'place_detail.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class PlaceDetail {

  const PlaceDetail({
    required this.placeId,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.name,
  });

  factory PlaceDetail.fromJson(Map<String, dynamic> json) =>
      _$PlaceDetailFromJson(json);

  final String placeId;

  final double latitude;

  final double longitude;

  final String formattedAddress;

  final String? name;

  Map<String, dynamic> toJson() => _$PlaceDetailToJson(this);
}
