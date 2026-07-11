// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Location _$LocationFromJson(Map<String, dynamic> json) => Location(
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  address: json['address'] as String?,
  placeId: json['placeId'] as String?,
);

Map<String, dynamic> _$LocationToJson(Location instance) => <String, dynamic>{
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'address': instance.address,
  'placeId': instance.placeId,
};
