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











class LiveTrackingPage extends StatefulWidget {
  
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  GoogleMapController? _mapController;

  
  TravelMode? _mode;
  TransitRoute? _transitRoute;
  Location? _origin;
  Location? _destination;
  List<LatLng> _polylinePoints = [];
  List<String> _steps = [];
  List<DirectionsStepInfo> _stepInfos = [];

  
  StreamSubscription<Location>? _locationSub;
  Location? _currentPosition;
  double _progress = 0.0;
  String _etaText = 'Calculating…';
  String? _statusMessage;

  
  double _polylineLength = 0.0;

  
  int? _currentStepIndex;

  
  final GlobalKey<RouteStepListState> _stepListKey =
      GlobalKey<RouteStepListState>();

  
  
  int _fromPolylineIndex = 0;

  
  LatLng? _snappedFromPoint;

  
  String? _preludeLabel;

  
  
  
  int get _skipOffset =>
      _snappedFromPoint != null ? 0 : (_mode == TravelMode.driving ? 1 : 0);

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromArgs());
  }

  
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
      
      final mins = _transitRoute?.durationMinutes ?? 0;
      setState(() {
        _etaText = mins > 0 ? '$mins min to destination' : 'Transit route';
      });
    } else {
      _startDrivingTracking();
    }
  }

  
  
  Future<void> _setupMapOverlays() async {
    _polylineLength = _computePolylineLength();


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

    
    for (var i = _skipOffset; i < _stepInfos.length; i++) {
      final stepInfo = _stepInfos[i];
      final stepPos = stepInfo.endLatLng;
      if (stepPos == null) continue;

      final number = i + 1 - _skipOffset;
      final markerIcon = await getNumberedMarker(number, size: 24);
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

    
    if (_polylinePoints.isNotEmpty) {
      _fitCameraToRoute();
    }
  }

  
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

  
  
  void _onStepMarkerTap(int number) {
    _stepListKey.currentState?.scrollToStep(number - 1);
  }

  
  void _onStepTap(int visibleIndex) {
    final stepIndex = visibleIndex + _skipOffset;
    if (stepIndex >= _stepInfos.length) return;
    final pos = _stepInfos[stepIndex].endLatLng;
    if (pos == null || _mapController == null) return;
    _mapController!.animateCamera(CameraUpdate.newLatLng(pos));
  }

  
  
  int? _computeCurrentStepIndex() {
    if (_stepInfos.isEmpty || _polylineLength <= 0) return null;
    final hasPrelude = _snappedFromPoint != null;

    
    
    
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

    
    
    
    final visible = hasPrelude ? current + 1 : current - _skipOffset;
    if (visible < 0) return 0; 
    return visible;
  }

  
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

  
  void _onLocationUpdate(Location location) {
    setState(() => _currentPosition = location);

    
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

    
    _calculateDrivingProgress(location);
  }

  
  void _calculateDrivingProgress(Location location) {
    if (_polylinePoints.length < 2) return;

    
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

    
    var totalLength = 0.0;
    for (var i = 0; i < _polylinePoints.length - 1; i++) {
      totalLength += calculateDistance(
        _polylinePoints[i].latitude,
        _polylinePoints[i].longitude,
        _polylinePoints[i + 1].latitude,
        _polylinePoints[i + 1].longitude,
      );
    }

    
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
    final etaMinutes = (remainingKm / 0.8).ceil(); 

    setState(() {
      _progress = progress;
      _etaText = etaMinutes <= 1
          ? 'Arriving soon'
          : '$etaMinutes min to destination';
      _currentStepIndex = _computeCurrentStepIndex();
    });
  }

  

  
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

  
  
  
  
  
  void _alternativeRoute() {
    Navigator.of(context).popUntil(
      (route) => route.settings.name == AppRoutes.comparison,
    );
  }

  
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

          
          if (_mode != null &&
              (_statusMessage == null || _currentPosition != null))
            _buildBottomSheet(accentColor),

          
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

              
              _buildStatusCardContent(accentColor),

              const Divider(height: 24, indent: 20, endIndent: 20),

              
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
