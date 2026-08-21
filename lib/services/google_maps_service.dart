import 'dart:convert';

import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../utils/constants.dart';

/// Service responsible for Google Maps web service APIs (REST fallback).
///
/// For Place Autocomplete use [NativePlacesService] instead.
/// This service handles Place Details, Distance Matrix, and Nearby Search
/// which are not available through the native Places SDK.
class GoogleMapsService {
  /// Creates a [GoogleMapsService].
  ///
  /// An optional [http.Client] can be injected for testing.
  GoogleMapsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Returns a human-readable emoji for a list of Google Places [types].
  ///
  /// Used by [PopularPlacesWidget] to display a category icon for each
  /// nearby place card.
  static String categoryEmoji(List<String> types) {
    for (final t in types) {
      if (t == 'restaurant' || t == 'meal_takeaway' || t == 'meal_delivery') {
        return '🍽️';
      }
      if (t == 'cafe' || t == 'bakery') return '☕';
      if (t == 'subway_station' ||
          t == 'transit_station' ||
          t == 'train_station') {
        return '🚇';
      }
      if (t == 'bus_station' || t == 'bus_stop') return '🚌';
      if (t == 'shopping_mall' || t == 'store') return '🛍️';
      if (t == 'hospital' || t == 'health') return '🏥';
      if (t == 'gas_station') return '⛽';
      if (t == 'park' || t == 'parking') return '🅿️';
      if (t == 'museum' || t == 'art_gallery') return '🏛️';
    }
    return '📍';
  }

  /// Builds a URI for Google Maps REST API calls using [Uri.https].
  ///
  /// Properly encodes all query parameters and avoids encoding issues
  /// that can occur with [Uri.parse] + [Uri.replace].
  Uri _buildUri(String host, String path, Map<String, String> params) {
    return Uri.https(host, path, params);
  }

