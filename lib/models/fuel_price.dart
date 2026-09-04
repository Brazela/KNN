import 'package:json_annotation/json_annotation.dart';

part 'fuel_price.g.dart';


@JsonSerializable(fieldRename: FieldRename.snake)
class FuelPrice {
  
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

  
  factory FuelPrice.fromJson(Map<String, dynamic> json) =>
      _$FuelPriceFromJson(json);

  
  final String date;

  
  final double ron95;

  
  final double ron97;

  
  final double diesel;


  @JsonKey(name: 'diesel_eastmsia')
  final double? dieselEastMsia;

  
  final double? ron95Skps;

  
  final double? dieselBudi;

  
  final double? dieselSkds;

  
  final double? ron95Budi95;

  
  final String? seriesType;

  
  Map<String, dynamic> toJson() => _$FuelPriceToJson(this);
}
