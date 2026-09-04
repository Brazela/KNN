import 'package:json_annotation/json_annotation.dart';

part 'place_suggestion.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class PlaceSuggestion {

  const PlaceSuggestion({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) =>
      _$PlaceSuggestionFromJson(json);

  final String placeId;

  final String description;

  final String? mainText;

  final String? secondaryText;

  Map<String, dynamic> toJson() => _$PlaceSuggestionToJson(this);
}
