import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Service responsible for fetching and parsing GTFS static and realtime data
/// from data.gov.my.
class GTFSService {
  /// Creates a [GTFSService].
  ///
  /// An optional [http.Client] can be injected for testing.
  GTFSService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// In-memory cache of parsed static feeds keyed by agency/category slug.
  final Map<String, GTFSFeed> _staticCache = {};

  /// Builds the full URL for a GTFS static feed.
  ///
  /// [agency] is the agency slug (e.g. `ktmb`).
  /// [category] is the optional category query parameter for Prasarana feeds.
  String _staticUrl(String agency, {String? category}) {
    final buffer = StringBuffer('${ApiUrls.gtfsStaticBaseUrl}/$agency');
    if (category != null && category.isNotEmpty) {
      buffer.write('?category=$category');
    }
    return buffer.toString();
  }

  /// Builds the full URL for a GTFS realtime vehicle position feed.
  String _realtimeUrl(String agency, {String? category}) {
    final buffer = StringBuffer('${ApiUrls.gtfsRealtimeBaseUrl}/$agency');
    if (category != null && category.isNotEmpty) {
      buffer.write('?category=$category');
    }
    return buffer.toString();
  }

  /// Fetches and parses a GTFS static ZIP feed for the given [agency].
  ///
  /// Parsed data is cached in memory. Subsequent calls with the same agency
  /// return the cached feed unless [forceRefresh] is true.
  ///
  /// Throws an exception if the network request fails or the ZIP cannot be
  /// parsed.
  Future<GTFSFeed> fetchGTFSStatic(
    String agency, {
    String? category,
    bool forceRefresh = false,
  }) async {
    final cacheKey = category != null ? '${agency}_$category' : agency;

    if (!forceRefresh && _staticCache.containsKey(cacheKey)) {
      return _staticCache[cacheKey]!;
    }

    final url = _staticUrl(agency, category: category);
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Failed to fetch GTFS static feed for $agency: ${response.statusCode}',
      );
    }

    final feed = _parseStaticZip(response.bodyBytes);
    _staticCache[cacheKey] = feed;
    return feed;
  }

  /// Parses a GTFS static ZIP byte buffer into a [GTFSFeed].
  GTFSFeed _parseStaticZip(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);

    final files = <String, List<String>>{};

    for (final file in archive) {
      if (file.isFile) {
        final content = utf8.decode(file.content as List<int>);
        files[file.name] = const LineSplitter().convert(content);
      }
    }

    final agency = _parseAgency(files['agency.txt'] ?? []);
    final stops = _parseStops(files['stops.txt'] ?? []);
    final routes = _parseRoutes(files['routes.txt'] ?? []);
    final trips = _parseTrips(files['trips.txt'] ?? []);
    final stopTimes = _parseStopTimes(files['stop_times.txt'] ?? []);
    final calendar = _parseCalendar(files['calendar.txt'] ?? []);

    return GTFSFeed(
      agency: agency,
      stops: stops,
      routes: routes,
      trips: trips,
      stopTimes: stopTimes,
      calendar: calendar,
    );
  }

  /// Parses `agency.txt` into a simple key-value map.
  Map<String, String> _parseAgency(List<String> lines) {
    return _parseSingleRow(lines);
  }

  /// Parses `stops.txt` into a list of [GTFSStop].
  List<GTFSStop> _parseStops(List<String> lines) {
    return _parseRows(lines, (row) {
      return GTFSStop(
        stopId: row['stop_id'] ?? '',
        stopName: row['stop_name'] ?? '',
        stopLat: double.tryParse(row['stop_lat'] ?? '0') ?? 0,
        stopLon: double.tryParse(row['stop_lon'] ?? '0') ?? 0,
        stopCode: row['stop_code'],
        locationType: int.tryParse(row['location_type'] ?? ''),
        parentStation: row['parent_station'],
        wheelchairBoarding: int.tryParse(row['wheelchair_boarding'] ?? ''),
      );
    });
  }

  /// Parses `routes.txt` into a list of [GTFSScheduleRoute].
  List<GTFSScheduleRoute> _parseRoutes(List<String> lines) {
    return _parseRows(lines, (row) {
      return GTFSScheduleRoute(
        routeId: row['route_id'] ?? '',
        routeShortName: row['route_short_name'] ?? '',
        routeLongName: row['route_long_name'] ?? '',
        routeType: int.tryParse(row['route_type'] ?? '3') ?? 3,
        agencyId: row['agency_id'],
        routeColor: row['route_color'],
        routeTextColor: row['route_text_color'],
      );
    });
  }

  /// Parses `trips.txt` into a list of [GTFSTrip].
  List<GTFSTrip> _parseTrips(List<String> lines) {
    return _parseRows(lines, (row) {
      return GTFSTrip(
        tripId: row['trip_id'] ?? '',
        routeId: row['route_id'] ?? '',
        serviceId: row['service_id'] ?? '',
        headsign: row['trip_headsign'],
        directionId: int.tryParse(row['direction_id'] ?? ''),
      );
    });
  }

  /// Parses `stop_times.txt` into a list of [GTFSStopTime].
  List<GTFSStopTime> _parseStopTimes(List<String> lines) {
    return _parseRows(lines, (row) {
      return GTFSStopTime(
        tripId: row['trip_id'] ?? '',
        arrivalTime: row['arrival_time'] ?? '',
        departureTime: row['departure_time'] ?? '',
        stopId: row['stop_id'] ?? '',
        stopSequence: int.tryParse(row['stop_sequence'] ?? '0') ?? 0,
        stopHeadsign: row['stop_headsign'],
      );
    });
  }

  /// Parses `calendar.txt` into a list of [GTFSCalendar].
  List<GTFSCalendar> _parseCalendar(List<String> lines) {
    return _parseRows(lines, (row) {
      return GTFSCalendar(
        serviceId: row['service_id'] ?? '',
        monday: int.tryParse(row['monday'] ?? '0') ?? 0,
        tuesday: int.tryParse(row['tuesday'] ?? '0') ?? 0,
        wednesday: int.tryParse(row['wednesday'] ?? '0') ?? 0,
        thursday: int.tryParse(row['thursday'] ?? '0') ?? 0,
        friday: int.tryParse(row['friday'] ?? '0') ?? 0,
        saturday: int.tryParse(row['saturday'] ?? '0') ?? 0,
        sunday: int.tryParse(row['sunday'] ?? '0') ?? 0,
        startDate: row['start_date'] ?? '',
        endDate: row['end_date'] ?? '',
      );
    });
  }

  /// Generic CSV-like parser for GTFS text files.
  ///
  /// GTFS files are comma-separated with optional quoting. This parser handles
  /// simple quoted fields and returns a list of mapped rows.
  List<T> _parseRows<T>(
    List<String> lines,
    T Function(Map<String, String> row) mapper,
  ) {
    if (lines.length < 2) return [];

    final headers = _splitLine(lines.first);
    final rows = <T>[];

    for (var i = 1; i < lines.length; i++) {
      final values = _splitLine(lines[i]);
      if (values.length != headers.length) continue;

      final map = <String, String>{};
      for (var j = 0; j < headers.length; j++) {
        map[headers[j]] = values[j];
      }
      rows.add(mapper(map));
    }

    return rows;
  }

  /// Parses the first data row of a GTFS file into a key-value map.
  Map<String, String> _parseSingleRow(List<String> lines) {
    if (lines.length < 2) return {};

    final headers = _splitLine(lines.first);
    final values = _splitLine(lines[1]);
    final map = <String, String>{};

    for (var i = 0; i < headers.length && i < values.length; i++) {
      map[headers[i]] = values[i];
    }
    return map;
  }

  /// Splits a single GTFS CSV line respecting quoted fields.
  List<String> _splitLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    result.add(buffer.toString().trim());
    return result;
  }

  /// Fetches and parses a GTFS realtime vehicle position feed.
  ///
  /// Returns a list of [GTFSVehicle] representing the latest positions.
  /// Throws an exception if the request fails or the protobuf cannot be parsed.
  Future<List<GTFSVehicle>> fetchGTFSRealtime(
    String agency, {
    String? category,
  }) async {
    final url = _realtimeUrl(agency, category: category);
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode != HttpStatus.ok) {
      throw Exception(
        'Failed to fetch GTFS realtime feed for $agency: ${response.statusCode}',
      );
    }

    return _parseRealtimeProtobuf(response.bodyBytes);
  }

  /// Parses GTFS Realtime protobuf bytes into a list of [GTFSVehicle].
  List<GTFSVehicle> _parseRealtimeProtobuf(Uint8List bytes) {
    final feedMessage = FeedMessage.fromBuffer(bytes);
    final vehicles = <GTFSVehicle>[];

    for (final entity in feedMessage.entity) {
      if (!entity.hasVehicle()) continue;

      final vehicle = entity.vehicle;
      final trip = vehicle.hasTrip() ? vehicle.trip : null;
      final position = vehicle.hasPosition() ? vehicle.position : null;

      vehicles.add(
        GTFSVehicle(
          vehicleId: vehicle.hasVehicle() ? vehicle.vehicle.id : entity.id,
          tripId: trip?.tripId,
          routeId: trip?.routeId,
          latitude: position?.latitude,
          longitude: position?.longitude,
          timestamp: vehicle.hasTimestamp() ? vehicle.timestamp.toInt() : null,
          bearing: position?.bearing,
          speed: position?.speed,
          label: vehicle.hasVehicle() ? vehicle.vehicle.label : null,
          occupancyStatus: vehicle.hasOccupancyStatus()
              ? vehicle.occupancyStatus.name
              : null,
        ),
      );
    }

    return vehicles;
  }

  /// Finds the nearest stop in the cached feed to the given [location].
  ///
  /// Returns `null` if no feed is cached. Use [fetchGTFSStatic] first.
  GTFSStop? findNearestStop(Location location, {String? agency, String? category}) {
    final cacheKey = category != null && agency != null
        ? '${agency}_$category'
        : agency ?? '';
    final feed = _staticCache[cacheKey];
    if (feed == null || feed.stops.isEmpty) return null;

    GTFSStop? nearest;
    var bestDistance = double.infinity;

    for (final stop in feed.stops) {
      final distance = calculateDistance(
        location.latitude,
        location.longitude,
        stop.stopLat,
        stop.stopLon,
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = stop;
      }
    }

    return nearest;
  }

  /// Finds transit routes between an [origin] and [destination].
  ///
  /// This first attempts to find direct trips where both the nearest origin
  /// and destination stops appear in the same trip. If no direct routes are
  /// found, it tries to build transfer paths via shared stops.
  ///
  /// Walking distance/time to/from stops is included in the result.
  ///
  /// NOTE: This is a fallback. The preferred method is
  /// [GoogleMapsService.getTransitRoutes] which uses the Directions API
  /// transit mode for proper routing with walking segments.
  Future<List<TransitRoute>> findRoutes(
    Location origin,
    Location destination, {
    required String agency,
    String? category,
  }) async {
    final feed = await fetchGTFSStatic(agency, category: category);

    if (feed.stops.isEmpty) return [];

    // Find nearby stops within 2 km of origin and destination.
    final originStops = _findNearbyStops(feed, origin, maxDistanceKm: 2.0);
    final destinationStops = _findNearbyStops(
      feed,
      destination,
      maxDistanceKm: 2.0,
    );

    if (originStops.isEmpty || destinationStops.isEmpty) return [];

    // Build trip → ordered stop list for quick lookup.
    final tripStopMap = <String, List<GTFSStopTime>>{};
    for (final st in feed.stopTimes) {
      tripStopMap.putIfAbsent(st.tripId, () => []).add(st);
    }
    // Sort each trip's stops by sequence.
    for (final entry in tripStopMap.values) {
      entry.sort((a, b) => a.stopSequence.compareTo(b.stopSequence));
    }

    final routes = <TransitRoute>[];

    // Phase 1: Find direct trips (origin stop → destination stop).
    for (final oStop in originStops) {
      for (final dStop in destinationStops) {
        for (final entry in tripStopMap.entries) {
          final stopTimes = entry.value;
          final oIdx = stopTimes.indexWhere(
            (st) => st.stopId == oStop.stopId,
          );
          final dIdx = stopTimes.indexWhere(
            (st) => st.stopId == dStop.stopId,
          );
          if (oIdx == -1 || dIdx == -1 || oIdx >= dIdx) continue;

          final trip = feed.trips.firstWhere(
            (t) => t.tripId == entry.key,
            orElse: () => GTFSTrip(
              tripId: entry.key,
              routeId: '',
              serviceId: '',
            ),
          );
          final route = feed.routes.firstWhere(
            (r) => r.routeId == trip.routeId,
            orElse: () => GTFSScheduleRoute(
              routeId: trip.routeId,
              routeShortName: trip.routeId,
              routeLongName: trip.headsign ?? 'Unknown Route',
              routeType: 3,
            ),
          );

          // Calculate walking from origin to stop.
          final walkOriginDist = calculateDistance(
            origin.latitude, origin.longitude,
            oStop.stopLat, oStop.stopLon,
          );
          final walkDestDist = calculateDistance(
            destination.latitude, destination.longitude,
            dStop.stopLat, dStop.stopLon,
          );
          final walkOriginMin = (walkOriginDist / _walkSpeedKmph * 60).round();
          final walkDestMin = (walkDestDist / _walkSpeedKmph * 60).round();

          // Estimate transit time from stop times.
          final oTime = parseGTFSTime(stopTimes[oIdx].arrivalTime);
          final dTime = parseGTFSTime(stopTimes[dIdx].arrivalTime);
          final transitMinutes = (dTime.inMinutes - oTime.inMinutes)
              .abs()
              .clamp(1, 240);

          final totalMinutes = walkOriginMin + transitMinutes + walkDestMin;
          final stopsBetween = dIdx - oIdx;

          routes.add(TransitRoute(
            id: '${agency}_${trip.tripId}_${oStop.stopId}_${dStop.stopId}',
            name: route.routeLongName.isNotEmpty
                ? route.routeLongName
                : route.routeShortName,
            type: _mapRouteType(route.routeType),
            stops: [oStop, dStop],
            durationMinutes: totalMinutes,
            transfers: 0,
            fare: _estimateGTFSFare(route.routeType, stopsBetween),
            realtimeStatus: RealtimeStatus.unknown,
          ));
        }
      }
    }

    // Phase 2: Try 1-transfer routes (origin stop → transfer stop → dest stop).
    if (routes.isEmpty) {
      for (final oStop in originStops) {
        for (final dStop in destinationStops) {
          // Find all trips from origin stop.
          final oTrips = <String, int>{}; // tripId → stop index
          for (final entry in tripStopMap.entries) {
            final idx = entry.value.indexWhere(
              (st) => st.stopId == oStop.stopId,
            );
            if (idx != -1) oTrips[entry.key] = idx;
          }

          // Find all trips to destination stop.
          final dTrips = <String, int>{};
          for (final entry in tripStopMap.entries) {
            final idx = entry.value.indexWhere(
              (st) => st.stopId == dStop.stopId,
            );
            if (idx != -1) dTrips[entry.key] = idx;
          }

          // Look for a transfer stop shared by oTrip and dTrip.
          for (final oEntry in oTrips.entries) {
            final oTripStops = tripStopMap[oEntry.key]!;
            for (final dEntry in dTrips.entries) {
              if (oEntry.key == dEntry.key) continue; // Already handled in Phase 1
              final dTripStops = tripStopMap[dEntry.key]!;

              // Find stops that appear in oTrip (after origin) and in dTrip (before dest).
              for (var i = oEntry.value + 1; i < oTripStops.length; i++) {
                final transferStopId = oTripStops[i].stopId;
                final dIdx = dTripStops.indexWhere(
                  (st) => st.stopId == transferStopId && dTripStops.indexOf(st) < dEntry.value,
                );
                if (dIdx == -1) continue;

                final transferStop = feed.stops.firstWhere(
                  (s) => s.stopId == transferStopId,
                  orElse: () => oStop,
                );

                final oTrip = feed.trips.firstWhere(
                  (t) => t.tripId == oEntry.key,
                  orElse: () => GTFSTrip(tripId: oEntry.key, routeId: '', serviceId: ''),
                );
                final dTrip = feed.trips.firstWhere(
                  (t) => t.tripId == dEntry.key,
                  orElse: () => GTFSTrip(tripId: dEntry.key, routeId: '', serviceId: ''),
                );
                final oRoute = feed.routes.firstWhere(
                  (r) => r.routeId == oTrip.routeId,
                  orElse: () => GTFSScheduleRoute(
                    routeId: oTrip.routeId, routeShortName: 'Line 1', routeLongName: 'Line 1', routeType: 3,
                  ),
                );
                final dRoute = feed.routes.firstWhere(
                  (r) => r.routeId == dTrip.routeId,
                  orElse: () => GTFSScheduleRoute(
                    routeId: dTrip.routeId, routeShortName: 'Line 2', routeLongName: 'Line 2', routeType: 3,
                  ),
                );

                routes.add(TransitRoute(
                  id: '${agency}_${oTrip.tripId}_${dTrip.tripId}_transfer',
                  name: '${oRoute.routeShortName} → ${dRoute.routeShortName}',
                  type: _mapRouteType(oRoute.routeType),
                  stops: [oStop, transferStop, dStop],
                  durationMinutes: 40,
                  transfers: 1,
                  fare: _estimateGTFSFare(oRoute.routeType, 10) +
                      _estimateGTFSFare(dRoute.routeType, 10),
                  realtimeStatus: RealtimeStatus.unknown,
                ));
              }
            }
          }
        }
      }
    }

    // Sort by duration (best first).
    routes.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));

    return routes;
  }

  /// Walking speed in km/h used for walk-time estimates.
  static const double _walkSpeedKmph = 5.0;

  /// Finds all stops within [maxDistanceKm] of a location, sorted by distance.
  List<GTFSStop> _findNearbyStops(
    GTFSFeed feed,
    Location location, {
    double maxDistanceKm = 2.0,
  }) {
    final result = <(GTFSStop, double)>[];
    for (final stop in feed.stops) {
      final dist = calculateDistance(
        location.latitude, location.longitude,
        stop.stopLat, stop.stopLon,
      );
      if (dist <= maxDistanceKm) {
        result.add((stop, dist));
      }
    }
    result.sort((a, b) => a.$2.compareTo(b.$2));
    return result.map((r) => r.$1).toList();
  }

  /// Rough fare estimate based on route type and number of stops.
  double _estimateGTFSFare(int routeType, int numStops) {
    switch (routeType) {
      case 0:
      case 5:
      case 6: // Train
        return (numStops * 0.30).clamp(1.50, 15.0);
      case 1:
      case 7: // MRT/Subway
        return (numStops * 0.25).clamp(1.20, 6.0);
      case 2: // Rail
        return (numStops * 0.30).clamp(1.50, 15.0);
      case 3:
      case 11:
      case 700:
      case 800: // Bus
        return (numStops * 0.10).clamp(1.0, 5.0);
      case 4: // Ferry
        return 1.50;
      case 12: // Monorail
        return (numStops * 0.20).clamp(1.20, 5.0);
      default:
        return 2.0;
    }
  }

  /// Maps a GTFS route_type integer to a [TransitMode].
  TransitMode _mapRouteType(int routeType) {
    switch (routeType) {
      case 0:
      case 5:
      case 6:
        return TransitMode.train;
      case 1:
      case 7:
        return TransitMode.mrt;
      case 2:
        return TransitMode.train;
      case 3:
      case 11:
      case 700:
      case 800:
        return TransitMode.bus;
      case 4:
        return TransitMode.train;
      case 12:
        return TransitMode.monorail;
      default:
        return TransitMode.unknown;
    }
  }

  /// Clears the in-memory static feed cache.
  void clearCache() {
    _staticCache.clear();
  }

  /// Fetches all GTFS realtime vehicle positions from all available agencies.
  ///
  /// Queries KTM trains, RapidKL buses, and MRT feeder buses in parallel.
  /// Returns a flat list of all vehicles with valid coordinates.
  ///
  /// Note: `rapid-rail-kl` (LRT/MRT/Monorail) does not yet have stable
  /// realtime feeds as of 2026.
  Future<List<GTFSVehicle>> fetchAllRealtimeVehicles() async {
    return fetchVehiclesByTransitMode(null);
  }

  /// Fetches GTFS realtime vehicles filtered by transit mode.
  ///
  /// If [transitMode] is null, fetches from all agencies.
  /// Otherwise, fetches only from agencies that serve the given transit mode.
  ///
  /// Mapping:
  /// - [TransitMode.train] → ktmb
  /// - [TransitMode.mrt] / [TransitMode.lrt] / [TransitMode.monorail] → prasarana rapid-rail-kl
  /// - [TransitMode.bus] → prasarana rapid-bus-kl, rapid-bus-mrtfeeder
  /// - null / unknown → all agencies
  Future<List<GTFSVehicle>> fetchVehiclesByTransitMode(TransitMode? transitMode) async {
    List<({String agency, String? category})> feeds;

    if (transitMode == null || transitMode == TransitMode.unknown) {
      feeds = [
        (agency: 'ktmb', category: null),
        (agency: 'prasarana', category: 'rapid-bus-kl'),
        (agency: 'prasarana', category: 'rapid-bus-mrtfeeder'),
        (agency: 'prasarana', category: 'rapid-rail-kl'),
      ];
    } else {
      switch (transitMode) {
        case TransitMode.train:
          feeds = [
            (agency: 'ktmb', category: null),
          ];
          break;
        case TransitMode.mrt:
        case TransitMode.lrt:
        case TransitMode.monorail:
          feeds = [
            (agency: 'prasarana', category: 'rapid-rail-kl'),
          ];
          break;
        case TransitMode.bus:
          feeds = [
            (agency: 'prasarana', category: 'rapid-bus-kl'),
            (agency: 'prasarana', category: 'rapid-bus-mrtfeeder'),
          ];
          break;
        case TransitMode.unknown:
          feeds = [
            (agency: 'ktmb', category: null),
            (agency: 'prasarana', category: 'rapid-bus-kl'),
            (agency: 'prasarana', category: 'rapid-bus-mrtfeeder'),
            (agency: 'prasarana', category: 'rapid-rail-kl'),
          ];
          break;
      }
    }

    final futures = feeds.map((f) {
      return fetchGTFSRealtime(f.agency, category: f.category)
          .catchError((_) => <GTFSVehicle>[]);
    });

    final results = await Future.wait(futures);
    final allVehicles = results.expand((v) => v).toList();

    return allVehicles
        .where((v) => v.latitude != null && v.longitude != null)
        .toList();
  }
}
