
part of 'nearby_place.dart';

NearbyPlace _$NearbyPlaceFromJson(Map<String, dynamic> json) => NearbyPlace(
  placeId: json['place_id'] as String,
  name: json['name'] as String,
  vicinity: json['vicinity'] as String?,
  rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
  userRatingsTotal: (json['user_ratings_total'] as num?)?.toInt() ?? 0,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  types:
      (json['types'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  icon: json['icon'] as String?,
  photoUrls:
      (json['photo_urls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  openNow: json['open_now'] as bool?,
  weekdayDescriptions: (json['weekday_descriptions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$NearbyPlaceToJson(NearbyPlace instance) =>
    <String, dynamic>{
      'place_id': instance.placeId,
      'name': instance.name,
      'vicinity': instance.vicinity,
      'rating': instance.rating,
      'user_ratings_total': instance.userRatingsTotal,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'types': instance.types,
      'icon': instance.icon,
      'photo_urls': instance.photoUrls,
      'open_now': instance.openNow,
      'weekday_descriptions': instance.weekdayDescriptions,
    };
