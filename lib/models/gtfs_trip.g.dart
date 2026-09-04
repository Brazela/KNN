
part of 'gtfs_trip.dart';

GTFSTrip _$GTFSTripFromJson(Map<String, dynamic> json) => GTFSTrip(
  tripId: json['trip_id'] as String,
  routeId: json['route_id'] as String,
  serviceId: json['service_id'] as String,
  headsign: json['headsign'] as String?,
  directionId: (json['direction_id'] as num?)?.toInt(),
  stops: json['stops'] == null
      ? const []
      : GTFSTrip._stopsFromJson(json['stops'] as List),
);

Map<String, dynamic> _$GTFSTripToJson(GTFSTrip instance) => <String, dynamic>{
  'trip_id': instance.tripId,
  'route_id': instance.routeId,
  'service_id': instance.serviceId,
  'headsign': instance.headsign,
  'direction_id': instance.directionId,
  'stops': GTFSTrip._stopsToJson(instance.stops),
};
