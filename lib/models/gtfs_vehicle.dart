import 'package:json_annotation/json_annotation.dart';

part 'gtfs_vehicle.g.dart';

/// A vehicle position parsed from a GTFS Realtime feed.
@JsonSerializable(fieldRename: FieldRename.snake)
class GTFSVehicle {
  /// Creates a [GTFSVehicle].
  const GTFSVehicle({
    required this.vehicleId,
    this.tripId,
    this.routeId,
    this.latitude,
    this.longitude,
    this.timestamp,
    this.bearing,
    this.speed,
    this.label,
    this.occupancyStatus,
  });

  /// Creates a [GTFSVehicle] from a JSON map.
  factory GTFSVehicle.fromJson(Map<String, dynamic> json) =>
      _$GTFSVehicleFromJson(json);

  /// Unique identifier for the vehicle.
  final String vehicleId;

  /// ID of the trip the vehicle is currently serving.
  final String? tripId;

  /// ID of the route the vehicle is currently serving.
  final String? routeId;

  /// Current vehicle latitude.
  final double? latitude;

  /// Current vehicle longitude.
  final double? longitude;

  /// POSIX timestamp of the position update.
  final int? timestamp;

  /// Vehicle heading in degrees.
  final double? bearing;

  /// Vehicle speed in m/s.
  final double? speed;

  /// Vehicle label shown to passengers.
  final String? label;

  /// GTFS Realtime occupancy status string.
  final String? occupancyStatus;

  /// Converts this [GTFSVehicle] to a JSON map.
  Map<String, dynamic> toJson() => _$GTFSVehicleToJson(this);
}
