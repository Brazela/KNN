import 'package:flutter/material.dart';

import '../utils/constants.dart';


class LocationPermissionDialog extends StatelessWidget {
  /// Creates a [LocationPermissionDialog].
  const LocationPermissionDialog({
    this.onAllow,
    this.onSkip,
    super.key,
  });

  /// Called when the user taps the "Allow" button.
  final VoidCallback? onAllow;

  /// Called when the user taps the "Skip" button.
  final VoidCallback? onSkip;

  /// Shows a [LocationPermissionDialog] on top of the current route.
  ///
  /// The dialog cannot be dismissed by tapping outside of it.
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onAllow,
    VoidCallback? onSkip,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LocationPermissionDialog(
        onAllow: onAllow,
        onSkip: onSkip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'We need your location',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: const Text(
        'To show nearby places and transit options',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            onSkip?.call();
            Navigator.of(context).pop();
          },
          child: const Text(
            'Skip',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            onAllow?.call();
            Navigator.of(context).pop();
          },
          child: const Text(
            'Allow',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
