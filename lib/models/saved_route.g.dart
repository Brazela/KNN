
part of 'saved_route.dart';

SavedRoute _$SavedRouteFromJson(Map<String, dynamic> json) => SavedRoute(
  id: json['id'] as String,
  origin: Location.fromJson(json['origin'] as Map<String, dynamic>),
  destination: Location.fromJson(json['destination'] as Map<String, dynamic>),
  mode: $enumDecode(_$TravelModeEnumMap, json['mode']),
  cost: (json['cost'] as num).toDouble(),
  timeMinutes: (json['timeMinutes'] as num).toInt(),
  savingsPerTripRM: (json['savingsPerTripRM'] as num).toDouble(),
);

Map<String, dynamic> _$SavedRouteToJson(SavedRoute instance) =>
    <String, dynamic>{
      'id': instance.id,
      'origin': instance.origin,
      'destination': instance.destination,
      'mode': _$TravelModeEnumMap[instance.mode]!,
      'cost': instance.cost,
      'timeMinutes': instance.timeMinutes,
      'savingsPerTripRM': instance.savingsPerTripRM,
    };

const _$TravelModeEnumMap = {
  TravelMode.transit: 'transit',
  TravelMode.driving: 'driving',
};
