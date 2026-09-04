import 'package:json_annotation/json_annotation.dart';

part 'driving_route.g.dart';


@JsonSerializable(fieldRename: FieldRename.snake)
class DrivingRoute {
  
  const DrivingRoute({
    required this.distanceMeters,
    required this.durationSeconds,
    this.tolls = 0.0,
    required this.fuelCost,
    this.steps = const [],
  });

  
  factory DrivingRoute.fromJson(Map<String, dynamic> json) =>
      _$DrivingRouteFromJson(json);

  
  final int distanceMeters;

  
  final int durationSeconds;

  
  final double tolls;

  
  final double fuelCost;

  
  final List<String> steps;

  
  Map<String, dynamic> toJson() => _$DrivingRouteToJson(this);
}
