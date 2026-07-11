import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Manages trip-related application state and notifies listeners of changes.
///
/// Holds the currently selected origin, destination, user's current location,
/// saved Home/Work locations, and recent trip history — all in-memory.
class TripProvider extends ChangeNotifier {
  // --- Private state ---

  Location? _origin;
  Location? _destination;
  Location? _currentLocation;
  Location? _home;
  Location? _work;
  List<Trip> _recentTrips = [];

  // --- Public getters ---

  /// The currently selected trip origin.
  Location? get origin => _origin;

  /// The currently selected trip destination.
  Location? get destination => _destination;

  /// The user's current device location (GPS).
  Location? get currentLocation => _currentLocation;

  /// The user's saved home location.
  Location? get home => _home;

  /// The user's saved work location.
  Location? get work => _work;

  /// Recently completed trips, most recent first (capped at 10).
  List<Trip> get recentTrips => List.unmodifiable(_recentTrips);

  // --- Setters ---

  /// Sets the trip origin and notifies listeners.
  void setOrigin(Location location) {
    _origin = location;
    notifyListeners();
  }

  /// Sets the trip destination and notifies listeners.
  void setDestination(Location location) {
    _destination = location;
    notifyListeners();
  }

  /// Updates the user's current device location and notifies listeners.
  void setCurrentLocation(Location location) {
    _currentLocation = location;
    notifyListeners();
  }

  /// Saves a home location and notifies listeners.
  void setHome(Location location) {
    _home = location;
    notifyListeners();
  }

  /// Saves a work location and notifies listeners.
  void setWork(Location location) {
    _work = location;
    notifyListeners();
  }

  /// Adds a [trip] to the beginning of the recent trips list.
  ///
  /// The list is capped at 10 entries.
  void addRecentTrip(Trip trip) {
    _recentTrips.insert(0, trip);
    if (_recentTrips.length > 10) {
      _recentTrips = _recentTrips.sublist(0, 10);
    }
    notifyListeners();
  }

  /// Clears only the current trip's origin and destination.
  void clearTrip() {
    _origin = null;
    _destination = null;
    notifyListeners();
  }
}
