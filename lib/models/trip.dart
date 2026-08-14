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
    this.transitCost,
    this.transitTime,
    this.drivingCost,
    this.drivingTime,
    this.recommendedMode,
    this.followedRecommendation,
    this.savingsCost,
    this.savingsTime,
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

  /// Recommended transit cost in MYR.
  final double? transitCost;

  /// Recommended transit time in minutes.
  final int? transitTime;

  /// Recommended driving cost in MYR.
  final double? drivingCost;

  /// Recommended driving time in minutes.
  final int? drivingTime;

  /// Recommended travel mode ('transit' or 'driving').
  final String? recommendedMode;

  /// Whether the user followed the recommendation (0 = no, 1 = yes).
  final int? followedRecommendation;

  /// Cost savings from following the recommendation in MYR.
  final double? savingsCost;

  /// Time savings from following the recommendation in minutes.
  final int? savingsTime;

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
