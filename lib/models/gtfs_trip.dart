import 'package:json_annotation/json_annotation.dart';

import 'gtfs_stop.dart';

part 'gtfs_trip.g.dart';


@JsonSerializable(fieldRename: FieldRename.snake)
class GTFSTrip {
  
  const GTFSTrip({
    required this.tripId,
    required this.routeId,
    required this.serviceId,
    this.headsign,
    this.directionId,
    this.stops = const [],
  });

  
  factory GTFSTrip.fromJson(Map<String, dynamic> json) =>
      _$GTFSTripFromJson(json);

  
  final String tripId;

  
  final String routeId;

  
  final String serviceId;

  
  final String? headsign;

  
  final int? directionId;

  
  @JsonKey(toJson: _stopsToJson, fromJson: _stopsFromJson)
  final List<GTFSStop> stops;

  static List<Map<String, dynamic>> _stopsToJson(List<GTFSStop> stops) =>
      stops.map((s) => s.toJson()).toList();

  static List<GTFSStop> _stopsFromJson(List<dynamic> json) =>
      json.map((e) => GTFSStop.fromJson(e as Map<String, dynamic>)).toList();

  
  Map<String, dynamic> toJson() => _$GTFSTripToJson(this);
}
