import 'dart:math';

import 'package:json_annotation/json_annotation.dart';

import 'comparison.dart';
import 'location.dart';
import 'weather.dart';

part 'trip.g.dart';

enum TravelMode { transit, driving }

@JsonSerializable(fieldRename: FieldRename.snake)
class Trip {

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

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

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

  final String id;

  final Location origin;

  final Location destination;

  @JsonKey(fromJson: _modeFromJson, toJson: _modeToJson)
  final TravelMode mode;

  final double cost;

  final int timeMinutes;

  final DateTime date;

  final Weather? weather;

  final double? transitCost;

  final int? transitTime;

  final double? drivingCost;

  final int? drivingTime;

  final String? recommendedMode;

  final int? followedRecommendation;

  final double? savingsCost;

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

  Map<String, dynamic> toJson() => _$TripToJson(this);
}
