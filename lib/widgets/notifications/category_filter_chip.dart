import 'package:flutter/material.dart';

import '../../utils/constants.dart';

/// A single filter chip at the top of the Notifications page, used to
/// narrow the list to one category (or show "All").
class CategoryFilterChip extends StatelessWidget {
  /// Creates a [CategoryFilterChip].
  const CategoryFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// Chip label, e.g. "All", "Price".
  final String label;

  /// Whether this chip is the active filter.
  final bool selected;

  /// Called when the user taps this chip.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
