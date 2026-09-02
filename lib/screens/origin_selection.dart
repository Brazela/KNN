import 'dart:async';

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

/// Full-screen overlay page for selecting the trip origin.
///
/// Mirrors the Search Destination layout but adds "📍 Current Location" as
/// the first option, plus Home / Work / Recent quick-access chips.
class OriginSelectionPage extends StatefulWidget {
  /// Creates an [OriginSelectionPage].
  const OriginSelectionPage({super.key});

  @override
  State<OriginSelectionPage> createState() => _OriginSelectionPageState();
}

class _OriginSelectionPageState extends State<OriginSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<PlaceSuggestion> _suggestions = [];
  Location? _selectedOrigin;
  String _selectedOriginLabel = '';
  bool _loading = false;
  bool _showMapPicker = false;
  Timer? _debounce;

  // Map-picker state.
  GoogleMapController? _mapController;
  LatLng _pickerCenter = const LatLng(3.139, 101.6869);

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  // --- Autocomplete ---

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(query);
    });
  }

  Future<void> _fetchSuggestions(String query) async {
    setState(() => _loading = true);
    try {
      final nativePlaces = context.read<NativePlacesService>();
      final results = await nativePlaces.autocomplete(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    _debounce?.cancel();
    setState(() {
      _loading = true;
      _suggestions = [];
    });
    try {
      final service = context.read<GoogleMapsService>();
      final detail = await service.getPlaceDetails(suggestion.placeId);
      if (mounted) {
        setState(() {
          _selectedOrigin = Location(
            latitude: detail.latitude,
            longitude: detail.longitude,
            address: detail.formattedAddress,
            placeId: detail.placeId,
          );
          _selectedOriginLabel = detail.name ?? detail.formattedAddress;
          _pickerCenter = LatLng(detail.latitude, detail.longitude);
          _searchController.text = suggestion.description;
          _loading = false;
        });
        _searchFocus.unfocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load place details: $e')),
        );
      }
    }
  }

  // --- Current Location ---

  Future<void> _selectCurrentLocation() async {
    try {
      setState(() => _loading = true);
      final loc = await context.read<LocationService>().getCurrentLocation();
      if (mounted) {
        setState(() {
          _selectedOrigin = loc;
          _selectedOriginLabel = 'Current Location';
          _pickerCenter = LatLng(loc.latitude, loc.longitude);
          _searchController.text = '📍 Current Location';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  // --- Quick selects ---

  void _selectHome() {
    final home = context.read<TripProvider>().home;
    if (home != null) {
      setState(() {
        _selectedOrigin = home;
        _selectedOriginLabel = 'Home';
        _pickerCenter = LatLng(home.latitude, home.longitude);
        _searchController.text = '🏠 Home';
      });
    }
  }

  void _selectWork() {
    final work = context.read<TripProvider>().work;
    if (work != null) {
      setState(() {
        _selectedOrigin = work;
        _selectedOriginLabel = 'Work';
        _pickerCenter = LatLng(work.latitude, work.longitude);
        _searchController.text = '💼 Work';
      });
    }
  }

  // --- Confirm ---

  void _confirm() {
    if (_selectedOrigin == null) return;

    final tripProvider = context.read<TripProvider>();
    final destination = tripProvider.destination;

    if (destination != null && isSameLocation(_selectedOrigin!, destination)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Origin and destination can\'t be the same place. '
            'Please pick a different location.',
          ),
        ),
      );
      return;
    }

    tripProvider.setOrigin(_selectedOrigin!);
    Navigator.of(context).pushNamed(AppRoutes.comparison);
  }

  // --- Map picker ---

  void _openMapPicker() {
    setState(() {
      _showMapPicker = true;
      if (_selectedOrigin != null) {
        _pickerCenter = LatLng(
          _selectedOrigin!.latitude,
          _selectedOrigin!.longitude,
        );
      }
    });
  }

  void _closeMapPicker() {
    setState(() => _showMapPicker = false);
  }

  Future<void> _goToCurrentLocation() async {
    try {
      final loc =
          await context.read<LocationService>().getCurrentLocation();
      final latLng = LatLng(loc.latitude, loc.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      setState(() => _pickerCenter = latLng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onCameraMove(CameraPosition position) {
    _pickerCenter = position.target;
  }

  void _confirmMapPicker() {
    setState(() {
      _selectedOrigin = Location(
        latitude: _pickerCenter.latitude,
        longitude: _pickerCenter.longitude,
        address:
            '${_pickerCenter.latitude.toStringAsFixed(6)}, ${_pickerCenter.longitude.toStringAsFixed(6)}',
      );
      _selectedOriginLabel = 'Pinned location';
      _showMapPicker = false;
    });
  }

  // --- Build ---

  @override
  Widget build(BuildContext context) {
    // Full-screen map picker mode.
    if (_showMapPicker) {
      return _buildMapPicker();
    }

    final tripProvider = context.watch<TripProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header: back button + search input.
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SearchInput(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      hintText: 'From where?',
                      onChanged: _onSearchChanged,
                      onSubmitted: (query) {
                        if (_suggestions.isNotEmpty) {
                          _selectSuggestion(_suggestions.first);
                        }
                      },
                      onMapTap: _openMapPicker,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Body: quick chips, suggestions, or selected preview.
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedOrigin != null
                      ? _buildPlacePreview()
                      : _buildSelectionBody(tripProvider),
            ),
          ],
        ),
      ),
    );
  }

  /// Quick-access chips + autocomplete suggestions.
  Widget _buildSelectionBody(TripProvider tripProvider) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick chips row.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Home.
                if (tripProvider.home != null)
                  _QuickChip(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    color: AppColors.success,
                    onTap: _selectHome,
                  ),
                // Work.
                if (tripProvider.work != null)
                  _QuickChip(
                    icon: Icons.work_outline_rounded,
                    label: 'Work',
                    color: AppColors.success,
                    onTap: _selectWork,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // "📍 Current Location" as first suggestion item.
          ListTile(
            onTap: _selectCurrentLocation,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: const Text(
              '📍 Current Location',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: const Text(
              'Use your GPS position',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Divider(height: 1),

          // Autocomplete suggestions.
          if (_suggestions.isEmpty && _searchController.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No results found',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            ..._suggestions.map(
              (s) => _SuggestionTile(
                suggestion: s,
                onTap: () => _selectSuggestion(s),
              ),
            ),

          // Empty state hint.
          if (_suggestions.isEmpty && _searchController.text.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Select an origin or search for a place',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Preview with an expanded map stretching down to the confirm button area.
  Widget _buildPlacePreview() {
    final origin = _selectedOrigin!;
    return Column(
      children: [
        // Full-height map — fills the space above the bottom section.
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(origin.latitude, origin.longitude),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('origin'),
                  position: LatLng(origin.latitude, origin.longitude),
                ),
              },
              onMapCreated: _onMapCreated,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Origin label.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.trip_origin_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedOriginLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (origin.address != null)
                      Text(
                        origin.address!,
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
        ),
        const SizedBox(height: 12),
        // Confirm button.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _confirm,
              child: const Text(
                'Confirm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Map picker with a fixed bottom bar (map does not cover the confirm button).
  Widget _buildMapPicker() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Map section — fills everything above the bottom bar.
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _pickerCenter,
                    zoom: 15,
                  ),
                  onMapCreated: _onMapCreated,
                  onCameraMove: _onCameraMove,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                ),
                const Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: AppColors.primary,
                    size: 50,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _closeMapPicker,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _goToCurrentLocation,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Fixed bottom bar with the confirm button (consistent with place preview).
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _confirmMapPicker,
                child: const Text(
                  'Confirm Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A quick-access chip for origin selection (Current Location, Home, etc.).
class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An individual autocomplete suggestion tile.
class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, this.onTap});

  final PlaceSuggestion suggestion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.location_on_outlined,
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        suggestion.mainText ?? suggestion.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: suggestion.secondaryText != null
          ? Text(
              suggestion.secondaryText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          : null,
    );
  }
}
