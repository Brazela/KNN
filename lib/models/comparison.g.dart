
part of 'comparison.dart';

Comparison _$ComparisonFromJson(Map<String, dynamic> json) => Comparison(
  origin: Location.fromJson(json['origin'] as Map<String, dynamic>),
  destination: Location.fromJson(json['destination'] as Map<String, dynamic>),
  transitOption: TransitRoute.fromJson(
    json['transit_option'] as Map<String, dynamic>,
  ),
  drivingOption: DrivingRoute.fromJson(
    json['driving_option'] as Map<String, dynamic>,
  ),
  recommendation: Comparison._recommendationFromJson(
    json['recommendation'] as String,
  ),
  recommendationReason: json['recommendation_reason'] as String,
  weather: json['weather'] == null
      ? null
      : Weather.fromJson(json['weather'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ComparisonToJson(
  Comparison instance,
) => <String, dynamic>{
  'origin': instance.origin,
  'destination': instance.destination,
  'transit_option': instance.transitOption,
  'driving_option': instance.drivingOption,
  'recommendation': Comparison._recommendationToJson(instance.recommendation),
  'recommendation_reason': instance.recommendationReason,
  'weather': instance.weather,
};
