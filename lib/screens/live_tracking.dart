import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../navigation/navigation.dart';
import '../services/services.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/map_markers.dart';
import '../widgets/widgets.dart';

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
  List<LatLng> _polylinePoints = [];
  List<String> _steps = [];
  List<DirectionsStepInfo> _stepInfos = [];

  // Tracking state.
  StreamSubscription<Location>? _locationSub;
  Location? _currentPosition;
  double _progress = 0.0;
  String _etaText = 'Calculating…';
  String? _statusMessage;

  /// Total polyline length in km (used to map progress → current step).
  double _polylineLength = 0.0;

  /// Visible-list index of the current step (auto-advances with progress).
  int? _currentStepIndex;

  /// Key for the step list so map markers can scroll it into view.
  final GlobalKey<RouteStepListState> _stepListKey =
      GlobalKey<RouteStepListState>();

  /// Index into the polyline where the user's from-location sits (nearest
  /// point, snapped to the road).
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
    _polylinePoints =
        (args['polylinePoints'] as List<dynamic>?)?.cast<LatLng>() ?? [];
    _steps = (args['steps'] as List<dynamic>?)?.cast<String>() ?? [];
    _stepInfos =
        (args['stepInfos'] as List<dynamic>?)?.cast<DirectionsStepInfo>() ?? [];
    _fromPolylineIndex = args['fromPolylineIndex'] as int? ?? 0;
    _snappedFromPoint = args['snappedFromPoint'] as LatLng?;
    _preludeLabel = args['preludeLabel'] as String?;

    if (_origin == null || _destination == null || _mode == null) {
      setState(() => _statusMessage = 'Missing trip data');
      return;
    }

    _setupMapOverlays();

    if (_mode == TravelMode.transit) {
      // Static transit route — no live tracking.
      final mins = _transitRoute?.durationMinutes ?? 0;
      setState(() {
        _etaText = mins > 0 ? '$mins min to destination' : 'Transit route';
      });
    } else {
      _startDrivingTracking();
    }
  }

  /// Draws the route polyline, start/destination markers, and numbered
  /// step pins on the map.
  Future<void> _setupMapOverlays() async {
    _polylineLength = _computePolylineLength();

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
      // The starting GPS position.
      _markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: LatLng(_origin!.latitude, _origin!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Start location'),
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

    // Numbered step pins (clickable) — numbering matches the step list.
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

    if (!mounted) return;
    setState(() {});

    // Fit camera to route.
    if (_polylinePoints.isNotEmpty) {
      _fitCameraToRoute();
    }
  }

  /// Total length of the route polyline in km.
  double _computePolylineLength() {
    var total = 0.0;
    for (var i = 0; i < _polylinePoints.length - 1; i++) {
      total += calculateDistance(
        _polylinePoints[i].latitude,
        _polylinePoints[i].longitude,
        _polylinePoints[i + 1].latitude,
        _polylinePoints[i + 1].longitude,
      );
    }
    return total;
  }

  /// Handles tapping a numbered step pin: shows its info window and
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

  /// Determines the current step (visible-list index) from the progress
  /// fraction along the route polyline.
  int? _computeCurrentStepIndex() {
    if (_stepInfos.isEmpty || _polylineLength <= 0) return null;
    final hasPrelude = _snappedFromPoint != null;

    // Distances along the polyline for the real steps. When a from-location
    // was set, the synthetic "Go to from" step (index 0) is skipped here —
    // it is highlighted only before the first real step is reached.
    final start = hasPrelude ? 1 : 0;
    final cumDists = <double>[];
    for (var i = start; i < _stepInfos.length; i++) {
      final end = _stepInfos[i].endLatLng;
      cumDists.add(end == null ? 0 : _distanceAlongPolyline(end));
    }

    final traveled = _progress * _polylineLength;
    var current = -1;
    for (var i = 0; i < cumDists.length; i++) {
      if (cumDists[i] <= traveled) current = i;
    }

    // Map the real-step index back to a visible-list index. With a prelude,
    // the synthetic step occupies visible index 0, so real step i is at
    // visible index i + 1.
    final visible = hasPrelude ? current + 1 : current - _skipOffset;
    if (visible < 0) return 0; // still before the first real step
    return visible;
  }

  /// Distance in km from the route start to [point] along the polyline.
  double _distanceAlongPolyline(LatLng point) {
    var nearest = 0;
    var best = double.infinity;
    for (var i = 0; i < _polylinePoints.length; i++) {
      final d = calculateDistance(
        point.latitude,
        point.longitude,
        _polylinePoints[i].latitude,
        _polylinePoints[i].longitude,
      );
      if (d < best) {
        best = d;
        nearest = i;
      }
    }
    var cum = 0.0;
    for (var i = 0; i < nearest; i++) {
      cum += calculateDistance(
        _polylinePoints[i].latitude,
        _polylinePoints[i].longitude,
        _polylinePoints[i + 1].latitude,
        _polylinePoints[i + 1].longitude,
      );
    }
    return cum;
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
      _currentStepIndex = _computeCurrentStepIndex();
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

  /// Opens Google Maps with the destination as the waypoint (driving only).
  Future<void> _openInGoogleMaps() async {
    final dest = _destination;
    if (dest == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${dest.latitude},${dest.longitude}',
    );
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps')),
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

          // Bottom sheet with live status + step list.
          if (_mode != null &&
              (_statusMessage == null || _currentPosition != null))
            _buildBottomSheet(accentColor),

          // Status message overlay (shown only when there's no live data yet).
          if (_statusMessage != null && _currentPosition == null)
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

  Widget _buildBottomSheet(Color accentColor) {
    return DraggableScrollableSheet(
      initialChildSize: 0.42,
      minChildSize: 0.18,
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

              // Live status (progress, ETA, actions).
              _buildStatusCardContent(accentColor),

              const Divider(height: 24, indent: 20, endIndent: 20),

              // Steps header.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.format_list_numbered_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Steps',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_steps.length} steps',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),

              // Step list (auto-highlights the current step).
              Expanded(
                child: RouteStepList(
                  key: _stepListKey,
                  steps: _steps,
                  stepInfos: _stepInfos,
                  mode: _mode!,
                  skipFirstStep: _snappedFromPoint != null ? false : null,
                  accentColor: accentColor,
                  currentStepIndex: _currentStepIndex,
                  onStepTap: _onStepTap,
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusCardContent(Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                child: Text(
                  _etaText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          // Open in Google Maps (driving only).
          if (_mode == TravelMode.driving) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openInGoogleMaps,
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('Open in Google Maps'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
