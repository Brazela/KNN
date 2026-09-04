import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Local trip history storage backed by [SharedPreferences].
///
/// The whole history is stored as one JSON array under a single key and
/// mirrored in memory; every mutation rewrites the key. There is no schema,
/// so there are no migrations that can fail silently.
class TripHistoryService {
  /// Storage key holding the JSON-encoded trip list.
  static const String _storageKey = 'trips_history';

  /// Upper bound on stored trips so the preferences blob stays small.
  static const int _maxTrips = 500;

  List<Trip>? _cache;

  /// Loads the stored history once and caches it in memory.
  ///
  /// A corrupt or incompatible payload is treated as an empty history
  /// rather than crashing every read.
  Future<List<Trip>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = [];
      return _cache!;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _cache = decoded
          .map((entry) => Trip.fromJson(entry as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('TripHistoryService: failed to decode stored trips: $e');
      _cache = [];
    }
    return _cache!;
  }

  /// Persists the in-memory cache. Failures are logged; the in-memory list
  /// remains the session's source of truth either way.
  Future<void> _persist(List<Trip> trips) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(trips.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('TripHistoryService: failed to persist trips: $e');
    }
  }

  /// Inserts or replaces [trip] (matched by [Trip.id]), newest first.
  Future<void> insertTrip(Trip trip) async {
    final trips = await _load();
    trips.removeWhere((t) => t.id == trip.id);
    trips.insert(0, trip);
    if (trips.length > _maxTrips) {
      trips.removeRange(_maxTrips, trips.length);
    }
    await _persist(trips);
  }

  /// Returns trips filtered by [mode] and [searchQuery], newest first.
  ///
  /// [searchQuery] matches the origin or destination address
  /// case-insensitively, mirroring the previous SQL LIKE behaviour.
  Future<List<Trip>> getTrips({
    TravelMode? mode,
    String? searchQuery,
    int limit = 10,
    int offset = 0,
  }) async {
    final filtered = _filter(await _load(), mode, searchQuery);
    return _page(filtered, limit, offset);
  }

  /// Counts trips matching [mode] and [searchQuery].
  Future<int> countTrips({
    TravelMode? mode,
    String? searchQuery,
  }) async {
    return _filter(await _load(), mode, searchQuery).length;
  }

  /// Returns every stored trip, newest first.
  Future<List<Trip>> getAllTrips() async {
    return List.of(await _load());
  }

  /// Deletes every stored trip.
  Future<void> clearHistory() async {
    _cache = [];
    await _persist(_cache!);
  }

  /// Deletes the trip with the given [id], if present.
  Future<void> deleteTrip(String id) async {
    final trips = await _load();
    trips.removeWhere((t) => t.id == id);
    await _persist(trips);
  }

  /// Aggregate stats over trips that carry a recommendation.
  ///
  /// Keys: `total`, `transit_recs`, `driving_recs`, `total_savings`.
  Future<Map<String, dynamic>> getRecommendationStats() async {
    final recs =
        (await _load()).where((t) => t.recommendedMode != null).toList();
    final totalSavings = recs.fold<double>(
      0,
      (sum, t) => sum + (t.savingsCost ?? 0),
    );
    return {
      'total': recs.length,
      'transit_recs':
          recs.where((t) => t.recommendedMode == 'transit').length,
      'driving_recs':
          recs.where((t) => t.recommendedMode == 'driving').length,
      'total_savings': totalSavings,
    };
  }

  /// Returns trips that carry a recommendation, newest first.
  Future<List<Trip>> getRecommendations({
    int limit = 5,
    int offset = 0,
  }) async {
    final recs =
        (await _load()).where((t) => t.recommendedMode != null).toList();
    return _page(recs, limit, offset);
  }

  /// Counts trips that carry a recommendation.
  Future<int> countRecommendations() async {
    return (await _load()).where((t) => t.recommendedMode != null).length;
  }

  /// Filters [trips] by [mode] and [searchQuery], sorted newest first.
  List<Trip> _filter(
    List<Trip> trips,
    TravelMode? mode,
    String? searchQuery,
  ) {
    final query = searchQuery?.toLowerCase() ?? '';
    return trips.where((trip) {
      if (mode != null && trip.mode != mode) return false;
      if (query.isEmpty) return true;
      final origin = trip.origin.address?.toLowerCase() ?? '';
      final destination = trip.destination.address?.toLowerCase() ?? '';
      return origin.contains(query) || destination.contains(query);
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Slices [items] to the [limit]/[offset] window, bounds-safe.
  List<Trip> _page(List<Trip> items, int limit, int offset) {
    final start = offset.clamp(0, items.length).toInt();
    final end = (offset + limit).clamp(0, items.length).toInt();
    return items.sublist(start, end);
  }
}
