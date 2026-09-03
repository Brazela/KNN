import 'settings_options.dart';

/// A specific car model with its typical fuel type and consumption.
///
/// Lets the Settings page offer "my car is a Perodua Axia" as a shortcut,
/// instead of requiring the user to already know their own fuel
/// consumption figure precisely.
class CarModel {
  /// Creates a [CarModel].
  const CarModel({
    required this.name,
    this.fuelType,
    this.consumptionKmPerL,
  });

  /// Display name, e.g. "Perodua Axia".
  final String name;

  /// Fuel type this car typically takes. Null for [custom].
  final FuelType? fuelType;

  /// Typical fuel consumption, in km per litre. Null for [custom].
  final double? consumptionKmPerL;

  /// Whether this represents "my car isn't listed" rather than a specific
  /// preset — selecting it leaves Fuel Type/Consumption for the user to
  /// fill in manually, instead of auto-filling them.
  bool get isCustom => fuelType == null;

  /// Sentinel entry for "my car isn't in this list".
  static const custom = CarModel(name: 'Other (enter manually)');

  /// Malaysia's common passenger, performance, and commercial car models,
  /// with approximate real-world fuel consumption figures — grouped
  /// roughly by [FuelType] so the dropdown reads in a sensible order.
  /// [custom] is listed first so it's always visible without scrolling.
  static const List<CarModel> predefinedCars = [
    custom,
    // RON95 — everyday passenger cars.
    CarModel(
      name: 'Perodua Axia',
      fuelType: FuelType.ron95,
      consumptionKmPerL: 20.0,
    ),
    CarModel(
      name: 'Perodua Bezza',
      fuelType: FuelType.ron95,
      consumptionKmPerL: 18.0,
    ),
    CarModel(
      name: 'Perodua Myvi',
      fuelType: FuelType.ron95,
      consumptionKmPerL: 16.5,
    ),
    CarModel(
      name: 'Proton Saga',
      fuelType: FuelType.ron95,
      consumptionKmPerL: 16.0,
    ),
    CarModel(
      name: 'Proton X50',
      fuelType: FuelType.ron95,
      consumptionKmPerL: 14.5,
    ),
    CarModel(
      name: 'Honda City',
      fuelType: FuelType.ron95,
      consumptionKmPerL: 17.0,
    ),
    CarModel(
      name: 'Honda Civic',
      fuelType: FuelType.ron95,
      consumptionKmPerL: 15.5,
    ),
    CarModel(
      name: 'Toyota Vios',
      fuelType: FuelType.ron95,
      consumptionKmPerL: 16.0,
    ),
    // RON97 — performance / turbo cars.
    CarModel(
      name: 'Honda Civic Type R',
      fuelType: FuelType.ron97,
      consumptionKmPerL: 11.0,
    ),
    CarModel(
      name: 'BMW 3 Series',
      fuelType: FuelType.ron97,
      consumptionKmPerL: 11.5,
    ),
    CarModel(
      name: 'Mercedes-Benz C-Class',
      fuelType: FuelType.ron97,
      consumptionKmPerL: 11.0,
    ),
    // Diesel — 4x4s / commercial.
    CarModel(
      name: 'Toyota Hilux',
      fuelType: FuelType.diesel,
      consumptionKmPerL: 12.0,
    ),
    CarModel(
      name: 'Isuzu D-Max',
      fuelType: FuelType.diesel,
      consumptionKmPerL: 12.3,
    ),
    CarModel(
      name: 'Mitsubishi Triton',
      fuelType: FuelType.diesel,
      consumptionKmPerL: 11.5,
    ),
    CarModel(
      name: 'Ford Ranger',
      fuelType: FuelType.diesel,
      consumptionKmPerL: 10.5,
    ),
  ];
}
