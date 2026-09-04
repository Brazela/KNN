import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../navigation/navigation.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/widgets.dart';


/// [GoogleMapsService.nearbySearch] and [GoogleMapsService.categoryEmoji]

class _ServiceCategory {
  const _ServiceCategory(this.type, this.label);

  final String type;
  final String label;
}

const _categories = [
  _ServiceCategory('gas_station', 'Fuel'),
  _ServiceCategory('parking', 'Parking'),
  _ServiceCategory('car_repair', 'Car Repair'),
  _ServiceCategory('atm', 'ATM'),
  _ServiceCategory('pharmacy', 'Pharmacy'),
  _ServiceCategory('electric_vehicle_charging_station', 'EV Charging'),
];


class NearbyServicesPage extends StatefulWidget {
  const NearbyServicesPage({super.key});

  @override
  State<NearbyServicesPage> createState() => _NearbyServicesPageState();
}

class _NearbyServicesPageState extends State<NearbyServicesPage> {
  final List<NearbyPlace> _places = _dummyPlaces();
  String? _activeType;

  static List<NearbyPlace> _dummyPlaces() => const [
        NearbyPlace(
          placeId: 'np-1',
          name: 'Petronas Jalan Ampang',
          vicinity: 'Jalan Ampang, Kuala Lumpur',
          rating: 4.3,
          userRatingsTotal: 210,
          latitude: 3.1602,
          longitude: 101.7188,
          types: ['gas_station', 'point_of_interest'],
        ),
        NearbyPlace(
          placeId: 'np-2',
          name: 'Menara UOA Parking',
          vicinity: 'Jalan P. Ramlee, Kuala Lumpur',
          rating: 3.9,
          userRatingsTotal: 87,
          latitude: 3.1520,
          longitude: 101.7120,
          types: ['parking'],
        ),
        NearbyPlace(
          placeId: 'np-3',
          name: 'Bengkel Ahmad Motor',
          vicinity: 'Jalan Tun Razak, Kuala Lumpur',
          rating: 4.6,
          userRatingsTotal: 54,
          latitude: 3.1580,
          longitude: 101.7250,
          types: ['car_repair'],
        ),
        NearbyPlace(
          placeId: 'np-4',
          name: 'Maybank ATM KL Sentral',
          vicinity: 'KL Sentral, Kuala Lumpur',
          rating: 4.0,
          userRatingsTotal: 12,
          latitude: 3.1335,
          longitude: 101.6865,
          types: ['atm', 'bank'],
        ),
        NearbyPlace(
          placeId: 'np-5',
          name: 'Guardian Pharmacy KLCC',
          vicinity: 'Suria KLCC, Kuala Lumpur',
          rating: 4.4,
          userRatingsTotal: 302,
          latitude: 3.1580,
          longitude: 101.7120,
          types: ['pharmacy'],
        ),
        NearbyPlace(
          placeId: 'np-6',
          name: 'ChargeSini EV Point',
          vicinity: 'Jalan Ampang, Kuala Lumpur',
          rating: 4.1,
          userRatingsTotal: 29,
          latitude: 3.1610,
          longitude: 101.7200,
          types: ['electric_vehicle_charging_station'],
        ),
      ];

  List<NearbyPlace> get _visiblePlaces {
    if (_activeType == null) return _places;
    return _places.where((p) => p.types.contains(_activeType)).toList();
  }

  
  Location get _referenceLocation => const Location(
        latitude: 3.1637,
        longitude: 101.7411,
        address: 'Current Location',
      );

  void _viewRoute(BuildContext context, NearbyPlace place) {
    final tripProvider = context.read<TripProvider>();
    tripProvider.setOrigin(_referenceLocation);
    tripProvider.setDestination(
      Location(
        latitude: place.latitude,
        longitude: place.longitude,
        address: place.name,
      ),
    );
    Navigator.of(context).pushNamed(AppRoutes.comparison);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final hPad = isWide ? 40.0 : 20.0;
            const maxW = 480.0;
            final reference = _referenceLocation;

            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxW),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildFilterRow(),
                      const SizedBox(height: 16),
                      if (_visiblePlaces.isEmpty)
                        const _EmptyState()
                      else
                        for (final place in _visiblePlaces) ...[
                          ServiceCard(
                            place: place,
                            distanceKm: calculateDistance(
                              reference.latitude,
                              reference.longitude,
                              place.latitude,
                              place.longitude,
                            ),
                            onViewRoute: () => _viewRoute(context, place),
                          ),
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Nearby Services',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          CategoryFilterChip(
            label: 'All',
            selected: _activeType == null,
            onTap: () => setState(() => _activeType = null),
          ),
          for (final category in _categories) ...[
            const SizedBox(width: 8),
            CategoryFilterChip(
              label: category.label,
              selected: _activeType == category.type,
              onTap: () => setState(() => _activeType = category.type),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 30,
            color: AppColors.textMuted,
          ),
          SizedBox(height: 8),
          Text(
            'No services found nearby',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
