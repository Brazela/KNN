
part of 'weather.dart';

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

MonthlyAverage _$MonthlyAverageFromJson(Map<String, dynamic> json) =>
    MonthlyAverage(
      avgTemp: (json['avg_temp'] as num).toDouble(),
      rainDays: (json['rain_days'] as num).toInt(),
      avgHumidity: (json['avg_humidity'] as num).toDouble(),
      year: (json['year'] as num).toInt(),
      month: (json['month'] as num).toInt(),
      hottestTemp: (json['hottest_temp'] as num).toDouble(),
      hottestDate: json['hottest_date'] as String,
      coldestTemp: (json['coldest_temp'] as num).toDouble(),
      coldestDate: json['coldest_date'] as String,
    );

Map<String, dynamic> _$MonthlyAverageToJson(MonthlyAverage instance) =>
    <String, dynamic>{
      'avg_temp': instance.avgTemp,
      'rain_days': instance.rainDays,
      'avg_humidity': instance.avgHumidity,
      'year': instance.year,
      'month': instance.month,
      'hottest_temp': instance.hottestTemp,
      'hottest_date': instance.hottestDate,
      'coldest_temp': instance.coldestTemp,
      'coldest_date': instance.coldestDate,
    };
