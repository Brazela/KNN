import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../navigation/navigation.dart';
import '../services/services.dart';
import '../utils/constants.dart';
import '../utils/parking_utils.dart';
import 'search_destination.dart';

class ParkingLocatorPage extends StatefulWidget {

  const ParkingLocatorPage({super.key});

  @override
  State<ParkingLocatorPage> createState() => _ParkingLocatorPageState();
}

class _ParkingLocatorPageState extends State<ParkingLocatorPage> {
  Location? _destination;
  List<ParkingSpot> _allSpots = [];
  List<ParkingSpot> _filteredSpots = [];
  _ParkingFilter _activeFilter = _ParkingFilter.all;
  bool _loading = false;
  String? _error;

  Future<void> _searchParking(Location destination) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = context.read<GoogleMapsService>();
      final places = await service.searchParkingNearby(
        latitude: destination.latitude,
        longitude: destination.longitude,
      );

      if (!mounted) return;

      final spots = enrichParkingSpots(places, destination);

      setState(() {
        _allSpots = spots;
        _filteredSpots = _applyFilter(spots);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    if (_destination != null) {
      await _searchParking(_destination!);
    }
  }

  List<ParkingSpot> _applyFilter(List<ParkingSpot> spots) {
    switch (_activeFilter) {
      case _ParkingFilter.all:
        return List.unmodifiable(spots);
      case _ParkingFilter.paid:
        return spots.where((s) => s.estimatedPricePerHour > 0).toList();
      case _ParkingFilter.free:
        return spots
            .where(
                (s) => s.isFree || isLikelyFreeParking(s.name))
            .toList();
      case _ParkingFilter.openNow:
        return spots.where((s) => s.openNow == true).toList();
    }
  }

  void _setFilter(_ParkingFilter filter) {
    setState(() {
      _activeFilter = filter;
      _filteredSpots = _applyFilter(_allSpots);
    });
  }

  Future<void> _navigateToSpot(ParkingSpot spot) async {

    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${spot.latitude},${spot.longitude}'
      '&destination_place_id=${spot.placeId}'
      '&travelmode=driving',
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open maps app')),
      );
    }
  }

  Future<void> _viewRoute(ParkingSpot spot) async {
    final dest = _destination;
    if (dest == null) return;

    final parkingLoc = Location(
      latitude: spot.latitude,
      longitude: spot.longitude,
      address: spot.name,
      placeId: spot.placeId,
    );

    Location? currentLoc;
    try {
      currentLoc = await context.read<LocationService>().getCurrentLocation();
    } catch (_) {
      currentLoc = null;
    }

    if (!mounted) return;
    Navigator.of(context).pushNamed(
      AppRoutes.routeDetails,
      arguments: <String, dynamic>{
        'mode': TravelMode.driving,
        'origin': currentLoc ?? parkingLoc,
        'via': currentLoc != null ? parkingLoc : null,
        'destination': dest,
        'fromParking': true,
      },
    );
  }

  Future<void> _changeDestination() async {

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchDestinationPage(
          onPlacePicked: (location) async {
            if (!mounted) return;
            setState(() {
              _destination = location;
              _allSpots = [];
              _filteredSpots = [];
            });
            _searchParking(location);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Parking Locator',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
            tooltip: 'Refresh',
            onPressed: _loading ? null : _refresh,
          ),
          IconButton(
            icon: const Icon(Icons.my_location_rounded,
                color: AppColors.primary),
            tooltip: 'Use my location',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                final loc =
                    await context.read<LocationService>().getCurrentLocation();
                if (mounted) {
                  setState(() {
                    _destination = loc;
                    _allSpots = [];
                    _filteredSpots = [];
                  });
                  _searchParking(loc);
                }
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Location error: $e')),
                  );
                }
              }
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          final hPad = isWide ? 40.0 : 20.0;
          const maxW = 420.0;

          return Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxW),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DestinationBar(
                      destination: _destination,
                      onChangeTap: _changeDestination,
                    ),
                    const SizedBox(height: 16),
                    if (_destination != null) ...[
                      _FilterChipRow(
                        activeFilter: _activeFilter,
                        onFilterChanged: _setFilter,
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildBody(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {

    if (_destination == null) {
      return _NoDestinationPrompt(onSetDestination: _changeDestination);
    }

    if (_loading) {
      return const _LoadingShimmer();
    }

    if (_error != null) {
      return _ErrorCard(
        message: _error!,
        onRetry: _refresh,
      );
    }

    if (_filteredSpots.isEmpty) {
      return _EmptyResults(filter: _activeFilter, onRetry: _refresh);
    }

    return Column(
      children: [
        _ResultsHeader(count: _filteredSpots.length),
        const SizedBox(height: 8),
        ..._filteredSpots.map(
          (spot) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ParkingCard(
              spot: spot,
              onNavigate: () => _navigateToSpot(spot),
              onViewRoute: () => _viewRoute(spot),
            ),
          ),
        ),
      ],
    );
  }
}

enum _ParkingFilter { all, paid, free, openNow }

class _DestinationBar extends StatelessWidget {
  const _DestinationBar({
    required this.destination,
    required this.onChangeTap,
  });

  final Location? destination;
  final VoidCallback onChangeTap;

  @override
  Widget build(BuildContext context) {
    final hasDest = destination != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parking near',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasDest
                      ? (destination!.address ?? 'Selected location')
                      : 'No destination set',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: hasDest
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onChangeTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                hasDest ? 'Change' : 'Set',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final _ParkingFilter activeFilter;
  final ValueChanged<_ParkingFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isActive: activeFilter == _ParkingFilter.all,
            onTap: () => onFilterChanged(_ParkingFilter.all),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Paid',
            isActive: activeFilter == _ParkingFilter.paid,
            onTap: () => onFilterChanged(_ParkingFilter.paid),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Free',
            isActive: activeFilter == _ParkingFilter.free,
            onTap: () => onFilterChanged(_ParkingFilter.free),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Open Now',
            isActive: activeFilter == _ParkingFilter.openNow,
            onTap: () => onFilterChanged(_ParkingFilter.openNow),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isActive
              ? const [
                  BoxShadow(
                    color: Color(0x1A1A2CC8),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$count parking spot${count == 1 ? '' : 's'} found',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ParkingCard extends StatelessWidget {
  const _ParkingCard({
    required this.spot,
    required this.onNavigate,
    required this.onViewRoute,
  });

  final ParkingSpot spot;
  final VoidCallback onNavigate;
  final VoidCallback onViewRoute;

  @override
  Widget build(BuildContext context) {
    final priceColor =
        spot.isFree ? AppColors.success : AppColors.primary;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          _PhotoBanner(photoUrl: spot.firstPhotoUrl),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Text(
                        spot.displayName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          const Icon(Icons.directions_walk_rounded,
                              size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 3),
                          Text(
                            '${spot.formattedDistance} away',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (spot.rating > 0) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.star_rounded,
                                size: 14, color: Colors.amber.shade600),
                            const SizedBox(width: 2),
                            Text(
                              '${spot.rating.toStringAsFixed(1)} '
                              '(${spot.userRatingsTotal})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: spot.isFree
                        ? AppColors.savingsBackground
                        : AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        spot.formattedPrice,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: priceColor,
                        ),
                      ),
                      if (!spot.isFree)
                        Text(
                          'Est.',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (spot.hoursSummary != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 5),
                  Text(
                    spot.hoursSummary!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: spot.openNow == true
                          ? AppColors.success
                          : spot.openNow == false
                              ? AppColors.textMuted
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.navigation_rounded,
                    label: 'Navigate',
                    color: AppColors.primary,
                    onTap: onNavigate,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.route_rounded,
                    label: 'View Route',
                    color: AppColors.darkSlate,
                    onTap: onViewRoute,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoBanner extends StatelessWidget {
  const _PhotoBanner({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: SizedBox(
          width: double.infinity,
          height: 120,
          child: Image.network(
            photoUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return _photoPlaceholder(isLoading: true);
            },
            errorBuilder: (context, error, stackTrace) {
              return _photoPlaceholder(isLoading: false);
            },
          ),
        ),
      );
    }
    return _photoPlaceholder(isLoading: false);
  }

  Widget _photoPlaceholder({required bool isLoading}) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textMuted,
                ),
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🅿️', style: TextStyle(fontSize: 32)),
                  SizedBox(height: 4),
                  Text(
                    'Parking',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
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
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoDestinationPrompt extends StatelessWidget {
  const _NoDestinationPrompt({required this.onSetDestination});

  final VoidCallback onSetDestination;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🅿️', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Find parking near your destination',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set your destination to discover nearby parking spots, '
            'compare prices, and navigate directly to your chosen lot.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onSetDestination,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A1A2CC8),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Set Destination',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (i) => Padding(
          padding: EdgeInsets.only(
            bottom: 12,
            top: i == 0 ? 4 : 0,
          ),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.filter, required this.onRetry});

  final _ParkingFilter filter;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      _ParkingFilter.all => 'No parking spots found nearby.',
      _ParkingFilter.paid => 'No paid parking found. Try a different area.',
      _ParkingFilter.free => 'No free parking found nearby.',
      _ParkingFilter.openNow => 'No parking confirmed open right now.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded,
              size: 44, color: AppColors.textMuted),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try expanding your search or changing filters.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
