import 'package:json_annotation/json_annotation.dart';

import 'driving_route.dart';
import 'location.dart';
import 'route.dart';
import 'weather.dart';

part 'comparison.g.dart';

/// Recommendation result for a transit-vs-driving comparison.
enum Recommendation { transit, driving, either }

/// A side-by-side comparison between transit and driving options.
@JsonSerializable(fieldRename: FieldRename.snake)
class Comparison {
  /// Creates a [Comparison].
  const Comparison({
    required this.origin,
    required this.destination,
    required this.transitOption,
    required this.drivingOption,
    required this.recommendation,
    required this.recommendationReason,
    this.weather,
  });

  /// Creates a [Comparison] from a JSON map.
  factory Comparison.fromJson(Map<String, dynamic> json) =>
      _$ComparisonFromJson(json);

  /// Origin location.
  final Location origin;

  /// Destination location.
  final Location destination;

  /// Best transit option.
  final TransitRoute transitOption;

  /// Best driving option.
  final DrivingRoute drivingOption;

  /// Recommended mode.
  @JsonKey(fromJson: _recommendationFromJson, toJson: _recommendationToJson)
  final Recommendation recommendation;

  /// Human-readable reason for the recommendation.
  final String recommendationReason;

  /// Optional weather context.
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

  /// Converts this [Comparison] to a JSON map.
  Map<String, dynamic> toJson() => _$ComparisonToJson(this);
}
