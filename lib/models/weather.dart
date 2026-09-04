import 'package:json_annotation/json_annotation.dart';

part 'weather.g.dart';


@JsonSerializable(fieldRename: FieldRename.snake)
class Weather {
  
  const Weather({
    required this.locationName,
    required this.date,
    required this.morningForecast,
    required this.afternoonForecast,
    required this.nightForecast,
    required this.summaryForecast,
    required this.summaryWhen,
    required this.minTemp,
    required this.maxTemp,
  });

  
  
  
  
  factory Weather.fromJson(Map<String, dynamic> json) {
    
    
    final location = json['location'] as Map<String, dynamic>?;
    if (location != null && location['location_name'] != null) {
      json = Map<String, dynamic>.from(json);
      json['location_name'] = location['location_name'];
    }
    return _$WeatherFromJson(json);
  }

  
  final String locationName;

  
  final String date;

  
  final String morningForecast;

  
  final String afternoonForecast;

  
  final String nightForecast;

  
  final String summaryForecast;

  
  final String summaryWhen;

  
  final int minTemp;

  
  final int maxTemp;

  
  Map<String, dynamic> toJson() => _$WeatherToJson(this);
}


@JsonSerializable(fieldRename: FieldRename.snake)
class EarthquakeWarning {
  
  const EarthquakeWarning({
    required this.issued,
    required this.titleEn,
    required this.titleBm,
    required this.headingEn,
    required this.textEn,
    required this.headingBm,
    required this.textBm,
    this.latitude,
    this.longitude,
    this.magnitude,
  });

  
  factory EarthquakeWarning.fromJson(Map<String, dynamic> json) =>
      _$EarthquakeWarningFromJson(json);

  
  final String issued;

  
  final String titleEn;

  
  final String titleBm;

  
  final String headingEn;

  
  final String textEn;

  
  final String headingBm;

  
  final String textBm;

  
  final double? latitude;

  
  final double? longitude;

  
  final double? magnitude;

  
  Map<String, dynamic> toJson() => _$EarthquakeWarningToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class MonthlyAverage {
  const MonthlyAverage({
    required this.avgTemp,
    required this.rainDays,
    required this.avgHumidity,
    required this.year,
    required this.month,
    required this.hottestTemp,
    required this.hottestDate,
    required this.coldestTemp,
    required this.coldestDate,
  });

  factory MonthlyAverage.fromJson(Map<String, dynamic> json) =>
      _$MonthlyAverageFromJson(json);

  final double avgTemp;
  final int rainDays;
  final double avgHumidity;
  final int year;
  final int month;
  final double hottestTemp;
  final String hottestDate;
  final double coldestTemp;
  final String coldestDate;

  Map<String, dynamic> toJson() => _$MonthlyAverageToJson(this);

  @override
  String toString() =>
      'MonthlyAverage($year-$month, avgTemp: $avgTemp, rainDays: $rainDays)';
}
