import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Persists the user's Home and Work places on-device.
class SavedPlacesService {
  static const _homeKey = 'saved_home';
  static const _workKey = 'saved_work';

  Future<Location?> getHome() => _read(_homeKey);
  Future<Location?> getWork() => _read(_workKey);
  Future<void> setHome(Location? location) => _write(_homeKey, location);
  Future<void> setWork(Location? location) => _write(_workKey, location);

  Future<Location?> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return null;
    return Location.fromJson(jsonDecode(raw) as Map<String, dynamic>);
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