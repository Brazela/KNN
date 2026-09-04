import 'settings_options.dart';


class CarModel {
  
  const CarModel({
    required this.name,
    this.fuelType,
    this.consumptionKmPerL,
  });

  
  final String name;

  
  final FuelType? fuelType;

  
  final double? consumptionKmPerL;

  bool get isCustom => fuelType == null;

  static const custom = CarModel(name: 'Other (enter manually)');

  static const List<CarModel> predefinedCars = [
    custom,
    
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
