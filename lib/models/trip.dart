import 'dart:math';

import 'package:json_annotation/json_annotation.dart';

import 'comparison.dart';
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

  /// Creates a trip record from a [Comparison] and the user's selected
  /// [TravelMode], matching the numbers shown on the comparison screen.
  ///
  /// Used when a route selection is recorded in trip history.
  factory Trip.fromComparison({
    required Comparison comparison,
    required TravelMode mode,
  }) {
    final cost = mode == TravelMode.transit
        ? comparison.transitOption.fare
        : comparison.drivingOption.fuelCost + comparison.drivingOption.tolls;
    final timeMinutes = mode == TravelMode.transit
        ? comparison.transitOption.durationMinutes
        : (comparison.drivingOption.durationSeconds / 60).round();

    final transitCost = comparison.transitOption.fare;
    final transitTime = comparison.transitOption.durationMinutes;
    final drivingCost =
        comparison.drivingOption.fuelCost + comparison.drivingOption.tolls;
    final drivingTime = (comparison.drivingOption.durationSeconds / 60).round();

    final recommendedMode = comparison.recommendation.name;
    final followed = comparison.recommendation.name == mode.name ? 1 : 0;

    // Savings: difference between the mode the user didn't choose and the
    // one they did. Null when there was no real alternative (no transit
    // routes), so the UI hides the savings chip.
    double? savingsCost;
    int? savingsTime;
    if (mode == TravelMode.transit) {
      savingsCost = drivingCost - cost;
      savingsTime = drivingTime - timeMinutes;
    } else if (comparison.transitOption.id != 'none') {
      savingsCost = transitCost - cost;
      savingsTime = transitTime - timeMinutes;
    }

    return Trip(
      id:
          'trip_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      origin: comparison.origin,
      destination: comparison.destination,
      mode: mode,
      cost: cost,
      timeMinutes: timeMinutes,
      date: DateTime.now(),
      weather: comparison.weather,
      transitCost: transitCost,
      transitTime: transitTime,
      drivingCost: drivingCost,
      drivingTime: drivingTime,
      recommendedMode: recommendedMode,
      followedRecommendation: followed,
      savingsCost: savingsCost,
      savingsTime: savingsTime,
    );
  }

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
