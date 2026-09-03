import 'package:flutter/material.dart';

import '../models/models.dart';
import '../navigation/navigation.dart';
import '../utils/constants.dart';
import '../widgets/widgets.dart';

/// Settings tab — general preferences, travel defaults, vehicle details,
/// notification toggles, data management actions, and app info.
///
/// This is a UI-mockup implementation: every field below holds local,
/// in-memory dummy state and nothing is persisted yet. Wiring this to a
/// real settings store is tracked as the Local Database module.
class SettingsPage extends StatefulWidget {
  /// Creates a [SettingsPage].
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  /// This page's own position in [BottomNav] (Home=0, Trips=1, Compare=2,
  /// Settings=3 — see `navigation/bottom_nav.dart`).
  static const int _tabIndex = 3;

  static const String _appVersion = '1.0.0';

  // --- General ---
  AppLanguage _language = AppLanguage.english;

  // --- Travel preferences ---
  DefaultTravelMode _defaultMode = DefaultTravelMode.fastest;
  final _homeAddressController =
      TextEditingController(text: '123, Jalan Ampang');
  final _workAddressController = TextEditingController(text: 'KL Sentral');

  // --- Vehicle details ---
  CarModel _selectedCar = CarModel.custom;
  FuelType _fuelType = FuelType.ron95;

  /// Fuel Consumption is shown in km/L (the unit drivers actually think
  /// in / what's on a car's spec sheet), while `Defaults.fuelConsumptionPerKm`
  /// — used elsewhere for cost math — is stored as L/km. The two are
  /// reciprocals of each other (0.15 L/km ≈ 6.67 km/L), so the initial
  /// value here is derived from the same constant rather than a second,
  /// separately-maintained number.
  late final _fuelConsumptionController = TextEditingController(
    text: (1 / Defaults.fuelConsumptionPerKm).toStringAsFixed(2),
  );

  // --- Notifications ---
  bool _priceAlerts = true;
  bool _weatherAlerts = true;

  @override
  void dispose() {
    _homeAddressController.dispose();
    _workAddressController.dispose();
    _fuelConsumptionController.dispose();
    super.dispose();
  }

  /// Validates a required address field.
  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter an address';
    return null;
  }

  /// Validates the fuel consumption field: must be a positive number.
  String? _validateFuelConsumption(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null) return 'Enter a number';
    if (parsed <= 0) return 'Must be greater than 0';
    return null;
  }

  /// Handles a Car Model selection.
  ///
  /// Picking a specific preset (e.g. "Perodua Myvi") auto-fills Fuel Type
  /// and Fuel Consumption from it. Picking [CarModel.custom] ("Other")
  /// leaves both fields exactly as they were, so a user whose car isn't
  /// listed keeps full manual control — nothing here overwrites their own
  /// entry with placeholder values.
  void _onCarModelChanged(CarModel car) {
    setState(() {
      _selectedCar = car;
      if (!car.isCustom) {
        _fuelType = car.fuelType!;
        _fuelConsumptionController.text =
            car.consumptionKmPerL!.toStringAsFixed(2);
      }
    });
  }

  /// Placeholder action for the About section's links — this build has no
  /// real Privacy Policy / Terms / Contact / Feedback destination yet.
  void _showComingSoon(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
  }

  /// Handles the back arrow in the header.
  ///
  /// Settings is reached almost exclusively via the bottom nav, which
  /// replaces the current route (see [_onTabTap] and the matching fix in
  /// `homepage.dart`), so there is usually nothing to pop back to. `canPop`
  /// covers both cases correctly: pop if there's a real previous route,
  /// otherwise fall back to Home.
  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed(AppRoutes.home);
    }
  }

  /// Switches bottom-nav tabs. See the doc comment on [_handleBack] for why
  /// this uses `pushReplacementNamed`.
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

  @override
  Widget build(BuildContext context) {
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
                          title: 'General',
                          icon: Icons.tune_rounded,
                          children: [
                            SettingsDropdownTile<AppLanguage>(
                              icon: Icons.language_rounded,
                              label: 'Language',
                              value: _language,
                              options: AppLanguage.values,
                              optionLabel: (o) => o.displayName,
                              onChanged: (value) =>
                                  setState(() => _language = value),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SettingsSection(
                          title: 'Travel Preferences',
                          icon: Icons.alt_route_rounded,
                          children: [
                            SettingsDropdownTile<DefaultTravelMode>(
                              icon: Icons.swap_vert_rounded,
                              label: 'Default Mode',
                              value: _defaultMode,
                              options: DefaultTravelMode.values,
                              optionLabel: (o) => o.displayName,
                              onChanged: (value) =>
                                  setState(() => _defaultMode = value),
                            ),
                            SettingsTextFieldTile(
                              icon: Icons.home_rounded,
                              label: 'Home Address',
                              controller: _homeAddressController,
                              hintText: 'Enter your home address',
                              validator: _validateAddress,
                            ),
                            SettingsTextFieldTile(
                              icon: Icons.work_outline_rounded,
                              label: 'Work Address',
                              controller: _workAddressController,
                              hintText: 'Enter your work address',
                              validator: _validateAddress,
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
                              value: _selectedCar,
                              options: CarModel.predefinedCars,
                              optionLabel: (o) => o.name,
                              onChanged: _onCarModelChanged,
                            ),
                            SettingsDropdownTile<FuelType>(
                              icon: Icons.local_gas_station_rounded,
                              label: 'Fuel Type',
                              value: _fuelType,
                              options: FuelType.values,
                              optionLabel: (o) => o.displayName,
                              onChanged: (value) => setState(() {
                                _fuelType = value;
                                // A manual override no longer matches the
                                // selected preset exactly, so fall back to
                                // "Other" rather than leave a stale car
                                // name showing above a value it didn't
                                // actually provide.
                                _selectedCar = CarModel.custom;
                              }),
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
                              value: _priceAlerts,
                              onChanged: (value) =>
                                  setState(() => _priceAlerts = value),
                            ),
                            SettingsSwitchTile(
                              icon: Icons.cloud_outlined,
                              label: 'Weather Alerts',
                              subtitle: 'Warnings along your routes',
                              value: _weatherAlerts,
                              onChanged: (value) =>
                                  setState(() => _weatherAlerts = value),
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
                            SettingsLinkTile(
                              icon: Icons.privacy_tip_outlined,
                              label: 'Privacy Policy',
                              onTap: () => _showComingSoon('Privacy Policy'),
                            ),
                            SettingsLinkTile(
                              icon: Icons.description_outlined,
                              label: 'Terms of Use',
                              onTap: () => _showComingSoon('Terms of Use'),
                            ),
                            SettingsLinkTile(
                              icon: Icons.mail_outline_rounded,
                              label: 'Contact Us',
                              onTap: () => _showComingSoon('Contact Us'),
                            ),
                            SettingsLinkTile(
                              icon: Icons.feedback_outlined,
                              label: 'Send Feedback',
                              onTap: () => _showComingSoon('Send Feedback'),
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
