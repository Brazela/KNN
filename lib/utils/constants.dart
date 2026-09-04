import 'package:flutter/material.dart';

abstract class ApiUrls {

  static const String gtfsStaticBaseUrl =
      'https://api.data.gov.my/gtfs-static';

  static const String gtfsRealtimeBaseUrl =
      'https://api.data.gov.my/gtfs-realtime/vehicle-position';

  static const String weatherForecastUrl =
      'https://api.data.gov.my/weather/forecast';

  static const String earthquakeWarningUrl =
      'https://api.data.gov.my/weather/warning/earthquake';

  static const String fuelPriceBaseUrl =
      'https://api.data.gov.my/data-catalogue?id=fuelprice&sort=-date&series_type=level';

  static String fuelPriceUrl({int limit = 1}) =>
      '$fuelPriceBaseUrl&limit=$limit';

  static String get fuelPriceLatestUrl => fuelPriceUrl();

  static String fuelPriceHistoryUrl({int limit = 50}) =>
      fuelPriceUrl(limit: limit);

  static const String googlePlacesAutocompleteUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';

  static const String googlePlacesNewAutocompleteUrl =
      'https://places.googleapis.com/v1/places:autocomplete';

  static const String googlePlaceDetailsUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  static const String googleDistanceMatrixUrl =
      'https://maps.googleapis.com/maps/api/distancematrix/json';

  static const String googlePlacesNearbyUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  static const String googlePlacesNewNearbyUrl =
      'https://places.googleapis.com/v1/places:searchNearby';

  static const String historicalWeatherBaseUrl =
      'https://archive-api.open-meteo.com/v1/archive';
}

abstract class GoogleMapsConfig {

  static const String apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyCwHiN8ZHF35vGGxYfvid1mR_bD_6Ay1zk',
  );
}

abstract class AppColors {

  static const Color primary = Color(0xFF1A2CC8);

  static const Color success = Color(0xFF059669);

  static const Color prelude = Color(0xFFFACC15);

  static const Color darkSlate = Color(0xFF1E293B);

  static const Color darkerSlate = Color(0xFF0F172A);

  static const Color textPrimary = Color(0xFF111827);

  static const Color textSecondary = Color(0xFF6B7280);

  static const Color textMuted = Color(0xFF9CA3AF);

  static const Color border = Color(0xFFE5E7EB);

  static const Color background = Color(0xFFF2F3F7);

  static const Color savingsBackground = Color(0xFFF0FDF4);

  static const Color savingsText = Color(0xFF065F46);
}

abstract class Defaults {

  static const double fuelConsumptionPerKm = 0.15;

  static const String defaultFuelType = 'ron95';

  static const int forecastDays = 7;

  static const double nearbyStopRadiusKm = 1.0;
}

abstract class HttpStatus {

  static const int ok = 200;

  static const int badRequest = 400;

  static const int unauthorized = 401;

  static const int forbidden = 403;

  static const int notFound = 404;

  static const int serverError = 500;
}
