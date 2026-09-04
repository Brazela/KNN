
part of 'gtfs_feed.dart';

GTFSScheduleRoute _$GTFSScheduleRouteFromJson(Map<String, dynamic> json) =>
    GTFSScheduleRoute(
      routeId: json['route_id'] as String,
      routeShortName: json['route_short_name'] as String,
      routeLongName: json['route_long_name'] as String,
      routeType: (json['route_type'] as num).toInt(),
      agencyId: json['agency_id'] as String?,
      routeColor: json['route_color'] as String?,
      routeTextColor: json['route_text_color'] as String?,
    );

Map<String, dynamic> _$GTFSScheduleRouteToJson(GTFSScheduleRoute instance) =>
    <String, dynamic>{
      'route_id': instance.routeId,
      'route_short_name': instance.routeShortName,
      'route_long_name': instance.routeLongName,
      'route_type': instance.routeType,
      'agency_id': instance.agencyId,
      'route_color': instance.routeColor,
      'route_text_color': instance.routeTextColor,
    };

GTFSCalendar _$GTFSCalendarFromJson(Map<String, dynamic> json) => GTFSCalendar(
  serviceId: json['service_id'] as String,
  monday: (json['monday'] as num).toInt(),
  tuesday: (json['tuesday'] as num).toInt(),
  wednesday: (json['wednesday'] as num).toInt(),
  thursday: (json['thursday'] as num).toInt(),
  friday: (json['friday'] as num).toInt(),
  saturday: (json['saturday'] as num).toInt(),
  sunday: (json['sunday'] as num).toInt(),
  startDate: json['start_date'] as String,
  endDate: json['end_date'] as String,
);

Map<String, dynamic> _$GTFSCalendarToJson(GTFSCalendar instance) =>
    <String, dynamic>{
      'service_id': instance.serviceId,
      'monday': instance.monday,
      'tuesday': instance.tuesday,
      'wednesday': instance.wednesday,
      'thursday': instance.thursday,
      'friday': instance.friday,
      'saturday': instance.saturday,
      'sunday': instance.sunday,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
    };

GTFSStopTime _$GTFSStopTimeFromJson(Map<String, dynamic> json) => GTFSStopTime(
  tripId: json['trip_id'] as String,
  arrivalTime: json['arrival_time'] as String,
  departureTime: json['departure_time'] as String,
  stopId: json['stop_id'] as String,
  stopSequence: (json['stop_sequence'] as num).toInt(),
  stopHeadsign: json['stop_headsign'] as String?,
);

Map<String, dynamic> _$GTFSStopTimeToJson(GTFSStopTime instance) =>
    <String, dynamic>{
      'trip_id': instance.tripId,
      'arrival_time': instance.arrivalTime,
      'departure_time': instance.departureTime,
      'stop_id': instance.stopId,
      'stop_sequence': instance.stopSequence,
      'stop_headsign': instance.stopHeadsign,
    };

GTFSFeed _$GTFSFeedFromJson(Map<String, dynamic> json) => GTFSFeed(
  agency: Map<String, String>.from(json['agency'] as Map),
  stops: GTFSFeed._stopsFromJson(json['stops'] as List),
  routes: GTFSFeed._routesFromJson(json['routes'] as List),
  trips: GTFSFeed._tripsFromJson(json['trips'] as List),
  stopTimes: GTFSFeed._stopTimesFromJson(json['stop_times'] as List),
  calendar: GTFSFeed._calendarFromJson(json['calendar'] as List),
);

Map<String, dynamic> _$GTFSFeedToJson(GTFSFeed instance) => <String, dynamic>{
  'agency': instance.agency,
  'stops': GTFSFeed._stopsToJson(instance.stops),
  'routes': GTFSFeed._routesToJson(instance.routes),
  'trips': GTFSFeed._tripsToJson(instance.trips),
  'stop_times': GTFSFeed._stopTimesToJson(instance.stopTimes),
  'calendar': GTFSFeed._calendarToJson(instance.calendar),
};
