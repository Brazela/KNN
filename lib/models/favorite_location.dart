import 'package:json_annotation/json_annotation.dart';

import 'location.dart';

part 'favorite_location.g.dart';

/// The role a [FavoriteLocation] plays in the user's daily commute.
///
/// [home] and [work] correspond to the `home`/`work` fields already tracked
/// by `TripProvider` (see `providers/trip_provider.dart`); [custom] covers
/// any other place the user chooses to bookmark (e.g. "Gym", "Mum's House").
enum FavoriteLocationType {
  /// The user's home address.
  home,

  /// The user's workplace address.
  work,

  /// Any other user-named saved place.
  custom,
}

/// A single saved place shown on the Favorites page.
///
/// Now persisted via `services/local_storage_service.dart` — the
/// `@JsonSerializable()` annotation and generated `favorite_location.g.dart`
/// (run `flutter pub run build_runner build --delete-conflicting-outputs`
/// after adding this file) follow the exact same pattern already used by
/// [Location] in `models/location.dart`.
@JsonSerializable()
class FavoriteLocation {
  /// Creates a [FavoriteLocation].
  const FavoriteLocation({
    required this.id,
    required this.type,
    required this.label,
    required this.location,
  });

  /// Creates a [FavoriteLocation] from decoded JSON.
  factory FavoriteLocation.fromJson(Map<String, dynamic> json) =>
      _$FavoriteLocationFromJson(json);

  /// Unique identifier.
  final String id;

  /// Which role this favorite plays (drives icon/colour choice in the UI).
  final FavoriteLocationType type;

  /// Display name shown on the card, e.g. "Home", "Work", "Gym".
  final String label;

  /// Geographic location and address for this favorite.
  final Location location;

  /// Converts this favorite to a JSON-compatible map.
  Map<String, dynamic> toJson() => _$FavoriteLocationToJson(this);

  /// Returns a copy of this favorite with the given fields replaced.
  ///
  /// [FavoriteLocation] is kept immutable, like the rest of this app's
  /// models: editing a favorite means building a new instance rather than
  /// mutating fields in place, so nothing else holding a reference to the
  /// old value is silently affected.
  FavoriteLocation copyWith({
    String? label,
    Location? location,
  }) {
    return FavoriteLocation(
      id: id,
      type: type,
      label: label ?? this.label,
      location: location ?? this.location,
    );
  }
}
