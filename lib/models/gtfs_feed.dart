import 'package:json_annotation/json_annotation.dart';

import 'gtfs_stop.dart';
import 'gtfs_trip.dart';

part 'gtfs_feed.g.dart';


@JsonSerializable(fieldRename: FieldRename.snake)
class GTFSScheduleRoute {
  
  const GTFSScheduleRoute({
    required this.routeId,
    required this.routeShortName,
    required this.routeLongName,
    required this.routeType,
    this.agencyId,
    this.routeColor,
    this.routeTextColor,
  });

  
  factory GTFSScheduleRoute.fromJson(Map<String, dynamic> json) =>
      _$GTFSScheduleRouteFromJson(json);

  
  final String routeId;

  
  final String routeShortName;

  
  final String routeLongName;

  
  final int routeType;

  
  final String? agencyId;

  
  final String? routeColor;

  
  final String? routeTextColor;

  
  Map<String, dynamic> toJson() => _$GTFSScheduleRouteToJson(this);
}


@JsonSerializable(fieldRename: FieldRename.snake)
class GTFSCalendar {
  
  const GTFSCalendar({
    required this.serviceId,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
    required this.startDate,
    required this.endDate,
  });

  
  factory GTFSCalendar.fromJson(Map<String, dynamic> json) =>
      _$GTFSCalendarFromJson(json);

  
  final String serviceId;

  
  final int monday;

  
  final int tuesday;

  
  final int wednesday;

  
  final int thursday;

  
  final int friday;

  
  final int saturday;

  
  final int sunday;

  
  final String startDate;

  
  final String endDate;

  
  Map<String, dynamic> toJson() => _$GTFSCalendarToJson(this);
}


@JsonSerializable(fieldRename: FieldRename.snake)
class GTFSStopTime {
  
  const GTFSStopTime({
    required this.tripId,
    required this.arrivalTime,
    required this.departureTime,
    required this.stopId,
    required this.stopSequence,
    this.stopHeadsign,
  });

  
  factory GTFSStopTime.fromJson(Map<String, dynamic> json) =>
      _$GTFSStopTimeFromJson(json);

  
  final String tripId;

  
  final String arrivalTime;

  
  final String departureTime;

  
  final String stopId;

  
  final int stopSequence;

  
  final String? stopHeadsign;

  
  Map<String, dynamic> toJson() => _$GTFSStopTimeToJson(this);
}


@JsonSerializable(fieldRename: FieldRename.snake)
class GTFSFeed {
  
  const GTFSFeed({
    required this.agency,
    required this.stops,
    required this.routes,
    required this.trips,
    required this.stopTimes,
    required this.calendar,
  });

  
  factory GTFSFeed.fromJson(Map<String, dynamic> json) =>
      _$GTFSFeedFromJson(json);

  
  final Map<String, String> agency;

  
  @JsonKey(toJson: _stopsToJson, fromJson: _stopsFromJson)
  final List<GTFSStop> stops;

  
  @JsonKey(toJson: _routesToJson, fromJson: _routesFromJson)
  final List<GTFSScheduleRoute> routes;

  
  @JsonKey(toJson: _tripsToJson, fromJson: _tripsFromJson)
  final List<GTFSTrip> trips;

  
  @JsonKey(toJson: _stopTimesToJson, fromJson: _stopTimesFromJson)
  final List<GTFSStopTime> stopTimes;

  
  @JsonKey(toJson: _calendarToJson, fromJson: _calendarFromJson)
  final List<GTFSCalendar> calendar;

  static List<Map<String, dynamic>> _stopsToJson(List<GTFSStop> items) =>
      items.map((e) => e.toJson()).toList();

  static List<GTFSStop> _stopsFromJson(List<dynamic> json) =>
      json.map((e) => GTFSStop.fromJson(e as Map<String, dynamic>)).toList();

  static List<Map<String, dynamic>> _routesToJson(
          List<GTFSScheduleRoute> items) =>
      items.map((e) => e.toJson()).toList();

  static List<GTFSScheduleRoute> _routesFromJson(List<dynamic> json) =>
      json
          .map((e) => GTFSScheduleRoute.fromJson(e as Map<String, dynamic>))
          .toList();

  static List<Map<String, dynamic>> _tripsToJson(List<GTFSTrip> items) =>
      items.map((e) => e.toJson()).toList();

  static List<GTFSTrip> _tripsFromJson(List<dynamic> json) =>
      json.map((e) => GTFSTrip.fromJson(e as Map<String, dynamic>)).toList();

  static List<Map<String, dynamic>> _stopTimesToJson(List<GTFSStopTime> items) =>
      items.map((e) => e.toJson()).toList();

  static List<GTFSStopTime> _stopTimesFromJson(List<dynamic> json) =>
      json.map((e) => GTFSStopTime.fromJson(e as Map<String, dynamic>)).toList();

  static List<Map<String, dynamic>> _calendarToJson(List<GTFSCalendar> items) =>
      items.map((e) => e.toJson()).toList();

  static List<GTFSCalendar> _calendarFromJson(List<dynamic> json) =>
      json.map((e) => GTFSCalendar.fromJson(e as Map<String, dynamic>)).toList();

  
  Map<String, dynamic> toJson() => _$GTFSFeedToJson(this);
}
