// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Weather _$WeatherFromJson(Map<String, dynamic> json) => Weather(
  locationName: json['location_name'] as String,
  date: json['date'] as String,
  morningForecast: json['morning_forecast'] as String,
  afternoonForecast: json['afternoon_forecast'] as String,
  nightForecast: json['night_forecast'] as String,
  summaryForecast: json['summary_forecast'] as String,
  summaryWhen: json['summary_when'] as String,
  minTemp: (json['min_temp'] as num).toInt(),
  maxTemp: (json['max_temp'] as num).toInt(),
);

Map<String, dynamic> _$WeatherToJson(Weather instance) => <String, dynamic>{
  'location_name': instance.locationName,
  'date': instance.date,
  'morning_forecast': instance.morningForecast,
  'afternoon_forecast': instance.afternoonForecast,
  'night_forecast': instance.nightForecast,
  'summary_forecast': instance.summaryForecast,
  'summary_when': instance.summaryWhen,
  'min_temp': instance.minTemp,
  'max_temp': instance.maxTemp,
};

WeatherWarning _$WeatherWarningFromJson(Map<String, dynamic> json) =>
    WeatherWarning(
      issued: json['issued'] as String,
      titleEn: json['title_en'] as String,
      titleBm: json['title_bm'] as String,
      validFrom: json['valid_from'] as String,
      validTo: json['valid_to'] as String,
      headingEn: json['heading_en'] as String,
      textEn: json['text_en'] as String,
      instructionEn: json['instruction_en'] as String,
      headingBm: json['heading_bm'] as String,
      textBm: json['text_bm'] as String,
      instructionBm: json['instruction_bm'] as String,
    );

Map<String, dynamic> _$WeatherWarningToJson(WeatherWarning instance) =>
    <String, dynamic>{
      'issued': instance.issued,
      'title_en': instance.titleEn,
      'title_bm': instance.titleBm,
      'valid_from': instance.validFrom,
      'valid_to': instance.validTo,
      'heading_en': instance.headingEn,
      'text_en': instance.textEn,
      'instruction_en': instance.instructionEn,
      'heading_bm': instance.headingBm,
      'text_bm': instance.textBm,
      'instruction_bm': instance.instructionBm,
    };

EarthquakeWarning _$EarthquakeWarningFromJson(Map<String, dynamic> json) =>
    EarthquakeWarning(
      issued: json['issued'] as String,
      titleEn: json['title_en'] as String,
      titleBm: json['title_bm'] as String,
      headingEn: json['heading_en'] as String,
      textEn: json['text_en'] as String,
      headingBm: json['heading_bm'] as String,
      textBm: json['text_bm'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      magnitude: (json['magnitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$EarthquakeWarningToJson(EarthquakeWarning instance) =>
    <String, dynamic>{
      'issued': instance.issued,
      'title_en': instance.titleEn,
      'title_bm': instance.titleBm,
      'heading_en': instance.headingEn,
      'text_en': instance.textEn,
      'heading_bm': instance.headingBm,
      'text_bm': instance.textBm,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'magnitude': instance.magnitude,
    };
