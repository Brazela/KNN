import 'package:json_annotation/json_annotation.dart';

part 'gtfs_stop.g.dart';


@JsonSerializable(fieldRename: FieldRename.snake)
class GTFSStop {
  
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

  
  factory GTFSStop.fromJson(Map<String, dynamic> json) =>
      _$GTFSStopFromJson(json);

  
  final String stopId;

  
  final String stopName;

  
  final double stopLat;

  
  final double stopLon;

  
  final String? stopCode;

  
  final int? locationType;

  
  final String? parentStation;

  
  final int? wheelchairBoarding;

  
  Map<String, dynamic> toJson() => _$GTFSStopToJson(this);
}
