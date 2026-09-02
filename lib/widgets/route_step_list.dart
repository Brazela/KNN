import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'route_step_card.dart';

/// A scrollable list of route steps shared by the route-details and
/// live-tracking screens.
///
/// Renders each step with a numbered badge (matching the numbered map
/// markers), an icon, description, and duration. Supports highlighting the
/// current step and ticking off completed steps during an active trip.
class RouteStepList extends StatefulWidget {
  /// Creates a [RouteStepList].
  const RouteStepList({
    super.key,
    required this.steps,
    required this.stepInfos,
    required this.mode,
    required this.accentColor,
    this.currentStepIndex,
    this.onStepTap,
    this.onStartTrip,
    this.scrollController,
    this.skipFirstStep,
  });

  /// Human-readable step instructions (primary text source).
  final List<String> steps;

  /// Rich step data (icons, durations, transit details) — parallels [steps].
  final List<DirectionsStepInfo> stepInfos;

  /// Travel mode; driving skips the first (trivial) step.
  final TravelMode mode;

  /// Accent color for badges and the active highlight.
  final Color accentColor;

  /// 0-based index (into the visible list) of the current step, or null.
  final int? currentStepIndex;

  /// Called when a step is tapped, with the visible-list index.
  final ValueChanged<int>? onStepTap;

  /// When non-null, a "Start Trip" button is rendered after the last step.
  final VoidCallback? onStartTrip;

  /// Optional scroll controller (e.g. from a DraggableScrollableSheet).
  final ScrollController? scrollController;

  /// When true, the first step is hidden (driving's trivial first step).
  /// Defaults to `mode == TravelMode.driving`. Set to false when a synthetic
  /// "Go to from" step was prepended so it is always shown.
  final bool? skipFirstStep;

  @override
  State<RouteStepList> createState() => RouteStepListState();
}

/// State for [RouteStepList], exposing [RouteStepListState.scrollToStep].
class RouteStepListState extends State<RouteStepList> {
  final List<GlobalKey> _itemKeys = [];

  /// Number of steps skipped from the start (driving skips the trivial
  /// "head from current location" step unless overridden).
  int get _skipOffset =>
      (widget.skipFirstStep ?? (widget.mode == TravelMode.driving)) ? 1 : 0;

  /// Scrolls the list so the step at [visibleIndex] is in view.
  void scrollToStep(int visibleIndex) {
    if (visibleIndex < 0 || visibleIndex >= _itemKeys.length) return;
    final ctx = _itemKeys[visibleIndex].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
  }

  @override
  void didUpdateWidget(RouteStepList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentStepIndex != oldWidget.currentStepIndex &&
        widget.currentStepIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) scrollToStep(widget.currentStepIndex!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final skipOffset = _skipOffset;
    final stepCount = widget.steps.length - skipOffset;
    final showButton = widget.onStartTrip != null;

    final children = <Widget>[];
    for (var i = 0; i < stepCount; i++) {
      final stepIndex = i + skipOffset;
      final stepNumber = i + 1;
      final isActive = widget.currentStepIndex == i;
      final isCompleted =
          widget.currentStepIndex != null && i < widget.currentStepIndex!;

      // Ensure a key exists for this item.
      while (_itemKeys.length <= i) {
        _itemKeys.add(GlobalKey());
      }

      children.add(
        GestureDetector(
          key: _itemKeys[i],
          onTap: widget.onStepTap == null
              ? null
              : () => widget.onStepTap!(i),
          child: _buildStepCard(
            stepIndex,
            stepNumber,
            isActive,
            isCompleted,
          ),
        ),
      );
    }

    if (showButton) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ElevatedButton(
            onPressed: widget.onStartTrip,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Start Trip',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      );
    }

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: children,
    );
  }

  Widget _buildStepCard(
    int stepIndex,
    int stepNumber,
    bool isActive,
    bool isCompleted,
  ) {
    final hasRich = stepIndex < widget.stepInfos.length;
    IconData stepIcon;
    String duration = '';

    if (hasRich) {
      final si = widget.stepInfos[stepIndex];
      final durSec = si.durationSeconds;
      if (si.travelMode == 'WALKING') {
        stepIcon = Icons.directions_walk_rounded;
        duration = durSec > 0 ? '${(durSec / 60).ceil()}m' : '';
      } else if (si.travelMode == 'TRANSIT') {
        stepIcon = _vehicleIcon(si.transitInfo?.vehicleType ?? '');
        duration = durSec > 0 ? '${(durSec / 60).ceil()}m' : '';
      } else {
        stepIcon = _stepIcon(widget.steps[stepIndex]);
        duration = durSec > 0 ? '${(durSec / 60).ceil()}m' : '';
      }
    } else {
      stepIcon = _stepIcon(widget.steps[stepIndex]);
      duration = '';
    }

    final stepText = widget.steps[stepIndex];
    String description;
    if (hasRich &&
        widget.stepInfos[stepIndex].travelMode == 'TRANSIT' &&
        widget.stepInfos[stepIndex].transitInfo != null) {
      final ti = widget.stepInfos[stepIndex].transitInfo!;
      description = '$stepText\n'
          '  ${ti.vehicleName}: ${ti.lineName}'
          '  · ${ti.departureStop} → ${ti.arrivalStop}'
          '${ti.numStops > 0 ? ' · ${ti.numStops} stops' : ''}';
    } else {
      description = stepText;
    }

    return RouteStepCard(
      stepNumber: stepNumber,
      icon: stepIcon,
      description: description,
      duration: duration,
      accentColor: widget.accentColor,
      isActive: isActive,
      isCompleted: isCompleted,
    );
  }

  /// Maps a Google vehicle type to a Flutter icon.
  IconData _vehicleIcon(String vehicleType) {
    switch (vehicleType.toUpperCase()) {
      case 'BUS':
        return Icons.directions_bus_rounded;
      case 'SUBWAY':
      case 'METRO':
        return Icons.subway_rounded;
      case 'TRAIN':
      case 'RAIL':
      case 'HEAVY_RAIL':
      case 'COMMUTER_TRAIN':
        return Icons.train_rounded;
      case 'TRAM':
      case 'LIGHT_RAIL':
        return Icons.tram_rounded;
      case 'MONORAIL':
        return Icons.mode_fan_off_rounded;
      default:
        return Icons.directions_transit_rounded;
    }
  }

  /// Chooses an appropriate icon based on step text content (driving fallback).
  IconData _stepIcon(String step) {
    final lower = step.toLowerCase();
    if (lower.contains('turn left')) return Icons.turn_left_rounded;
    if (lower.contains('turn right')) return Icons.turn_right_rounded;
    if (lower.contains('straight') || lower.contains('continue')) {
      return Icons.straight_rounded;
    }
    if (lower.contains('roundabout') || lower.contains('rotary')) {
      return Icons.roundabout_right_rounded;
    }
    if (lower.contains('merge')) return Icons.merge_type_rounded;
    if (lower.contains('exit') || lower.contains('ramp')) {
      return Icons.exit_to_app_rounded;
    }
    if (lower.contains('walk') || lower.contains('foot')) {
      return Icons.directions_walk_rounded;
    }
    if (lower.contains('bus')) return Icons.directions_bus_rounded;
    if (lower.contains('train') || lower.contains('rail')) {
      return Icons.train_rounded;
    }
    if (lower.contains('subway') || lower.contains('metro')) {
      return Icons.subway_rounded;
    }
    return Icons.navigation_rounded;
  }
}