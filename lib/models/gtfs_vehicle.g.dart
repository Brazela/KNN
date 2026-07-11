// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gtfs_vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GTFSVehicle _$GTFSVehicleFromJson(Map<String, dynamic> json) => GTFSVehicle(
  vehicleId: json['vehicle_id'] as String,
  tripId: json['trip_id'] as String?,
  routeId: json['route_id'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  timestamp: (json['timestamp'] as num?)?.toInt(),
  bearing: (json['bearing'] as num?)?.toDouble(),
  speed: (json['speed'] as num?)?.toDouble(),
  label: json['label'] as String?,
  occupancyStatus: json['occupancy_status'] as String?,
);

Map<String, dynamic> _$GTFSVehicleToJson(GTFSVehicle instance) =>
    <String, dynamic>{
      'vehicle_id': instance.vehicleId,
      'trip_id': instance.tripId,
      'route_id': instance.routeId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'timestamp': instance.timestamp,
      'bearing': instance.bearing,
      'speed': instance.speed,
      'label': instance.label,
      'occupancy_status': instance.occupancyStatus,
    };
