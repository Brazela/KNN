import 'package:json_annotation/json_annotation.dart';

import 'gtfs_stop.dart';

part 'route.g.dart';

enum TransitMode { train, mrt, lrt, monorail, bus, unknown }

enum RealtimeStatus { onTime, delayed, unknown }

@JsonSerializable(fieldRename: FieldRename.snake)
class TransitRoute {

  const TransitRoute({
    required this.id,
    required this.name,
    required this.type,
    required this.stops,
    required this.durationMinutes,
    required this.transfers,
    required this.fare,
    this.realtimeStatus = RealtimeStatus.unknown,
  });

  factory TransitRoute.fromJson(Map<String, dynamic> json) =>
      _$TransitRouteFromJson(json);

  final String id;

  final String name;

  @JsonKey(fromJson: _modeFromJson, toJson: _modeToJson)
  final TransitMode type;

  @JsonKey(toJson: _stopsToJson, fromJson: _stopsFromJson)
  final List<GTFSStop> stops;

  final int durationMinutes;

  final int transfers;

  final double fare;

  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  final RealtimeStatus realtimeStatus;

  static TransitMode _modeFromJson(String value) {
    switch (value) {
      case 'train':
        return TransitMode.train;
      case 'mrt':
        return TransitMode.mrt;
      case 'lrt':
        return TransitMode.lrt;
      case 'monorail':
        return TransitMode.monorail;
      case 'bus':
        return TransitMode.bus;
      default:
        return TransitMode.unknown;
    }
  }

  static String _modeToJson(TransitMode mode) => mode.name;

  static RealtimeStatus _statusFromJson(String value) {
    switch (value) {
      case 'on_time':
        return RealtimeStatus.onTime;
      case 'delayed':
        return RealtimeStatus.delayed;
      default:
        return RealtimeStatus.unknown;
    }
  }

  static String _statusToJson(RealtimeStatus status) {
    switch (status) {
      case RealtimeStatus.onTime:
        return 'on_time';
      case RealtimeStatus.delayed:
        return 'delayed';
      case RealtimeStatus.unknown:
        return 'unknown';
    }
  }

  static List<Map<String, dynamic>> _stopsToJson(List<GTFSStop> stops) =>
      stops.map((s) => s.toJson()).toList();

  static List<GTFSStop> _stopsFromJson(List<dynamic> json) =>
      json.map((e) => GTFSStop.fromJson(e as Map<String, dynamic>)).toList();

  Map<String, dynamic> toJson() => _$TransitRouteToJson(this);
}
