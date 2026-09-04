// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavoriteLocation _$FavoriteLocationFromJson(Map<String, dynamic> json) =>
    FavoriteLocation(
      id: json['id'] as String,
      type: $enumDecode(_$FavoriteLocationTypeEnumMap, json['type']),
      label: json['label'] as String,
      location: Location.fromJson(json['location'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FavoriteLocationToJson(FavoriteLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$FavoriteLocationTypeEnumMap[instance.type]!,
      'label': instance.label,
      'location': instance.location,
    };

const _$FavoriteLocationTypeEnumMap = {FavoriteLocationType.custom: 'custom'};
