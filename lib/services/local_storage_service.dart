import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class LocalStorageService {
  static const _savedRoutesKey = 'saved_routes';
  static const _fuelHistoryKey = 'fuel_history';

  Future<List<SavedRoute>?> loadSavedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedRoutesKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => SavedRoute.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSavedRoutes(List<SavedRoute> routes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(routes.map((r) => r.toJson()).toList());
    await prefs.setString(_savedRoutesKey, encoded);
  }

  Future<List<FuelPrice>?> loadFuelHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_fuelHistoryKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => FuelPrice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveFuelHistory(List<FuelPrice> history) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(history.map((h) => h.toJson()).toList());
    await prefs.setString(_fuelHistoryKey, encoded);
  }
}
