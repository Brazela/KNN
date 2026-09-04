import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class TripHistoryService {
  static const String _storageKey = 'trips_history';

  static const int _maxTrips = 500;

  List<Trip>? _cache;

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

  Future<void> _persist(List<Trip> trips) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(trips.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('TripHistoryService: failed to persist trips: $e');
    }
  }

  Future<void> insertTrip(Trip trip) async {
    final trips = await _load();
    trips.removeWhere((t) => t.id == trip.id);
    trips.insert(0, trip);
    if (trips.length > _maxTrips) {
      trips.removeRange(_maxTrips, trips.length);
    }
    await _persist(trips);
  }

  Future<List<Trip>> getTrips({
    TravelMode? mode,
    String? searchQuery,
    int limit = 10,
    int offset = 0,
  }) async {
    final filtered = _filter(await _load(), mode, searchQuery);
    return _page(filtered, limit, offset);
  }

  Future<int> countTrips({
    TravelMode? mode,
    String? searchQuery,
  }) async {
    return _filter(await _load(), mode, searchQuery).length;
  }

  Future<List<Trip>> getAllTrips() async {
    return List.of(await _load());
  }

  Future<List<Trip>> getTripsForDate(DateTime date) async {
    final all = await _load();
    return all
        .where((t) =>
            t.date.year == date.year &&
            t.date.month == date.month &&
            t.date.day == date.day)
        .toList();
  }

  Future<void> clearHistory() async {
    _cache = [];
    await _persist(_cache!);
  }

  Future<void> deleteTrip(String id) async {
    final trips = await _load();
    trips.removeWhere((t) => t.id == id);
    await _persist(trips);
  }

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

  Future<List<Trip>> getRecommendations({
    int limit = 5,
    int offset = 0,
  }) async {
    final recs =
        (await _load()).where((t) => t.recommendedMode != null).toList();
    return _page(recs, limit, offset);
  }

  Future<int> countRecommendations() async {
    return (await _load()).where((t) => t.recommendedMode != null).length;
  }

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

  List<Trip> _page(List<Trip> items, int limit, int offset) {
    final start = offset.clamp(0, items.length).toInt();
    final end = (offset + limit).clamp(0, items.length).toInt();
    return items.sublist(start, end);
  }
}
