import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/services.dart';
import '../utils/constants.dart';

/// Displays the latest Malaysian fuel prices published by data.gov.my.
///
/// Shows RON95, RON97, Diesel (Peninsular & East Malaysia), and any
/// additional subsidised price tiers when available. Also displays the
/// effective date of the published prices.
class FuelPriceWidget extends StatefulWidget {
  /// Creates a [FuelPriceWidget].
  const FuelPriceWidget({super.key});

  @override
  State<FuelPriceWidget> createState() => _FuelPriceWidgetState();
}

class _FuelPriceWidgetState extends State<FuelPriceWidget> {
  FuelPrice? _fuelPrice;
  bool _loading = false;
  String? _error;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadFuelPrice();
    }
  }

  /// Fetches the latest fuel price record.
  Future<void> _loadFuelPrice() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final service = context.read<FuelPriceService>();
      final price = await service.getFuelPrice();

      if (mounted) {
        setState(() {
          _fuelPrice = price;
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

  /// Formats the effective date into a human-readable string.
  String _formatDate(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state.
    if (_loading && _fuelPrice == null) {
      return _buildShimmer();
    }

    // Error state.
    if (_error != null && _fuelPrice == null) {
      return _buildError();
    }

    // Data loaded.
    if (_fuelPrice != null) {
      return _buildContent(_fuelPrice!);
    }

    // Before first load.
    return const SizedBox.shrink();
  }

  /// Card content when data is loaded.
  Widget _buildContent(FuelPrice fuel) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icon + title + date badge.
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_gas_station_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Fuel Prices',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(fuel.date),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Main price rows.
          _PriceRow(
            label: 'RON 95',
            price: fuel.ron95,
            color: const Color(0xFF059669),
          ),
          const SizedBox(height: 8),
          _PriceRow(
            label: 'RON 97',
            price: fuel.ron97,
            color: const Color(0xFFD97706),
          ),
          const SizedBox(height: 8),
          _PriceRow(
            label: 'Diesel',
            price: fuel.diesel,
            subtitle: 'Peninsular',
            color: const Color(0xFF1D4ED8),
          ),
          if (fuel.dieselEastMsia != null) ...[
            const SizedBox(height: 8),
            _PriceRow(
              label: 'Diesel',
              price: fuel.dieselEastMsia!,
              subtitle: 'East Malaysia',
              color: const Color(0xFF7C3AED),
            ),
          ],
          // Optional subsidised price tiers.
          if (fuel.ron95Skps != null ||
              fuel.dieselBudi != null ||
              fuel.dieselSkds != null ||
              fuel.ron95Budi95 != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            const Text(
              'Subsidised Tiers',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            if (fuel.ron95Skps != null)
              _SubPriceRow(
                label: 'RON 95 SKPS',
                price: fuel.ron95Skps!,
              ),
            if (fuel.ron95Budi95 != null)
              _SubPriceRow(
                label: 'RON 95 BUDI95',
                price: fuel.ron95Budi95!,
              ),
            if (fuel.dieselBudi != null)
              _SubPriceRow(
                label: 'Diesel BUDI',
                price: fuel.dieselBudi!,
              ),
            if (fuel.dieselSkds != null)
              _SubPriceRow(
                label: 'Diesel SKDS',
                price: fuel.dieselSkds!,
              ),
          ],
          // Last-updated note.
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Updated ${_formatDate(fuel.date)}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Error state with retry button.
  Widget _buildError() {
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_gas_station_rounded,
              color: Color(0xFFDC2626),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Fuel prices unavailable',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            height: 32,
            child: TextButton(
              onPressed: _loading ? null : _loadFuelPrice,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: const Color(0xFFF3F4F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer placeholder while data loads.
  Widget _buildShimmer() {
    return Container(
      height: 100,
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
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// A main price row showing a fuel type and its price.
class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.price,
    this.subtitle,
    required this.color,
  });

  final String label;
  final double price;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ),
        Text(
          'RM ${price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// A smaller price row for subsidised fuel tiers.
class _SubPriceRow extends StatelessWidget {
  const _SubPriceRow({required this.label, required this.price});

  final String label;
  final double price;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            'RM ${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
