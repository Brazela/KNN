import 'package:json_annotation/json_annotation.dart';

part 'distance_matrix.g.dart';


@JsonSerializable(fieldRename: FieldRename.snake)
class DistanceMatrix {
  
  const DistanceMatrix({
    required this.distanceMeters,
    required this.durationSeconds,
    this.tolls = 0.0,
  });

  
  factory DistanceMatrix.fromJson(Map<String, dynamic> json) =>
      _$DistanceMatrixFromJson(json);

  
  final int distanceMeters;

  
  final int durationSeconds;

  
  final double tolls;

  
  Map<String, dynamic> toJson() => _$DistanceMatrixToJson(this);
}
