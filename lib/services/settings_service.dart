import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../utils/constants.dart';

class SettingsService extends ChangeNotifier {
  static const _defaultModeKey = 'settings_default_mode';
  static const _carModelKey = 'settings_car_model';
  static const _fuelTypeKey = 'settings_fuel_type';
  static const _fuelConsumptionKey = 'settings_fuel_consumption';
  static const _priceAlertsKey = 'settings_price_alerts';

  DefaultTravelMode defaultMode = DefaultTravelMode.fastest;
  String carModelName = '';
  FuelType fuelType = FuelType.ron95;
  double fuelConsumptionPerKm = Defaults.fuelConsumptionPerKm;
  bool priceAlerts = true;

  CarModel get selectedCar {
    for (final car in CarModel.predefinedCars) {
      if (car.name == carModelName) return car;
    }
    return CarModel.custom;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    defaultMode = DefaultTravelMode.values.firstWhere(
      (e) => e.name == prefs.getString(_defaultModeKey),
      orElse: () => DefaultTravelMode.fastest,
    );
    carModelName = prefs.getString(_carModelKey) ?? '';
    fuelType = FuelType.values.firstWhere(
      (e) => e.name == prefs.getString(_fuelTypeKey),
      orElse: () => FuelType.ron95,
    );
    fuelConsumptionPerKm =
        prefs.getDouble(_fuelConsumptionKey) ?? Defaults.fuelConsumptionPerKm;
    priceAlerts = prefs.getBool(_priceAlertsKey) ?? true;
    notifyListeners();
  }

  Future<void> setDefaultMode(DefaultTravelMode value) async {
    defaultMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultModeKey, value.name);
  }

  Future<void> setCarModel(CarModel car) async {
    carModelName = car.name;
    if (!car.isCustom) {
      fuelType = car.fuelType!;
      fuelConsumptionPerKm = 1 / car.consumptionKmPerL!;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_carModelKey, car.name);
    await prefs.setString(_fuelTypeKey, fuelType.name);
    await prefs.setDouble(_fuelConsumptionKey, fuelConsumptionPerKm);
  }

  Future<void> setFuelType(FuelType value) async {
    fuelType = value;
    carModelName = '';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fuelTypeKey, value.name);
    await prefs.setString(_carModelKey, '');
  }

  Future<void> setFuelConsumptionKmPerL(double kmPerL) async {
    fuelConsumptionPerKm = 1 / kmPerL;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fuelConsumptionKey, fuelConsumptionPerKm);
  }

  Future<void> setPriceAlerts(bool value) async {
    priceAlerts = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_priceAlertsKey, value);
  }
}
