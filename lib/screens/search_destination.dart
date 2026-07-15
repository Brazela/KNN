import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../navigation/navigation.dart';
import '../providers/providers.dart';
import '../services/services.dart'; // provides GoogleMapsService, NativePlacesService
import '../utils/constants.dart';
import '../widgets/widgets.dart';

/// Full-screen overlay page for searching a trip destination.
///
/// Provides Google Places autocomplete suggestions as the user types, a
/// map-preview once a place is selected, and a full-screen map picker
/// accessible via the map icon.
class SearchDestinationPage extends StatefulWidget {
  /// Creates a [SearchDestinationPage].
  ///
  /// If [initialPlace] is provided (e.g. from Popular Places), the page
  /// will pre-select it and show the confirm button immediately.
  ///
  /// If [openMapPicker] is true, the page opens directly into the full-
  /// screen map-picker mode for pinning a location on the map.
  const SearchDestinationPage({this.initialPlace, this.openMapPicker = false, super.key});

  /// An optional nearby place to pre-fill, bypassing the search step.
  final NearbyPlace? initialPlace;

  /// If true, the full-screen map picker is shown immediately on open
  /// instead of the search interface.
  final bool openMapPicker;

  @override
  State<SearchDestinationPage> createState() => _SearchDestinationPageState();
}

class _SearchDestinationPageState extends State<SearchDestinationPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<PlaceSuggestion> _suggestions = [];
  PlaceDetail? _selectedPlace;
  bool _loading = false;
  bool _showMapPicker = false;
  Timer? _debounce;

  // Map-picker state.
  GoogleMapController? _mapController;
  LatLng _pickerCenter = const LatLng(3.139, 101.6869); // KL default.

  @override
  void initState() {
    super.initState();
    if (widget.initialPlace != null) {
      final p = widget.initialPlace!;
      _selectedPlace = PlaceDetail(
        placeId: p.placeId,
        latitude: p.latitude,
        longitude: p.longitude,
        formattedAddress: p.vicinity ?? p.name,
        name: p.name,
      );
      _pickerCenter = LatLng(p.latitude, p.longitude);
      _searchController.text = p.name;
    }

    // Auto-focus the search field after the first frame so the keyboard
    // appears without an extra tap (skip if map picker opens directly).
    if (!widget.openMapPicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }

    // If the caller wants the map picker open immediately, schedule it
    // after the build phase so the Scaffold is ready.
    if (widget.openMapPicker) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openMapPicker();
      });
    }
  }

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
          _selectedPlace = detail;
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

  void _confirm() {
    if (_selectedPlace == null) return;

    context.read<TripProvider>().setDestination(
          Location(
            latitude: _selectedPlace!.latitude,
            longitude: _selectedPlace!.longitude,
            address: _selectedPlace!.formattedAddress,
            placeId: _selectedPlace!.placeId,
          ),
        );

    Navigator.of(context).pushNamed(AppRoutes.originSelection);
  }

  // --- Map picker ---

  void _openMapPicker() {
    setState(() {
      _showMapPicker = true;
      _pickerCenter =
          _selectedPlace != null
              ? LatLng(_selectedPlace!.latitude, _selectedPlace!.longitude)
              : _pickerCenter;
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
      _selectedPlace = PlaceDetail(
        placeId: '',
        latitude: _pickerCenter.latitude,
        longitude: _pickerCenter.longitude,
        formattedAddress:
            '${_pickerCenter.latitude.toStringAsFixed(6)}, ${_pickerCenter.longitude.toStringAsFixed(6)}',
      );
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
                      hintText: 'Where to?',
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

            // Body: suggestions list or selected-place preview.
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedPlace != null
                      ? _buildPlacePreview()
                      : _buildSuggestionsList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Suggestions list from autocomplete.
  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty) {
      return const Center(
        child: Text(
          'Search for a destination',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _suggestions.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return _SuggestionTile(
          suggestion: suggestion,
          onTap: () => _selectSuggestion(suggestion),
        );
      },
    );
  }

  /// Small map preview + confirm button after a place is selected.
  Widget _buildPlacePreview() {
    final place = _selectedPlace!;
    return Column(
      children: [
        // Mini interactive map.
        SizedBox(
          height: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(place.latitude, place.longitude),
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: LatLng(place.latitude, place.longitude),
                ),
              },
              onMapCreated: _onMapCreated,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Place name and address.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name ?? 'Selected location',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      place.formattedAddress,
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
        const Spacer(),
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

  /// Full-screen map picker overlay.
  Widget _buildMapPicker() {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map.
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

          // Centered pin.
          const Center(
            child: Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 50,
            ),
          ),

          // Top bar: back + current location.
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

          // Bottom: Confirm button.
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: const Color(0x30000000),
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

/// An individual autocomplete suggestion tile.
class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, this.onTap});

  final PlaceSuggestion suggestion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
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
