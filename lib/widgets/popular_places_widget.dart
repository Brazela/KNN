import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

/// Displays a horizontally scrollable list of nearby popular places.
///
/// Uses the Google Places Nearby Search API to find restaurants, cafes, and
/// transit stations near the user's current location. Only places rated
/// 4.0 and above are shown.
class PopularPlacesWidget extends StatefulWidget {
  /// Creates a [PopularPlacesWidget].
  ///
  /// [onPlaceSelected] is called when the user taps a place card.
  const PopularPlacesWidget({
    this.onPlaceSelected,
    super.key,
  });

  /// Called with the selected [NearbyPlace] when the user taps a card.
  final ValueChanged<NearbyPlace>? onPlaceSelected;

  @override
  State<PopularPlacesWidget> createState() => _PopularPlacesWidgetState();
}

class _PopularPlacesWidgetState extends State<PopularPlacesWidget> {
  List<NearbyPlace> _places = [];
  bool _loading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = context.watch<TripProvider>().currentLocation;
    if (location != null && _places.isEmpty && !_loading) {
      _loadPlaces(location);
    }
  }

  /// Fetches nearby places and filters to those rated ≥ 4.0.
  Future<void> _loadPlaces(Location location) async {
    setState(() {
      _loading = true;
    });

    try {
      final service = context.read<GoogleMapsService>();

      // Search for transit-friendly places nearby.
      final allPlaces = <NearbyPlace>[];

      final restaurants = await service.nearbySearch(
        latitude: location.latitude,
        longitude: location.longitude,
        type: 'restaurant',
      );
      allPlaces.addAll(restaurants);

      final cafes = await service.nearbySearch(
        latitude: location.latitude,
        longitude: location.longitude,
        type: 'cafe',
      );
      allPlaces.addAll(cafes);

      final transit = await service.nearbySearch(
        latitude: location.latitude,
        longitude: location.longitude,
        type: 'transit_station',
      );
      allPlaces.addAll(transit);

      // Deduplicate by placeId, filter ≥ 4.0, sort by rating desc, take 10.
      final seen = <String>{};
      final filtered = allPlaces
          .where((p) => p.rating >= 4.0 && seen.add(p.placeId))
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));

      if (mounted) {
        setState(() {
          _places = filtered.take(10).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load places: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_places.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'Popular Nearby',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 158,
          child: RawScrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            thumbColor: Colors.black26,
            trackColor: Colors.black.withValues(alpha: 0.06),
            radius: const Radius.circular(4),
            thickness: 4,
            child: ListView.separated(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 4, right: 16, bottom: 4),
              itemCount: _places.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _PlaceCard(
                place: _places[index],
                userLat: context.watch<TripProvider>().currentLocation?.latitude,
                userLng: context.watch<TripProvider>().currentLocation?.longitude,
                onTap: () => widget.onPlaceSelected?.call(_places[index]),
              );
            },
          ),
        ),
        ),
      ],
    );
  }
}

/// A single horizontally scrollable place card.
class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    this.userLat,
    this.userLng,
    this.onTap,
  });

  final NearbyPlace place;
  final double? userLat;
  final double? userLng;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final emoji = GoogleMapsService.categoryEmoji(place.types);

    // Compute distance from user if coordinates available.
    String? distanceText;
    if (userLat != null && userLng != null) {
      final km = calculateDistance(
        userLat!,
        userLng!,
        place.latitude,
        place.longitude,
      );
      if (km < 1) {
        distanceText = '${(km * 1000).round()}m';
      } else {
        distanceText = '${km.toStringAsFixed(1)}km';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top accent bar with emoji.
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Rating row.
                  if (place.rating > 0)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 13,
                            color: Color(0xFFF59E0B)),
                        const SizedBox(width: 3),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '(${place.userRatingsTotal})',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (distanceText != null) ...[
                          const SizedBox(width: 5),
                          Text(
                            '· $distanceText',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  const SizedBox(height: 6),
                  // Vicinity.
                  if (place.vicinity != null)
                    Text(
                      place.vicinity!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
