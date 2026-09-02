import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../navigation/navigation.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/address_utils.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/weather_utils.dart';
import '../widgets/widgets.dart';

/// Compares transit and driving options between the selected origin
/// and destination, then recommends the best mode.
///
/// Uses Google Directions API transit mode as the primary transit router
/// (handles walking to/from stations, transfers, and correct line names).
/// GTFS is used as a fallback and for real-time enrichment.
class ComparisonPage extends StatefulWidget {
  /// Creates a [ComparisonPage].
  const ComparisonPage({super.key});

  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  bool _loading = true;
  String? _error;

  List<TransitRoute> _transitRoutes = [];
  DrivingRoute? _drivingRoute;
  Weather? _originWeather;
  Weather? _destinationWeather;
  Recommendation _recommendation = Recommendation.either;
  String _recommendationReason = '';

  TravelMode? _selectedMode;
  Comparison? _comparison;

  /// Transit step details (line name, stops, vehicle type) for the best route.
  List<DirectionsStepInfo>? _transitStepInfos;

  @override
  void initState() {
    super.initState();
    // Defer fetch to next frame so context is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  /// Fetches all data needed for the comparison in parallel.
  Future<void> _fetchAll() async {
    final tripProvider = context.read<TripProvider>();
    final origin = tripProvider.origin;
    final destination = tripProvider.destination;

    if (origin == null || destination == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Please select an origin and destination first.';
        });
      }
      return;
    }

    final gtfsService = context.read<GTFSService>();
    final mapsService = context.read<GoogleMapsService>();
    final fuelService = context.read<FuelPriceService>();
    final weatherService = context.read<WeatherService>();

    try {
      // Parallel fetch everything.
      final results = await Future.wait([
        _fetchTransitRoutes(mapsService, gtfsService, origin, destination),
        mapsService.getDistanceMatrix(origin, destination),
        fuelService.getFuelPrice(),
        weatherService.getForecast(origin.latitude, origin.longitude),
        weatherService.getForecast(destination.latitude, destination.longitude),
      ]);

      final transitRoutes = results[0] as List<TransitRoute>;
      final distanceMatrix = results[1] as DistanceMatrix;
      final fuelPrice = results[2] as FuelPrice;
      final originForecasts = results[3] as List<Weather>;
      final destinationForecasts = results[4] as List<Weather>;

      // Build driving route.
      final distanceKm = distanceMatrix.distanceMeters / 1000.0;
      final fuelCost = distanceKm * Defaults.fuelConsumptionPerKm * fuelPrice.ron95;
      final drivingRoute = DrivingRoute(
        distanceMeters: distanceMatrix.distanceMeters,
        durationSeconds: distanceMatrix.durationSeconds,
        tolls: distanceMatrix.tolls,
        fuelCost: fuelCost,
      );

      // Compute recommendation.
      final recommendation = _computeRecommendation(
        transitRoutes: transitRoutes,
        drivingRoute: drivingRoute,
        originWeather: originForecasts.isNotEmpty ? originForecasts.first : null,
        destinationWeather: destinationForecasts.isNotEmpty ? destinationForecasts.first : null,
      );

      if (mounted) {
        setState(() {
          _transitRoutes = transitRoutes;
          _drivingRoute = drivingRoute;
          _originWeather = originForecasts.isNotEmpty ? originForecasts.first : null;
          _destinationWeather = destinationForecasts.isNotEmpty ? destinationForecasts.first : null;
          _recommendation = recommendation.$1;
          _recommendationReason = recommendation.$2;
          _loading = false;
        });
      }

      // Build comparison object for persistence.
      final bestTransit = transitRoutes.isNotEmpty ? transitRoutes.first : TransitRoute(
        id: 'none',
        name: 'No transit',
        type: TransitMode.unknown,
        stops: [],
        durationMinutes: 0,
        transfers: 0,
        fare: 0,
      );
      _comparison = Comparison(
        origin: origin,
        destination: destination,
        transitOption: bestTransit,
        drivingOption: drivingRoute,
        recommendation: recommendation.$1,
        recommendationReason: recommendation.$2,
        weather: originForecasts.isNotEmpty ? originForecasts.first : null,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load comparison data: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Fetches transit routes between origin and destination.
  ///
  /// **Primary:** Uses Google Directions API in transit mode which handles
  /// walking to/from stations, line names, transfers, and polyline routes.
  ///
  /// **Fallback:** If Directions API fails, tries GTFS static feeds.
  Future<List<TransitRoute>> _fetchTransitRoutes(
    GoogleMapsService mapsService,
    GTFSService gtfsService,
    Location origin,
    Location destination,
  ) async {
    try {
      // Primary: Google Directions API transit mode.
      final transitResults = await mapsService.getTransitRoutes(
        origin,
        destination,
      );

      final routes = <TransitRoute>[];
      for (final result in transitResults) {
        routes.add(_directionsToTransitRoute(result));
      }

      // Store transit step infos from the best (first) route for leg display.
      if (transitResults.isNotEmpty) {
        _transitStepInfos = transitResults.first.stepInfos
            .where((s) => s.travelMode == 'TRANSIT')
            .toList();
      }

      if (routes.isNotEmpty) return routes;
    } catch (_) {
      // Fall through to GTFS fallback.
    }

    // Fallback: GTFS static feeds.
    return _fetchGTFSRoutes(gtfsService, origin, destination);
  }

  /// Converts a [DirectionsResult] from transit mode into a [TransitRoute].
  TransitRoute _directionsToTransitRoute(DirectionsResult result) {
    // Separate walking and transit steps.
    final walkingSteps = <DirectionsStepInfo>[];
    final transitSteps = <DirectionsStepInfo>[];
    for (final step in result.stepInfos) {
      if (step.travelMode == 'WALKING') {
        walkingSteps.add(step);
      } else {
        transitSteps.add(step);
      }
    }

    // Calculate walking distance/time.
    final totalWalkingMeters = walkingSteps.fold<int>(
      0, (sum, s) => sum + s.distanceMeters,
    );
    final totalWalkingSeconds = walkingSteps.fold<int>(
      0, (sum, s) => sum + s.durationSeconds,
    );

    // Build the route name from transit lines.
    final lineNames = transitSteps
        .map((s) => s.transitInfo?.lineName ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
    final name = lineNames.isNotEmpty
        ? lineNames.join(' → ')
        : 'Transit Route';

    // Determine the primary transit mode from vehicle type.
    final primaryType = transitSteps.isNotEmpty
        ? _mapVehicleType(transitSteps.first.transitInfo?.vehicleType ?? '')
        : TransitMode.unknown;

    // Build detail strings for the comparison card.
    final details = <String>[];
    if (totalWalkingMeters > 0) {
      final walkMin = (totalWalkingSeconds / 60).ceil();
      details.add(
        'Walk ${totalWalkingMeters}m (~$walkMin min) to/from stations',
      );
    }
    for (final ts in transitSteps) {
      final ti = ts.transitInfo;
      if (ti != null) {
        details.add(
          '${ti.vehicleName}: ${ti.lineName} (${ti.departureStop} → ${ti.arrivalStop})',
        );
      }
    }
    if (transitSteps.isEmpty && result.steps.isNotEmpty) {
      details.addAll(result.steps);
    }

    // Estimate fare based on distance and mode.
    final distanceKm = result.distanceMeters / 1000.0;
    final fare = _estimateFare(primaryType, distanceKm);

    // Build synthetic GTFS stops from Directions data.
    final stops = <GTFSStop>[];
    final firstDeparture = transitSteps.isNotEmpty
        ? transitSteps.first.transitInfo?.departureStop
        : null;
    final lastArrival = transitSteps.isNotEmpty
        ? transitSteps.last.transitInfo?.arrivalStop
        : null;
    if (firstDeparture != null) {
      stops.add(GTFSStop(
        stopId: 'dir_dep',
        stopName: firstDeparture,
        stopLat: 0,
        stopLon: 0,
      ));
    }
    if (lastArrival != null && lastArrival != firstDeparture) {
      stops.add(GTFSStop(
        stopId: 'dir_arr',
        stopName: lastArrival,
        stopLat: 0,
        stopLon: 0,
      ));
    }

    return TransitRoute(
      id: 'dir_${lineNames.join('_').replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: primaryType,
      stops: stops,
      durationMinutes: (result.durationSeconds / 60).ceil(),
      transfers: transitSteps.length > 1 ? transitSteps.length - 1 : 0,
      fare: fare,
      realtimeStatus: RealtimeStatus.unknown,
    );
  }

  /// Maps a Google vehicle type string to our [TransitMode].
  TransitMode _mapVehicleType(String vehicleType) {
    switch (vehicleType.toUpperCase()) {
      case 'BUS':
        return TransitMode.bus;
      case 'SUBWAY':
      case 'METRO':
        return TransitMode.mrt;
      case 'TRAIN':
      case 'RAIL':
      case 'HEAVY_RAIL':
      case 'COMMUTER_TRAIN':
        return TransitMode.train;
      case 'TRAM':
      case 'LIGHT_RAIL':
        return TransitMode.lrt;
      case 'MONORAIL':
        return TransitMode.monorail;
      default:
        return TransitMode.unknown;
    }
  }

  /// Estimates fare in MYR based on transit mode and distance.
  double _estimateFare(TransitMode mode, double distanceKm) {
    switch (mode) {
      case TransitMode.bus:
        return (distanceKm * 0.15).clamp(1.0, 5.0);
      case TransitMode.train:
        return (distanceKm * 0.20).clamp(1.50, 15.0);
      case TransitMode.mrt:
      case TransitMode.lrt:
      case TransitMode.monorail:
        return (distanceKm * 0.25).clamp(1.20, 6.0);
      case TransitMode.unknown:
        return (distanceKm * 0.20).clamp(1.0, 10.0);
    }
  }

  /// Fallback: fetches transit routes from multiple GTFS agencies.
  Future<List<TransitRoute>> _fetchGTFSRoutes(
    GTFSService service,
    Location origin,
    Location destination,
  ) async {
    final agencies = [
      (agency: 'prasarana', category: 'rapid-rail-kl'),
      (agency: 'prasarana', category: 'rapid-bus-kl'),
      (agency: 'ktmb', category: null),
    ];

    final futures = agencies.map((a) {
      return service.findRoutes(
        origin,
        destination,
        agency: a.agency,
        category: a.category,
      ).catchError((_) => <TransitRoute>[]);
    });

    final results = await Future.wait(futures);
    final allRoutes = results.expand((r) => r).toList();

    // Deduplicate by route ID and sort by duration.
    final seen = <String>{};
    final unique = <TransitRoute>[];
    for (final route in allRoutes) {
      if (seen.add(route.id)) {
        unique.add(route);
      }
    }
    unique.sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
    return unique;
  }

  /// Computes the recommendation based on cost, time, and weather.
  (Recommendation, String) _computeRecommendation({
    required List<TransitRoute> transitRoutes,
    required DrivingRoute drivingRoute,
    required Weather? originWeather,
    required Weather? destinationWeather,
  }) {
    // No transit routes available.
    if (transitRoutes.isEmpty) {
      return (
        Recommendation.driving,
        'No transit routes found for this journey',
      );
    }

    final bestTransit = transitRoutes.first;
    final drivingMinutes = drivingRoute.durationSeconds ~/ 60;
    final drivingTotalCost = drivingRoute.fuelCost + drivingRoute.tolls;
    final savingRM = (drivingTotalCost - bestTransit.fare).abs();
    final timeDeltaMin = (bestTransit.durationMinutes - drivingMinutes).abs();
    final savingText = formatCurrency(savingRM);

    final hasRain = _hasRainForecast(originWeather, destinationWeather);

    // Score each option (lower = better): cost weight + time weight.
    final transitScore = bestTransit.fare * 2 + bestTransit.durationMinutes;
    final drivingScore = drivingTotalCost * 2 + drivingMinutes;
    final transitWins = transitScore <= drivingScore;

    if (hasRain) {
      // Rain → transit always preferred (avoids driving in rain).
      if (transitWins) {
        return (
          Recommendation.transit,
          "It's raining — transit avoids traffic delays · saves $savingText vs driving",
        );
      }
      return (
        Recommendation.transit,
        "It's raining — transit avoids traffic delays",
      );
    }

    if (transitWins) {
      if (timeDeltaMin == 0) {
        return (
          Recommendation.transit,
          'Saves $savingText vs driving · same time',
        );
      }
      if (bestTransit.durationMinutes <= drivingMinutes) {
        return (
          Recommendation.transit,
          'Saves $savingText vs driving · $timeDeltaMin min faster',
        );
      }
      return (
        Recommendation.transit,
        'Saves $savingText vs driving · only $timeDeltaMin min slower',
      );
    }

    // Driving wins on combined cost + time.
    if (drivingTotalCost < bestTransit.fare) {
      if (timeDeltaMin == 0) {
        return (
          Recommendation.driving,
          'Saves $savingText vs transit · same time',
        );
      }
      if (drivingMinutes < bestTransit.durationMinutes) {
        return (
          Recommendation.driving,
          'Saves $timeDeltaMin min and $savingText vs transit',
        );
      }
      return (
        Recommendation.driving,
        'Saves $savingText vs transit',
      );
    }
    if (drivingMinutes < bestTransit.durationMinutes) {
      return (
        Recommendation.driving,
        'Saves $timeDeltaMin min vs transit',
      );
    }
    return (
      Recommendation.driving,
      'Driving is more convenient for this route',
    );
  }

  /// Checks if origin or destination is raining now.
  bool _hasRainForecast(Weather? origin, Weather? destination) {
    for (final w in [origin, destination]) {
      if (w == null) continue;
      if (isRaining(w.summaryForecast)) return true;
    }
    return false;
  }

  /// Called when the user taps a comparison card.
  void _selectMode(TravelMode mode) {
    setState(() {
      _selectedMode = mode;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Navigates to route details with the selected option.
  void _onSelectRoute() {
    if (_selectedMode == null) return;

    final tripProvider = context.read<TripProvider>();
    final origin = tripProvider.origin!;
    final destination = tripProvider.destination!;

    if (_selectedMode == TravelMode.transit && _transitRoutes.isNotEmpty) {
      Navigator.of(context).pushNamed(
        AppRoutes.routeDetails,
        arguments: {
          'mode': TravelMode.transit,
          'transitRoute': _transitRoutes.first,
          'origin': origin,
          'destination': destination,
          'weather': _originWeather,
          'comparison': _comparison,
        },
      );
    } else if (_selectedMode == TravelMode.driving && _drivingRoute != null) {
      final currentLoc = tripProvider.currentLocation;
      // If the user picked a specific from-location (not their current
      // position), route from the current location first, then to the
      // from-location, then continue to the destination.
      final via = (currentLoc != null && !_isSameLocation(currentLoc, origin))
          ? origin
          : null;
      final routeOrigin = via != null ? currentLoc : origin;

      Navigator.of(context).pushNamed(
        AppRoutes.routeDetails,
        arguments: {
          'mode': TravelMode.driving,
          'drivingRoute': _drivingRoute,
          'origin': routeOrigin,
          'via': via,
          'destination': destination,
          'weather': _originWeather,
          'comparison': _comparison,
        },
      );
    }
  }

  /// Returns true when [a] and [b] refer to the same place, either by
  /// matching Google place IDs or by matching coordinates (rounded to
  /// ~5 decimal places, roughly 1 m).
  bool _isSameLocation(Location a, Location b) {
    if (a.placeId != null &&
        b.placeId != null &&
        a.placeId!.isNotEmpty &&
        a.placeId == b.placeId) {
      return true;
    }

    const precision = 5;
    final latA = double.parse(a.latitude.toStringAsFixed(precision));
    final lngA = double.parse(a.longitude.toStringAsFixed(precision));
    final latB = double.parse(b.latitude.toStringAsFixed(precision));
    final lngB = double.parse(b.longitude.toStringAsFixed(precision));
    return latA == latB && lngA == lngB;
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final origin = tripProvider.origin;
    final destination = tripProvider.destination;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header.
            _buildHeader(origin, destination),
            const SizedBox(height: 4),

            // Content.
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildError(_error!)
                      : _buildComparisonBody(),
            ),

            // Bottom action button.
            if (!_loading && _error == null)
              _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Location? origin, Location? destination) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Compare Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${shortAddress(origin)} → ${shortAddress(destination)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _fetchAll();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonBody() {
    final bestTransit = _transitRoutes.isNotEmpty ? _transitRoutes.first : null;
    final driving = _drivingRoute;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weather banner.
          WeatherStatusWidget(
            originWeather: _originWeather,
            destinationWeather: _destinationWeather,
          ),
          const SizedBox(height: 16),

          // Transit card.
          if (bestTransit != null) ...[
            ComparisonCard(
              title: bestTransit.name,
              icon: Icons.directions_transit_rounded,
              cost: formatCurrency(bestTransit.fare),
              time: formatDuration(bestTransit.durationMinutes),
              details: [
                'Transfers: ${bestTransit.transfers}',
                'Mode: ${_transitModeLabel(bestTransit.type)}',
                'Status: ${_realtimeLabel(bestTransit.realtimeStatus)}',
                if (bestTransit.stops.isNotEmpty)
                  'From: ${bestTransit.stops.first.stopName}',
                if (bestTransit.stops.length > 1)
                  'To: ${bestTransit.stops.last.stopName}',
                if (_recommendation == Recommendation.transit)
                  '✓ Recommended: $_recommendationReason',
              ],
              accentColor: AppColors.success,
              isRecommended: _recommendation == Recommendation.transit,
              isSelected: _selectedMode == TravelMode.transit,
              onTap: () => _selectMode(TravelMode.transit),
            ),
            const SizedBox(height: 14),

            // Transit legs — shown when transit is selected.
            if (_selectedMode == TravelMode.transit && _transitStepInfos != null)
              _buildTransitLegs(),
          ] else ...[
            _buildNoTransitCard(),
            const SizedBox(height: 14),
          ],

          // Driving card.
          if (driving != null) ...[
            ComparisonCard(
              title: 'Driving',
              icon: Icons.directions_car_rounded,
              cost: formatCurrency(driving.fuelCost + driving.tolls),
              time: formatDuration(driving.durationSeconds ~/ 60),
              details: [
                'Distance: ${(driving.distanceMeters / 1000).toStringAsFixed(1)} km',
                'Fuel cost: ${formatCurrency(driving.fuelCost)}',
                'Tolls: ${formatCurrency(driving.tolls)}',
                'Based on current RON95 price',
                if (_recommendation == Recommendation.driving)
                  '✓ Recommended: $_recommendationReason',
              ],
              accentColor: AppColors.primary,
              isRecommended: _recommendation == Recommendation.driving,
              isSelected: _selectedMode == TravelMode.driving,
              onTap: () => _selectMode(TravelMode.driving),
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// Shows the transit legs (e.g. Bus → MRT) the user will ride on.
  Widget _buildTransitLegs() {
    final legs = _transitStepInfos!;
    if (legs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(Icons.route_rounded, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text(
                'Your route',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        ...legs.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final ti = step.transitInfo;
          if (ti == null) return const SizedBox.shrink();

          final icon = _transitVehicleIcon(ti.vehicleType);
          final isLast = i == legs.length - 1;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline connector.
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon, color: AppColors.success, size: 18),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 28,
                          color: AppColors.border,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ti.lineName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ti.departureStop}  →  ${ti.arrivalStop}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ti.vehicleName} · ${ti.numStops} stops · ${(step.durationSeconds / 60).ceil()} min',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 14),
      ],
    );
  }

  /// Maps a Google vehicle type to an icon for transit leg display.
  IconData _transitVehicleIcon(String vehicleType) {
    switch (vehicleType.toUpperCase()) {
      case 'BUS':
        return Icons.directions_bus_rounded;
      case 'SUBWAY':
      case 'METRO':
        return Icons.subway_rounded;
      case 'TRAIN':
      case 'RAIL':
      case 'HEAVY_RAIL':
      case 'COMMUTER_TRAIN':
        return Icons.train_rounded;
      case 'TRAM':
      case 'LIGHT_RAIL':
        return Icons.tram_rounded;
      case 'MONORAIL':
        return Icons.mode_fan_off_rounded;
      default:
        return Icons.directions_transit_rounded;
    }
  }

  Widget _buildNoTransitCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.directions_transit_rounded,
            size: 32,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 8),
          Text(
            'No transit routes found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try a different origin or destination within the Klang Valley.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    final isEnabled = _selectedMode != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isEnabled ? _onSelectRoute : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.border,
            disabledForegroundColor: AppColors.textMuted,
            elevation: 0,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            'Select Route',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  String _transitModeLabel(TransitMode mode) {
    return switch (mode) {
      TransitMode.train => 'Train / KTM',
      TransitMode.mrt => 'MRT',
      TransitMode.lrt => 'LRT',
      TransitMode.monorail => 'Monorail',
      TransitMode.bus => 'Bus',
      TransitMode.unknown => 'Transit',
    };
  }

  String _realtimeLabel(RealtimeStatus status) {
    return switch (status) {
      RealtimeStatus.onTime => 'On time',
      RealtimeStatus.delayed => 'Delayed',
      RealtimeStatus.unknown => 'No realtime data',
    };
  }
}