  /// Returns autocomplete suggestions via REST API (fallback).
  ///
  /// Prefer using [NativePlacesService.autocomplete] on Android.
  @Deprecated('Use NativePlacesService instead')
  Future<List<PlaceSuggestion>> autocomplete(
    String query, {
    String? sessionToken,
  }) async {
    final params = <String, String>{
      'input': query,
      'key': GoogleMapsConfig.apiKey,
      'components': 'country:my',
    };
    if (sessionToken != null) params['sessiontoken'] = sessionToken;

    final uri = _buildUri('maps.googleapis.com',
        '/maps/api/place/autocomplete/json', params);

    final http.Response response;
    try {
      response = await _client.get(uri);
    } on http.ClientException catch (e) {
      throw Exception(
          'Network error fetching place suggestions: ${e.message} (uri: $uri)');
    }

    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Failed to fetch place suggestions: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'UNKNOWN_ERROR';

    if (status != 'OK' && status != 'ZERO_RESULTS') {
      throw Exception('Google Places API error: $status');
    }

    final predictions = data['predictions'] as List<dynamic>? ?? [];
    return predictions
        .map((json) => PlaceSuggestion.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches detailed location information for a given [placeId].
  ///
  /// Uses the new Places API (`GET /v1/places/{placeId}`).
  /// Throws an exception if the request fails.
  Future<PlaceDetail> getPlaceDetails(String placeId) async {
    final uri = Uri.https(
      'places.googleapis.com',
      '/v1/places/${Uri.encodeComponent(placeId)}',
      {'key': GoogleMapsConfig.apiKey},
    );

    try {
      final response = await _client.get(
        uri,
        headers: {
          'X-Goog-FieldMask':
              'id,displayName,formattedAddress,location',
        },
      );

      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
          'Failed to fetch place details: ${response.statusCode} — ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final displayName = data['displayName'] as Map<String, dynamic>?;
      final loc = data['location'] as Map<String, dynamic>?;

      return PlaceDetail(
        placeId: data['id'] as String? ?? placeId,
        latitude: (loc?['latitude'] as num?)?.toDouble() ?? 0.0,
        longitude: (loc?['longitude'] as num?)?.toDouble() ?? 0.0,
        formattedAddress: data['formattedAddress'] as String? ?? '',
        name: displayName?['text'] as String?,
      );
    } on http.ClientException catch (e) {
      throw Exception(
          'Network error fetching place details: ${e.message} (uri: $uri)');
    }
  }

  /// Fetches driving distance and duration between two coordinates.
  ///
  /// [origin] and [destination] should be `Location` models.
  /// Returns a [DistanceMatrix] result.
  /// Throws an exception if the request fails or no route is found.
  Future<DistanceMatrix> getDistanceMatrix(
    Location origin,
    Location destination,
  ) async {
    final originStr = '${origin.latitude},${origin.longitude}';
    final destinationStr = '${destination.latitude},${destination.longitude}';

    final params = <String, String>{
      'origins': originStr,
      'destinations': destinationStr,
      'mode': 'driving',
      'key': GoogleMapsConfig.apiKey,
    };
    final uri = _buildUri(
        'maps.googleapis.com', '/maps/api/distancematrix/json', params);

    try {
      final response = await _client.get(uri);

      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
          'Failed to fetch distance matrix: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'UNKNOWN_ERROR';

      if (status != 'OK') {
        throw Exception('Google Distance Matrix API error: $status');
      }

      final rows = data['rows'] as List<dynamic>;
      if (rows.isEmpty) {
        throw Exception('No distance matrix rows returned');
      }

      final elements = rows.first['elements'] as List<dynamic>;
      if (elements.isEmpty) {
        throw Exception('No distance matrix elements returned');
      }

      final element = elements.first as Map<String, dynamic>;
      final elementStatus = element['status'] as String? ?? 'UNKNOWN_ERROR';

      if (elementStatus != 'OK') {
        throw Exception('Distance Matrix element error: $elementStatus');
      }

      final distance = element['distance'] as Map<String, dynamic>;
      final duration = element['duration'] as Map<String, dynamic>;

      return DistanceMatrix(
        distanceMeters: distance['value'] as int,
        durationSeconds: duration['value'] as int,
      );
    } on http.ClientException catch (e) {
      throw Exception(
          'Network error fetching distance matrix: ${e.message} (uri: $uri)');
    }
  }

  /// Searches for nearby places using the **new** Google Places API.
  ///
  /// Uses `POST /v1/places:searchNearby` with the API key in the header.
  /// [latitude] and [longitude] define the search center. [radius] is in
  /// metres (default 1500). [type] filters by place type (default
  /// `'restaurant'`). [keyword] is an optional text search term.
  ///
  /// Returns an empty list if no results; throws on error.
  Future<List<NearbyPlace>> nearbySearch({
    required double latitude,
    required double longitude,
    int radius = 1500,
    String type = 'restaurant',
    String? keyword,
  }) async {
    final body = <String, dynamic>{
      'includedTypes': [type],
      'maxResultCount': 20,
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': radius.toDouble(),
        },
      },
    };
    if (keyword != null && keyword.isNotEmpty) {
      body['textQuery'] = keyword;
    }

    final uri = Uri.parse(ApiUrls.googlePlacesNewNearbyUrl);

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': GoogleMapsConfig.apiKey,
          'X-Goog-FieldMask':
              'places.id,places.displayName,places.formattedAddress,'
              'places.location,places.rating,places.userRatingCount,'
              'places.types,places.photos,places.currentOpeningHours,'
              'places.regularOpeningHours',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
          'Failed to fetch nearby places: ${response.statusCode} — ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final places = data['places'] as List<dynamic>? ?? [];

      return places.map((json) {
        final map = json as Map<String, dynamic>;
        final displayName = map['displayName'] as Map<String, dynamic>?;
        final loc = map['location'] as Map<String, dynamic>?;

        // Extract photo URLs.
        final photosList = map['photos'] as List<dynamic>? ?? [];
        final photoUrls = photosList.take(3).map((photo) {
          final photoMap = photo as Map<String, dynamic>;
          final name = photoMap['name'] as String? ?? '';
          return NearbyPlace.buildPhotoUrl(name, maxWidth: 400);
        }).toList();

        // Extract opening hours.
        final currentHours =
            map['currentOpeningHours'] as Map<String, dynamic>?;
        final regularHours =
            map['regularOpeningHours'] as Map<String, dynamic>?;
        final hours = currentHours ?? regularHours;
        final openNow = hours?['openNow'] as bool?;
        final weekdayDescriptions =
            (hours?['weekdayDescriptions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList();

        return NearbyPlace(
          placeId: map['id'] as String? ?? '',
          name: displayName?['text'] as String? ?? 'Unknown',
          vicinity: map['formattedAddress'] as String?,
          rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
          userRatingsTotal: (map['userRatingCount'] as num?)?.toInt() ?? 0,
          latitude: (loc?['latitude'] as num?)?.toDouble() ?? 0.0,
          longitude: (loc?['longitude'] as num?)?.toDouble() ?? 0.0,
          types: (map['types'] as List<dynamic>?)
                  ?.map((t) => t.toString())
                  .toList() ??
              [],
          icon: null,
          photoUrls: photoUrls,
          openNow: openNow,
          weekdayDescriptions: weekdayDescriptions,
        );
      }).toList();
    } on http.ClientException catch (e) {
      throw Exception(
          'Network error fetching nearby places: ${e.message} (uri: $uri)');
    }
  }

  /// Searches for parking lots near a given location.
  ///
  /// Convenience wrapper around [nearbySearch] with `type: 'parking'`.
  /// [latitude] and [longitude] define the search center. [radius] is in
  /// metres (default 1500). [keyword] optionally narrows results.
  ///
  /// Returns an empty list if no parking found; throws on error.
  Future<List<NearbyPlace>> searchParkingNearby({
    required double latitude,
    required double longitude,
    int radius = 1500,
    String? keyword,
  }) {
    return nearbySearch(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      type: 'parking',
      keyword: keyword,
    );
  }

  /// Fetches turn-by-turn directions and a route polyline between two points.
  ///
  /// Uses the classic Google Directions API. [mode] can be `'driving'` or
  /// `'transit'`. Returns decoded polyline points, step instructions, and
  /// total distance/duration.
  ///
  /// Throws an exception if the request fails or no route is found.
  Future<DirectionsResult> getDirections(
    Location origin,
    Location destination, {
    String mode = 'driving',
  }) async {
    final result = await _fetchDirectionsRaw(origin, destination, mode: mode);
    return result;
  }

  /// Fetches multiple transit route alternatives between two points.
  ///
  /// Uses the Google Directions API in transit mode with `alternatives=true`
  /// to get up to 3 route options. Each result includes full step-level
  /// data: walking segments, transit line info, departure/arrival stops.
  ///
  /// This is the primary transit routing method — it handles walking to/from
  /// stations, transfers, and correct line names automatically.
  Future<List<DirectionsResult>> getTransitRoutes(
    Location origin,
    Location destination,
  ) async {
    final result = await _fetchDirectionsRaw(
      origin,
      destination,
      mode: 'transit',
      alternatives: true,
    );
    return (result as List<dynamic>).cast<DirectionsResult>();
  }

  /// Internal: fetches directions from the API and parses all route data.
  Future<dynamic> _fetchDirectionsRaw(
    Location origin,
    Location destination, {
    required String mode,
    bool alternatives = false,
  }) async {
    final params = <String, String>{
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': mode,
      'key': GoogleMapsConfig.apiKey,
    };
    if (alternatives) {
      params['alternatives'] = 'true';
    }

    final uri = _buildUri(
      'maps.googleapis.com',
      '/maps/api/directions/json',
      params,
    );

    try {
      final response = await _client.get(uri);

      if (response.statusCode != HttpStatus.ok) {
        throw Exception(
          'Failed to fetch directions: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'UNKNOWN_ERROR';

      if (status != 'OK') {
        throw Exception('Google Directions API error: $status');
      }

      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) {
        throw Exception('No routes found');
      }

      if (alternatives) {
        return routes.map((r) {
          return _parseRoute(r as Map<String, dynamic>);
        }).toList();
      } else {
        final route = routes.first as Map<String, dynamic>;
        return _parseRoute(route);
      }
    } on http.ClientException catch (e) {
      throw Exception(
          'Network error fetching directions: ${e.message} (uri: $uri)');
    }
  }

  /// Parses a single route from the Directions API response.
  DirectionsResult _parseRoute(Map<String, dynamic> route) {
    final overviewPolyline =
        route['overview_polyline'] as Map<String, dynamic>?;
    final polylinePoints = overviewPolyline?['points'] as String? ?? '';

    final legs = route['legs'] as List<dynamic>? ?? [];
    final leg = legs.isNotEmpty ? legs.first as Map<String, dynamic> : null;

    final stepInfos = <DirectionsStepInfo>[];
    final steps = <String>[];
    var distanceMeters = 0;
    var durationSeconds = 0;

    if (leg != null) {
      final distance = leg['distance'] as Map<String, dynamic>?;
      final duration = leg['duration'] as Map<String, dynamic>?;
      distanceMeters = distance?['value'] as int? ?? 0;
      durationSeconds = duration?['value'] as int? ?? 0;

      final stepList = leg['steps'] as List<dynamic>? ?? [];
      for (final s in stepList) {
        final step = s as Map<String, dynamic>;
        final instruction = _stripHtml(step['html_instructions'] as String? ?? '');
        final stepDistance = step['distance'] as Map<String, dynamic>?;
        final stepDuration = step['duration'] as Map<String, dynamic>?;
        final travelMode = step['travel_mode'] as String? ?? 'UNKNOWN';

        final distText = stepDistance?['text'] as String? ?? '';
        steps.add('$instruction${distText.isNotEmpty ? ' ($distText)' : ''}');

        // Parse step start/end coordinates.
        LatLng? startLatLng;
        LatLng? endLatLng;
        final startLoc = step['start_location'] as Map<String, dynamic>?;
        final endLoc = step['end_location'] as Map<String, dynamic>?;
        if (startLoc != null) {
          startLatLng = LatLng(
            (startLoc['lat'] as num).toDouble(),
            (startLoc['lng'] as num).toDouble(),
          );
        }
        if (endLoc != null) {
          endLatLng = LatLng(
            (endLoc['lat'] as num).toDouble(),
            (endLoc['lng'] as num).toDouble(),
          );
        }

        // Parse transit-specific details.
        TransitStepInfo? transitInfo;
        if (travelMode == 'TRANSIT') {
          final td = step['transit_details'] as Map<String, dynamic>?;
          if (td != null) {
            final line = td['line'] as Map<String, dynamic>?;
            final depStop = td['departure_stop'] as Map<String, dynamic>?;
            final arrStop = td['arrival_stop'] as Map<String, dynamic>?;
            final vehicle = line?['vehicle'] as Map<String, dynamic>?;

            transitInfo = TransitStepInfo(
              lineName: line?['short_name'] as String? ?? line?['name'] as String? ?? '',
              lineFullName: line?['name'] as String?,
              lineColor: line?['color'] as String?,
              vehicleType: vehicle?['type'] as String? ?? 'UNKNOWN',
              vehicleName: vehicle?['name'] as String? ?? '',
              departureStop: depStop?['name'] as String? ?? '',
              arrivalStop: arrStop?['name'] as String? ?? '',
              numStops: td['num_stops'] as int? ?? 0,
              headwaySeconds: td['headway'] as int?,
              agencyName: _extractAgencyName(line?['agencies']),
            );
          }
        }

        stepInfos.add(DirectionsStepInfo(
          instruction: instruction,
          distanceMeters: stepDistance?['value'] as int? ?? 0,
          durationSeconds: stepDuration?['value'] as int? ?? 0,
          travelMode: travelMode,
          transitInfo: transitInfo,
          startLatLng: startLatLng,
          endLatLng: endLatLng,
        ));
      }
    }

    // Decode polyline into LatLng list.
    final decoded = PolylinePoints().decodePolyline(polylinePoints);
    final latLngs = decoded
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    return DirectionsResult(
      polylinePoints: latLngs,
      steps: steps,
      stepInfos: stepInfos,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
    );
  }

  /// Extracts the first agency name from a list of transit agencies.
  String? _extractAgencyName(List<dynamic>? agencies) {
    if (agencies == null || agencies.isEmpty) return null;
    final first = agencies.first as Map<String, dynamic>?;
    return first?['name'] as String?;
  }

  /// Strips HTML tags from a string.
  String _stripHtml(String htmlText) {
    return htmlText
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// Result of a Google Directions API call.
class DirectionsResult {
  /// Creates a [DirectionsResult].
  const DirectionsResult({
    required this.polylinePoints,
    required this.steps,
    this.stepInfos = const [],
    required this.distanceMeters,
    required this.durationSeconds,
  });

  /// Decoded polyline points for drawing the route on a map.
  final List<LatLng> polylinePoints;

  /// Human-readable turn-by-turn instructions (HTML stripped).
  final List<String> steps;

  /// Rich step-level data with transit details when available.
  ///
  /// Parallels [steps] — index `i` in both lists refers to the same step.
  final List<DirectionsStepInfo> stepInfos;

  /// Total distance in meters.
  final int distanceMeters;

  /// Total duration in seconds.
  final int durationSeconds;
}

/// A single step in a Directions API route.
class DirectionsStepInfo {
  /// Creates a [DirectionsStepInfo].
  const DirectionsStepInfo({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.travelMode,
    this.transitInfo,
    this.startLatLng,
    this.endLatLng,
  });

  /// Clean (HTML-stripped) instruction text.
  final String instruction;

  /// Distance of this step in meters.
  final int distanceMeters;

  /// Duration of this step in seconds.
  final int durationSeconds;

  /// Travel mode: `'WALKING'` or `'TRANSIT'`.
  final String travelMode;

  /// Transit line and stop details, non-null only when [travelMode] is `'TRANSIT'`.
  final TransitStepInfo? transitInfo;

  /// Coordinates where this step starts, if available.
  final LatLng? startLatLng;

  /// Coordinates where this step ends, if available.
  final LatLng? endLatLng;
}

/// Transit-specific details for a transit step in a Directions API route.
class TransitStepInfo {
  /// Creates a [TransitStepInfo].
  const TransitStepInfo({
    required this.lineName,
    this.lineFullName,
    this.lineColor,
    required this.vehicleType,
    required this.vehicleName,
    required this.departureStop,
    required this.arrivalStop,
    required this.numStops,
    this.headwaySeconds,
    this.agencyName,
  });

  /// Short name of the transit line (e.g. "Seremban Line" or "KJ").
  final String lineName;

  /// Full name of the transit line.
  final String? lineFullName;

  /// Hex color of the transit line (e.g. "FF0000" for red).
  final String? lineColor;

  /// Vehicle type: `'BUS'`, `'SUBWAY'`, `'TRAIN'`, `'TRAM'`, `'RAIL'`, etc.
  final String vehicleType;

  /// Human-readable vehicle name (e.g. "Train" or "Bus").
  final String vehicleName;

  /// Name of the departure stop/station.
  final String departureStop;

  /// Name of the arrival stop/station.
  final String arrivalStop;

  /// Number of intermediate stops on this leg.
  final int numStops;

  /// Seconds between vehicles (headway), if available.
  final int? headwaySeconds;

  /// Transit agency name (e.g. "KTM" or "RapidKL").
  final String? agencyName;
}
