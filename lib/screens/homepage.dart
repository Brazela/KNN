import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../navigation/navigation.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/constants.dart';
import '../widgets/widgets.dart';
import 'search_destination.dart';

/// Root homepage for the KNN Commute app.
///
/// On first load, requests location permission. Once granted, displays
/// current weather, popular nearby places, quick shortcuts, and
/// transit/cost status summaries.
class Homepage extends StatefulWidget {
  /// Creates a [Homepage].
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _bottomNavIndex = 0;
  bool _locationChecked = false;
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_locationChecked) {
      _locationChecked = true;
      _checkLocationPermission();
    }
  }

  /// Checks location permission and requests the user's current position.
  Future<void> _checkLocationPermission() async {
    final locationService = context.read<LocationService>();
    final tripProvider = context.read<TripProvider>();

    try {
      final permission = await locationService.requestPermission();

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        await LocationPermissionDialog.show(
          context,
          onAllow: () => Geolocator.openAppSettings(),
        );
        return;
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        await LocationPermissionDialog.show(
          context,
          onAllow: () async {
            try {
              final loc = await locationService.getCurrentLocation();
              if (mounted) tripProvider.setCurrentLocation(loc);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not get location: $e')),
                );
              }
            }
          },
        );
        return;
      }

      // Permission granted — get location.
      final loc = await locationService.getCurrentLocation();
      if (mounted) tripProvider.setCurrentLocation(loc);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    final location = context.read<TripProvider>().currentLocation;
    if (location == null) return;

    // Trigger a full data reload by clearing and re-reading dependencies.
    // Widgets will re-fetch via didChangeDependencies on next build.
    setState(() {
      _locationChecked = true; // stays true; re-trigger in widgets.
    });
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();
    final isLoadingLocation =
        tripProvider.currentLocation == null && _locationChecked;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          key: _refreshKey,
          onRefresh: _onRefresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final hPad = isWide ? 40.0 : 20.0;
              const maxW = 420.0;

              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding:
                      EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: maxW),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isLoadingLocation)
                          const _HeroSearch()
                        else
                          const _HeroSearch(),
                        const SizedBox(height: 18),
                        const _ShortcutsRow(),
                        const SizedBox(height: 24),
                        // Popular places — engaging explore content right after shortcuts.
                        if (!isLoadingLocation) ...[
                          PopularPlacesWidget(
                            onPlaceSelected: (place) {
                              Navigator.of(context).pushNamed(
                                AppRoutes.searchDestination,
                                arguments: place,
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                        ],
                        // Weather widget — compact useful context.
                        if (!isLoadingLocation) ...[
                          const WeatherWidget(),
                          const SizedBox(height: 18),
                        ],
                        // Fuel price widget.
                        if (!isLoadingLocation) ...[
                          const FuelPriceWidget(),
                          const SizedBox(height: 18),
                        ],
                        const CostComparisonCard(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _bottomNavIndex,
        onTap: (index) => setState(() => _bottomNavIndex = index),
      ),
    );
  }
}

/// Top bar + weather chip section.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return TopBar(
      onNotificationTap: () {
        Navigator.of(context).pushNamed(AppRoutes.notifications);
      },
      onAlertTap: () {
        Navigator.of(context).pushNamed(AppRoutes.alertsEmergency);
      },
      onProfileTap: () {
        Navigator.of(context).pushNamed(AppRoutes.profile);
      },
    );
  }
}

/// Hero search input section.
class _HeroSearch extends StatelessWidget {
  const _HeroSearch();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _TopBar(),
        const SizedBox(height: 28),
        const Text(
          'Where to?',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.6,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Plan your trip & save',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            // Search text area — tap to go to search destination page.
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.searchDestination,
                  );
                },
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.search_rounded,
                        color: AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Enter destination...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Map icon — tap to pin a location on the map.
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SearchDestinationPage(
                      openMapPicker: true,
                    ),
                  ),
                );
              },
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A1A2CC8),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.map_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Quick shortcut chips row.
class _ShortcutsRow extends StatelessWidget {
  const _ShortcutsRow();

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();

    return Row(
      children: [
        ShortcutChip(
          icon: Icons.home_rounded,
          label: 'Home',
          subtitle: tripProvider.home != null ? 'Saved' : 'Set',
          color: AppColors.primary,
          onTap: () {
            if (tripProvider.home != null) {
              tripProvider.setOrigin(tripProvider.home!);
              Navigator.of(context).pushNamed(AppRoutes.originSelection);
            } else {
              Navigator.of(context).pushNamed(AppRoutes.originSelection);
            }
          },
        ),
        const SizedBox(width: 10),
        ShortcutChip(
          icon: Icons.work_outline_rounded,
          label: 'Work',
          subtitle: tripProvider.work != null ? 'Saved' : 'Set',
          color: AppColors.success,
          onTap: () {
            if (tripProvider.work != null) {
              tripProvider.setOrigin(tripProvider.work!);
              Navigator.of(context).pushNamed(AppRoutes.originSelection);
            } else {
              Navigator.of(context).pushNamed(AppRoutes.originSelection);
            }
          },
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RecentTripChip(
            destination:
                tripProvider.recentTrips.isNotEmpty
                    ? (tripProvider.recentTrips.first.destination.address ??
                        'Recent')
                    : 'Pasar Senen',
            onTap: () {
              if (tripProvider.recentTrips.isNotEmpty) {
                tripProvider.setDestination(
                  tripProvider.recentTrips.first.destination,
                );
              }
              Navigator.of(context).pushNamed(AppRoutes.searchDestination);
            },
          ),
        ),
      ],
    );
  }
}
