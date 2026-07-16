import 'package:flutter/material.dart';

/// Base URLs for all external APIs used by the app.
abstract class ApiUrls {
  /// data.gov.my GTFS static feed endpoint.
  ///
  /// Append the agency slug, e.g. `gtfsStaticBaseUrl/ktmb`.
  static const String gtfsStaticBaseUrl =
      'https://api.data.gov.my/gtfs-static';

  /// data.gov.my GTFS realtime vehicle position endpoint.
  ///
  /// Append the agency slug, e.g. `gtfsRealtimeBaseUrl/ktmb`.
  static const String gtfsRealtimeBaseUrl =
      'https://api.data.gov.my/gtfs-realtime/vehicle-position';

  /// data.gov.my weather forecast endpoint (returns all districts).
  static const String weatherForecastUrl =
      'https://api.data.gov.my/weather/forecast';

  /// data.gov.my weather warning endpoint.
  static const String weatherWarningUrl =
      'https://api.data.gov.my/weather/warning';

  /// data.gov.my earthquake warning endpoint.
  static const String earthquakeWarningUrl =
      'https://api.data.gov.my/weather/warning/earthquake';

  /// data.gov.my fuel price catalogue endpoint.
  ///
  /// Sorts by date descending and filters for price levels (not weekly
  /// changes) so the first result is always the most recent price.
  static const String fuelPriceBaseUrl =
      'https://api.data.gov.my/data-catalogue?id=fuelprice&sort=-date&series_type=level';

  static String fuelPriceUrl({int limit = 1}) =>
      '$fuelPriceBaseUrl&limit=$limit';

  static String get fuelPriceLatestUrl => fuelPriceUrl();

  static String fuelPriceHistoryUrl({int limit = 50}) =>
      fuelPriceUrl(limit: limit);

  /// Google Maps Places Autocomplete endpoint (classic).
  static const String googlePlacesAutocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  /// Google Places API (New) — Autocomplete.
  static const String googlePlacesNewAutocompleteUrl =
      'https://places.googleapis.com/v1/places:autocomplete';

  /// Google Maps Place Details endpoint.
  static const String googlePlaceDetailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  /// Google Maps Distance Matrix endpoint.
  static const String googleDistanceMatrixUrl =
      'https://maps.googleapis.com/maps/api/distancematrix/json';

  /// Google Maps Places Nearby Search endpoint (classic).
  static const String googlePlacesNearbyUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  /// Google Places API (New) — Nearby Search.
  static const String googlePlacesNewNearbyUrl =
      'https://places.googleapis.com/v1/places:searchNearby';
}

/// Google Maps API configuration.
///
/// TODO: Move this key to `--dart-define` or `flutter_dotenv` before release.
abstract class GoogleMapsConfig {
  /// API key for Google Maps web services.
  static const String apiKey = 'AIzaSyCwHiN8ZHF35vGGxYfvid1mR_bD_6Ay1zk';
}

/// App-wide color palette extracted from the existing UI.
abstract class AppColors {
  /// Primary brand blue.
  static const Color primary = Color(0xFF1A2CC8);

  /// Success / transit accent green.
  static const Color success = Color(0xFF059669);

  /// Dark slate used for status cards.
  static const Color darkSlate = Color(0xFF1E293B);

  /// Darker slate used for gradients.
  static const Color darkerSlate = Color(0xFF0F172A);

  /// Primary text color (near black).
  static const Color textPrimary = Color(0xFF111827);

  /// Secondary text color (gray).
  static const Color textSecondary = Color(0xFF6B7280);

  /// Muted text color.
  static const Color textMuted = Color(0xFF9CA3AF);

  /// Border color for cards and inputs.
  static const Color border = Color(0xFFE5E7EB);

  /// Page background color.
  static const Color background = Color(0xFFF2F3F7);

  /// Light green background for savings highlights.
  static const Color savingsBackground = Color(0xFFF0FDF4);

  /// Dark green text for savings highlights.
  static const Color savingsText = Color(0xFF065F46);
}

/// Default values used by cost estimation and trip planning.
abstract class Defaults {
  /// Default fuel consumption in litres per kilometre.
  static const double fuelConsumptionPerKm = 0.15;

  /// Default fuel type used when the user has not selected one.
  static const String defaultFuelType = 'ron95';

  /// Default trip planning date range in days.
  static const int forecastDays = 7;

  /// Default search radius for nearby stops in kilometres.
  static const double nearbyStopRadiusKm = 1.0;
}

/// Common HTTP status codes used for error handling.
abstract class HttpStatus {
  /// HTTP 200 OK.
  static const int ok = 200;

  /// HTTP 400 Bad Request.
  static const int badRequest = 400;

  /// HTTP 401 Unauthorized.
  static const int unauthorized = 401;

  /// HTTP 403 Forbidden.
  static const int forbidden = 403;

  /// HTTP 404 Not Found.
  static const int notFound = 404;

  /// HTTP 500 Internal Server Error.
  static const int serverError = 500;
}
