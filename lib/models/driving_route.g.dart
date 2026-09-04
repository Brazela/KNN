// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driving_route.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DrivingRoute _$DrivingRouteFromJson(Map<String, dynamic> json) => DrivingRoute(
  distanceMeters: (json['distance_meters'] as num).toInt(),
  durationSeconds: (json['duration_seconds'] as num).toInt(),
  tolls: (json['tolls'] as num?)?.toDouble() ?? 0.0,
  fuelCost: (json['fuel_cost'] as num).toDouble(),
  steps:
      (json['steps'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$DrivingRouteToJson(DrivingRoute instance) =>
    <String, dynamic>{
      'distance_meters': instance.distanceMeters,
      'duration_seconds': instance.durationSeconds,
      'tolls': instance.tolls,
      'fuel_cost': instance.fuelCost,
      'steps': instance.steps,
    };
