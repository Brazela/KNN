import 'package:json_annotation/json_annotation.dart';

import '../utils/constants.dart';

part 'nearby_place.g.dart';


@JsonSerializable(fieldRename: FieldRename.snake)
class NearbyPlace {
  
  const NearbyPlace({
    required this.placeId,
    required this.name,
    this.vicinity,
    this.rating = 0.0,
    this.userRatingsTotal = 0,
    required this.latitude,
    required this.longitude,
    this.types = const [],
    this.icon,
    this.photoUrls = const [],
    this.openNow,
    this.weekdayDescriptions,
  });

  
  factory NearbyPlace.fromJson(Map<String, dynamic> json) =>
      _$NearbyPlaceFromJson(json);

  
  final String placeId;

  
  final String name;

  
  final String? vicinity;

  
  final double rating;

  
  final int userRatingsTotal;

  
  final double latitude;

  
  final double longitude;

  
  final List<String> types;

  
  final String? icon;

  
  final List<String> photoUrls;

  
  final bool? openNow;

  
  
  final List<String>? weekdayDescriptions;

  
  Map<String, dynamic> toJson() => _$NearbyPlaceToJson(this);

  
  static String buildPhotoUrl(String photoName, {int maxWidth = 400}) {
    return 'https://places.googleapis.com/v1/$photoName/media'
        '?key=${GoogleMapsConfig.apiKey}&maxWidthPx=$maxWidth';
  }

  
  String? get firstPhotoUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  
  String? get hoursSummary {
    if (openNow == true) return 'Open now';
    if (openNow == false) return 'Closed now';
    return null;
  }

  
  String? get hoursDetail =>
      (weekdayDescriptions != null && weekdayDescriptions!.isNotEmpty)
          ? weekdayDescriptions!.first
          : null;
}
