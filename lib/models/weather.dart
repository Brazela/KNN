import 'package:json_annotation/json_annotation.dart';

part 'weather.g.dart';

/// Represents a daily weather forecast for a specific Malaysian district.
@JsonSerializable(fieldRename: FieldRename.snake)
class Weather {
  /// Creates a [Weather] forecast.
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

  /// Creates a [Weather] from a JSON map.
  ///
  /// Handles the nested `location` object format returned by the
  /// data.gov.my weather API (e.g. `{"location": {"location_name": "..."}}`).
  factory Weather.fromJson(Map<String, dynamic> json) {
    // The API nests location_name inside a `location` object.
    // Flatten it to the top level so the generated code works.
    final location = json['location'] as Map<String, dynamic>?;
    if (location != null && location['location_name'] != null) {
      json = Map<String, dynamic>.from(json);
      json['location_name'] = location['location_name'];
    }
    return _$WeatherFromJson(json);
  }

  /// District or location name (e.g. "Kuala Lumpur").
  final String locationName;

  /// Forecast date in YYYY-MM-DD format.
  final String date;

  /// Morning forecast description in Malay.
  final String morningForecast;

  /// Afternoon forecast description in Malay.
  final String afternoonForecast;

  /// Night forecast description in Malay.
  final String nightForecast;

  /// Short summary forecast description.
  final String summaryForecast;

  /// Time-of-day qualifier for the summary (e.g. "Pagi", "Petang").
  final String summaryWhen;

  /// Minimum temperature in Celsius.
  final int minTemp;

  /// Maximum temperature in Celsius.
  final int maxTemp;

  /// Converts this [Weather] to a JSON map.
  Map<String, dynamic> toJson() => _$WeatherToJson(this);
}

/// A weather warning issued by the Malaysian Meteorological Department.
@JsonSerializable(fieldRename: FieldRename.snake)
class WeatherWarning {
  /// Creates a [WeatherWarning].
  const WeatherWarning({
    required this.issued,
    required this.titleEn,
    required this.titleBm,
    required this.validFrom,
    required this.validTo,
    required this.headingEn,
    required this.textEn,
    required this.instructionEn,
    required this.headingBm,
    required this.textBm,
    required this.instructionBm,
  });

  /// Creates a [WeatherWarning] from a JSON map.
  factory WeatherWarning.fromJson(Map<String, dynamic> json) =>
      _$WeatherWarningFromJson(json);

  /// ISO 8601 timestamp when the warning was issued.
  final String issued;

  /// Warning title in English.
  final String titleEn;

  /// Warning title in Bahasa Malaysia.
  final String titleBm;

  /// ISO 8601 timestamp when the warning becomes valid.
  final String validFrom;

  /// ISO 8601 timestamp when the warning expires.
  final String validTo;

  /// Warning heading in English.
  final String headingEn;

  /// Warning body text in English.
  final String textEn;

  /// Safety instructions in English.
  final String instructionEn;

  /// Warning heading in Bahasa Malaysia.
  final String headingBm;

  /// Warning body text in Bahasa Malaysia.
  final String textBm;

  /// Safety instructions in Bahasa Malaysia.
  final String instructionBm;

  /// Converts this [WeatherWarning] to a JSON map.
  Map<String, dynamic> toJson() => _$WeatherWarningToJson(this);
}

/// An earthquake warning or report issued by the authorities.
@JsonSerializable(fieldRename: FieldRename.snake)
class EarthquakeWarning {
  /// Creates an [EarthquakeWarning].
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

  /// Creates an [EarthquakeWarning] from a JSON map.
  factory EarthquakeWarning.fromJson(Map<String, dynamic> json) =>
      _$EarthquakeWarningFromJson(json);

  /// ISO 8601 timestamp when the report was issued.
  final String issued;

  /// Report title in English.
  final String titleEn;

  /// Report title in Bahasa Malaysia.
  final String titleBm;

  /// Report heading in English.
  final String headingEn;

  /// Report body text in English.
  final String textEn;

  /// Report heading in Bahasa Malaysia.
  final String headingBm;

  /// Report body text in Bahasa Malaysia.
  final String textBm;

  /// Epicenter latitude, if available.
  final double? latitude;

  /// Epicenter longitude, if available.
  final double? longitude;

  /// Earthquake magnitude, if available.
  final double? magnitude;

  /// Converts this [EarthquakeWarning] to a JSON map.
  Map<String, dynamic> toJson() => _$EarthquakeWarningToJson(this);
}
