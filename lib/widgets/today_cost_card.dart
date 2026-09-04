import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/helpers.dart';
import 'cost_comparison_card.dart';

class TodayCostCard extends StatefulWidget {

  const TodayCostCard({super.key});

  @override
  State<TodayCostCard> createState() => _TodayCostCardState();
}

class _TodayCostCardState extends State<TodayCostCard> {
  double _drivingTotal = 0;
  double _transitTotal = 0;
  double _savings = 0;
  bool _hasTrips = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    context.watch<TripProvider>();
    _loadToday();
  }

  Future<void> _loadToday() async {
    try {
      final service = context.read<TripHistoryService>();
      final today = DateTime.now();
      final trips = await service.getTripsForDate(today);
      if (!mounted) return;

      var driving = 0.0;
      var transit = 0.0;
      var savings = 0.0;
      for (final trip in trips) {
        if (trip.mode == TravelMode.driving) {
          driving += trip.cost;
        } else {
          transit += trip.cost;
        }
        savings += trip.savingsCost ?? 0;
      }

      setState(() {
        _drivingTotal = driving;
        _transitTotal = transit;
        _savings = savings;
        _hasTrips = trips.isNotEmpty;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || !_hasTrips) return const SizedBox.shrink();

    final savingsText = _savings > 0.01
        ? 'You saved ${formatCurrency(_savings)} today'
        : 'No savings yet today';
    return CostComparisonCard(
      title: "Today's Travel Cost",
      driveCost: formatCurrency(_drivingTotal),
      transitCost: formatCurrency(_transitTotal),
      savingsText: savingsText,
    );
  }
}
