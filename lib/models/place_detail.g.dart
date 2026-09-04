
part of 'place_detail.dart';

PlaceDetail _$PlaceDetailFromJson(Map<String, dynamic> json) => PlaceDetail(
  placeId: json['place_id'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  formattedAddress: json['formatted_address'] as String,
  name: json['name'] as String?,
);

Map<String, dynamic> _$PlaceDetailToJson(PlaceDetail instance) =>
    <String, dynamic>{
      'place_id': instance.placeId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'formatted_address': instance.formattedAddress,
      'name': instance.name,
    };
