import 'package:json_annotation/json_annotation.dart';

part 'distance_matrix.g.dart';

/// Distance and duration result from Google Maps Distance Matrix API.
@JsonSerializable(fieldRename: FieldRename.snake)
class DistanceMatrix {
  /// Creates a [DistanceMatrix].
  const DistanceMatrix({
    required this.distanceMeters,
    required this.durationSeconds,
    this.tolls = 0.0,
  });

  /// Creates a [DistanceMatrix] from a JSON map.
  factory DistanceMatrix.fromJson(Map<String, dynamic> json) =>
      _$DistanceMatrixFromJson(json);

  /// Distance in meters.
  final int distanceMeters;

  /// Duration in seconds.
  final int durationSeconds;

  /// Estimated toll cost in MYR (not provided by Google; default 0).
  final double tolls;

  /// Converts this [DistanceMatrix] to a JSON map.
  Map<String, dynamic> toJson() => _$DistanceMatrixToJson(this);
}
