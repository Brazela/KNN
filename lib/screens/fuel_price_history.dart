import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../utils/constants.dart';

class FuelPriceHistoryPage extends StatefulWidget {
  const FuelPriceHistoryPage({super.key});

  @override
  State<FuelPriceHistoryPage> createState() => _FuelPriceHistoryPageState();
}

class _FuelPriceHistoryPageState extends State<FuelPriceHistoryPage> {
  List<FuelPrice> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchHistory());
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = context.read<FuelPriceService>();
      final history = await service.getFuelPriceHistory();

      if (mounted) {
        setState(() {
          _history = history;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Price History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _fetchHistory,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'Could not load fuel price data',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchHistory,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_history.isEmpty) {
      return const Center(child: Text('No fuel price data available.'));
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPriceTrendsSection(),
            const SizedBox(height: 20),
            _buildCurrentPricesSection(),
            const SizedBox(height: 20),
            _buildPriceHistoryTable(),
            const SizedBox(height: 20),
            _buildInsightsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceTrendsSection() {
    return const SizedBox.shrink(); // Task 6
  }

  Widget _buildCurrentPricesSection() {
    return const SizedBox.shrink(); // Task 7
  }

  Widget _buildPriceHistoryTable() {
    return const SizedBox.shrink(); // Task 8
  }

  Widget _buildInsightsSection() {
    return const SizedBox.shrink(); // Task 9
  }
}
