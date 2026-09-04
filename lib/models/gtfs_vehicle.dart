import 'package:json_annotation/json_annotation.dart';

part 'gtfs_vehicle.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class GTFSVehicle {

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

  factory GTFSVehicle.fromJson(Map<String, dynamic> json) =>
      _$GTFSVehicleFromJson(json);

  final String vehicleId;

  final String? tripId;

  final String? routeId;

  final double? latitude;

  final double? longitude;

  final int? timestamp;

  final double? bearing;

  final double? speed;

  final String? label;

  final String? occupancyStatus;

  Map<String, dynamic> toJson() => _$GTFSVehicleToJson(this);
}
