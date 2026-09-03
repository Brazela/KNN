import 'package:json_annotation/json_annotation.dart';

import 'location.dart';
import 'trip.dart';

part 'saved_route.g.dart';

/// A transit or driving route the user has bookmarked for one-tap planning.
///
/// Field names deliberately mirror [Trip] (`cost`, `timeMinutes`, `mode`)
/// so the two types stay easy to convert between once saved routes can be
/// generated from real trip history.
///
/// Now persisted via `services/local_storage_service.dart` — see the note
/// on `favorite_location.dart` for the `.g.dart` generation step.
@JsonSerializable()
class SavedRoute {
  /// Creates a [SavedRoute].
  const SavedRoute({
    required this.id,
    required this.origin,
    required this.destination,
    required this.mode,
    required this.cost,
    required this.timeMinutes,
    required this.savingsPerTripRM,
  });

  /// Creates a [SavedRoute] from decoded JSON.
  factory SavedRoute.fromJson(Map<String, dynamic> json) =>
      _$SavedRouteFromJson(json);

  /// Unique identifier.
  final String id;

  /// Trip origin.
  final Location origin;

  /// Trip destination.
  final Location destination;

  /// Recommended travel mode for this saved route.
  final TravelMode mode;

  /// Estimated cost in MYR for [mode].
  final double cost;

  /// Estimated travel time in minutes for [mode].
  final int timeMinutes;

  /// Estimated savings, in MYR, versus the alternative mode, *per trip*.
  final double savingsPerTripRM;

  /// Converts this route to a JSON-compatible map.
  Map<String, dynamic> toJson() => _$SavedRouteToJson(this);
}
