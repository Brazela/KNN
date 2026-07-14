import 'package:json_annotation/json_annotation.dart';

part 'fuel_price.g.dart';

/// Latest fuel prices published by data.gov.my.
@JsonSerializable(fieldRename: FieldRename.snake)
class FuelPrice {
  /// Creates a [FuelPrice].
  const FuelPrice({
    required this.date,
    required this.ron95,
    required this.ron97,
    required this.diesel,
    required this.dieselEastMsia,
    this.ron95Skps,
    this.dieselBudi,
    this.dieselSkds,
    this.ron95Budi95,
    this.seriesType,
  });

  /// Creates a [FuelPrice] from a JSON map.
  factory FuelPrice.fromJson(Map<String, dynamic> json) =>
      _$FuelPriceFromJson(json);

  /// Price effective date in YYYY-MM-DD format.
  final String date;

  /// Price of RON95 in MYR per litre.
  final double ron95;

  /// Price of RON97 in MYR per litre.
  final double ron97;

  /// Price of diesel in Peninsular Malaysia in MYR per litre.
  final double diesel;

  /// Price of diesel in East Malaysia in MYR per litre.
  ///
  /// May be `null` in recent records where the government no longer sets a
  /// separate price for East Malaysia.
  @JsonKey(name: 'diesel_eastmsia')
  final double? dieselEastMsia;

  /// RON95 price for SKPS, if available.
  final double? ron95Skps;

  /// Diesel price under BUDI scheme, if available.
  final double? dieselBudi;

  /// Diesel price under SKDS, if available.
  final double? dieselSkds;

  /// RON95 price under BUDI95, if available.
  final double? ron95Budi95;

  /// Series type identifier, if available.
  final String? seriesType;

  /// Converts this [FuelPrice] to a JSON map.
  Map<String, dynamic> toJson() => _$FuelPriceToJson(this);
}
