import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Bottom navigation bar with Home, Trips, Compare, and Settings tabs.
class BottomNav extends StatelessWidget {
  /// Creates a [BottomNav].
  const BottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  /// Currently selected tab index.
  final int currentIndex;

  /// Callback invoked when a tab is tapped.
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route_rounded),
            activeIcon: Icon(Icons.route_rounded),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows_rounded),
            activeIcon: Icon(Icons.compare_arrows_rounded),
            label: 'Compare',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
