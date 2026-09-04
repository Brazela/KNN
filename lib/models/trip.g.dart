
part of 'trip.dart';

Trip _$TripFromJson(Map<String, dynamic> json) => Trip(
  id: json['id'] as String,
  origin: Location.fromJson(json['origin'] as Map<String, dynamic>),
  destination: Location.fromJson(json['destination'] as Map<String, dynamic>),
  mode: Trip._modeFromJson(json['mode'] as String),
  cost: (json['cost'] as num).toDouble(),
  timeMinutes: (json['time_minutes'] as num).toInt(),
  date: DateTime.parse(json['date'] as String),
  weather: json['weather'] == null
      ? null
      : Weather.fromJson(json['weather'] as Map<String, dynamic>),
  transitCost: (json['transit_cost'] as num?)?.toDouble(),
  transitTime: (json['transit_time'] as num?)?.toInt(),
  drivingCost: (json['driving_cost'] as num?)?.toDouble(),
  drivingTime: (json['driving_time'] as num?)?.toInt(),
  recommendedMode: json['recommended_mode'] as String?,
  followedRecommendation: (json['followed_recommendation'] as num?)?.toInt(),
  savingsCost: (json['savings_cost'] as num?)?.toDouble(),
  savingsTime: (json['savings_time'] as num?)?.toInt(),
);

Map<String, dynamic> _$TripToJson(Trip instance) => <String, dynamic>{
  'id': instance.id,
  'origin': instance.origin,
  'destination': instance.destination,
  'mode': Trip._modeToJson(instance.mode),
  'cost': instance.cost,
  'time_minutes': instance.timeMinutes,
  'date': instance.date.toIso8601String(),
  'weather': instance.weather,
  'transit_cost': instance.transitCost,
  'transit_time': instance.transitTime,
  'driving_cost': instance.drivingCost,
  'driving_time': instance.drivingTime,
  'recommended_mode': instance.recommendedMode,
  'followed_recommendation': instance.followedRecommendation,
  'savings_cost': instance.savingsCost,
  'savings_time': instance.savingsTime,
};
