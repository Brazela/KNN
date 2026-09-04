import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../navigation/navigation.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/constants.dart';
import '../widgets/widgets.dart';
import 'search_destination.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const int _tabIndex = 3;
  static const String _appVersion = '1.0.0';

  final _fuelConsumptionController = TextEditingController();
  bool _consumptionSynced = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = context.watch<SettingsService>();
    if (!_consumptionSynced) {
      _consumptionSynced = true;
      _fuelConsumptionController.text =
          (1 / settings.fuelConsumptionPerKm).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _fuelConsumptionController.dispose();
    super.dispose();
  }

  String? _validateFuelConsumption(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) return 'Enter a number';
    if (parsed <= 0) return 'Must be greater than 0';
    return null;
  }

  void _onCarModelChanged(CarModel car) {
    final settings = context.read<SettingsService>();
    settings.setCarModel(car);
    if (!car.isCustom) {
      _fuelConsumptionController.text =
          car.consumptionKmPerL!.toStringAsFixed(2);
    }
  }

  void _onFuelConsumptionChanged(String value) {
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return;
    context.read<SettingsService>().setFuelConsumptionKmPerL(parsed);
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AppRoutes.home);
    }
  }

  void _onTabTap(int index) {
    if (index == _tabIndex) return;
    final navigator = Navigator.of(context);
    switch (index) {
      case 0:
        navigator.pushReplacementNamed(AppRoutes.home);
        break;
      case 1:
        navigator.pushReplacementNamed(AppRoutes.tripHistory);
        break;
      case 2:
        navigator.pushReplacementNamed(AppRoutes.comparison);
        break;
    }
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

  Future<void> _testNotification() async {
    final settings = context.read<SettingsService>();
    final service = context.read<NotificationService>();
    final now = DateTime.now();

    final priceNotification = AppNotification(
      id: 'test-price-${now.millisecondsSinceEpoch}',
      category: NotificationCategory.price,
      title: 'Test: Price alert',
      message: 'This is a test price notification.',
      timestamp: now,
    );

    if (settings.priceAlerts) {
      await service.show(priceNotification);
    } else {
      await service.add(priceNotification);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final tripProvider = context.watch<TripProvider>();

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
                  child: Form(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        SettingsSection(
                          title: 'Travel Preferences',
                          icon: Icons.alt_route_rounded,
                          children: [
                            SettingsDropdownTile<DefaultTravelMode>(
                              icon: Icons.swap_vert_rounded,
                              label: 'Default Mode',
                              value: settings.defaultMode,
                              options: DefaultTravelMode.values,
                              optionLabel: (o) => o.displayName,
                              onChanged: (value) => context
                                  .read<SettingsService>()
                                  .setDefaultMode(value),
                            ),
                            _LocationTile(
                              icon: Icons.home_rounded,
                              label: 'Home',
                              location: tripProvider.home,
                              onTap: () => _setPlace(isHome: true),
                              onRemove: () => _removePlace(isHome: true),
                            ),
                            _LocationTile(
                              icon: Icons.work_outline_rounded,
                              label: 'Work',
                              location: tripProvider.work,
                              onTap: () => _setPlace(isHome: false),
                              onRemove: () => _removePlace(isHome: false),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SettingsSection(
                          title: 'Vehicle Details',
                          icon: Icons.directions_car_rounded,
                          children: [
                            SettingsDropdownTile<CarModel>(
                              icon: Icons.directions_car_filled_rounded,
                              label: 'Car Model',
                              value: settings.selectedCar,
                              options: CarModel.predefinedCars,
                              optionLabel: (o) => o.name,
                              onChanged: _onCarModelChanged,
                            ),
                            SettingsDropdownTile<FuelType>(
                              icon: Icons.local_gas_station_rounded,
                              label: 'Fuel Type',
                              value: settings.fuelType,
                              options: FuelType.values,
                              optionLabel: (o) => o.displayName,
                              onChanged: (value) => context
                                  .read<SettingsService>()
                                  .setFuelType(value),
                            ),
                            SettingsTextFieldTile(
                              icon: Icons.speed_rounded,
                              label: 'Fuel Consumption',
                              controller: _fuelConsumptionController,
                              hintText: 'e.g. 6.67',
                              suffixText: 'km/L',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: _validateFuelConsumption,
                              onChanged: _onFuelConsumptionChanged,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SettingsSection(
                          title: 'Notifications',
                          icon: Icons.notifications_none_rounded,
                          children: [
                            SettingsSwitchTile(
                              icon: Icons.attach_money_rounded,
                              label: 'Price Alerts',
                              subtitle: 'Fuel and fare price changes',
                              value: settings.priceAlerts,
                              onChanged: (value) => context
                                  .read<SettingsService>()
                                  .setPriceAlerts(value),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _testNotification,
                                icon: const Icon(
                                  Icons.notifications_active_outlined,
                                  size: 18,
                                ),
                                label: const Text('Send test notification'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SettingsSection(
                          title: 'About',
                          icon: Icons.info_outline_rounded,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.tag_rounded,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Version',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _appVersion,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _tabIndex,
        onTap: _onTabTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: _handleBack,
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
          'Settings',
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

class _LocationTile extends StatelessWidget {
  const _LocationTile({
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

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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