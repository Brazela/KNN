import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../navigation/navigation.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/constants.dart';
import '../widgets/widgets.dart';
import 'search_destination.dart';

class FavoritesPage extends StatefulWidget {

  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _storage = LocalStorageService();

  List<SavedRoute> _savedRoutes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storedRoutes = await _storage.loadSavedRoutes();
    if (!mounted) return;

    setState(() {
      _savedRoutes = (storedRoutes ?? const [])
          .where((r) => r.id != 'route-1' && r.id != 'route-2')
          .toList();
      _isLoading = false;
    });

    if (storedRoutes != null) await _storage.saveSavedRoutes(_savedRoutes);
  }

  Future<void> _editSavedRoute(SavedRoute route) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.trip_origin_rounded),
              title: const Text('Change origin'),
              onTap: () => Navigator.of(sheetContext).pop('origin'),
            ),
            ListTile(
              leading: const Icon(Icons.location_on_rounded),
              title: const Text('Change destination'),
              onTap: () => Navigator.of(sheetContext).pop('destination'),
            ),
            ListTile(
              leading: Icon(
                route.mode == TravelMode.transit
                    ? Icons.directions_car_rounded
                    : Icons.directions_transit_rounded,
              ),
              title: Text(
                route.mode == TravelMode.transit
                    ? 'Switch to driving'
                    : 'Switch to transit',
              ),
              onTap: () => Navigator.of(sheetContext).pop('mode'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case 'origin':
        final loc = await _pickLocation(
          context,
          initial: route.origin,
          confirmLabel: 'Change origin',
        );
        if (loc != null && mounted) {
          await _updateSavedRoute(route.copyWith(origin: loc));
        }
        break;
      case 'destination':
        final loc = await _pickLocation(
          context,
          initial: route.destination,
          confirmLabel: 'Change destination',
        );
        if (loc != null && mounted) {
          await _updateSavedRoute(route.copyWith(destination: loc));
        }
        break;
      case 'mode':
        await _updateSavedRoute(
          route.copyWith(
            mode: route.mode == TravelMode.transit
                ? TravelMode.driving
                : TravelMode.transit,
          ),
        );
        break;
    }
  }

  Future<void> _updateSavedRoute(SavedRoute updated) async {
    setState(() {
      _savedRoutes = [
        for (final r in _savedRoutes) if (r.id == updated.id) updated else r,
      ];
    });
    await _storage.saveSavedRoutes(_savedRoutes);
  }

  Future<void> _deleteSavedRoute(SavedRoute route) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Delete this route?',
      message:
          '${route.origin.address ?? 'Origin'} → '
          '${route.destination.address ?? 'Destination'}',
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _savedRoutes = _savedRoutes.where((r) => r.id != route.id).toList();
    });
    await _storage.saveSavedRoutes(_savedRoutes);
  }

  Future<void> _setPlace({required bool isHome}) async {
    final tripProvider = context.read<TripProvider>();
    final label = isHome ? 'Home' : 'Work';
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchDestinationPage(
          confirmLabel: 'Save as $label',
          onPlacePicked: (location) async {
            if (isHome) {
              tripProvider.setHome(location);
            } else {
              tripProvider.setWork(location);
            }
          },
        ),
      ),
    );
  }

  void _removePlace({required bool isHome}) {
    final tripProvider = context.read<TripProvider>();
    if (isHome) {
      tripProvider.clearHome();
    } else {
      tripProvider.clearWork();
    }
  }

  void _planRoute(SavedRoute route) {
    final tripProvider = context.read<TripProvider>();
    tripProvider.setOrigin(route.origin);
    tripProvider.setDestination(route.destination);
    Navigator.of(context).pushNamed(AppRoutes.comparison);
  }

  @override
  Widget build(BuildContext context) {
    final tripProvider = context.watch<TripProvider>();

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final hPad = isWide ? 40.0 : 20.0;
            const maxW = 480.0;

            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxW),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _HomeWorkCard(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        location: tripProvider.home,
                        onTap: () => _setPlace(isHome: true),
                        onRemove: () => _removePlace(isHome: true),
                      ),
                      const SizedBox(height: 10),
                      _HomeWorkCard(
                        icon: Icons.work_outline_rounded,
                        label: 'Work',
                        location: tripProvider.work,
                        onTap: () => _setPlace(isHome: false),
                        onRemove: () => _removePlace(isHome: false),
                      ),
                      const SizedBox(height: 20),
                      const _SectionLabel('Saved Routes'),
                      const SizedBox(height: 10),
                      if (_savedRoutes.isEmpty)
                        const _EmptyState(
                          icon: Icons.route_outlined,
                          message: 'No saved routes yet. Plan a trip and '
                              'save it here for one-tap access.',
                        )
                      else
                        for (final route in _savedRoutes) ...[
                          SavedRouteCard(
                            route: route,
                            onPlanRoute: () => _planRoute(route),
                            onEdit: () => _editSavedRoute(route),
                            onDelete: () => _deleteSavedRoute(route),
                          ),
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Favorites',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

Future<Location?> _pickLocation(
  BuildContext context, {
  Location? initial,
  required String confirmLabel,
}) async {
  Location? picked;
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SearchDestinationPage(
        initialLocation: initial,
        confirmLabel: confirmLabel,
        onPlacePicked: (location) async {
          picked = location;
        },
      ),
    ),
  );
  return picked;
}

Future<bool?> _showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HomeWorkCard extends StatelessWidget {
  const _HomeWorkCard({
    required this.icon,
    required this.label,
    required this.location,
    required this.onTap,
    required this.onRemove,
  });

  final IconData icon;
  final String label;
  final Location? location;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  Color get _color =>
      icon == Icons.home_rounded ? AppColors.primary : AppColors.success;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: _color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    location?.address ?? 'Not set — tap to choose',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: location != null
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            if (location != null)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.textMuted,
                onPressed: onRemove,
              ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
