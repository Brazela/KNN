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
import '../utils/map_markers.dart';
import '../utils/route_prelude.dart';
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

  /// An intermediate stop the user must pass through (e.g. a selected
  /// from-location) before reaching the final destination. When set, the
  /// route is: current location → [via] → destination.
  Location? _via;

  /// All step infos from Directions API (walking + transit + driving).
  List<DirectionsStepInfo> _stepInfos = [];

  /// All human-readable step instructions.
  List<String> _steps = [];

  /// Key for the step list so map markers can scroll it into view.
  final GlobalKey<RouteStepListState> _stepListKey =
      GlobalKey<RouteStepListState>();

  /// Index into the polyline where the waypoint (from-location or nearest
  /// station) sits (nearest point, snapped to the road).
  int _fromPolylineIndex = 0;

  /// The waypoint snapped to the nearest polyline point.
  LatLng? _snappedFromPoint;

  /// Display label for the waypoint (e.g. "KL118" or the station name).
  String? _preludeLabel;

  /// Number of steps skipped from the start of the display list. Driving
  /// hides its trivial first step unless a waypoint was set (in which case
  /// a synthetic "Go to waypoint" step is prepended and must be shown).
  int get _skipOffset =>
      _snappedFromPoint != null ? 0 : (_mode == TravelMode.driving ? 1 : 0);

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
    _via = args['via'] as Location?;
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
      DirectionsResult result;
      String? preludeLabel;

      if (_mode == TravelMode.transit) {
        // Transit always routes: current location → nearest station →
        // destination. The transit plan is computed from the from-location
        // to determine the departure station.
        final transitData = await mapsService.getTransitWithStationPrelude(
          _origin!,
          _via ?? _origin!,
          _destination!,
        );
        result = transitData.result;
        if (transitData.preludePointCount > 0) {
          _fromPolylineIndex = transitData.preludePointCount - 1;
          _snappedFromPoint = result.polylinePoints[_fromPolylineIndex];
          preludeLabel = transitData.stationName.isNotEmpty
              ? transitData.stationName
              : 'nearest station';
        }
      } else {
        // Driving: if the user set a from-location different from their
        // current position, route current → from → destination via a
        // waypoint call.
        result = await mapsService.getDirections(
          _origin!,
          _destination!,
          mode: 'driving',
          waypoints: _via != null ? [_via!] : const [],
        );
        if (_via != null) {
          final split = computePreludeSplit(
            from: _via!,
            polylinePoints: result.polylinePoints,
          );
          _fromPolylineIndex = split.fromPolylineIndex;
          _snappedFromPoint = split.snappedFromPoint;
          preludeLabel = _via!.address ?? 'From location';
        }
      }

      _polylinePoints = result.polylinePoints;
      _steps = result.steps;
      _stepInfos = result.stepInfos;
      _preludeLabel = preludeLabel;

      // Prepend a synthetic "Go to {waypoint}" step so the waypoint
      // (from-location or nearest station) appears as step 1.
      if (preludeLabel != null && _snappedFromPoint != null) {
        final preludeSteps = buildPreludeSteps(
          fromLabel: preludeLabel,
          steps: result.steps,
          stepInfos: result.stepInfos,
          snappedFromPoint: _snappedFromPoint!,
        );
        _steps = preludeSteps.steps;
        _stepInfos = preludeSteps.stepInfos;
      }

      // Build markers — start (waypoint) + current location + destination
      // + numbered step checkpoints.
      _markers.clear();

      if (_snappedFromPoint != null) {
        // The waypoint (from-location or nearest station) is the journey's
        // start point, snapped to the nearest road.
        _markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: _snappedFromPoint!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: _preludeLabel ?? 'Start point',
            ),
          ),
        );
        // The real GPS position gets its own "You are here" pin.
        _markers.add(
          Marker(
            markerId: const MarkerId('origin'),
            position: LatLng(_origin!.latitude, _origin!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: const InfoWindow(title: 'You are here'),
          ),
        );
      } else {
        _markers.add(
          Marker(
            markerId: const MarkerId('origin'),
            position: LatLng(_origin!.latitude, _origin!.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: _origin!.address ?? 'Origin',
            ),
          ),
        );
      }

      // Add numbered step markers for each route step. Numbering matches
      // the step list (driving skips the trivial first step unless a
      // from-location was set, in which case the synthetic step is #1).
      for (var i = _skipOffset; i < _stepInfos.length; i++) {
        final stepInfo = _stepInfos[i];
        final stepPos = stepInfo.endLatLng;
        if (stepPos == null) continue;

        final number = i + 1 - _skipOffset;
        final markerIcon = await getNumberedMarker(number);
        _markers.add(
          Marker(
            markerId: MarkerId('step_$number'),
            position: stepPos,
            icon: markerIcon,
            infoWindow: InfoWindow(
              title: 'Step $number',
              snippet: stepInfo.instruction,
            ),
            onTap: () => _onStepMarkerTap(number),
          ),
        );
      }

      // Destination marker.
      _markers.add(
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

      // Build polylines — yellow "get to your start" leg + main route.
      _polylines.clear();
      final mainColor = _mode == TravelMode.transit
          ? AppColors.success
          : AppColors.primary;
      if (_snappedFromPoint != null && _fromPolylineIndex > 0) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('prelude'),
            points: _polylinePoints.sublist(0, _fromPolylineIndex + 1),
            color: AppColors.prelude,
            width: 5,
            geodesic: true,
          ),
        );
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: _polylinePoints.sublist(_fromPolylineIndex),
            color: mainColor,
            width: 5,
            geodesic: true,
          ),
        );
      } else {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: _polylinePoints,
            color: mainColor,
            width: 5,
            geodesic: true,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _directions = result;
          _loading = false;
        });
      }

      // Animate camera to fit the route.
      _fitCameraToRoute();
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

  /// Handles tapping a numbered step marker: shows its info window and
  /// scrolls the matching step into view in the bottom sheet.
  void _onStepMarkerTap(int number) {
    _stepListKey.currentState?.scrollToStep(number - 1);
  }

  /// Moves the camera to the tapped step's location.
  void _onStepTap(int visibleIndex) {
    final stepIndex = visibleIndex + _skipOffset;
    if (stepIndex >= _stepInfos.length) return;
    final pos = _stepInfos[stepIndex].endLatLng;
    if (pos == null || _mapController == null) return;
    _mapController!.animateCamera(CameraUpdate.newLatLng(pos));
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
        'via': _via,
        'destination': _destination,
        'weather': _weather,
        'polylinePoints': _polylinePoints,
        'steps': _steps,
        'stepInfos': _stepInfos,
        'fromPolylineIndex': _fromPolylineIndex,
        'snappedFromPoint': _snappedFromPoint,
        'preludeLabel': _preludeLabel,
      },
    );
  }

  @override
  void dispose() {
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

          // Back button overlay (top-left).
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

          // Zoom controls (top-right).
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom in.
                    GestureDetector(
                      onTap: () => _mapController?.animateCamera(
                        CameraUpdate.zoomIn(),
                      ),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 1,
                      color: AppColors.border,
                    ),
                    // Zoom out.
                    GestureDetector(
                      onTap: () => _mapController?.animateCamera(
                        CameraUpdate.zoomOut(),
                      ),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.remove_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
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
              // Driving: skips the first step (index 0) which is the user's
              // current location ("Head to current location") — not useful.
              // Transit: keeps all steps so the first one is always the walk
              // to the station ("find a way to go to the station").
              Expanded(
                child: RouteStepList(
                  key: _stepListKey,
                  steps: _steps,
                  stepInfos: _stepInfos,
                  mode: _mode!,
                  skipFirstStep: _snappedFromPoint != null ? false : null,
                  accentColor: accentColor,
                  onStepTap: _onStepTap,
                  onStartTrip: _startTrip,
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
