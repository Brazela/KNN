import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../navigation/navigation.dart';
import '../providers/providers.dart';
import '../utils/constants.dart';
import '../widgets/widgets.dart';

/// Favorites page — saved Home/Work locations and bookmarked routes.
///
/// UI-mockup implementation: [_favorites] and [_savedRoutes] are seeded
/// with local, in-memory dummy data. Nothing is persisted yet; this is
/// tracked as the Local Database module.
class FavoritesPage extends StatefulWidget {
  /// Creates a [FavoritesPage].
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<FavoriteLocation> _favorites = _dummyFavorites();
  List<SavedRoute> _savedRoutes = _dummySavedRoutes();

  // --- Dummy data ---------------------------------------------------------

  static List<FavoriteLocation> _dummyFavorites() => const [
        FavoriteLocation(
          id: 'fav-home',
          type: FavoriteLocationType.home,
          label: 'Home',
          location: Location(
            latitude: 3.1637,
            longitude: 101.7411,
            address: '123, Jalan Ampang',
          ),
        ),
        FavoriteLocation(
          id: 'fav-work',
          type: FavoriteLocationType.work,
          label: 'Work',
          location: Location(
            latitude: 3.1332,
            longitude: 101.6866,
            address: 'KL Sentral',
          ),
        ),
      ];

  /// Origin/destination addresses here are short labels ("Home", "Work",
  /// "KLCC") rather than full street addresses — matching how the route
  /// cards display them ("Home → Work"), as distinct from the fuller
  /// addresses shown on the location cards above.
  static List<SavedRoute> _dummySavedRoutes() => const [
        SavedRoute(
          id: 'route-1',
          origin: Location(
            latitude: 3.1637,
            longitude: 101.7411,
            address: 'Home',
          ),
          destination: Location(
            latitude: 3.1332,
            longitude: 101.6866,
            address: 'Work',
          ),
          mode: TravelMode.transit,
          cost: 3.0,
          timeMinutes: 55,
          savingsPerTripRM: 15,
        ),
        SavedRoute(
          id: 'route-2',
          origin: Location(
            latitude: 3.1637,
            longitude: 101.7411,
            address: 'Home',
          ),
          destination: Location(
            latitude: 3.1579,
            longitude: 101.7116,
            address: 'KLCC',
          ),
          mode: TravelMode.transit,
          cost: 2.5,
          timeMinutes: 30,
          savingsPerTripRM: 8,
        ),
      ];

  // --- Actions -------------------------------------------------------------

  Future<void> _addFavorite() async {
    final result = await _showEditFavoriteDialog(context);
    if (result == null || !mounted) return;
    setState(() => _favorites = [..._favorites, result]);
  }

  Future<void> _editFavorite(FavoriteLocation favorite) async {
    final result =
        await _showEditFavoriteDialog(context, existing: favorite);
    if (result == null || !mounted) return;
    setState(() {
      _favorites = [
        for (final f in _favorites) if (f.id == result.id) result else f,
      ];
    });
  }

  Future<void> _deleteFavorite(FavoriteLocation favorite) async {
    final confirmed = await _showConfirmDialog(
      context,
      title: 'Remove ${favorite.label}?',
      message: 'You can add it again later from the + button.',
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _favorites = _favorites.where((f) => f.id != favorite.id).toList();
    });
  }

  /// Hands the route off to [TripProvider] and opens the Comparison page —
  /// [ComparisonPage] reads its origin/destination from [TripProvider]
  /// rather than route arguments, so this mirrors how the rest of the app
  /// (e.g. the homepage shortcut chips) starts a comparison.
  void _planRoute(SavedRoute route) {
    final tripProvider = context.read<TripProvider>();
    tripProvider.setOrigin(route.origin);
    tripProvider.setDestination(route.destination);
    Navigator.of(context).pushNamed(AppRoutes.comparison);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _addFavorite,
        backgroundColor: AppColors.primary,
        tooltip: 'Add favorite',
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
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
                      const _SectionLabel('Saved Locations'),
                      const SizedBox(height: 10),
                      if (_favorites.isEmpty)
                        const _EmptyState(
                          icon: Icons.location_off_outlined,
                          message: 'No saved locations yet.',
                        )
                      else
                        for (final favorite in _favorites) ...[
                          FavoriteLocationCard(
                            favorite: favorite,
                            onEdit: () => _editFavorite(favorite),
                            onDelete: () => _deleteFavorite(favorite),
                          ),
                          const SizedBox(height: 10),
                        ],
                      const SizedBox(height: 14),
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
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.savedRouteComparison,
                              arguments: route,
                            ),
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

// --- Dialogs ---------------------------------------------------------------

/// Shows a dialog to add a new favorite, or edit [existing] if provided.
///
/// Returns the created/updated [FavoriteLocation], or `null` if cancelled.
Future<FavoriteLocation?> _showEditFavoriteDialog(
  BuildContext context, {
  FavoriteLocation? existing,
}) {
  final labelController = TextEditingController(text: existing?.label ?? '');
  final addressController = TextEditingController(
    text: existing?.location.address ?? '',
  );
  final formKey = GlobalKey<FormState>();

  return showDialog<FavoriteLocation>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        existing == null ? 'Add favorite' : 'Edit favorite',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter a name'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Enter an address'
                  : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            if (!(formKey.currentState?.validate() ?? false)) return;
            final updated = FavoriteLocation(
              id: existing?.id ?? 'fav-${DateTime.now().millisecondsSinceEpoch}',
              type: existing?.type ?? FavoriteLocationType.custom,
              label: labelController.text.trim(),
              location: Location(
                latitude: existing?.location.latitude ?? 0,
                longitude: existing?.location.longitude ?? 0,
                address: addressController.text.trim(),
              ),
            );
            Navigator.of(dialogContext).pop(updated);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  ).whenComplete(() {
    labelController.dispose();
    addressController.dispose();
  });
}

/// Shows a Yes/No confirmation dialog. Returns `true` if confirmed.
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

// --- Small private widgets --------------------------------------------------

/// Small uppercase section label used above the Locations/Routes lists.
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

/// Placeholder shown when a list has no items yet.
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
