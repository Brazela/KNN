import 'package:json_annotation/json_annotation.dart';

import 'driving_route.dart';
import 'location.dart';
import 'route.dart';
import 'weather.dart';

part 'comparison.g.dart';

enum Recommendation { transit, driving, either }

@JsonSerializable(fieldRename: FieldRename.snake)
class Comparison {

  const Comparison({
    required this.origin,
    required this.destination,
    required this.transitOption,
    required this.drivingOption,
    required this.recommendation,
    required this.recommendationReason,
    this.weather,
  });

  factory Comparison.fromJson(Map<String, dynamic> json) =>
      _$ComparisonFromJson(json);

  final Location origin;

  final Location destination;

  final TransitRoute transitOption;

  final DrivingRoute drivingOption;

  @JsonKey(fromJson: _recommendationFromJson, toJson: _recommendationToJson)
  final Recommendation recommendation;

  final String recommendationReason;

  final Weather? weather;

  static Recommendation _recommendationFromJson(String value) {
    switch (value) {
      case 'transit':
        return Recommendation.transit;
      case 'driving':
        return Recommendation.driving;
      default:
        return Recommendation.either;
    }
  }

  static String _recommendationToJson(Recommendation recommendation) =>
      recommendation.name;

  Map<String, dynamic> toJson() => _$ComparisonToJson(this);
}
