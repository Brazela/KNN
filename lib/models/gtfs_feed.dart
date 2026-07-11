import 'package:json_annotation/json_annotation.dart';

import 'gtfs_stop.dart';
import 'gtfs_trip.dart';

part 'gtfs_feed.g.dart';

/// A GTFS route entry parsed from `routes.txt`.
@JsonSerializable(fieldRename: FieldRename.snake)
class GTFSScheduleRoute {
  /// Creates a [GTFSScheduleRoute].
  const GTFSScheduleRoute({
    required this.routeId,
    required this.routeShortName,
    required this.routeLongName,
    required this.routeType,
    this.agencyId,
    this.routeColor,
    this.routeTextColor,
  });

  /// Creates a [GTFSScheduleRoute] from a JSON map.
  factory GTFSScheduleRoute.fromJson(Map<String, dynamic> json) =>
      _$GTFSScheduleRouteFromJson(json);

  /// Unique identifier for the route.
  final String routeId;

  /// Short name or number of the route.
  final String routeShortName;

  /// Long descriptive name of the route.
  final String routeLongName;

  /// GTFS route_type value (e.g. 0 = tram, 1 = subway, 3 = bus).
  final int routeType;

  /// ID of the agency operating this route.
  final String? agencyId;

  /// Route color as a hex string (without #).
  final String? routeColor;

  /// Route text color as a hex string (without #).
  final String? routeTextColor;

  /// Converts this [GTFSScheduleRoute] to a JSON map.
  Map<String, dynamic> toJson() => _$GTFSScheduleRouteToJson(this);
}

/// A GTFS calendar entry parsed from `calendar.txt`.
@JsonSerializable(fieldRename: FieldRename.snake)
class GTFSCalendar {
  /// Creates a [GTFSCalendar].
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

  /// Creates a [GTFSCalendar] from a JSON map.
  factory GTFSCalendar.fromJson(Map<String, dynamic> json) =>
      _$GTFSCalendarFromJson(json);

  /// Unique identifier for the service.
  final String serviceId;

  /// Whether the service runs on Monday (1 = yes, 0 = no).
  final int monday;

  /// Whether the service runs on Tuesday.
  final int tuesday;

  /// Whether the service runs on Wednesday.
  final int wednesday;

  /// Whether the service runs on Thursday.
  final int thursday;

  /// Whether the service runs on Friday.
  final int friday;

  /// Whether the service runs on Saturday.
  final int saturday;

  /// Whether the service runs on Sunday.
  final int sunday;

  /// Service start date in YYYYMMDD format.
  final String startDate;

  /// Service end date in YYYYMMDD format.
  final String endDate;

  /// Converts this [GTFSCalendar] to a JSON map.
  Map<String, dynamic> toJson() => _$GTFSCalendarToJson(this);
}

/// A single stop time entry parsed from `stop_times.txt`.
@JsonSerializable(fieldRename: FieldRename.snake)
class GTFSStopTime {
  /// Creates a [GTFSStopTime].
  const GTFSStopTime({
    required this.tripId,
    required this.arrivalTime,
    required this.departureTime,
    required this.stopId,
    required this.stopSequence,
    this.stopHeadsign,
  });

  /// Creates a [GTFSStopTime] from a JSON map.
  factory GTFSStopTime.fromJson(Map<String, dynamic> json) =>
      _$GTFSStopTimeFromJson(json);

  /// ID of the trip.
  final String tripId;

  /// Scheduled arrival time (HH:MM:SS).
  final String arrivalTime;

  /// Scheduled departure time (HH:MM:SS).
  final String departureTime;

  /// ID of the stop.
  final String stopId;

  /// Order of the stop within the trip.
  final int stopSequence;

  /// Destination sign for this stop, if different from trip headsign.
  final String? stopHeadsign;

  /// Converts this [GTFSStopTime] to a JSON map.
  Map<String, dynamic> toJson() => _$GTFSStopTimeToJson(this);
}

/// Container for all parsed GTFS static feed data.
@JsonSerializable(fieldRename: FieldRename.snake)
class GTFSFeed {
  /// Creates a [GTFSFeed].
  const GTFSFeed({
    required this.agency,
    required this.stops,
    required this.routes,
    required this.trips,
    required this.stopTimes,
    required this.calendar,
  });

  /// Creates a [GTFSFeed] from a JSON map.
  factory GTFSFeed.fromJson(Map<String, dynamic> json) =>
      _$GTFSFeedFromJson(json);

  /// Agency metadata parsed from `agency.txt`.
  final Map<String, String> agency;

  /// All stops parsed from `stops.txt`.
  @JsonKey(toJson: _stopsToJson, fromJson: _stopsFromJson)
  final List<GTFSStop> stops;

  /// All routes parsed from `routes.txt`.
  @JsonKey(toJson: _routesToJson, fromJson: _routesFromJson)
  final List<GTFSScheduleRoute> routes;

  /// All trips parsed from `trips.txt`.
  @JsonKey(toJson: _tripsToJson, fromJson: _tripsFromJson)
  final List<GTFSTrip> trips;

  /// All stop times parsed from `stop_times.txt`.
  @JsonKey(toJson: _stopTimesToJson, fromJson: _stopTimesFromJson)
  final List<GTFSStopTime> stopTimes;

  /// All calendar entries parsed from `calendar.txt`.
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

  /// Converts this [GTFSFeed] to a JSON map.
  Map<String, dynamic> toJson() => _$GTFSFeedToJson(this);
}
