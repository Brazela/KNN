import 'package:json_annotation/json_annotation.dart';

part 'driving_route.g.dart';

/// A driving route option produced by Google Maps Distance Matrix / Directions.
@JsonSerializable(fieldRename: FieldRename.snake)
class DrivingRoute {
  /// Creates a [DrivingRoute].
  const DrivingRoute({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.tolls,
    required this.fuelCost,
    this.steps = const [],
  });

  /// Creates a [DrivingRoute] from a JSON map.
  factory DrivingRoute.fromJson(Map<String, dynamic> json) =>
      _$DrivingRouteFromJson(json);

  /// Total distance in meters.
  final int distanceMeters;

  /// Total duration in seconds.
  final int durationSeconds;

  /// Estimated toll cost in MYR.
  final double tolls;

  /// Estimated fuel cost in MYR.
  final double fuelCost;

  /// Human-readable navigation steps.
  final List<String> steps;

  /// Converts this [DrivingRoute] to a JSON map.
  Map<String, dynamic> toJson() => _$DrivingRouteToJson(this);
}
