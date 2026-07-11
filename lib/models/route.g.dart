// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransitRoute _$TransitRouteFromJson(Map<String, dynamic> json) => TransitRoute(
  id: json['id'] as String,
  name: json['name'] as String,
  type: TransitRoute._modeFromJson(json['type'] as String),
  stops: TransitRoute._stopsFromJson(json['stops'] as List),
  durationMinutes: (json['duration_minutes'] as num).toInt(),
  transfers: (json['transfers'] as num).toInt(),
  fare: (json['fare'] as num).toDouble(),
  realtimeStatus: json['realtime_status'] == null
      ? RealtimeStatus.unknown
      : TransitRoute._statusFromJson(json['realtime_status'] as String),
);

Map<String, dynamic> _$TransitRouteToJson(TransitRoute instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': TransitRoute._modeToJson(instance.type),
      'stops': TransitRoute._stopsToJson(instance.stops),
      'duration_minutes': instance.durationMinutes,
      'transfers': instance.transfers,
      'fare': instance.fare,
      'realtime_status': TransitRoute._statusToJson(instance.realtimeStatus),
    };
