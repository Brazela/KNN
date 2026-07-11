import 'package:json_annotation/json_annotation.dart';

import 'gtfs_stop.dart';

part 'route.g.dart';

/// Types of public transit supported by the app.
enum TransitMode { train, mrt, lrt, monorail, bus, unknown }

/// Realtime status of a transit route.
enum RealtimeStatus { onTime, delayed, unknown }

/// A transit route option presented to the user.
///
/// Named [TransitRoute] to avoid clashing with Flutter's [Route] class.
@JsonSerializable(fieldRename: FieldRename.snake)
class TransitRoute {
  /// Creates a [TransitRoute].
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

  /// Creates a [TransitRoute] from a JSON map.
  factory TransitRoute.fromJson(Map<String, dynamic> json) =>
      _$TransitRouteFromJson(json);

  /// Unique route identifier.
  final String id;

  /// Human-readable route name.
  final String name;

  /// Mode of transit.
  @JsonKey(fromJson: _modeFromJson, toJson: _modeToJson)
  final TransitMode type;

  /// Stops along this route option.
  @JsonKey(toJson: _stopsToJson, fromJson: _stopsFromJson)
  final List<GTFSStop> stops;

  /// Estimated total duration in minutes.
  final int durationMinutes;

  /// Number of transfers required.
  final int transfers;

  /// Estimated fare in MYR.
  final double fare;

  /// Current realtime status.
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

  /// Converts this [TransitRoute] to a JSON map.
  Map<String, dynamic> toJson() => _$TransitRouteToJson(this);
}
