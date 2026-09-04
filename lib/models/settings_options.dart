/// Display language for the app.
enum AppLanguage {
  english('English'),
  malay('Bahasa Melayu'),
  chinese('中文');

  const AppLanguage(this.displayName);

  /// Human-readable label shown in the dropdown.
  final String displayName;
}

/// Default travel mode used to pre-select what a comparison should
/// optimise for.
///
/// [fastest]/[cheapest] map directly onto what this app is actually for —
/// trading time against money when comparing transit vs driving — so the
/// user picks which one they'd rather default to: get there quickly
/// regardless of cost, or spend as little as possible regardless of time.
enum DefaultTravelMode {
  fastest('Fastest'),
  cheapest('Cheapest');

  const DefaultTravelMode(this.displayName);

  /// Human-readable label shown in the dropdown.
  final String displayName;
}

/// Vehicle fuel type, used to estimate driving costs.
///
/// Names match the keys already used by `Defaults.defaultFuelType` in
/// `utils/constants.dart` and by the `FuelPrice` model (`ron95`, `ron97`,
/// `diesel`), so a value here can be looked up directly against a fetched
/// `FuelPrice` once Vehicle Details is wired to the real fuel price service.
///
/// The Settings mockup's dropdown showed a generic "Petrol" placeholder;
/// RON95/RON97/Diesel is kept here instead since it matches the fuel types
/// this app's own Fuel Price Service actually tracks.
enum FuelType {
  ron95('RON95'),
  ron97('RON97'),
  diesel('Diesel');

  const FuelType(this.displayName);

  /// Human-readable label shown in the dropdown.
  final String displayName;
}
