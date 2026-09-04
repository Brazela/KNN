import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/services.dart';
import 'route_step_card.dart';

class RouteStepList extends StatefulWidget {

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

  final List<String> steps;

  final List<DirectionsStepInfo> stepInfos;

  final TravelMode mode;

  final Color accentColor;

  final int? currentStepIndex;

  final ValueChanged<int>? onStepTap;

  final VoidCallback? onStartTrip;

  final ScrollController? scrollController;

  final bool? skipFirstStep;

  @override
  State<RouteStepList> createState() => RouteStepListState();
}

class RouteStepListState extends State<RouteStepList> {
  final List<GlobalKey> _itemKeys = [];

  int get _skipOffset =>
      (widget.skipFirstStep ?? (widget.mode == TravelMode.driving)) ? 1 : 0;

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
