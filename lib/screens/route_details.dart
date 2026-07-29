import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../navigation/navigation.dart';
import '../services/services.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/map_markers.dart';
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

  // Real-time vehicle tracking overlay.
  List<GTFSVehicle> _realtimeVehicles = [];
  Timer? _realtimeTimer;
  List<String> _vehicleEtaMessages = [];

  /// Transit step infos from Directions API (only transit steps).
  List<DirectionsStepInfo> _transitStepInfos = [];

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

      // Build markers — origin + destination + numbered step checkpoints.
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
        );

      // Add numbered step markers for each route step.
      for (var i = 0; i < result.stepInfos.length; i++) {
        final stepInfo = result.stepInfos[i];
        final stepPos = stepInfo.endLatLng;
        if (stepPos == null) continue;

        final number = i + 1;
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

      // Store transit step infos for vehicle matching.
      if (_mode == TravelMode.transit) {
        _transitStepInfos = result.stepInfos
            .where((s) => s.travelMode == 'TRANSIT')
            .toList();
      }

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

  /// Navigates to the live tracking screen.
  void _startTrip() {
    if (_mode == null || _origin == null || _destination == null) return;

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

  /// Fetches live vehicle positions filtered by the route's transit mode and line.
  Future<void> _fetchRealtimeVehicles() async {
    try {
      final gtfsService = context.read<GTFSService>();

      // Only fetch vehicles matching the route's transit mode.
      final transitMode = _transitRoute?.type;
      final vehicles = await gtfsService.fetchVehiclesByTransitMode(transitMode);
      if (!mounted) return;

      // Get the line name(s) the user will actually ride (e.g. "T800", "KJ").
      final lineNames = _transitStepInfos
          .map((s) => s.transitInfo?.lineName ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      final lineNameLower = lineNames.isNotEmpty ? lineNames.first.toLowerCase() : '';

      // Get departure station info from the first transit step.
      LatLng? departureCoords;
      String departureStationName = '';
      if (_transitStepInfos.isNotEmpty) {
        final firstTransit = _transitStepInfos.first;
        departureCoords = firstTransit.startLatLng;
        departureStationName = firstTransit.transitInfo?.departureStop ?? '';
      }

      // Filter vehicles:
      // 1. Must be on the correct route/line (match routeId or label to line name)
      // 2. Must be within 5 km of the departure station (not 20 km of midpoint)
      final filtered = vehicles.where((v) {
        // Match by routeId or label against the line name.
        final vRoute = (v.routeId ?? '').toLowerCase();
        final vLabel = (v.label ?? '').toLowerCase();
        final vId = (v.vehicleId ?? '').toLowerCase();
        final matchesLine = lineNameLower.isEmpty ||
            vRoute.contains(lineNameLower) ||
            vLabel.contains(lineNameLower) ||
            vId.contains(lineNameLower);

        if (!matchesLine) return false;

        // Must be near the departure station.
        if (departureCoords != null) {
          final dist = calculateDistance(
            v.latitude!, v.longitude!,
            departureCoords.latitude, departureCoords.longitude,
          );
          return dist < 5.0; // within 5 km of departure station
        }
        return true;
      }).toList();

      // Find the vehicle nearest to the departure station.
      GTFSVehicle? nearestVehicle;
      double nearestDist = double.infinity;
      String nearestEtaMsg = '';

      // Build vehicle markers.
      _markers.removeWhere((m) => m.markerId.value.startsWith('rt_'));
      for (final v in filtered) {
        final vehicleType = _inferVehicleType(v);
        final plate = v.label ?? v.vehicleId;
        final lineTag = lineNames.isNotEmpty ? lineNames.first : '';

        // Calculate actual speed in km/h (GTFS speed is in m/s).
        final speedMs = v.speed ?? 0;
        final speedKmh = (speedMs > 0.5 && speedMs < 33.4) // 0.5–120 km/h
            ? '${(speedMs * 3.6).toStringAsFixed(0)} km/h'
            : '';

        // Distance from vehicle to departure station.
        double distToStation = double.infinity;
        String? distanceMsg;
        if (departureCoords != null) {
          distToStation = calculateDistance(
            v.latitude!, v.longitude!,
            departureCoords.latitude, departureCoords.longitude,
          );
          if (distToStation < 5.0) {
            distanceMsg = '${distToStation.toStringAsFixed(2)} km from $departureStationName';
          }
        }

        // ETA using actual vehicle speed if available.
        String? etaText;
        if (distToStation < 5.0) {
          final effectiveSpeedKmh = speedMs > 0.5
              ? speedMs * 3.6
              : _defaultSpeedKmh(vehicleType);
          final etaMinutes = ((distToStation / effectiveSpeedKmh) * 60).ceil();
          etaText = etaMinutes <= 1 ? '<1 min away' : '$etaMinutes min away';
        }

        // Track nearest vehicle.
        if (distToStation < nearestDist) {
          nearestDist = distToStation;
          nearestVehicle = v;
          if (distToStation < 5.0) {
            final effectiveSpeedKmh = v.speed != null && v.speed! > 0.5
                ? v.speed! * 3.6
                : _defaultSpeedKmh(vehicleType);
            final etaMin = ((distToStation / effectiveSpeedKmh) * 60).ceil();
            final etaStr = etaMin <= 1 ? '<1 min' : '$etaMin min';
            nearestEtaMsg = '$lineTag $plate arriving at $departureStationName in $etaStr';
          }
        }

        // Highlight nearest vehicle in red.
        final isNearest = v.vehicleId == nearestVehicle?.vehicleId &&
            distToStation < 5.0;
        final markerIcon = isNearest
            ? await getVehicleMarker(vehicleType, highlightColor: true)
            : await getVehicleMarker(vehicleType);

        // Direction indicator.
        final direction = v.bearing != null
            ? _bearingToDirection(v.bearing!)
            : '';

        _markers.add(
          Marker(
            markerId: MarkerId('rt_${v.vehicleId}'),
            position: LatLng(v.latitude!, v.longitude!),
            icon: markerIcon,
            rotation: v.bearing ?? 0,
            infoWindow: InfoWindow(
              title: '$lineTag $plate${direction.isNotEmpty ? ' · $direction' : ''}',
              snippet: [
                if (speedKmh.isNotEmpty) speedKmh,
                if (etaText != null) etaText,
                if (distanceMsg != null) distanceMsg,
              ].join(' · '),
            ),
          ),
        );
      }

      // Build ETA messages for the bottom sheet.
      final etaMessages = <String>[];
      if (nearestVehicle != null && nearestDist < 5.0) {
        etaMessages.add(nearestEtaMsg);
      }

      setState(() {
        _realtimeVehicles = filtered;
        _vehicleEtaMessages = etaMessages;
      });
    } catch (_) {
      // Silently ignore.
    }
  }

  /// Returns a reasonable default speed (km/h) for a vehicle type when
  /// realtime speed data is unavailable.
  double _defaultSpeedKmh(String vehicleType) {
    switch (vehicleType) {
      case 'BUS':
        return 25.0;
      case 'SUBWAY':
      case 'METRO':
        return 40.0;
      case 'TRAIN':
      case 'RAIL':
        return 50.0;
      case 'TRAM':
      case 'LIGHT_RAIL':
        return 30.0;
      case 'MONORAIL':
        return 35.0;
      default:
        return 30.0;
    }
  }

  /// Infers the vehicle type string from a [GTFSVehicle] for marker icon.
  String _inferVehicleType(GTFSVehicle vehicle) {
    // First check the transit step info for the actual vehicle type.
    if (_transitStepInfos.isNotEmpty) {
      final ti = _transitStepInfos.first.transitInfo;
      if (ti != null) {
        final vt = ti.vehicleType.toUpperCase();
        if (vt == 'BUS' || vt == 'SUBWAY' || vt == 'METRO' ||
            vt == 'TRAIN' || vt == 'RAIL' || vt == 'HEAVY_RAIL' ||
            vt == 'COMMUTER_TRAIN' || vt == 'TRAM' || vt == 'LIGHT_RAIL' ||
            vt == 'MONORAIL') {
          return vt;
        }
      }
    }

    // Fallback: infer from vehicle IDs.
    final id = (vehicle.routeId ?? '').toLowerCase() +
        (vehicle.label ?? '').toLowerCase();
    if (id.contains('train') || id.contains('rail') || id.contains('ktm')) {
      return 'TRAIN';
    }
    if (id.contains('subway') || id.contains('metro') || id.contains('mrt')) {
      return 'SUBWAY';
    }
    if (id.contains('lrt') || id.contains('light')) {
      return 'TRAM';
    }
    if (id.contains('monorail')) {
      return 'MONORAIL';
    }
    return 'BUS';
  }

  /// Converts a bearing in degrees to a cardinal direction string.
  String _bearingToDirection(double bearing) {
    if (bearing < 22.5 || bearing >= 337.5) return 'Northbound';
    if (bearing < 67.5) return 'NE-bound';
    if (bearing < 112.5) return 'Eastbound';
    if (bearing < 157.5) return 'SE-bound';
    if (bearing < 202.5) return 'Southbound';
    if (bearing < 247.5) return 'SW-bound';
    if (bearing < 292.5) return 'Westbound';
    return 'NW-bound';
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

              // Vehicle ETA messages — shown for transit mode with live vehicles.
              if (_mode == TravelMode.transit && _vehicleEtaMessages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.directions_bus_rounded,
                              size: 14, color: AppColors.textSecondary),
                          SizedBox(width: 6),
                          Text(
                            'Live vehicle updates',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ...List.generate(_vehicleEtaMessages.length, (i) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: i < _vehicleEtaMessages.length - 1 ? 4 : 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(
                                fontSize: 12, color: AppColors.success,
                              )),
                              Expanded(
                                child: Text(
                                  _vehicleEtaMessages[i],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

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
