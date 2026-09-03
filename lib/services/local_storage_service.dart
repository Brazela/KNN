import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Thin wrapper around [SharedPreferences] for persisting the small,
/// list-shaped data this app's UI-mockup phase used to hardcode.
///
/// Per the team's decision, this app uses simple key/value phone storage
/// rather than a full database (SQLite/Hive) — each list is serialized to
/// one JSON string under one key. This is a reasonable fit for how small
/// these lists are (a handful of favorites/saved routes), and keeps every
/// page's persistence logic in one place instead of scattered across
/// widgets.
///
/// Stateless by design (no fields, no `ChangeNotifier`) — there's nothing
/// here for a widget to *listen* to, only read/write, so this isn't
/// registered in `main.dart`'s `MultiProvider`. Pages just create their own
/// `LocalStorageService()` instance where needed.
class LocalStorageService {
  static const _favoritesKey = 'favorites';
  static const _savedRoutesKey = 'saved_routes';

  /// Loads saved favorite locations, or `null` if none have been saved yet
  /// (e.g. first run).
  Future<List<FavoriteLocation>?> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_favoritesKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => FavoriteLocation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Persists the full list of favorite locations, replacing whatever was
  /// stored before.
  Future<void> saveFavorites(List<FavoriteLocation> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(favorites.map((f) => f.toJson()).toList());
    await prefs.setString(_favoritesKey, encoded);
  }

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
}
