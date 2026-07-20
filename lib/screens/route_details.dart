import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../navigation/navigation.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/widgets.dart';

/// Displays a full-screen map with the selected route polyline and a
/// draggable bottom sheet containing turn-by-turn instructions.
///
/// Supports both transit and driving modes. The route is fetched from
/// Google Directions API when the page loads.
class RouteDetailsPage extends StatefulWidget {
  /// Creates a [RouteDetailsPage].
  const RouteDetailsPage({super.key});

  @override
  State<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends State<RouteDetailsPage> {
  GoogleMapController? _mapController;
  bool _loading = true;
  String? _error;

  DirectionsResult? _directions;
  List<LatLng> _polylinePoints = [];
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  TravelMode? _mode;
  TransitRoute? _transitRoute;
  DrivingRoute? _drivingRoute;
  Location? _origin;
  Location? _destination;
  Weather? _weather;
  Comparison? _comparison;

  // Real-time vehicle tracking overlay.
  List<GTFSVehicle> _realtimeVehicles = [];
  Timer? _realtimeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromArgs());
  }

  /// Extracts route arguments and fetches directions.
  void _initFromArgs() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map<String, dynamic>) {
      setState(() {
        _loading = false;
        _error = 'Invalid route arguments';
      });
      return;
    }

    _mode = args['mode'] as TravelMode?;
    _transitRoute = args['transitRoute'] as TransitRoute?;
    _drivingRoute = args['drivingRoute'] as DrivingRoute?;
    _origin = args['origin'] as Location?;
    _destination = args['destination'] as Location?;
    _weather = args['weather'] as Weather?;
    _comparison = args['comparison'] as Comparison?;

    if (_origin == null || _destination == null || _mode == null) {
      setState(() {
        _loading = false;
        _error = 'Missing route data';
      });
      return;
    }

    _fetchDirections();
  }

  /// Fetches turn-by-turn directions and draws the route on the map.
  Future<void> _fetchDirections() async {
    final mapsService = context.read<GoogleMapsService>();

    try {
      final modeStr = _mode == TravelMode.transit ? 'transit' : 'driving';
      final result = await mapsService.getDirections(
        _origin!,
        _destination!,
        mode: modeStr,
      );

      _polylinePoints = result.polylinePoints;

      // Build markers.
      _markers
        ..clear()
        ..add(
          Marker(
            markerId: const MarkerId('origin'),
            position: LatLng(_origin!.latitude, _origin!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: const InfoWindow(title: 'Origin'),
          ),
        )
        ..add(
          Marker(
            markerId: const MarkerId('destination'),
            position: LatLng(
              _destination!.latitude,
              _destination!.longitude,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: const InfoWindow(title: 'Destination'),
          ),
        );

      // Build polyline.
      _polylines
        ..clear()
        ..add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: _polylinePoints,
            color: _mode == TravelMode.transit
                ? AppColors.success
                : AppColors.primary,
            width: 5,
            geodesic: true,
          ),
        );

      if (mounted) {
        setState(() {
          _directions = result;
          _loading = false;
        });
      }

      // Animate camera to fit the route.
      _fitCameraToRoute();

      // Start real-time vehicle polling for transit mode.
      if (_mode == TravelMode.transit) {
        _startRealtimePolling();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Failed to load route: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  /// Moves the camera to fit all polyline points.
  void _fitCameraToRoute() {
    if (_mapController == null || _polylinePoints.isEmpty) return;

    double minLat = _polylinePoints.first.latitude;
    double maxLat = _polylinePoints.first.latitude;
    double minLng = _polylinePoints.first.longitude;
    double maxLng = _polylinePoints.first.longitude;

    for (final point in _polylinePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        80, // padding
      ),
    );
  }

  /// Navigates to the live tracking screen and saves the trip to history.
  void _startTrip() {
    if (_mode == null || _origin == null || _destination == null) return;

    final cost = _mode == TravelMode.transit
        ? (_transitRoute?.fare ?? 0.0)
        : (_drivingRoute?.fuelCost ?? 0.0);
    final timeMinutes = _mode == TravelMode.transit
        ? (_transitRoute?.durationMinutes ?? 0)
        : ((_drivingRoute?.durationSeconds ?? 0) / 60).round();
    final id =
        'trip_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

    // Recommendation data from comparison.
    double? transitCost;
    int? transitTime;
    double? drivingCost;
    int? drivingTime;
    String? recommendedMode;
    int? followed;
    double? savingsCost;
    int? savingsTime;

    if (_comparison != null) {
      transitCost = _comparison!.transitOption.fare;
      transitTime = _comparison!.transitOption.durationMinutes;
      drivingCost = _comparison!.drivingOption.fuelCost + _comparison!.drivingOption.tolls;
      drivingTime = _comparison!.drivingOption.durationSeconds ~/ 60;
      recommendedMode = _comparison!.recommendation.name;
      followed = _comparison!.recommendation.name == _mode!.name ? 1 : 0;

      // Calculate savings: cost/time difference between recommended and actual.
      if (_comparison!.recommendation == Recommendation.transit) {
        savingsCost = transitCost - cost;
        savingsTime = transitTime - timeMinutes;
      } else if (_comparison!.recommendation == Recommendation.driving) {
        savingsCost = drivingCost - cost;
        savingsTime = drivingTime - timeMinutes;
      }
    }

    context.read<TripProvider>().addRecentTrip(
      Trip(
        id: id,
        origin: _origin!,
        destination: _destination!,
        mode: _mode!,
        cost: cost,
        timeMinutes: timeMinutes,
        date: DateTime.now(),
        weather: _weather,
        transitCost: transitCost,
        transitTime: transitTime,
        drivingCost: drivingCost,
        drivingTime: drivingTime,
        recommendedMode: recommendedMode,
        followedRecommendation: followed,
        savingsCost: savingsCost,
        savingsTime: savingsTime,
      ),
    );

    Navigator.of(context).pushNamed(
      AppRoutes.liveTracking,
      arguments: {
        'mode': _mode,
        'transitRoute': _transitRoute,
        'drivingRoute': _drivingRoute,
        'origin': _origin,
        'destination': _destination,
        'weather': _weather,
        'polylinePoints': _polylinePoints,
      },
    );
  }

  /// Starts polling GTFS realtime vehicle positions every 30 seconds.
  void _startRealtimePolling() {
    _fetchRealtimeVehicles();
    _realtimeTimer?.cancel();
    _realtimeTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchRealtimeVehicles(),
    );
  }

  /// Fetches live vehicle positions and adds them as markers on the map.
  Future<void> _fetchRealtimeVehicles() async {
    try {
      final gtfsService = context.read<GTFSService>();
      final vehicles = await gtfsService.fetchAllRealtimeVehicles();
      if (!mounted) return;

      // Filter to vehicles near the route.
      List<GTFSVehicle> filtered;
      if (_origin != null && _destination != null) {
        final midLat = (_origin!.latitude + _destination!.latitude) / 2;
        final midLng = (_origin!.longitude + _destination!.longitude) / 2;
        filtered = vehicles.where((v) {
          final dist = calculateDistance(
            midLat, midLng, v.latitude!, v.longitude!,
          );
          return dist < 20.0;
        }).toList();
      } else {
        filtered = vehicles;
      }

      // Build vehicle markers.
      _markers.removeWhere((m) => m.markerId.value.startsWith('rt_'));
      for (final v in filtered) {
        final color = _vehicleMarkerColor(v);
        final label = v.label ?? v.routeId ?? v.vehicleId;
        _markers.add(
          Marker(
            markerId: MarkerId('rt_${v.vehicleId}'),
            position: LatLng(v.latitude!, v.longitude!),
            icon: BitmapDescriptor.defaultMarkerWithHue(color),
            rotation: v.bearing ?? 0,
            infoWindow: InfoWindow(
              title: label,
              snippet: v.speed != null
                  ? '${(v.speed! * 3.6).toStringAsFixed(0)} km/h'
                  : '',
            ),
          ),
        );
      }

      setState(() => _realtimeVehicles = filtered);
    } catch (_) {
      // Silently ignore.
    }
  }

  /// Color-codes vehicle markers: red=Train, blue=Bus, orange=Feeder.
  double _vehicleMarkerColor(GTFSVehicle vehicle) {
    final id = (vehicle.routeId ?? '').toLowerCase() +
        (vehicle.label ?? '').toLowerCase();
    if (id.contains('train') || id.contains('rail') || id.contains('ktm')) {
      return BitmapDescriptor.hueRed;
    }
    if (id.contains('feeder') || id.contains('mrt')) {
      return BitmapDescriptor.hueOrange;
    }
    return BitmapDescriptor.hueBlue;
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Full-screen map.
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _origin != null
                  ? LatLng(_origin!.latitude, _origin!.longitude)
                  : const LatLng(3.139, 101.6869),
              zoom: 12,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_polylinePoints.isNotEmpty) {
                _fitCameraToRoute();
              }
            },
          ),

          // Back button overlay.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay.
          if (_loading)
            Container(
              color: Colors.white.withValues(alpha: 0.7),
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Error overlay.
          if (_error != null && !_loading)
            Container(
              color: Colors.white.withValues(alpha: 0.9),
              child: Center(
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
                        _error!,
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
                          _fetchDirections();
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
              ),
            ),

          // Bottom sheet with route details.
          if (!_loading && _error == null)
            _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    final accentColor = _mode == TravelMode.transit
        ? AppColors.success
        : AppColors.primary;
    final icon = _mode == TravelMode.transit
        ? Icons.directions_transit_rounded
        : Icons.directions_car_rounded;
    final title = _mode == TravelMode.transit
        ? (_transitRoute?.name ?? 'Transit Route')
        : 'Driving Route';

    final distanceKm = _directions != null
        ? (_directions!.distanceMeters / 1000).toStringAsFixed(1)
        : '0.0';
    final duration = _directions != null
        ? formatDuration(_directions!.durationSeconds ~/ 60)
        : '0m';

    return DraggableScrollableSheet(
      initialChildSize: _mode == TravelMode.transit ? 0.48 : 0.35,
      minChildSize: 0.15,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle.
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accentColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$distanceKm km · $duration',
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
              ),

              const Divider(height: 24, indent: 20, endIndent: 20),

              // Steps list — uses string steps as primary (always reliable),
              // enhanced with icons/durations from stepInfos when available.
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: (_directions?.steps.length ?? 0) + 1,
                  itemBuilder: (context, index) {
                    final steps = _directions!.steps;
                    if (index == steps.length) {
                      // Start trip button at the bottom.
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ElevatedButton(
                          onPressed: _startTrip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Start Trip',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }

                    // Determine the best icon and duration for this step.
                    final stepInfos = _directions?.stepInfos ?? [];
                    final hasRich = index < stepInfos.length;
                    IconData stepIcon;
                    String? duration;

                    if (hasRich) {
                      final si = stepInfos[index];
                      final durSec = si.durationSeconds;
                      if (si.travelMode == 'WALKING') {
                        stepIcon = Icons.directions_walk_rounded;
                        duration = durSec > 0 ? '${(durSec / 60).ceil()}m' : '';
                      } else if (si.travelMode == 'TRANSIT') {
                        stepIcon = _vehicleIcon(
                          si.transitInfo?.vehicleType ?? '',
                        );
                        duration = durSec > 0 ? '${(durSec / 60).ceil()}m' : '';
                      } else {
                        stepIcon = _stepIcon(steps[index]);
                        duration = durSec > 0 ? '${(durSec / 60).ceil()}m' : '';
                      }
                    } else {
                      stepIcon = _stepIcon(steps[index]);
                      duration = '';
                    }

                    // Build the description: use string step as primary text,
                    // with transit line details from stepInfos as a subtitle.
                    final stepText = steps[index];
                    String description;
                    if (hasRich &&
                        stepInfos[index].travelMode == 'TRANSIT' &&
                        stepInfos[index].transitInfo != null) {
                      final ti = stepInfos[index].transitInfo!;
                      description = '$stepText\n'
                          '  ${ti.vehicleName}: ${ti.lineName}'
                          '  · ${ti.departureStop} → ${ti.arrivalStop}'
                          '${ti.numStops > 0 ? ' · ${ti.numStops} stops' : ''}';
                    } else {
                      description = stepText;
                    }

                    return RouteStepCard(
                      stepNumber: index + 1,
                      icon: stepIcon,
                      description: description,
                      duration: duration ?? '',
                      accentColor: accentColor,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Maps a Google vehicle type to a Flutter icon.
  IconData _vehicleIcon(String vehicleType) {
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

  /// Chooses an appropriate icon based on step text content (driving fallback).
  IconData _stepIcon(String step) {
    final lower = step.toLowerCase();
    if (lower.contains('turn left')) return Icons.turn_left_rounded;
    if (lower.contains('turn right')) return Icons.turn_right_rounded;
    if (lower.contains('straight') || lower.contains('continue')) {
      return Icons.straight_rounded;
    }
    if (lower.contains('roundabout') || lower.contains('rotary')) {
      return Icons.roundabout_right_rounded;
    }
    if (lower.contains('merge')) return Icons.merge_type_rounded;
    if (lower.contains('exit') || lower.contains('ramp')) {
      return Icons.exit_to_app_rounded;
    }
    if (lower.contains('walk') || lower.contains('foot')) {
      return Icons.directions_walk_rounded;
    }
    if (lower.contains('bus')) return Icons.directions_bus_rounded;
    if (lower.contains('train') || lower.contains('rail')) {
      return Icons.train_rounded;
    }
    if (lower.contains('subway') || lower.contains('metro')) {
      return Icons.subway_rounded;
    }
    return Icons.navigation_rounded;
  }
}
