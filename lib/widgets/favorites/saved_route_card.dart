import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class SavedRouteCard extends StatelessWidget {

  const SavedRouteCard({
    required this.route,
    required this.onPlanRoute,
    this.onEdit,
    this.onDelete,
    super.key,
  });

  final SavedRoute route;

  final VoidCallback onPlanRoute;

  final VoidCallback? onEdit;

  final VoidCallback? onDelete;

  bool get _isTransit => route.mode == TravelMode.transit;

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit route'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onEdit?.call();
                },
              ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Delete route',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onDelete?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeColor = _isTransit ? AppColors.success : AppColors.primary;

    return GestureDetector(
      onLongPress: (onEdit != null || onDelete != null)
          ? () => _showActions(context)
          : null,
      child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${route.origin.address ?? 'Origin'} → '
            '${route.destination.address ?? 'Destination'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _isTransit
                    ? Icons.directions_transit_rounded
                    : Icons.directions_car_rounded,
                size: 16,
                color: modeColor,
              ),
              const SizedBox(width: 6),
              Text(
                _isTransit ? 'Transit' : 'Driving',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: modeColor,
                ),
              ),
              if (route.savingsPerTripRM > 0) ...[
                Text(
                  '  •  ',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                Flexible(
                  child: Text(
                    'Saves ${formatCurrency(route.savingsPerTripRM)}/trip',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPlanRoute,
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text('Plan Route'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
