
part of 'place_suggestion.dart';

PlaceSuggestion _$PlaceSuggestionFromJson(Map<String, dynamic> json) =>
    PlaceSuggestion(
      placeId: json['place_id'] as String,
      description: json['description'] as String,
      mainText: json['main_text'] as String?,
      secondaryText: json['secondary_text'] as String?,
    );

Map<String, dynamic> _$PlaceSuggestionToJson(PlaceSuggestion instance) =>
    <String, dynamic>{
      'place_id': instance.placeId,
      'description': instance.description,
      'main_text': instance.mainText,
      'secondary_text': instance.secondaryText,
    };
