// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_price.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FuelPrice _$FuelPriceFromJson(Map<String, dynamic> json) => FuelPrice(
  date: json['date'] as String,
  ron95: (json['ron95'] as num).toDouble(),
  ron97: (json['ron97'] as num).toDouble(),
  diesel: (json['diesel'] as num).toDouble(),
  dieselEastMsia: (json['diesel_eastmsia'] as num?)?.toDouble(),
  ron95Skps: (json['ron95_skps'] as num?)?.toDouble(),
  dieselBudi: (json['diesel_budi'] as num?)?.toDouble(),
  dieselSkds: (json['diesel_skds'] as num?)?.toDouble(),
  ron95Budi95: (json['ron95_budi95'] as num?)?.toDouble(),
  seriesType: json['series_type'] as String?,
);

Map<String, dynamic> _$FuelPriceToJson(FuelPrice instance) => <String, dynamic>{
  'date': instance.date,
  'ron95': instance.ron95,
  'ron97': instance.ron97,
  'diesel': instance.diesel,
  'diesel_eastmsia': instance.dieselEastMsia,
  'ron95_skps': instance.ron95Skps,
  'diesel_budi': instance.dieselBudi,
  'diesel_skds': instance.dieselSkds,
  'ron95_budi95': instance.ron95Budi95,
  'series_type': instance.seriesType,
};
