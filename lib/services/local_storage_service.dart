import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Thin wrapper around [SharedPreferences] for persisting small lists as
/// single JSON strings, one per key.
///
/// Stateless by design (no fields, no `ChangeNotifier`) — pages create
/// their own `LocalStorageService()` instance where needed.
class LocalStorageService {
  static const _savedRoutesKey = 'saved_routes';
  static const _fuelHistoryKey = 'fuel_history';

  /// Loads saved routes, or `null` if none have been saved yet.
  Future<List<SavedRoute>?> loadSavedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedRoutesKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => SavedRoute.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Persists the full list of saved routes, replacing whatever was stored
  /// before.
  Future<void> saveSavedRoutes(List<SavedRoute> routes) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(routes.map((r) => r.toJson()).toList());
    await prefs.setString(_savedRoutesKey, encoded);
  }

  /// Loads locally saved fuel price history, or `null` if none saved yet.
  Future<List<FuelPrice>?> loadFuelHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_fuelHistoryKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => FuelPrice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Persists the full fuel price history, replacing whatever was stored.
  Future<void> saveFuelHistory(List<FuelPrice> history) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(history.map((h) => h.toJson()).toList());
    await prefs.setString(_fuelHistoryKey, encoded);
  }
}
