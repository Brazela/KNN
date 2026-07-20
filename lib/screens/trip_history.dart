import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../navigation/navigation.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../widgets/widgets.dart';

class TripHistoryPage extends StatefulWidget {
  const TripHistoryPage({super.key});

  @override
  State<TripHistoryPage> createState() => _TripHistoryPageState();
}

class _TripHistoryPageState extends State<TripHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _showSearch = false;
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _searchQuery = '';
  TravelMode? _selectedMode;

  List<Trip> _trips = [];
  int _page = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;
  bool _initialLoading = true;
  int _generation = 0;

  List<Trip> _recommendations = [];
  int _recPage = 0;
  bool _recHasMore = false;
  bool _recIsLoadingMore = false;
  bool _recInitialLoading = true;
  Map<String, dynamic> _recStats = {};
  int _recGeneration = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _recommendations.isEmpty) {
        _loadRecommendations(page: 0, replace: true);
      }
    });
    _loadPage(page: 0, replace: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPage({required int page, bool replace = false}) async {
    final gen = ++_generation;
    if (!replace) {
      setState(() => _isLoadingMore = true);
    }

    try {
      final provider = context.read<TripProvider>();
      final results = await provider.getFilteredTrips(
        mode: _selectedMode,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        limit: 10,
        offset: page * 10,
      );

      if (gen != _generation) return;

      final count = await provider.countFilteredTrips(
        mode: _selectedMode,
        searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (gen != _generation || !mounted) return;

      setState(() {
        if (replace) {
          _trips = results;
          _page = 0;
        } else {
          _trips.addAll(results);
          _page = page;
        }
        _hasMore = _trips.length < count;
        _initialLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initialLoading = false;
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load trips: $e')),
      );
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = value;
        _initialLoading = true;
      });
      _loadPage(page: 0, replace: true);
    });
  }

  void _onFilterChanged(TravelMode? mode) {
    setState(() {
      _selectedMode = mode;
      _initialLoading = true;
    });
    _loadPage(page: 0, replace: true);
  }

  void _onLoadMore() {
    if (!_isLoadingMore && _hasMore) {
      _loadPage(page: _page + 1);
    }
  }

  void _onRepeatTrip(Trip trip) {
    final provider = context.read<TripProvider>();
    provider.setOrigin(trip.origin);
    provider.setDestination(trip.destination);
    Navigator.of(context).pushNamed(AppRoutes.comparison);
  }

  Future<void> _loadRecommendations({required int page, bool replace = false}) async {
    final gen = ++_recGeneration;
    if (!replace) {
      setState(() => _recIsLoadingMore = true);
    }

    try {
      final provider = context.read<TripProvider>();

      if (replace) {
        _recStats = await provider.getRecommendationStats();
      }

      final results = await provider.getRecommendations(
        limit: 5,
        offset: page * 5,
      );

      if (gen != _recGeneration) return;

      final count = await provider.countRecommendations();

      if (gen != _recGeneration || !mounted) return;

      setState(() {
        if (replace) {
          _recommendations = results;
          _recPage = 0;
        } else {
          _recommendations.addAll(results);
          _recPage = page;
        }
        _recHasMore = _recommendations.length < count;
        _recInitialLoading = false;
        _recIsLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recInitialLoading = false;
        _recIsLoadingMore = false;
      });
    }
  }

  void _onCompareAgain(Trip trip) {
    final provider = context.read<TripProvider>();
    provider.setOrigin(trip.origin);
    provider.setDestination(trip.destination);
    Navigator.of(context).pushNamed(AppRoutes.comparison);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: BottomNav(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pop();
            case 1:
              break;
            case 2:
              Navigator.of(context).pushNamed(AppRoutes.comparison);
            case 3:
              Navigator.of(context).pushNamed(AppRoutes.settings);
          }
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_showSearch && _tabController.index == 0) _buildSearchBar(),
            TabBar(
              controller: _tabController,
              onTap: (index) {
                setState(() {
                  if (index == 1) {
                    _showSearch = false;
                    _searchController.clear();
                    _searchQuery = '';
                  }
                });
              },
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Trips'),
                Tab(text: 'Recommendations'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTripsTab(),
                  _buildRecommendationsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Trip History',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
              color: AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchQuery = '';
                  _loadPage(page: 0, replace: true);
                }
              });
            },
          ),

        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: const InputDecoration(
            hintText: 'Search by location',
            prefixIcon: Icon(Icons.search_rounded),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    const chips = <_FilterChipData>[
      _FilterChipData('All', null),
      _FilterChipData('🚇 Transit', TravelMode.transit),
      _FilterChipData('🚗 Driving', TravelMode.driving),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: chips.map((chip) {
          final isSelected = _selectedMode == chip.mode;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => _onFilterChanged(chip.mode),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  chip.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTripsTab() {
    return Column(
      children: [
        _buildFilterChips(),
        Expanded(child: _buildTripsList()),
      ],
    );
  }

  Widget _buildTripsList() {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedMode != null
                  ? 'No trips match your search'
                  : 'No trips yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedMode != null
                  ? 'Try adjusting your filters'
                  : 'Your trip history will appear here',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _trips.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _trips.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _isLoadingMore
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: _onLoadMore,
                      child: const Text(
                        'Load More',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          );
        }

        return TripCard(
          trip: _trips[index],
          onRepeatTrip: () => _onRepeatTrip(_trips[index]),
        );
      },
    );
  }

  Widget _buildRecommendationsTab() {
    if (_recInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lightbulb_outline_rounded,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'No recommendations yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete a trip to see your recommendation history',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _recommendations.length + (_recHasMore ? 1 : 0) + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildStatsCard();
        }

        final recIndex = index - 1;

        if (recIndex == _recommendations.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _recIsLoadingMore
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : TextButton(
                      onPressed: () {
                        if (!_recIsLoadingMore && _recHasMore) {
                          _loadRecommendations(page: _recPage + 1);
                        }
                      },
                      child: const Text(
                        'Load More',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          );
        }

        return RecommendationCard(
          trip: _recommendations[recIndex],
          onCompareAgain: () => _onCompareAgain(_recommendations[recIndex]),
        );
      },
    );
  }

  Widget _buildStatsCard() {
    final total = _recStats['total'] as int? ?? 0;
    final transitRecs = _recStats['transit_recs'] as int? ?? 0;
    final drivingRecs = _recStats['driving_recs'] as int? ?? 0;
    final totalSavings = (_recStats['total_savings'] as num?)?.toDouble() ?? 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatItem(
                value: '$total',
                label: 'Total',
              ),
              const SizedBox(width: 16),
              _StatItem(
                value: '$transitRecs',
                label: 'Transit (${total > 0 ? (transitRecs * 100 ~/ total) : 0}%)',
                color: AppColors.success,
              ),
              const SizedBox(width: 16),
              _StatItem(
                value: '$drivingRecs',
                label: 'Driving (${total > 0 ? (drivingRecs * 100 ~/ total) : 0}%)',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.savingsBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.savings_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Text(
                  'Total Savings: ${formatCurrency(totalSavings)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.savingsText,
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

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    this.color,
  });

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChipData {
  const _FilterChipData(this.label, this.mode);
  final String label;
  final TravelMode? mode;
}
