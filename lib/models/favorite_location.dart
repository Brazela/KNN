import 'location.dart';

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
/// This is a plain, immutable value type for the current UI-mockup phase.
/// It intentionally does *not* implement `@JsonSerializable()` yet, since no
/// persistence layer exists — but its shape mirrors [Location] closely so it
/// can adopt the same `json_annotation` pattern once the Local Database
/// module is implemented.
class FavoriteLocation {
  /// Creates a [FavoriteLocation].
  const FavoriteLocation({
    required this.id,
    required this.type,
    required this.label,
    required this.location,
  });

  /// Unique identifier.
  ///
  /// Generated client-side for this mockup phase; replace with the local
  /// database's primary key once persistence is implemented.
  final String id;

  /// Which role this favorite plays (drives icon/colour choice in the UI).
  final FavoriteLocationType type;

  /// Display name shown on the card, e.g. "Home", "Work", "Gym".
  final String label;

  /// Geographic location and address for this favorite.
  final Location location;

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
