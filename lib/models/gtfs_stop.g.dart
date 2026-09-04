
part of 'gtfs_stop.dart';

GTFSStop _$GTFSStopFromJson(Map<String, dynamic> json) => GTFSStop(
  stopId: json['stop_id'] as String,
  stopName: json['stop_name'] as String,
  stopLat: (json['stop_lat'] as num).toDouble(),
  stopLon: (json['stop_lon'] as num).toDouble(),
  stopCode: json['stop_code'] as String?,
  locationType: (json['location_type'] as num?)?.toInt(),
  parentStation: json['parent_station'] as String?,
  wheelchairBoarding: (json['wheelchair_boarding'] as num?)?.toInt(),
);

Map<String, dynamic> _$GTFSStopToJson(GTFSStop instance) => <String, dynamic>{
  'stop_id': instance.stopId,
  'stop_name': instance.stopName,
  'stop_lat': instance.stopLat,
  'stop_lon': instance.stopLon,
  'stop_code': instance.stopCode,
  'location_type': instance.locationType,
  'parent_station': instance.parentStation,
  'wheelchair_boarding': instance.wheelchairBoarding,
};
