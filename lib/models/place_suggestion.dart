import 'package:json_annotation/json_annotation.dart';

part 'place_suggestion.g.dart';

/// A single Google Places autocomplete suggestion.
@JsonSerializable(fieldRename: FieldRename.snake)
class PlaceSuggestion {
  /// Creates a [PlaceSuggestion].
  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });

  /// Creates a [PlaceSuggestion] from a JSON map.
  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) =>
      _$PlaceSuggestionFromJson(json);

  /// Unique Google Places ID.
  final String placeId;

  /// Full description shown in autocomplete.
  final String description;

  /// Primary place name.
  final String? mainText;

  /// Secondary location context.
  final String? secondaryText;

  /// Converts this [PlaceSuggestion] to a JSON map.
  Map<String, dynamic> toJson() => _$PlaceSuggestionToJson(this);
}
