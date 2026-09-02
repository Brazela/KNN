import 'package:flutter/material.dart';

import '../../utils/constants.dart';

/// A single settings row: an icon, a label, and a text field with inline
/// validation.
///
/// Used for the Home/Work address fields and the fuel consumption field.
/// `autovalidateMode: onUserInteraction` gives immediate feedback without
/// needing a separate "Save" step, matching a typical mobile settings page.
class SettingsTextFieldTile extends StatelessWidget {
  /// Creates a [SettingsTextFieldTile].
  const SettingsTextFieldTile({
    required this.icon,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.validator,
    this.suffixText,
    super.key,
  });

  /// Icon shown beside [label].
  final IconData icon;

  /// Row label, e.g. "Home Address".
  final String label;

  /// Controls the text being edited.
  final TextEditingController controller;

  /// Placeholder text shown when the field is empty.
  final String? hintText;

  /// Keyboard type, e.g. [TextInputType.number] for numeric fields.
  final TextInputType? keyboardType;

  /// Validates the field's value; returns an error string, or `null` when
  /// valid.
  final String? Function(String? value)? validator;

  /// Optional unit shown after the input, e.g. "L/km".
  final String? suffixText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText,
            suffixText: suffixText,
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}
