import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/helpers.dart';
import '../utils/constants.dart';

class PopularPlacesWidget extends StatefulWidget {

  const PopularPlacesWidget({
    this.onPlaceSelected,
    super.key,
  });

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

  Future<void> _loadPlaces(Location location) async {
    setState(() {
      _loading = true;
    });

    try {
      final service = context.read<GoogleMapsService>();

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
          height: 220,
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
              padding: const EdgeInsets.only(left: 4, right: 16, top: 24, bottom: 8),
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
    final icon = GoogleMapsService.categoryIcon(place.types);

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
        clipBehavior: Clip.antiAlias,
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

            _PlacePhoto(place: place, icon: icon),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                  const SizedBox(height: 4),

                  if (place.rating > 0)
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 12,
                            color: Color(0xFFF59E0B)),
                        const SizedBox(width: 2),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '(${place.userRatingsTotal})',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (distanceText != null) ...[
                          const SizedBox(width: 4),
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
                  const SizedBox(height: 4),

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

class _PlacePhoto extends StatelessWidget {
  const _PlacePhoto({
    required this.place,
    required this.icon,
  });

  final NearbyPlace place;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final photoUrl = place.firstPhotoUrl;
    if (photoUrl == null || photoUrl.isEmpty) {
      return _fallback();
    }
    return Image.network(
      photoUrl,
      width: double.infinity,
      height: 110,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _fallback(loading: true);
      },
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback({bool loading = false}) {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
      ),
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 22, color: AppColors.primary),
    );
  }
}
