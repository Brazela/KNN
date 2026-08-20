import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Persists the user's saved Home and Work places on-device using
/// [SharedPreferences] (key-value storage — no database).
class SavedPlacesService {
  static const String _homeKey = 'saved_home';
  static const String _workKey = 'saved_work';

  /// Loads the saved home place, or null if not set.
  Future<Location?> getHome() => _read(_homeKey);

  /// Saves (or clears, when [location] is null) the home place.
  Future<void> setHome(Location? location) => _write(_homeKey, location);

  /// Loads the saved work place, or null if not set.
  Future<Location?> getWork() => _read(_workKey);

  /// Saves (or clears, when [location] is null) the work place.
  Future<void> setWork(Location? location) => _write(_workKey, location);

  Future<Location?> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Location.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _write(String key, Location? location) async {
    final prefs = await SharedPreferences.getInstance();
    if (location == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, jsonEncode(location.toJson()));
    }
  }
}