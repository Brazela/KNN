import 'package:json_annotation/json_annotation.dart';

import 'location.dart';
import 'weather.dart';

part 'trip.g.dart';

/// Travel mode for a saved or planned trip.
enum TravelMode { transit, driving }

/// A user trip or recent search.
@JsonSerializable(fieldRename: FieldRename.snake)
class Trip {
  /// Creates a [Trip].
  const Trip({
    required this.id,
    required this.origin,
    required this.destination,
    required this.mode,
    required this.cost,
    required this.timeMinutes,
    required this.date,
    this.weather,
  });

  /// Creates a [Trip] from a JSON map.
  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

  /// Unique trip identifier.
  final String id;

  /// Origin location.
  final Location origin;

  /// Destination location.
  final Location destination;

  /// Selected travel mode.
  @JsonKey(fromJson: _modeFromJson, toJson: _modeToJson)
  final TravelMode mode;

  /// Estimated or actual cost in MYR.
  final double cost;

  /// Estimated travel time in minutes.
  final int timeMinutes;

  /// Trip date/time.
  final DateTime date;

  /// Optional weather snapshot for the trip date.
  final Weather? weather;

  static TravelMode _modeFromJson(String value) {
    switch (value) {
      case 'transit':
        return TravelMode.transit;
      case 'driving':
        return TravelMode.driving;
      default:
        return TravelMode.transit;
    }
  }

  static String _modeToJson(TravelMode mode) => mode.name;

  /// Converts this [Trip] to a JSON map.
  Map<String, dynamic> toJson() => _$TripToJson(this);
}
