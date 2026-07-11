import 'package:json_annotation/json_annotation.dart';

part 'gtfs_stop.g.dart';

/// A GTFS stop parsed from `stops.txt`.
@JsonSerializable(fieldRename: FieldRename.snake)
class GTFSStop {
  /// Creates a [GTFSStop].
  const GTFSStop({
    required this.stopId,
    required this.stopName,
    required this.stopLat,
    required this.stopLon,
    this.stopCode,
    this.locationType,
    this.parentStation,
    this.wheelchairBoarding,
  });

  /// Creates a [GTFSStop] from a JSON map.
  factory GTFSStop.fromJson(Map<String, dynamic> json) =>
      _$GTFSStopFromJson(json);

  /// Unique identifier for the stop.
  final String stopId;

  /// Human-readable name of the stop.
  final String stopName;

  /// Stop latitude.
  final double stopLat;

  /// Stop longitude.
  final double stopLon;

  /// Short code or platform identifier for the stop.
  final String? stopCode;

  /// GTFS location_type value (0 = stop, 1 = station, etc.).
  final int? locationType;

  /// ID of the parent station, if this stop is part of one.
  final String? parentStation;

  /// Wheelchair boarding accessibility flag.
  final int? wheelchairBoarding;

  /// Converts this [GTFSStop] to a JSON map.
  Map<String, dynamic> toJson() => _$GTFSStopToJson(this);
}
