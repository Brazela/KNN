
part of 'distance_matrix.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DistanceMatrix _$DistanceMatrixFromJson(Map<String, dynamic> json) =>
    DistanceMatrix(
      distanceMeters: (json['distance_meters'] as num).toInt(),
      durationSeconds: (json['duration_seconds'] as num).toInt(),
      tolls: (json['tolls'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$DistanceMatrixToJson(DistanceMatrix instance) =>
    <String, dynamic>{
      'distance_meters': instance.distanceMeters,
      'duration_seconds': instance.durationSeconds,
      'tolls': instance.tolls,
    };
