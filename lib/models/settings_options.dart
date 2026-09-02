/// Display language for the app.
enum AppLanguage {
  english('English'),
  malay('Bahasa Melayu'),
  chinese('中文');

  const AppLanguage(this.displayName);

  /// Human-readable label shown in the dropdown.
  final String displayName;
}

/// Default travel mode used to pre-select a recommendation when a
/// comparison first loads.
///
/// [fastest] matches the mockup's default selected value and pairs with
/// this app's rules-based recommendation engine (recommend whichever mode
/// is quicker, unless a stronger signal like heavy rain overrides it).
enum DefaultTravelMode {
  fastest('Fastest'),
  transit('Transit'),
  driving('Driving');

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
