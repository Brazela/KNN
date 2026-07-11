import 'package:json_annotation/json_annotation.dart';

import 'gtfs_stop.dart';

part 'gtfs_trip.g.dart';

/// A GTFS trip parsed from `trips.txt` with optional nested stop sequence.
@JsonSerializable(fieldRename: FieldRename.snake)
class GTFSTrip {
  /// Creates a [GTFSTrip].
  const GTFSTrip({
    required this.tripId,
    required this.routeId,
    required this.serviceId,
    this.headsign,
    this.directionId,
    this.stops = const [],
  });

  /// Creates a [GTFSTrip] from a JSON map.
  factory GTFSTrip.fromJson(Map<String, dynamic> json) =>
      _$GTFSTripFromJson(json);

  /// Unique identifier for the trip.
  final String tripId;

  /// ID of the route this trip belongs to.
  final String routeId;

  /// ID of the service (calendar) defining when this trip runs.
  final String serviceId;

  /// Destination sign for the trip.
  final String? headsign;

  /// Direction identifier (0 or 1).
  final int? directionId;

  /// Ordered list of stops served by this trip.
  @JsonKey(toJson: _stopsToJson, fromJson: _stopsFromJson)
  final List<GTFSStop> stops;

  static List<Map<String, dynamic>> _stopsToJson(List<GTFSStop> stops) =>
      stops.map((s) => s.toJson()).toList();

  static List<GTFSStop> _stopsFromJson(List<dynamic> json) =>
      json.map((e) => GTFSStop.fromJson(e as Map<String, dynamic>)).toList();

  /// Converts this [GTFSTrip] to a JSON map.
  Map<String, dynamic> toJson() => _$GTFSTripToJson(this);
}
