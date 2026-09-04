import 'package:flutter/material.dart';

import '../../utils/constants.dart';


class SettingsDropdownTile<T> extends StatelessWidget {
  /// Creates a [SettingsDropdownTile].
  const SettingsDropdownTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.optionLabel,
    required this.onChanged,
    super.key,
  });

  /// Icon shown at the start of the row.
  final IconData icon;

  /// Row label, e.g. "Default Mode".
  final String label;

  /// Currently selected option.
  final T value;

  /// All selectable options.
  final List<T> options;

  /// Maps an option to the text shown in the dropdown.
  final String Function(T option) optionLabel;

  /// Called when the user picks a different option.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        DropdownButton<T>(
          value: value,
          underline: const SizedBox.shrink(),
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
          items: [
            for (final option in options)
              DropdownMenuItem<T>(
                value: option,
                child: Text(optionLabel(option)),
              ),
          ],
          onChanged: (selected) {
            if (selected != null) onChanged(selected);
          },
        ),
      ],
    );
  }
}
