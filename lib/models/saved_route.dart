import 'package:json_annotation/json_annotation.dart';

import 'location.dart';
import 'trip.dart';

part 'saved_route.g.dart';


@JsonSerializable()
class SavedRoute {
  
  const SavedRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.mode,
    required this.cost,
    required this.timeMinutes,
    required this.savingsPerTripRM,
  });

  
  factory SavedRoute.fromJson(Map<String, dynamic> json) =>
      _$SavedRouteFromJson(json);

  
  final String id;

  
  final Location origin;

  
  final Location destination;

  
  final TravelMode mode;

  
  final double cost;

  
  final int timeMinutes;

  
  final double savingsPerTripRM;

  
  Map<String, dynamic> toJson() => _$SavedRouteToJson(this);

  
  SavedRoute copyWith({
    Location? origin,
    Location? destination,
    TravelMode? mode,
    double? cost,
    int? timeMinutes,
    double? savingsPerTripRM,
  }) {
    return SavedRoute(
      id: id,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      mode: mode ?? this.mode,
      cost: cost ?? this.cost,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      savingsPerTripRM: savingsPerTripRM ?? this.savingsPerTripRM,
    );
  }
}
