import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../navigation/navigation.dart';
import '../services/services.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/map_markers.dart';
import '../utils/weather_utils.dart';

/// Live tracking screen for both transit and driving trips.
///
/// **Transit mode:** Polls GTFS realtime every 30 seconds to show the
/// vehicle's current position on the map and calculate progress.
///
/// **Driving mode:** Streams the device's GPS location to track progress
/// along the route polyline.
///
/// Displays a bottom status card with a progress bar, weather alerts,
/// and quick actions (Share ETA, Alternative Route, Cancel Trip).
class LiveTrackingPage extends StatefulWidget {
  /// Creates a [LiveTrackingPage].
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  GoogleMapController? _mapController;

  // Route data from arguments.
  TravelMode? _mode;
  TransitRoute? _transitRoute;
  Location? _origin;
  Location? _destination;
  Weather? _weather;
  List<LatLng> _polylinePoints = [];

  // Tracking state.
  Timer? _gtfsTimer;
  StreamSubscription<Location>? _locationSub;
  GTFSVehicle? _currentVehicle;
  Location? _currentPosition;
  double _progress = 0.0;
  String _etaText = 'Calculating…';
  String? _statusMessage;

  /// Tracks previous vehicle samples to estimate speed.
  final Map<String, ({LatLng pos, int ts})> _vehicleSamples = {};

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromArgs());
  }

  /// Extracts route arguments and starts the appropriate tracking.
  void _initFromArgs() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map<String, dynamic>) {
      setState(() => _statusMessage = 'Invalid route arguments');
      return;
    }

    _mode = args['mode'] as TravelMode?;
    _transitRoute = args['transitRoute'] as TransitRoute?;
    _origin = args['origin'] as Location?;
    _destination = args['destination'] as Location?;
    _weather = args['weather'] as Weather?;
    _polylinePoints =
        (args['polylinePoints'] as List<dynamic>?)?.cast<LatLng>() ?? [];

    if (_origin == null || _destination == null || _mode == null) {
      setState(() => _statusMessage = 'Missing trip data');
      return;
    }

    _setupMapOverlays();

    if (_mode == TravelMode.transit) {
      _startTransitTracking();
    } else {
      _startDrivingTracking();
    }
  }

  /// Draws the route polyline and origin/destination markers on the map.
  void _setupMapOverlays() {
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

    setState(() {});

    // Fit camera to route.
    if (_polylinePoints.isNotEmpty) {
      _fitCameraToRoute();
    }
  }

  /// Moves the camera to fit the entire route.
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
        80,
      ),
    );
  }

  // ─── Transit tracking ───

  /// Starts a 30-second timer that polls GTFS realtime feeds.
  void _startTransitTracking() {
    _pollGTFSRealtime(); // immediate first poll
    _gtfsTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _pollGTFSRealtime(),
    );
  }

  /// Fetches realtime vehicle positions from all agencies and updates
  /// the map with the matching vehicle.
  Future<void> _pollGTFSRealtime() async {
    final gtfsService = context.read<GTFSService>();

    final agencies = [
      (agency: 'prasarana', category: 'rapid-rail-kl'),
      (agency: 'prasarana', category: 'rapid-bus-kl'),
      (agency: 'ktmb', category: null),
    ];

    try {
      final futures = agencies.map((a) {
        return gtfsService
            .fetchGTFSRealtime(a.agency, category: a.category)
            .catchError((_) => <GTFSVehicle>[]);
      });

      final results = await Future.wait(futures);
      final allVehicles = results.expand((v) => v).toList();

      // Find a vehicle matching the trip ID.
      GTFSVehicle? matched;
      if (_transitRoute != null) {
        matched = allVehicles.firstWhere(
          (v) => v.tripId == _transitRoute!.id,
          orElse: () => const GTFSVehicle(vehicleId: ''),
        );
        if (matched.vehicleId.isEmpty) matched = null;
      }

      // Fallback: nearest vehicle to origin if no trip match.
      matched ??= _findNearestVehicle(allVehicles, _origin!);

      if (matched != null && mounted) {
        setState(() {
          _currentVehicle = matched;
          _statusMessage = null;
        });
        await _updateVehicleMarker(matched);
        _calculateTransitProgress(matched);
      } else if (mounted) {
        setState(() => _statusMessage = 'No realtime vehicle data available');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Realtime update failed: $e');
      }
    }
  }

  /// Finds the nearest vehicle to a given location.
  GTFSVehicle? _findNearestVehicle(List<GTFSVehicle> vehicles, Location loc) {
    GTFSVehicle? nearest;
    var bestDistance = double.infinity;

    for (final v in vehicles) {
      if (v.latitude == null || v.longitude == null) continue;
      final distance = calculateDistance(
        loc.latitude,
        loc.longitude,
        v.latitude!,
        v.longitude!,
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        nearest = v;
      }
    }

    return nearest;
  }

  /// Adds or updates the vehicle marker on the map.
  Future<void> _updateVehicleMarker(GTFSVehicle vehicle) async {
    if (vehicle.latitude == null || vehicle.longitude == null) return;

    // Estimate speed from consecutive samples (fall back to feed speed).
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final ts = vehicle.timestamp ?? now;
    final prev = _vehicleSamples[vehicle.vehicleId];
    _vehicleSamples[vehicle.vehicleId] = (
      pos: LatLng(vehicle.latitude!, vehicle.longitude!),
      ts: ts,
    );
    double? speedKmh;
    if (prev != null && ts - prev.ts > 0) {
      final distKm = calculateDistance(
        prev.pos.latitude,
        prev.pos.longitude,
        vehicle.latitude!,
        vehicle.longitude!,
      );
      speedKmh = (distKm / (ts - prev.ts)) * 3600;
    }
    final feedMs = vehicle.speed ?? 0;
    final feedKmh = (feedMs > 0.5 && feedMs < 33.4) ? feedMs * 3.6 : null;
    final effectiveKmh = speedKmh ?? feedKmh;

    // Transit → red bus icon; driving → keep pin.
    final icon = _mode == TravelMode.transit
        ? await getVehicleMarker('BUS', highlightColor: true)
        : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

    _markers.removeWhere((m) => m.markerId.value == 'vehicle');
    _markers.add(
      Marker(
        markerId: const MarkerId('vehicle'),
        position: LatLng(vehicle.latitude!, vehicle.longitude!),
        icon: icon,
        infoWindow: InfoWindow(
          title: vehicle.label ?? 'Vehicle',
          snippet: effectiveKmh != null
              ? 'Speed: ${effectiveKmh.toStringAsFixed(0)} km/h'
              : 'Speed: N/A',
        ),
        rotation: vehicle.bearing ?? 0,
      ),
    );

    setState(() {});
  }

  /// Calculates transit progress based on vehicle distance to destination.
  void _calculateTransitProgress(GTFSVehicle vehicle) {
    if (vehicle.latitude == null || vehicle.longitude == null) return;

    final distanceToDestination = calculateDistance(
      vehicle.latitude!,
      vehicle.longitude!,
      _destination!.latitude,
      _destination!.longitude,
    );

    final totalDistance = calculateDistance(
      _origin!.latitude,
      _origin!.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );

    if (totalDistance <= 0) return;

    final progress = 1.0 - (distanceToDestination / totalDistance).clamp(0.0, 1.0);
    final etaMinutes = (distanceToDestination / 0.5).ceil(); // rough estimate: 30 km/h avg

    setState(() {
      _progress = progress;
      _etaText = etaMinutes <= 1
          ? 'Arriving soon'
          : '$etaMinutes min to destination';
    });
  }

  // ─── Driving tracking ───

  /// Starts listening to the device's GPS location stream.
  void _startDrivingTracking() {
    final locationService = context.read<LocationService>();

    _locationSub = locationService
        .getLocationStream(distanceFilterMeters: 10)
        .listen(
          (location) => _onLocationUpdate(location),
          onError: (Object e) {
            setState(() => _statusMessage = 'GPS error: $e');
          },
        );
  }

  /// Handles a new GPS position update.
  void _onLocationUpdate(Location location) {
    setState(() => _currentPosition = location);

    // Update current position marker.
    _markers.removeWhere((m) => m.markerId.value == 'current');
    _markers.add(
      Marker(
        markerId: const MarkerId('current'),
        position: LatLng(location.latitude, location.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
        infoWindow: const InfoWindow(title: 'You are here'),
      ),
    );

    // Calculate progress along the polyline.
    _calculateDrivingProgress(location);
  }

  /// Calculates driving progress as a percentage of the total polyline.
  void _calculateDrivingProgress(Location location) {
    if (_polylinePoints.length < 2) return;

    // Find nearest point on polyline.
    var nearestIndex = 0;
    var minDistance = double.infinity;

    for (var i = 0; i < _polylinePoints.length; i++) {
      final point = _polylinePoints[i];
      final distance = calculateDistance(
        location.latitude,
        location.longitude,
        point.latitude,
        point.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    // Calculate total polyline length.
    var totalLength = 0.0;
    for (var i = 0; i < _polylinePoints.length - 1; i++) {
      totalLength += calculateDistance(
        _polylinePoints[i].latitude,
        _polylinePoints[i].longitude,
        _polylinePoints[i + 1].latitude,
        _polylinePoints[i + 1].longitude,
      );
    }

    // Calculate length up to nearest point.
    var lengthSoFar = 0.0;
    for (var i = 0; i < nearestIndex; i++) {
      lengthSoFar += calculateDistance(
        _polylinePoints[i].latitude,
        _polylinePoints[i].longitude,
        _polylinePoints[i + 1].latitude,
        _polylinePoints[i + 1].longitude,
      );
    }

    if (totalLength <= 0) return;

    final progress = (lengthSoFar / totalLength).clamp(0.0, 1.0);
    final remainingKm = totalLength * (1 - progress);
    final etaMinutes = (remainingKm / 0.8).ceil(); // assume 48 km/h avg urban

    setState(() {
      _progress = progress;
      _etaText = etaMinutes <= 1
          ? 'Arriving soon'
          : '$etaMinutes min to destination';
    });
  }

  // ─── Actions ───

  /// Copies a simple ETA message to the clipboard.
  Future<void> _shareEta() async {
    final message =
        'I\'m on my way! ETA: $_etaText via ${_mode == TravelMode.transit ? 'transit' : 'driving'}.';
    await Clipboard.setData(ClipboardData(text: message));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ETA copied to clipboard')),
      );
    }
  }

  /// Navigates back to the comparison screen for an alternative route.
  ///
  /// Pops back to the existing comparison page in the navigation stack so
  /// the user can still go back to change the origin/destination afterwards
  /// (instead of wiping the stack and landing on the homepage).
  void _alternativeRoute() {
    Navigator.of(context).popUntil(
      (route) => route.settings.name == AppRoutes.comparison,
    );
  }

  /// Cancels the trip and returns to the home screen.
  void _cancelTrip() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Trip?'),
        content: const Text(
          'Are you sure you want to cancel this trip?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.home,
                (route) => false,
              );
            },
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gtfsTimer?.cancel();
    _locationSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _mode == TravelMode.transit
        ? AppColors.success
        : AppColors.primary;

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
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: _mode == TravelMode.driving,
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

          // Back button (top-left).
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

          // Bottom status card.
          if (_statusMessage == null || _currentVehicle != null || _currentPosition != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildStatusCard(accentColor),
            ),

          // Status message overlay.
          if (_statusMessage != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildStatusMessageCard(accentColor),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(Color accentColor) {
    final hasRain = _hasRainForecast();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),

            // ETA and mode.
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _mode == TravelMode.transit
                        ? Icons.directions_transit_rounded
                        : Icons.directions_car_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _etaText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${(_progress * 100).toStringAsFixed(0)}% complete',
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

            // Rain warning.
            if (hasRain) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFDBA74),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Color(0xFFEA580C),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rain forecasted — expect delays',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Quick actions.
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_location_rounded,
                    label: 'Share ETA',
                    onTap: _shareEta,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.alt_route_rounded,
                    label: 'Alternative',
                    onTap: _alternativeRoute,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.cancel_rounded,
                    label: 'Cancel',
                    color: Colors.red,
                    onTap: _cancelTrip,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessageCard(Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: accentColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _cancelTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel Trip'),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasRainForecast() {
    if (_weather == null) return false;
    return isRaining(_weather!.summaryForecast);
  }
}

/// A compact action button for the live tracking bottom card.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color ?? AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
