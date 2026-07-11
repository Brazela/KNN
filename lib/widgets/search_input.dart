import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// A reusable search input field used by both the Search Destination and
/// Origin Selection pages.
///
/// Features a search icon on the left, a text field in the centre, and an
/// optional map-picker icon on the right.
class SearchInput extends StatelessWidget {
  /// Creates a [SearchInput].
  const SearchInput({
    required this.controller,
    this.hintText = 'Where to?',
    this.onChanged,
    this.onSubmitted,
    this.onMapTap,
    this.focusNode,
    super.key,
  });

  /// Controls the text being edited.
  final TextEditingController controller;

  /// Placeholder text shown when the field is empty.
  final String hintText;

  /// Called when the user types into the field.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the search (e.g. presses Enter).
  final ValueChanged<String>? onSubmitted;

  /// Called when the user taps the map icon on the right.
  ///
  /// Typically opens a full-screen map picker.
  final VoidCallback? onMapTap;

  /// An optional focus node for the text field.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (onMapTap != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onMapTap,
              child: const Icon(
                Icons.map_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
