import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/services.dart';

class TripProvider extends ChangeNotifier {
  Location? _origin;
  Location? _destination;
  Location? _currentLocation;
  Location? _home;
  Location? _work;
  List<Trip> _recentTrips = [];
  TripHistoryService? _tripHistoryService;

  Location? get origin => _origin;
  Location? get destination => _destination;
  Location? get currentLocation => _currentLocation;
  Location? get home => _home;
  Location? get work => _work;
  List<Trip> get recentTrips => List.unmodifiable(_recentTrips);

  void setOrigin(Location location) {
    _origin = location;
    notifyListeners();
  }

  void setDestination(Location location) {
    _destination = location;
    notifyListeners();
  }

  void setCurrentLocation(Location location) {
    _currentLocation = location;
    notifyListeners();
  }

  void setHome(Location location) {
    _home = location;
    notifyListeners();
  }

  void setWork(Location location) {
    _work = location;
    notifyListeners();
  }

  void addRecentTrip(Trip trip) {
    _recentTrips.insert(0, trip);
    if (_recentTrips.length > 10) {
      _recentTrips = _recentTrips.sublist(0, 10);
    }
    unawaited(
      _tripHistoryService?.insertTrip(trip).catchError((_) {}),
    );
    notifyListeners();
  }

  void clearTrip() {
    _origin = null;
    _destination = null;
    notifyListeners();
  }

  Future<void> initHistoryService(TripHistoryService service) async {
    _tripHistoryService = service;
    _recentTrips = await service.getTrips(limit: 10);
    notifyListeners();
  }

  Future<List<Trip>> getFilteredTrips({
    TravelMode? mode,
    String? searchQuery,
    int limit = 10,
    int offset = 0,
  }) async {
    if (_tripHistoryService == null) return [];
    return _tripHistoryService!.getTrips(
      mode: mode,
      searchQuery: searchQuery,
      limit: limit,
      offset: offset,
    );
  }

  Future<Map<String, dynamic>> getRecommendationStats() async {
    if (_tripHistoryService == null) return {};
    return _tripHistoryService!.getRecommendationStats();
  }

  Future<List<Trip>> getRecommendations({
    int limit = 5,
    int offset = 0,
  }) async {
    if (_tripHistoryService == null) return [];
    return _tripHistoryService!.getRecommendations(
      limit: limit,
      offset: offset,
    );
  }

  Future<int> countRecommendations() async {
    if (_tripHistoryService == null) return 0;
    return _tripHistoryService!.countRecommendations();
  }

  Future<int> countFilteredTrips({
    TravelMode? mode,
    String? searchQuery,
  }) async {
    if (_tripHistoryService == null) return 0;
    return _tripHistoryService!.countTrips(
      mode: mode,
      searchQuery: searchQuery,
    );
  }
}
