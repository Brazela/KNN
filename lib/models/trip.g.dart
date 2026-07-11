// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
};
