import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../navigation/navigation.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/constants.dart';
import '../widgets/widgets.dart';
import 'search_destination.dart';






class Homepage extends StatefulWidget {
  
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final int _bottomNavIndex = 0;
  bool _locationChecked = false;
  int _refreshTick = 0;
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

    
    setState(() {
      _refreshTick++;
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
                        
                        if (!isLoadingLocation) ...[
                          WeatherWidget(key: ValueKey('weather-$_refreshTick')),
                          const SizedBox(height: 18),
                        ],
                        
                        if (!isLoadingLocation) ...[
                          FuelPriceWidget(key: ValueKey('fuel-$_refreshTick')),
                          const SizedBox(height: 18),
                        ],
                        
                        
                        if (!isLoadingLocation) ...[
                          const ParkingShortcutWidget(),
                          const SizedBox(height: 18),
                        ],
                        const TodayCostCard(),
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
        onTap: (index) {
          if (index == _bottomNavIndex) {
            
            setState(() => _refreshTick++);
            return;
          }
          switch (index) {
            case 1:
              Navigator.of(context).pushReplacementNamed(
                AppRoutes.tripHistory,
              );
              break;
            case 2:
              Navigator.of(context).pushReplacementNamed(
                AppRoutes.comparison,
              );
              break;
            case 3:
              Navigator.of(context).pushReplacementNamed(AppRoutes.settings);
              break;
          }
        },
      ),
    );
  }
}


class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return TopBar(
      onFavoritesTap: () {
        Navigator.of(context).pushNamed(AppRoutes.favorites);
      },
      onNearbyServicesTap: () {
        Navigator.of(context).pushNamed(AppRoutes.nearbyServices);
      },
      onNotificationTap: () {
        Navigator.of(context).pushNamed(AppRoutes.notifications);
      },
    );
  }
}


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
          subtitle: tripProvider.home != null
              ? (tripProvider.home!.address ?? 'Saved')
              : 'Set home',
          color: AppColors.primary,
          onTap: () => _onPlaceTap(context, tripProvider, isHome: true),
          onLongPress: () =>
              _onPlaceLongPress(context, tripProvider, isHome: true),
        ),
        const SizedBox(width: 10),
        ShortcutChip(
          icon: Icons.work_outline_rounded,
          label: 'Work',
          subtitle: tripProvider.work != null
              ? (tripProvider.work!.address ?? 'Saved')
              : 'Set work',
          color: AppColors.success,
          onTap: () => _onPlaceTap(context, tripProvider, isHome: false),
          onLongPress: () =>
              _onPlaceLongPress(context, tripProvider, isHome: false),
        ),
      ],
    );
  }

  
  
  
  
  
  
  void _onPlaceTap(
    BuildContext context,
    TripProvider tripProvider, {
    required bool isHome,
  }) {
    final place = isHome ? tripProvider.home : tripProvider.work;
    if (place != null) {
      tripProvider.setDestination(place);
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SearchDestinationPage(initialLocation: place),
        ),
      );
      return;
    }
    _openSetPlace(context, tripProvider, isHome: isHome);
  }

  
  void _onPlaceLongPress(
    BuildContext context,
    TripProvider tripProvider, {
    required bool isHome,
  }) {
    final place = isHome ? tripProvider.home : tripProvider.work;
    if (place == null) return;

    final label = isHome ? 'Home' : 'Work';
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_location_alt_rounded),
              title: Text('Change $label'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _openSetPlace(context, tripProvider, isHome: isHome);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: Text('Remove $label'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                if (isHome) {
                  tripProvider.clearHome();
                } else {
                  tripProvider.clearWork();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label removed')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  
  Future<void> _openSetPlace(
    BuildContext context,
    TripProvider tripProvider, {
    required bool isHome,
  }) async {
    final label = isHome ? 'Home' : 'Work';
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchDestinationPage(
          confirmLabel: 'Save as $label',
          onPlacePicked: (location) async {
            if (isHome) {
              tripProvider.setHome(location);
            } else {
              tripProvider.setWork(location);
            }
          },
        ),
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label saved')),
      );
    }
  }
}
