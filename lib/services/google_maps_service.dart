import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../utils/constants.dart';

class GoogleMapsService {

  GoogleMapsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static IconData categoryIcon(List<String> types) {
    for (final t in types) {
      if (t == 'restaurant' || t == 'meal_takeaway' || t == 'meal_delivery') {
        return Icons.restaurant_rounded;
      }
      if (t == 'cafe' || t == 'bakery') return Icons.local_cafe_rounded;
      if (t == 'subway_station' ||
          t == 'transit_station' ||
          t == 'train_station') {
        return Icons.directions_transit_rounded;
      }
      if (t == 'bus_station' || t == 'bus_stop') {
        return Icons.directions_bus_rounded;
      }
      if (t == 'shopping_mall' || t == 'store') {
        return Icons.shopping_bag_rounded;
      }
      if (t == 'hospital' || t == 'health') return Icons.local_hospital_rounded;
      if (t == 'gas_station') return Icons.local_gas_station_rounded;
      if (t == 'park' || t == 'parking') return Icons.local_parking_rounded;
      if (t == 'car_repair') return Icons.build_rounded;
      if (t == 'atm' || t == 'bank') return Icons.account_balance_rounded;
      if (t == 'pharmacy') return Icons.local_pharmacy_rounded;
      if (t == 'electric_vehicle_charging_station') {
        return Icons.ev_station_rounded;
      }
      if (t == 'museum' || t == 'art_gallery') return Icons.museum_rounded;
    }
    return Icons.place_rounded;
  }

  Uri _buildUri(String host, String path, Map<String, String> params) {
    return Uri.https(host, path, params);
  }

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

        final photosList = map['photos'] as List<dynamic>? ?? [];
        final photoUrls = photosList.take(3).map((photo) {
          final photoMap = photo as Map<String, dynamic>;
          final name = photoMap['name'] as String? ?? '';
          return NearbyPlace.buildPhotoUrl(name, maxWidth: 400);
        }).toList();

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

  Future<DirectionsResult> getDirections(
    Location origin,
    Location destination, {
    String mode = 'driving',
    List<Location> waypoints = const [],
  }) async {
    final result = await _fetchDirectionsRaw(
      origin,
      destination,
      mode: mode,
      waypoints: waypoints,
    );
    return result;
  }

  Future<DirectionsResult> getDirectionsWithPrelude(
    Location currentLocation,
    Location fromLocation,
    Location destination, {
    required String mode,
  }) async {
    final prelude = await getDirections(
      currentLocation,
      fromLocation,
      mode: 'driving',
    );
    final main = await getDirections(
      fromLocation,
      destination,
      mode: mode,
    );
    return DirectionsResult(
      polylinePoints: [...prelude.polylinePoints, ...main.polylinePoints],
      steps: [...prelude.steps, ...main.steps],
      stepInfos: [...prelude.stepInfos, ...main.stepInfos],
      distanceMeters: prelude.distanceMeters + main.distanceMeters,
      durationSeconds: prelude.durationSeconds + main.durationSeconds,
    );
  }

  Future<({DirectionsResult result, int preludePointCount, String stationName})>
      getTransitWithStationPrelude(
    Location currentLocation,
    Location fromLocation,
    Location destination,
  ) async {
    final transit = await getDirections(
      fromLocation,
      destination,
      mode: 'transit',
    );

    final firstTransitIndex =
        transit.stepInfos.indexWhere((s) => s.travelMode == 'TRANSIT');
    if (firstTransitIndex < 0) {
      return (result: transit, preludePointCount: 0, stationName: '');
    }

    final firstTransit = transit.stepInfos[firstTransitIndex];
    final station = firstTransit.startLatLng;
    final stationName = firstTransit.transitInfo?.departureStop ?? '';
    if (station == null) {
      return (result: transit, preludePointCount: 0, stationName: stationName);
    }

    final prelude = await getDirections(
      currentLocation,
      Location(latitude: station.latitude, longitude: station.longitude),
      mode: 'driving',
    );

    final transitSteps = transit.steps.sublist(firstTransitIndex);
    final transitStepInfos = transit.stepInfos.sublist(firstTransitIndex);

    return (
      result: DirectionsResult(
        polylinePoints: [...prelude.polylinePoints, ...transit.polylinePoints],
        steps: [...prelude.steps, ...transitSteps],
        stepInfos: [...prelude.stepInfos, ...transitStepInfos],
        distanceMeters: prelude.distanceMeters + transit.distanceMeters,
        durationSeconds: prelude.durationSeconds + transit.durationSeconds,
      ),
      preludePointCount: prelude.polylinePoints.length,
      stationName: stationName,
    );
  }

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

  Future<dynamic> _fetchDirectionsRaw(
    Location origin,
    Location destination, {
    required String mode,
    bool alternatives = false,
    List<Location> waypoints = const [],
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
    if (waypoints.isNotEmpty) {
      params['waypoints'] = waypoints
          .map((w) => '${w.latitude},${w.longitude}')
          .join('|');
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

  DirectionsResult _parseRoute(Map<String, dynamic> route) {
    final overviewPolyline =
        route['overview_polyline'] as Map<String, dynamic>?;
    final polylinePoints = overviewPolyline?['points'] as String? ?? '';

    final legs = route['legs'] as List<dynamic>? ?? [];

    final stepInfos = <DirectionsStepInfo>[];
    final steps = <String>[];
    var distanceMeters = 0;
    var durationSeconds = 0;

    for (final legJson in legs) {
      final leg = legJson as Map<String, dynamic>;
      final distance = leg['distance'] as Map<String, dynamic>?;
      final duration = leg['duration'] as Map<String, dynamic>?;
      distanceMeters += distance?['value'] as int? ?? 0;
      durationSeconds += duration?['value'] as int? ?? 0;

      final stepList = leg['steps'] as List<dynamic>? ?? [];
      for (final s in stepList) {
        final step = s as Map<String, dynamic>;
        final instruction = _stripHtml(step['html_instructions'] as String? ?? '');
        final stepDistance = step['distance'] as Map<String, dynamic>?;
        final stepDuration = step['duration'] as Map<String, dynamic>?;
        final travelMode = step['travel_mode'] as String? ?? 'UNKNOWN';

        final distText = stepDistance?['text'] as String? ?? '';
        steps.add('$instruction${distText.isNotEmpty ? ' ($distText)' : ''}');

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

  String? _extractAgencyName(List<dynamic>? agencies) {
    if (agencies == null || agencies.isEmpty) return null;
    final first = agencies.first as Map<String, dynamic>?;
    return first?['name'] as String?;
  }

  String _stripHtml(String htmlText) {
    return htmlText
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class DirectionsResult {

  const DirectionsResult({
    required this.polylinePoints,
    required this.steps,
    this.stepInfos = const [],
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> polylinePoints;

  final List<String> steps;

  final List<DirectionsStepInfo> stepInfos;

  final int distanceMeters;

  final int durationSeconds;
}

class DirectionsStepInfo {

  const DirectionsStepInfo({
    required this.instruction,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.travelMode,
    this.transitInfo,
    this.startLatLng,
    this.endLatLng,
  });

  final String instruction;

  final int distanceMeters;

  final int durationSeconds;

  final String travelMode;

  final TransitStepInfo? transitInfo;

  final LatLng? startLatLng;

  final LatLng? endLatLng;
}

class TransitStepInfo {

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

  final String lineName;

  final String? lineFullName;

  final String? lineColor;

  final String vehicleType;

  final String vehicleName;

  final String departureStop;

  final String arrivalStop;

  final int numStops;

  final int? headwaySeconds;

  final String? agencyName;
}
